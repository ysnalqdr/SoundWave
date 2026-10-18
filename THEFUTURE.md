# 🔍 SOUNDWAVE — REVIEW SISTEM LENGKAP

> Disimpan: 2026-10-15 | Key: thefuture

---

## 👨‍💻 1. WEB/MOBILE DEVELOPER

**Kekuatan:**
- Flutter pilihan tepat — 1 codebase, performa native, bisa Android + iOS
- Riverpod state management — modern, bisa di-test, lebih bagus dari Provider
- `qr_flutter` + tanda tangan kriptografis Ed25519 untuk validasi tiket offline — pintar, gate scanner tidak butuh internet
- URL backend dinamis via Firestore `events._backend_config` — APK tidak perlu rebuild kalau tunnel berubah
- Atomic checkout pakai `revisionCounter` + `runTransaction()` — standar industri untuk cegah race condition

**Kelemahan:**
- **Backend monolitik**: `server.js` 1124 baris di 1 file. Harus dipecah: `routes/pembayaran.js`, `routes/tiket.js`, `middleware/auth.js`, `services/midtrans.js`
- **Tidak ada versioning API**: `/checkout-atomic` tanpa prefix `/api/v1/`. Kalau ada breaking change, client lama crash
- **Tidak ada rate limiting**: Endpoint publik tanpa pembatasan. 1 user bisa spam 1000x/detik
- **Tidak ada automated test**: 0 unit test, 0 integration test. Setiap patch = test manual di HP
- **Tidak ada CI/CD**: Build manual via terminal
- **APK 207MB debug build**: Production harus ~20-30MB pakai `--release` + R8 + `--split-per-abi`
- **Tidak ada validasi input**: Backend terima JSON apa saja, tidak ada schema validation

---

## 🏗️ 2. SOFTWARE ENGINEER

**Skema Arsitektur:**
```
┌─────────────┐     HTTPS      ┌──────────────┐     ┌──────────────┐
│   Flutter    │ ──────────────▶│ Cloudflare   │────▶│  Node.js     │
│   APK        │                │ Tunnel       │     │  server.js   │
│              │                │ (sementara)  │     │  (port 3000) │
└──────┬───────┘                └──────────────┘     └──────┬───────┘
       │                                                    │
       │              ┌──────────────┐                     │
       └──────────────│  Firestore   │◀────────────────────┘
                      │  (Spark)     │
                      └──────────────┘
```

**Masalah Kritis:**
- **Single point of failure**: Backend jalan di 1 laptop. Laptop mati = seluruh sistem pembayaran mati
- **Tidak ada graceful shutdown**: Hard kill = transaksi yang lagi jalan bisa corrupt
- **Tidak ada process manager**: Tidak ada PM2/Docker. Restart = manual
- **Cloudflare TryCloudflare**: URL berubah setiap restart. Ada jeda 5-10 detik request gagal
- **Tidak ada pemisahan environment**: 1 `.env`, 1 Firestore project untuk dev/staging/prod
- **Tidak ada database migration**: Perubahan schema manual
- **Duplikasi kode**: `loadOrderForCharge()` duplikat logic `/checkout-atomic`
- **Tidak ada audit log**: Admin hapus konser/tiket tidak tercatat

**Kualitas Kode:**
- `checkout_screen.dart` 2112 baris — harus dipecah jadi 5 file
- `server.js` campur routes + business logic + Midtrans + Firebase + crypto — tidak ada separation of concerns
- Penamaan tidak konsisten: `warnaHarga` (ID) vs `accent` (EN) vs `_SwWhite.green`

---

## 🔧 3. FULLSTACK ENGINEER

**Backend:**
- Integrasi Midtrans: Snap API + Core API — pendekatan benar
- Verifikasi signature webhook SHA512 — bagus
- Cek idempotency mencegah double-decrement — bagus
- **TAPI**: Webhook belum di-register di dashboard Midtrans → status tidak auto-update
- **Tidak ada retry queue**: Midtrans API timeout = user stuck
- **Tidak ada idempotency key**: Double-tap = 2 VA number untuk 1 order

**Database (Firestore):**
- Spark plan: 50K reads/hari, 20K writes/hari. Konser viral = **hit limit di siang hari**
- Tidak ada composite indexes
- Tidak ada strategi arsip data

**Frontend:**
- Auto-refresh 3 detik via `ref.refresh()` = boros Firestore reads. Harus pakai `snapshots()` listener
- Tidak ada optimistic UI updates
- Tidak ada fallback image

**Infrastruktur:**
- Tidak ada monitoring/alerting
- Tidak ada backup
- Tidak ada CDN

---

## 💼 4. BISNISMAN

**Peluang Pasar:**
- Pasar ticketing event Indonesia: Rp 5-10 triliun/tahun (tumbuh 15%/tahun)
- Kompetitor: Loket, Tiket.com, GoTix — charge 3-5% + Rp 2,500-5,000/tiket
- Model Soundwave: Rp 5,000 flat — **terlalu murah**. Kompetitor charge Rp 15,000-25,000/tiket VIP
- Target: event kampus, konser indie, festival lokal — pasar underserved

