// SoundWave — Firestore Security Rules Test Harness
// Emulating @firebase/rules-unit-testing semantics (authenticatedContext, assertSucceeds, assertFails)
// Targeted strictly at local Firestore Emulator (demo-soundwave-rules)

import fs from 'node:fs';
import path from 'node:path';

const EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const PROJECT_ID = 'demo-soundwave-rules';
const BASE_URL = `http://${EMULATOR_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

/**
 * Creates an unsigned JWT structured identically to the token minted by @firebase/rules-unit-testing
 * and Google Firebase client SDKs when connecting to the Firestore Emulator.
 * The Firestore Emulator extracts sub/user_id, email, and claims without verifying cryptographic signature.
 */
function createMockJwt(uid, claims = {}) {
  const header = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
  const payloadObj = {
    sub: uid,
    user_id: uid,
    aud: PROJECT_ID,
    iss: `https://securetoken.google.com/${PROJECT_ID}`,
    auth_time: Math.floor(Date.now() / 1000),
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 3600,
    firebase: {
      sign_in_provider: 'password',
      identities: {}
    },
    ...claims
  };
  const payload = Buffer.from(JSON.stringify(payloadObj)).toString('base64url');
  return `${header}.${payload}.`;
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, val] of Object.entries(obj)) {
    if (val === null || val === undefined) {
      fields[key] = { nullValue: null };
    } else if (typeof val === 'string') {
      fields[key] = { stringValue: val };
    } else if (typeof val === 'number') {
      if (Number.isInteger(val)) {
        fields[key] = { integerValue: val.toString() };
      } else {
        fields[key] = { doubleValue: val };
      }
    } else if (typeof val === 'boolean') {
      fields[key] = { booleanValue: val };
    } else if (Array.isArray(val)) {
      fields[key] = {
        arrayValue: {
          values: val.map(item => {
            if (typeof item === 'string') return { stringValue: item };
            if (typeof item === 'number') return { integerValue: item.toString() };
            if (typeof item === 'boolean') return { booleanValue: item };
            return { stringValue: String(item) };
          })
        }
      };
    } else if (typeof val === 'object') {
      fields[key] = { mapValue: { fields: toFirestoreFields(val) } };
    }
  }
  return fields;
}

class FirestoreContext {
  constructor(authHeader = null, label = 'anonymous') {
    this.authHeader = authHeader;
    this.label = label;
  }

  async get(docPath) {
    const url = `${BASE_URL}/${docPath}`;
    const headers = { 'Content-Type': 'application/json' };
    if (this.authHeader) headers['Authorization'] = this.authHeader;
    const res = await fetch(url, { method: 'GET', headers });
    return { ok: res.ok, status: res.status, statusText: res.statusText };
  }

  async set(docPath, data) {
    const url = `${BASE_URL}/${docPath}`;
    const headers = { 'Content-Type': 'application/json' };
    if (this.authHeader) headers['Authorization'] = this.authHeader;
    const res = await fetch(url, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ fields: toFirestoreFields(data) })
    });
    return { ok: res.ok, status: res.status, statusText: res.statusText };
  }

  async update(docPath, data, fieldPaths = null) {
    let url = `${BASE_URL}/${docPath}`;
    const keys = fieldPaths || Object.keys(data);
    const query = keys.map(f => `updateMask.fieldPaths=${encodeURIComponent(f)}`).join('&');
    url += (url.includes('?') ? '&' : '?') + query;

    const headers = { 'Content-Type': 'application/json' };
    if (this.authHeader) headers['Authorization'] = this.authHeader;
    const res = await fetch(url, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ fields: toFirestoreFields(data) })
    });
    return { ok: res.ok, status: res.status, statusText: res.statusText };
  }

  async delete(docPath) {
    const url = `${BASE_URL}/${docPath}`;
    const headers = { 'Content-Type': 'application/json' };
    if (this.authHeader) headers['Authorization'] = this.authHeader;
    const res = await fetch(url, { method: 'DELETE', headers });
    return { ok: res.ok, status: res.status, statusText: res.statusText };
  }
}

class TestEnvironment {
  constructor(projectId = PROJECT_ID) {
    this.projectId = projectId;
  }

  authenticatedContext(uid, claims = {}) {
    const token = createMockJwt(uid, claims);
    return new FirestoreContext(`Bearer ${token}`, `user(${uid})`);
  }

  unauthenticatedContext() {
    return new FirestoreContext(null, 'unauthenticated');
  }

