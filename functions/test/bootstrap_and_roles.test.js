const assert = require('assert');

// Mock Firestore Database
class MockFirestore {
  constructor() {
    this.users = new Map();
  }

  collection(col) {
    if (col !== 'users') throw new Error(`Unexpected collection: ${col}`);
    const self = this;
    return {
      doc(id) {
        return {
          async get() {
            const exists = self.users.has(id);
            return {
              exists,
              data: () => self.users.get(id),
            };
          },
          async set(data) {
            self.users.set(id, { ...data, id });
          },
          async update(data) {
            if (!self.users.has(id)) throw new Error('Not found');
            const existing = self.users.get(id);
            self.users.set(id, { ...existing, ...data });
          },
        };
      },
      where(field, op, value) {
        return {
          limit(n) {
            return {
              async get() {
                const results = [];
                for (const [id, doc] of self.users.entries()) {
                  if (doc[field] === value) {
                    results.push({ id, data: () => doc });
                  }
                  if (results.length >= n) break;
                }
                return {
                  empty: results.length === 0,
                  docs: results,
                };
              },
            };
          },
        };
      },
    };
  }
}

// Logic mirror of exports.bootstrapSuperAdmin from functions/index.js
async function runBootstrapSuperAdmin(db, context, env = {}) {
  if (!context || !context.auth) {
    throw new Error('unauthenticated: Login diperlukan.');
  }

  const bootstrapEmail = env.SUPER_ADMIN_EMAIL || 'admin@soundwave.id';

  if (context.auth.token.email !== bootstrapEmail) {
    throw new Error('permission-denied: Email Anda tidak memiliki hak untuk bootstrap super admin.');
  }

  const existingSuperAdmins = await db.collection('users')
    .where('role', '==', 'super_admin')
    .limit(1)
    .get();

  if (!existingSuperAdmins.empty) {
    throw new Error('already-exists: Super admin sudah ada di sistem. Bootstrap tidak dapat dijalankan lagi.');
  }

  const callerRef = db.collection('users').doc(context.auth.uid);
  const callerDoc = await callerRef.get();

  if (callerDoc.exists) {
    await callerRef.update({
      role: 'super_admin',
    });
  } else {
    await callerRef.set({
      nama: context.auth.token.name || 'Super Admin',
      email: context.auth.token.email,
      role: 'super_admin',
    });
  }

  return {
    success: true,
    uid: context.auth.uid,
  };
}

// Logic mirror of exports.promoteToAdmin from functions/index.js
async function runPromoteToAdmin(db, data, context) {
  if (!context || !context.auth) {
    throw new Error('unauthenticated: Login diperlukan.');
  }

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
    throw new Error('permission-denied: Hanya super_admin yang berhak mengubah role pengguna.');
  }

  const { targetUid, newRole } = data;
  if (!targetUid || !newRole) {
    throw new Error('invalid-argument: targetUid dan newRole wajib disertakan.');
  }

  if (targetUid === context.auth.uid) {
    throw new Error('failed-precondition: Super admin tidak dapat mengubah role akun sendiri via endpoint ini.');
  }

  if (!['admin', 'user'].includes(newRole)) {
    throw new Error('invalid-argument: Role baru hanya boleh "admin" atau "user".');
  }

  const targetRef = db.collection('users').doc(targetUid);
  const targetDoc = await targetRef.get();
  if (!targetDoc.exists) {
    throw new Error('not-found: Pengguna target tidak ditemukan.');
  }

  await targetRef.update({ role: newRole });
  return { success: true, message: `Role pengguna berhasil diubah menjadi ${newRole}.` };
}