**Masalah Pendapatan:**
- Margin cuma Rp 1,300/tiket (Rp 5,000 - fee Midtrans ~Rp 3,700)
- Biaya production: VPS Rp 200K/bln, domain, Midtrans 3%, Firebase Blaze Rp 300K-1M/bln
- Break-even: ~500 tiket/bulan

**Fitur Bisnis Kurang:**
- Kode promo, early bird, group discount
- Program afiliasi/referral
- Dashboard organizer self-service
- Dashboard analitik pendapatan
- Workflow refund/pembatalan
- Invoice/faktur pajak
- Pemilihan kursi spesifik

---

## 😈 5. DEVIL'S ADVOCATE

1. **Cloudflare TryCloudflare BUKAN production.** "Quick tunnels are meant to be used for testing, not production."
2. **Firebase Spark plan akan collapse saat viral.** 50K reads/hari. 2,000 user/hari = limit habis
3. **Laptop sebagai server = tidak viable production.** WiFi putus, Windows update, battery habis = sistem down
4. **Private key Ed25519 hardcoded di server.js.** Siapapun bisa palsukan QR tiket valid
5. **Tidak kepatuhan UU PDP (UU 27/2022).** Denda 2% pendapatan tahunan
6. **APK 207MB tanpa obfuscation.** Bisa decompile, baca endpoint, clone dalam 1 hari
7. **Tidak ada deteksi penipuan.** 1 user = 100 tiket dengan 100 email. Surga calo
8. **Webhook belum registered.** User bayar → status PENDING selamanya
9. **Tidak ada disaster recovery.** Laptop dicuri/crash = SEMUA DATA HILANG
10. **Ilusi "gratis".** Production minimum $50-100/bulan

---

## 🎨 6. UI/UX DESIGNER

**Kondisi:**
- Dark theme (hitam + hijau accent) — bold, modern, cocok untuk brand musik
- Rajdhani untuk heading, Space Grotesk untuk body
- Kartu tiket dengan divider berlubang — detail excellent
- QR scanner overlay dengan corner brackets — profesional

**Masalah:**
1. Tema tidak konsisten: app dark → checkout putih → Midtrans putih
2. Tidak ada empty state dengan ilustrasi
3. Tidak ada loading skeleton (shimmer ada tapi tidak dipakai)
4. Tidak ada error recovery dengan retry button
5. 3-step checkout mungkin terlalu banyak tap (kompetitor 2 tap)
6. Tidak ada indikator progress stepper
7. Tidak ada haptic feedback di aksi kritis
8. Tidak ada accessibility (screen reader, large text)
9. Denah venue text terlalu kecil di HP kecil
10. Form admin tidak handle layar kecil dengan baik

---

## 📋 SARAN PRIORITAS

### 🔴 PRIORITAS 0 — KRITIS (Sebelum go-live):
| # | Aksi | Waktu |
|---|------|-------|
| 1 | Register webhook Midtrans di dashboard | 10 menit |
| 2 | Firebase Blaze plan ($25/bln) | 1 jam |
| 3 | Deploy ke VPS (Render/Railway $5-7/bln) | 2-3 jam |
| 4 | Registrasi Midtrans production (KYC) | 3-5 hari |
| 5 | Build APK release + R8 obfuscation | 1 jam |
| 6 | Ed25519 key: generate baru, simpan di env | 30 menit |
| 7 | Privacy policy + dialog persetujuan (UU PDP) | 1 hari |

### 🟡 PRIORITAS 1 — PENTING (Bulan 1):
| # | Aksi | Waktu |
|---|------|-------|
| 8 | Refactor server.js jadi modular | 1 hari |
| 9 | Pecah checkout_screen.dart jadi 5 file | 1 hari |
| 10 | Rate limiting (express-rate-limit) | 1 jam |
| 11 | Validasi input (Zod/Joi) | 2-3 jam |
| 12 | Sentry error tracking | 30 menit |
| 13 | Firestore indexes | 1 jam |
| 14 | Real-time listener ganti polling | 2-3 jam |
| 15 | Pemilihan kursi spesifik | 3-5 hari |

### 🟢 PRIORITAS 2 — BAGUS DIPUNYA (Bulan 2-3):
| # | Aksi | Waktu |
|---|------|-------|
| 16 | Kode promo & early bird | 2 hari |
| 17 | Dashboard organizer self-service | 1 minggu |
| 18 | Publikasi Google Play Store | 2-3 hari |
| 19 | Build iOS | 1-2 hari |
| 20 | Dashboard analitik | 3-5 hari |
| 21 | Deteksi penipuan (CAPTCHA, velocity check) | 2-3 hari |
| 22 | Backup otomatis | 2 jam |
| 23 | CI/CD pipeline (GitHub Actions) | 1 hari |
| 24 | Web admin panel | 1 minggu |
| 25 | Workflow refund | 2-3 hari |

---

**Kesimpulan:** Soundwave sebagai demo/prototype tugas kampus = excellent. Fondasi kuat (atomic checkout, QR kriptografis, URL backend dinamis). Soundwave sebagai produk production = belum siap, tapi semua masalah bisa diperbaiki tanpa rewrite.