  async withSecurityRulesDisabled(callback) {
    const adminContext = new FirestoreContext('Bearer owner', 'admin_sdk');
    return await callback(adminContext);
  }

  async clearFirestore() {
    const clearUrl = `http://${EMULATOR_HOST}/emulator/v1/projects/${this.projectId}/databases/(default)/documents`;
    const res = await fetch(clearUrl, { method: 'DELETE' });
    if (!res.ok) {
      console.warn(`[WARN] Could not reset emulator database: ${res.status}`);
    }
  }

  async loadRules(rulesPath = 'firestore.rules') {
    const content = fs.readFileSync(rulesPath, 'utf8');
    const putUrl = `http://${EMULATOR_HOST}/emulator/v1/projects/${this.projectId}/rules`;
    const res = await fetch(putUrl, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        rules: [
          {
            files: [
              {
                name: 'firestore.rules',
                content
              }
            ]
          }
        ]
      })
    });
    return res.ok;
  }
}

// Semantic assertion wrappers matching @firebase/rules-unit-testing
async function assertSucceeds(operationPromise, description = '') {
  const result = await operationPromise;
  if (!result.ok) {
    throw new Error(`Expected operation to SUCCEED, but failed with HTTP ${result.status} (${result.statusText}). Context: ${description}`);
  }
  return result;
}

async function assertFails(operationPromise, description = '') {
  const result = await operationPromise;
  if (result.ok) {
    throw new Error(`Expected operation to FAIL (PERMISSION_DENIED), but SUCCEEDED with HTTP ${result.status}. Context: ${description}`);
  }
  if (result.status !== 403 && result.status !== 400) {
    console.warn(`[NOTICE] Rejection returned HTTP ${result.status} instead of standard 403 for: ${description}`);
  }
  return result;
}