async function runTests() {
  console.log('--- RUNNING CLOUD FUNCTIONS RUNTIME QA TESTS ---');
  const db = new MockFirestore();

  // Test A: unauthenticated caller
  await assert.rejects(
    async () => runBootstrapSuperAdmin(db, null),
    /unauthenticated/,
    'A. Unauthenticated caller must be rejected'
  );
  console.log('PASS: Test A: unauthenticated caller rejected');

  // Test B: authenticated user with wrong email
  await assert.rejects(
    async () => runBootstrapSuperAdmin(db, {
      auth: { uid: 'user_wrong', token: { email: 'wrong@soundwave.id' } }
    }),
    /permission-denied/,
    'B. Authenticated user with wrong email must be rejected'
  );
  console.log('PASS: Test B: wrong email rejected');

  // Test C: designated bootstrap identity accepted when no super_admin exists
  const resC = await runBootstrapSuperAdmin(db, {
    auth: { uid: 'bootstrap_uid', token: { email: 'admin@soundwave.id', name: 'Super Admin Initial' } }
  });
  assert.strictEqual(resC.success, true);
  const createdDoc = await db.collection('users').doc('bootstrap_uid').get();
  assert.strictEqual(createdDoc.data().role, 'super_admin');
  console.log('PASS: Test C: designated bootstrap accepted, role == super_admin');

  // Test D: after super_admin exists -> reject further bootstrap
  await assert.rejects(
    async () => runBootstrapSuperAdmin(db, {
      auth: { uid: 'second_bootstrap_uid', token: { email: 'admin@soundwave.id' } }
    }),
    /already-exists/,
    'D. Further bootstrap attempts must be permanently rejected'
  );
  console.log('PASS: Test D: subsequent bootstrap permanently rejected');

  // Test Role Security via promoteToAdmin:
  // Seed regular user
  await db.collection('users').doc('regular_user').set({
    nama: 'Buyer User',
    email: 'buyer@soundwave.id',
    role: 'user',
  });

  // 1. Regular user calling promoteToAdmin -> rejected
  await assert.rejects(
    async () => runPromoteToAdmin(db, { targetUid: 'regular_user', newRole: 'admin' }, {
      auth: { uid: 'regular_user', token: { email: 'buyer@soundwave.id' } }
    }),
    /permission-denied/
  );
  console.log('PASS: Role Security: USER cannot promote self or others');

  // 2. Admin calling promoteToAdmin -> rejected
  await db.collection('users').doc('admin_user').set({
    nama: 'Admin Gate',
    email: 'admin_gate@soundwave.id',
    role: 'admin',
  });
  await assert.rejects(
    async () => runPromoteToAdmin(db, { targetUid: 'admin_user', newRole: 'super_admin' }, {
      auth: { uid: 'admin_user', token: { email: 'admin_gate@soundwave.id' } }
    }),
    /permission-denied/
  );
  console.log('PASS: Role Security: ADMIN cannot promote self or others');

  // 3. Super admin promoting regular user to admin -> succeeds
  const resPromote = await runPromoteToAdmin(db, { targetUid: 'regular_user', newRole: 'admin' }, {
    auth: { uid: 'bootstrap_uid', token: { email: 'admin@soundwave.id' } }
  });
  assert.strictEqual(resPromote.success, true);
  const updatedDoc = await db.collection('users').doc('regular_user').get();
  assert.strictEqual(updatedDoc.data().role, 'admin');
  console.log('PASS: Role Security: SUPER_ADMIN successfully promotes user to admin');

  // 4. Super admin demoting admin back to user -> succeeds
  const resDemote = await runPromoteToAdmin(db, { targetUid: 'regular_user', newRole: 'user' }, {
    auth: { uid: 'bootstrap_uid', token: { email: 'admin@soundwave.id' } }
  });
  assert.strictEqual(resDemote.success, true);
  const demotedDoc = await db.collection('users').doc('regular_user').get();
  assert.strictEqual(demotedDoc.data().role, 'user');
  console.log('PASS: Role Security: SUPER_ADMIN successfully demotes admin to user');

  // 5. Super admin trying to promote self via endpoint -> rejected
  await assert.rejects(
    async () => runPromoteToAdmin(db, { targetUid: 'bootstrap_uid', newRole: 'user' }, {
      auth: { uid: 'bootstrap_uid', token: { email: 'admin@soundwave.id' } }
    }),
    /failed-precondition/
  );
  console.log('PASS: Role Security: Self-mutation via promote endpoint rejected');

  // 6. Attempting to grant 'super_admin' via promoteToAdmin -> rejected
  await assert.rejects(
    async () => runPromoteToAdmin(db, { targetUid: 'regular_user', newRole: 'super_admin' }, {
      auth: { uid: 'bootstrap_uid', token: { email: 'admin@soundwave.id' } }
    }),
    /invalid-argument/
  );
  console.log('PASS: Role Security: Cannot grant super_admin via promoteToAdmin');

  console.log('--- ALL BACKEND TESTS PASSED (10/10) ---');
}

runTests().catch(err => {
  console.error('TEST RUNNER FAILED:', err);
  process.exit(1);
});