async function runTestSuite() {
  console.log('================================================================');
  console.log('SOUNDWAVE — FIRESTORE RULES UNIT TEST HARNESS');
  console.log(`Target: http://${EMULATOR_HOST} | Project: ${PROJECT_ID}`);
  console.log('Using @firebase/rules-unit-testing semantics & unsigned JWT wire spec');
  console.log('================================================================\n');

  const testEnv = new TestEnvironment(PROJECT_ID);

  // 1. Load actual local firestore.rules
  console.log('[Setup] Loading local firestore.rules into emulator...');
  const rulesLoaded = await testEnv.loadRules('firestore.rules');
  console.log(`[Setup] Rules loaded: ${rulesLoaded ? 'SUCCESS' : 'EMULATOR JAR DEFAULT (Active)'}`);

  // 2. Clear previous state and seed test fixtures via Admin SDK (withSecurityRulesDisabled)
  console.log('[Setup] Clearing and seeding fixtures with security rules disabled...');
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (admin) => {
    // Seed users with roles
    await admin.set('users/user_alice', { role: 'user', email: 'alice@test.com', createdAt: '2026-01-01' });
    await admin.set('users/user_dave', { role: 'user', email: 'dave@test.com', createdAt: '2026-01-01' });
    await admin.set('users/admin_bob', { role: 'admin', email: 'bob@test.com', createdAt: '2026-01-01' });
    await admin.set('users/super_charlie', { role: 'super_admin', email: 'charlie@test.com', createdAt: '2026-01-01' });

    // Seed events & tickets
    await admin.set('events/event_coldplay', { judul: 'Coldplay Live', status: 'PUBLISHED' });
    await admin.set('tickets/ticket_coldplay_vvip', {
      idKonser: 'event_coldplay',
      kategori: 'VVIP',
      harga: 3500000,
      stok: 50,
      zona: 'VVIP Royal Pass (Front Row)'
    });
  });
  console.log('[Setup] Test fixtures seeded.\n');

  const alice = testEnv.authenticatedContext('user_alice', { email: 'alice@test.com' });
  const dave = testEnv.authenticatedContext('user_dave', { email: 'dave@test.com' });
  const bobAdmin = testEnv.authenticatedContext('admin_bob', { email: 'bob@test.com' });
  const charlieSuper = testEnv.authenticatedContext('super_charlie', { email: 'charlie@test.com' });
  const unauth = testEnv.unauthenticatedContext();

  let passedCount = 0;
  let failedCount = 0;
  const findings = [];

  async function test(name, fn) {
    try {
      await fn();
      console.log(`[PASS] ${name}`);
      passedCount++;
    } catch (err) {
      console.error(`[FAIL] ${name}\n       -> ${err.message}`);
      failedCount++;
      findings.push({ name, error: err.message });
    }
  }

  // --- 9 REQUIRED SCENARIOS ---

  // 1. User dapat membuat dan menghapus favorit sendiri
  await test('Skenario 1: User dapat membuat dan menghapus favorit sendiri', async () => {
    await assertSucceeds(
      alice.set('favorites/fav_alice_coldplay', { userId: 'user_alice', eventId: 'event_coldplay' }),
      'Alice creates own favorite'
    );
    await assertSucceeds(
      alice.get('favorites/fav_alice_coldplay'),
      'Alice reads own favorite'
    );
    await assertSucceeds(
      alice.delete('favorites/fav_alice_coldplay'),
      'Alice deletes own favorite'
    );
  });

  // 2. User dan admin tidak dapat membaca atau menghapus favorit pengguna lain, kecuali kebijakan eksplisit memang membutuhkannya
  await test('Skenario 2a: User tidak dapat membaca, mengubah, atau menghapus favorit pengguna lain', async () => {
    // Seed Dave's favorite via admin
    await testEnv.withSecurityRulesDisabled(async (admin) => {
      await admin.set('favorites/fav_dave_coldplay', { userId: 'user_dave', eventId: 'event_coldplay' });
    });

    await assertFails(
      alice.get('favorites/fav_dave_coldplay'),
      'Alice reads Dave favorite'
    );
    await assertFails(
      alice.update('favorites/fav_dave_coldplay', { eventId: 'event_hacked' }),
      'Alice updates Dave favorite'
    );
    await assertFails(
      alice.delete('favorites/fav_dave_coldplay'),
      'Alice deletes Dave favorite'
    );
    // Favorit juga harus immutable (pemilik pun tidak boleh update)
    await testEnv.withSecurityRulesDisabled(async (admin) => {
      await admin.set('favorites/fav_alice_fixed', { userId: 'user_alice', eventId: 'event_coldplay' });
    });
    await assertFails(
      alice.update('favorites/fav_alice_fixed', { eventId: 'event_modified' }),
      'Alice tries to update own favorite (must be rejected - favorites are immutable)'
    );
  });

  // 2b. Admin dan superadmin tidak dapat membaca atau menghapus favorit pengguna lain
  await test('Skenario 2b: Admin dan Superadmin tidak dapat membaca atau menghapus favorit pengguna lain', async () => {
    await assertFails(
      bobAdmin.get('favorites/fav_dave_coldplay'),
      'Admin Bob attempts to read Dave favorite (must be rejected - personal user bookmark)'
    );
    await assertFails(
      bobAdmin.delete('favorites/fav_dave_coldplay'),
      'Admin Bob attempts to delete Dave favorite (must be rejected)'
    );
    await assertFails(
      charlieSuper.get('favorites/fav_dave_coldplay'),
      'Superadmin Charlie attempts to read Dave favorite (must be rejected - personal user bookmark)'
    );
    await assertFails(
      charlieSuper.delete('favorites/fav_dave_coldplay'),
      'Superadmin Charlie attempts to delete Dave favorite (must be rejected)'
    );
  });

  // 3. Admin tidak dapat mengubah role atau menghapus dokumen pengguna
  await test('Skenario 3: Admin tidak dapat mengubah role atau menghapus dokumen pengguna', async () => {
    await assertFails(
      bobAdmin.update('users/user_alice', { role: 'admin' }, ['role']),
      'Admin Bob attempts to change Alice role'
    );
    await assertFails(
      bobAdmin.delete('users/user_alice'),
      'Admin Bob attempts to delete Alice user document'
    );
    // User juga tidak boleh eskalasi role sendiri atau hapus dokumen
    await assertFails(
      alice.update('users/user_alice', { role: 'super_admin' }, ['role']),
      'Alice attempts to self-escalate role'
    );
    await assertFails(
      alice.delete('users/user_alice'),
      'Alice attempts to delete own user document'
    );
  });

  // 4. Superadmin hanya dapat melakukan perubahan role sesuai kebijakan bisnis
  await test('Skenario 4: Superadmin hanya dapat melakukan perubahan role sesuai kebijakan bisnis', async () => {
    // Valid role change on another user
    await assertSucceeds(
      charlieSuper.update('users/user_dave', { role: 'admin' }, ['role']),
      'Superadmin Charlie sets Dave to admin'
    );
    await assertSucceeds(
      charlieSuper.update('users/user_dave', { role: 'user' }, ['role']),
      'Superadmin Charlie reverts Dave to user'
    );
    // Illegal role
    await assertFails(
      charlieSuper.update('users/user_dave', { role: 'super_hacker' }, ['role']),
      'Superadmin Charlie attempts to assign invalid role name'
    );
    // Cannot modify own role
    await assertFails(
      charlieSuper.update('users/super_charlie', { role: 'user' }, ['role']),
      'Superadmin Charlie attempts to demote own role'
    );
    // Cannot delete another super_admin
    await testEnv.withSecurityRulesDisabled(async (admin) => {
      await admin.set('users/super_second', { role: 'super_admin', email: 'second@test.com' });
    });
    await assertFails(
      charlieSuper.delete('users/super_second'),
      'Superadmin Charlie attempts to delete another super_admin'
    );
  });

  // 5. Buyer tidak dapat mengubah harga atau stok tiket
  await test('Skenario 5: Buyer tidak dapat mengubah harga atau stok tiket', async () => {
    await assertFails(
      alice.update('tickets/ticket_coldplay_vvip', { harga: 10000 }, ['harga']),
      'Buyer Alice attempts to change ticket price'
    );
    await assertFails(
      alice.update('tickets/ticket_coldplay_vvip', { stok: 999 }, ['stok']),
      'Buyer Alice attempts to modify ticket stock'
    );
    await assertFails(
      alice.delete('tickets/ticket_coldplay_vvip'),
      'Buyer Alice attempts to delete ticket'
    );
    // Admin update must succeed
    await assertSucceeds(
      bobAdmin.update('tickets/ticket_coldplay_vvip', { stok: 48 }, ['stok']),
      'Admin Bob updates ticket stock'
    );
  });

  // 6. Buyer tidak dapat membuat order langsung berstatus PAID
  await test('Skenario 6: Buyer tidak dapat membuat order langsung berstatus PAID', async () => {
    await assertFails(
      alice.set('orders/order_paid_tamper', {
        userId: 'user_alice',
        status: 'PAID',
        kodeBooking: 'SW-TAMPER-01',
        idKonser: 'event_coldplay',
        judulKonser: 'Coldplay Live',
        kategoriTiket: 'VVIP',
        jumlahTiket: 1,
        totalHarga: 3500000,
        tanggalBeli: '2026-10-15'
      }),
      'Buyer Alice attempts to create order with status PAID directly'
    );

    // Order berstatus PENDING dengan struktur lengkap diizinkan
    await assertSucceeds(
      alice.set('orders/order_alice_pending', {
        userId: 'user_alice',
        status: 'PENDING',
        kodeBooking: 'SW-VALID-01',
        idKonser: 'event_coldplay',
        judulKonser: 'Coldplay Live',
        kategoriTiket: 'VVIP',
        jumlahTiket: 1,
        totalHarga: 3500000,
        tanggalBeli: '2026-10-15'
      }),
      'Buyer Alice creates legitimate order with status PENDING'
    );
  });

  // 7. Buyer tidak dapat mengubah order PENDING yang sudah ada menjadi PAID
  await test('Skenario 7: Buyer tidak dapat mengubah order PENDING yang sudah ada menjadi PAID', async () => {
    await assertFails(
      alice.update('orders/order_alice_pending', { status: 'PAID' }, ['status']),
      'Buyer Alice attempts to update status to PAID'
    );
    // Buyer hanya diizinkan membatalkan (CANCELLED)
    await assertSucceeds(
      alice.update('orders/order_alice_pending', { status: 'CANCELLED', updatedAt: '2026-10-15T10:00:00Z' }, ['status', 'updatedAt']),
      'Buyer Alice cancels own pending order'
    );
  });

  // 8. Buyer tidak dapat mengubah harga, total pembayaran, atau field settlement otoritatif
  await test('Skenario 8: Buyer tidak dapat mengubah harga, total pembayaran, atau field settlement yang bersifat otoritatif', async () => {
    // Seed pesanan pending baru
    await testEnv.withSecurityRulesDisabled(async (admin) => {
      await admin.set('orders/order_alice_locked', {
        userId: 'user_alice',
        status: 'PENDING',
        kodeBooking: 'SW-LOCKED-01',
        idKonser: 'event_coldplay',
        judulKonser: 'Coldplay Live',
        kategoriTiket: 'VVIP',
        jumlahTiket: 2,
        totalHarga: 7000000,
        tanggalBeli: '2026-10-15'
      });
    });

    await assertFails(
      alice.update('orders/order_alice_locked', { totalHarga: 1000 }, ['totalHarga']),
      'Buyer Alice attempts to change totalHarga'
    );
    await assertFails(
      alice.update('orders/order_alice_locked', { jumlahTiket: 10 }, ['jumlahTiket']),
      'Buyer Alice attempts to modify jumlahTiket'
    );
    await assertFails(
      alice.update('orders/order_alice_locked', { status: 'CANCELLED', totalHarga: 0 }, ['status', 'totalHarga']),
      'Buyer Alice attempts to sneak totalHarga change during cancellation'
    );
  });

  // 9. Permintaan tanpa autentikasi ditolak pada operasi privat
  await test('Skenario 9: Permintaan tanpa autentikasi ditolak pada operasi privat', async () => {
    // Akses privat tanpa auth ditolak
    await assertFails(unauth.get('users/user_alice'), 'Unauthenticated read user doc');
    await assertFails(unauth.get('orders/order_alice_locked'), 'Unauthenticated read order doc');
    await assertFails(unauth.get('favorites/fav_alice_fixed'), 'Unauthenticated read favorite doc');
    await assertFails(
      unauth.set('orders/order_unauth', {
        userId: 'user_anon',
        status: 'PENDING',
        kodeBooking: 'ANON',
        idKonser: 'event_coldplay',
        judulKonser: 'Coldplay',
        kategoriTiket: 'VVIP',
        jumlahTiket: 1,
        totalHarga: 3500000,
        tanggalBeli: '2026-10-15'
      }),
      'Unauthenticated create order'
    );

    // Operasi publik diizinkan
    await assertSucceeds(unauth.get('events/event_coldplay'), 'Unauthenticated read public event');
    await assertSucceeds(unauth.get('tickets/ticket_coldplay_vvip'), 'Unauthenticated read public ticket');
  });

  // 10. Voucher (claimed_promos) hanya milik user sendiri
  await test('Skenario 10: Voucher terklaim hanya dapat diakses pemiliknya', async () => {
    await assertSucceeds(
      alice.set('users/user_alice/claimed_promos/promo_hemat10', {
        promoId: 'promo_hemat10', kode: 'HEMAT10', tipe: 'percentage', nilai: 10, used: false
      }),
      'Alice claims own promo'
    );
    await assertSucceeds(
      alice.get('users/user_alice/claimed_promos/promo_hemat10'),
      'Alice reads own claimed promo'
    );
    await assertSucceeds(
      alice.update('users/user_alice/claimed_promos/promo_hemat10', { used: true, orderId: 'order_1' }),
      'Alice marks own claimed promo as used'
    );
    await assertFails(
      dave.get('users/user_alice/claimed_promos/promo_hemat10'),
      'Dave reads Alice claimed promo'
    );
    await assertFails(
      dave.set('users/user_alice/claimed_promos/promo_stolen', { promoId: 'promo_stolen', kode: 'X' }),
      'Dave writes into Alice claimed promos'
    );
    await assertSucceeds(
      bobAdmin.get('users/user_alice/claimed_promos/promo_hemat10'),
      'Admin reads claimed promo for audit'
    );
    await assertFails(
      bobAdmin.set('users/user_alice/claimed_promos/promo_adminwrite', { promoId: 'promo_adminwrite', kode: 'X' }),
      'Admin cannot write another user claimed promo'
    );
    await assertFails(
      unauth.get('users/user_alice/claimed_promos/promo_hemat10'),
      'Unauthenticated reads claimed promo'
    );
  });

  // 11. promo_codes: baca butuh login, tulis hanya admin
  await test('Skenario 11: promo_codes hanya dibaca user login dan ditulis admin', async () => {
    await assertSucceeds(
      bobAdmin.set('promo_codes/promo_hemat10', {
        kode: 'HEMAT10', tipe: 'percentage', nilai: 10, minPembelian: 0, aktif: true
      }),
      'Admin creates promo code'
    );
    await assertSucceeds(
      alice.get('promo_codes/promo_hemat10'),
      'Signed-in user reads promo code'
    );
    await assertFails(
      unauth.get('promo_codes/promo_hemat10'),
      'Unauthenticated reads promo code'
    );
    await assertFails(
      alice.set('promo_codes/promo_evil', { kode: 'EVIL', aktif: true }),
      'Regular user writes promo code'
    );
  });

  console.log('\n================================================================');
  console.log(`REKAPITULASI PENGUJIAN: ${passedCount} LULUS, ${failedCount} GAGAL`);
  console.log('================================================================\n');

  if (failedCount > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

runTestSuite().catch(err => {
  console.error('Fatal harness error:', err);
  process.exit(1);
});
