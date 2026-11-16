<div align="center">

# SoundWave

**Aplikasi pemesanan tiket konser musik. Flutter, Firebase, Midtrans.**

Berjalan penuh dengan biaya Rp 0: Firebase Spark, Midtrans Sandbox, dan Cloudflare Quick Tunnel.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D18-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Midtrans](https://img.shields.io/badge/Midtrans-Sandbox-1B4B8F)](https://midtrans.com)
[![Tests](https://img.shields.io/badge/tests-768%20passing-2E7D32)](#pengujian-dan-kualitas-kode)
[![Analyze](https://img.shields.io/badge/flutter%20analyze-0%20issues-2E7D32)](#pengujian-dan-kualitas-kode)
[![Lisensi](https://img.shields.io/badge/lisensi-MIT-6B6B6B)](#lisensi)

</div>

---

## Ringkasan

SoundWave punya dua sisi dalam satu aplikasi. Penonton mencari konser, memilih kategori tiket, membayar lewat Midtrans, lalu menyimpan tiket ber-QR di HP. Admin memakai panel di aplikasi yang sama untuk mengelola konser, kuota, promo, refund, dan memindai tiket di pintu masuk.

Waktu paling banyak habis di bagian yang mudah salah, terutama ketika dua orang membeli tiket yang sama pada detik yang sama:

- Harga dihitung ulang di server saat checkout. Angka kiriman klien diabaikan, dan kalau ada selisih permintaan ditolak.
- Stok dijaga transaksi Firestore dengan `revisionCounter` sebagai kunci optimistis. Yang kalah balapan menerima `409` lalu diminta mencoba lagi.
- Setiap pesanan membawa `orderId` idempoten, jadi retry jaringan tidak menghasilkan dua tagihan.
- Tiket ditandatangani Ed25519 di server dan diverifikasi di HP memakai public key per `keyId`. Verifikasi tidak bertanya ke server, sehingga gerbang tetap jalan saat sinyal di lokasi acara buruk.
- Reservasi 5 menit memakai `reservedUntil` dari jam server. Mengubah jam perangkat tidak memperpanjang pesanan.

Dokumen desain lengkap — context diagram, DFD, ERD, LRS, class diagram, sequence diagram, flow user dan flow admin — ada di **[`docs/design/`](docs/design/)** dalam satu berkas draw.io berisi 9 halaman.

---

## English Summary

SoundWave is a two-sided concert ticketing system built with Flutter (Riverpod, Firebase) and a Node.js/Express backend. It runs at zero cost on the Firebase Spark plan, Midtrans Sandbox, and a Cloudflare quick tunnel.

The server owns the truth. Prices are recomputed at checkout, stock is guarded by a Firestore transaction with an optimistic `revisionCounter` lock, and every order carries an idempotent `orderId` so retries never double-charge. Payments are confirmed through a SHA512-verified Midtrans webhook, with polling as a fallback. Issued tickets are signed with Ed25519 and verified offline by the app, so gate scanning keeps working when the venue network does not. Reservations expire on a server-side five-minute clock, not the device clock.

Architecturally this is a layered monolith: Flutter feature-first UI over service facades, and an Express transaction-script backend acting as a BFF in front of Firestore and Midtrans. 768 automated tests, `flutter analyze` clean.

---

## Daftar Isi

- [Ringkasan](#ringkasan)
- [System Design](#system-design)
- [Alur Pembelian Tiket](#alur-pembelian-tiket)
- [Status Pesanan](#status-pesanan)
- [Fitur](#fitur)
- [Cara Memakai Aplikasi](#cara-memakai-aplikasi)
- [Endpoint Backend](#endpoint-backend)
- [Teknologi](#teknologi)
- [Struktur Proyek](#struktur-proyek)
- [Menjalankan Proyek](#menjalankan-proyek)
- [Konfigurasi](#konfigurasi)
- [Pengujian dan Kualitas Kode](#pengujian-dan-kualitas-kode)
- [Keamanan](#keamanan)
- [Batasan yang Diketahui](#batasan-yang-diketahui)
- [Roadmap](#roadmap)
- [Lisensi](#lisensi)

---

## System Design

```
+----------------------------------------------------------+
|                    CLIENT (Flutter)                      |
|  Feature-first UI - Riverpod (18 provider)               |
|  Facades: database - auth - midtrans - storage -         |
|           ticket - notification - audio                  |
|                                                          |
|  Dependency direction (strictly one-way):                |
|    screens -> providers -> services -> models            |
+------------------------+---------------------------------+
                         | HTTPS via Cloudflare Quick Tunnel
                         v
+----------------------------------------------------------+
|               BACKEND (Node.js / Express)                |
|  server.js -- 23 routes                                  |
|                                                          |
|  Responsibilities:                                       |
|    - Recompute prices from Firestore                     |
|    - Run atomic stock transactions                       |
|    - Verify Midtrans webhook SHA512 signatures           |
|    - Issue Ed25519-signed tickets                        |
|    - Gate scanner verification                           |
|                                                          |
|  Request middleware (in order):                          |
|    1. Firebase ID token check  <- /admin/* only          |
|    2. JSON body parse                                    |
|    3. Route handler                                      |
|    4. Centralised error handler                          |
+---------------+-----------------------+------------------+
                |                       |
                v                       v
+-------------------------+   +---------------------------+
|  Firebase               |   |  Midtrans Sandbox         |
|  - Firestore (data)     |   |  - Payment creation       |
|  - Auth (identity)      |   |  - Webhook (SHA512)       |
|  - Storage (posters)    |   |  - Status polling         |
|  - FCM (push)           |   |                           |
+-------------------------+   +---------------------------+
```

Architecture: Layered monolith -- not microservices. One team, one database, campus-scale load.

---

## Alur Pembelian Tiket

```
USER              CLIENT                  BACKEND                 FIRESTORE
 |                  |                        |                        |
 |- pick category ->|                        |                        |
 |   + promo code   |- POST /validate-promo >|                        |
 |                  |<- discount amount -----|                        |
 |- confirm & pay ->|                        |                        |
 |                  |- POST /checkout-atomic>|                        |
 |                  |                        |- BEGIN TRANSACTION --> |
 |                  |                        |  1. read tiket doc     |
 |                  |                        |  2. check revisionCounter
 |                  |                        |  3. recompute price    |
 |                  |                        |  4. assert quota > 0   |
 |                  |                        |  5. write RESERVED     |
 |                  |                        |  6. decrement quota    |
 |                  |                        |  7. increment revision |
 |                  |                        |<- COMMIT --------------|
 |                  |<- orderId + expiry ----|                        |
 |                  |- POST /create-va|gopay|qris ------------------>|
 |                  |<- VA / QR / deeplink --------------------------|
 |- pay ----------->|   (Midtrans Snap)                               |
 |                  |                        |<- POST /midtrans-webhook
 |                  |                        |   verify SHA512        |
 |                  |                        |   order -> AKTIF       |
 |                  |                        |   issue Ed25519 ticket |
 |                  |<- ticket + QR ---------|                        |
 |<- ticket shown --|                        |                        |
```

**Failure branches -- all handled explicitly:**

| Failure | Where caught | Handling |
|---|---|---|
| Out of stock | Client pre-request | Block UI, show message |
| Concurrent stock race | `/checkout-atomic` | `409` -- client prompts retry |
| Reservation expired (>5 min) | `/sweep-expired` | Order -> `EXPIRED`, stock restored |
| Invalid webhook signature | `/midtrans-webhook` | `401` -- order status unchanged |
| Webhook delayed | Client timer | `GET /check-status/:orderId` every 3s |
| Network retry | Client | Same `orderId` -- idempotent, no double charge |

---

## Status Pesanan

```
[client]      PENDING --------------------------------------------> CANCELLED
                 |
                 v
[/checkout-atomic]
             RESERVED ------- 5 min server clock ----------------> EXPIRED
                 |                                                (stock restored)
                 v
[webhook / poll]
              AKTIF -------------------------------------------- > REFUND_REQUESTED
                 |                                                       |
                 v                                                       v
[gate scanner] TERPAKAI                              REFUND_REQUIRED / REFUNDED
```

Satu pesanan berpindah status beberapa kali. Yang menulis status hanya server, kecuali `PENDING` dan `CANCELLED` yang dibuat aplikasi sebelum uang terlibat.

| Status | Arti | Ditulis oleh |
|---|---|---|
| `PENDING` | Pesanan dibuat di HP. Stok belum dipotong | aplikasi |
| `RESERVED` | Stok sudah dipotong, menunggu pembayaran 5 menit | `/checkout-atomic` |
| `AKTIF` | Pembayaran diterima, tiket dan QR bertanda tangan terbit | webhook, dengan polling sebagai cadangan |
| `TERPAKAI` | QR sudah dipindai di gerbang | scanner gerbang |
| `EXPIRED` | Lewat 5 menit tanpa pembayaran, stok dikembalikan | `/sweep-expired` |
| `CANCELLED` | Dibatalkan sebelum dibayar | aplikasi |
| `REFUND_REQUESTED` | Pengajuan refund masuk, menunggu admin | `/request-refund` |
| `REFUND_REQUIRED` | Perlu refund manual, misalnya pembayaran masuk setelah pesanan kedaluwarsa | backend |
| `REFUNDED` | Dana dikembalikan, tiket dicabut | admin |

`PAID` masih ada di konstanta dan masih diterima halaman tiket serta scanner, tapi tidak ada kode yang menulisnya lagi. Alurnya sekarang langsung dari `RESERVED` ke `AKTIF`.

---

## Fitur

### Sisi penonton

| Fitur | Keterangan |
|---|---|
| Jelajah konser | Daftar konser dengan pencarian, filter kategori, dan status penjualan |
| Detail konser | Jadwal, lokasi, lineup, dan kebijakan refund dalam dua tab: `TENTANG` dan `TIKET` |
| Pilih kategori tiket | Harga dan sisa kuota dibaca dari Firestore, bukan ditulis di UI |
| Checkout dua langkah | Pilih metode bayar, lalu konfirmasi. Setelah masuk langkah konfirmasi, metode tidak bisa diubah |
| Reservasi 5 menit | Stok dikunci sementara dengan jam server. Lewat batas, pesanan menjadi `EXPIRED` dan stok kembali |
| Pembayaran | Virtual Account, GoPay, dan QRIS lewat Midtrans Sandbox |
| Tiket ber-QR | Kode booking dan QR, bisa dibagikan, punya hitung mundur menuju hari-H |
| Mode offline | Tiket ditandatangani Ed25519 dan diverifikasi tanpa internet |
| Promo | Kode promo dengan kuota dan masa berlaku, diklaim per pengguna |
| Refund | Pengajuan refund dengan alasan, ditinjau admin, statusnya terlihat di sisi pengguna |
| Favorit dan notifikasi | Simpan konser favorit, plus notifikasi push dan lonceng in-app |

### Sisi admin

| Fitur | Keterangan |
|---|---|
| Dashboard | Halaman pertama setelah login: pendapatan, tiket terjual, pesanan menunggu bayar, refund yang perlu ditinjau, grafik 7 hari, daftar perlu tindakan, progres konser terdekat, dan jalan pintas ke Scan Gate |
| Kelola konser | Tambah, ubah, hapus konser beserta poster dan detail acara |
| Kelola tiket | Kategori, harga, kuota, dan pembukuan stok per kategori |
| Kelola promo | Kode diskon, nominal, kuota, dan masa berlaku |
| Kelola refund | Tinjau, setujui, atau tolak pengajuan refund |
| Laporan | Laporan penjualan dan pendapatan dengan filter |
| Pemindaian gerbang | Scanner QR dengan verifikasi tanda tangan tiket dan pencatatan pindai |
| Manajemen pengguna | Daftar pengguna dan perannya. Ubah peran hanya boleh dilakukan `super_admin` |
| Inspeksi konser | Pemeriksaan data konser langsung dari panel |

---

## Cara Memakai Aplikasi

Bagian ini untuk siapa pun yang memegang berkas APK dan ingin mencoba aplikasinya, tanpa perlu memasang Flutter atau menyentuh kode.

### 1. Pasang APK

APK adalah satu berkas yang bisa dipasang langsung di HP Android.

1. Unduh `app-debug.apk` (dari tim kamu, atau hasil `flutter build apk --debug`).
2. Buka berkas itu di HP. Android akan menampilkan peringatan **"Instal aplikasi tidak dikenal"** — itu normal untuk APK di luar Play Store.
3. Pilih **Setelan**, lalu izinkan **Instal dari sumber ini** untuk aplikasi yang membuka berkas tersebut (biasanya File Manager atau Chrome).
4. Kembali ke layar pemasangan, pilih **Instal**, lalu **Buka**.

Syarat minimum **Android 7.0 (API 24)** atau lebih baru. Nama paket aplikasi `com.example.soundwave`.

> **Kenapa muncul peringatan?** Karena APK ini ditandatangani dengan debug key, bukan kunci rilis Play Store. Aman untuk demo dan tugas kampus.

### 2. Daftar akun

Aplikasi terbuka di halaman login.

1. Pilih **Daftar** di bagian bawah form login.
2. Isi nama, email, dan kata sandi.
3. Tekan **Daftar**. Akun dibuat dan kamu langsung masuk.

Setiap akun baru **selalu** dibuat dengan peran `user` (pembeli). Ini disengaja: peran admin tidak bisa didaftarkan sendiri dari aplikasi.

### 3. Membeli tiket

1. **Jelajah** — pilih konser yang ingin ditonton.
2. **Detail konser** — baca jadwal dan lokasi di tab `TENTANG`, lalu buka tab `TIKET` untuk melihat kategori dan sisa kuota.
3. **Pilih kategori** — tekan kategori yang diinginkan, lalu atur jumlah tiket.
4. **Checkout** — isi data pembeli. Kalau punya kode promo, masukkan di kolom voucher; potongannya dihitung di server.
5. **Pilih metode bayar** — Virtual Account, GoPay, atau QRIS.
6. **Konfirmasi** — setelah masuk langkah ini, metode bayar tidak bisa diubah lagi.
7. **Bayar** — ikuti instruksi yang muncul. Tiket ditahan **5 menit**; kalau lewat, pesanan menjadi `EXPIRED` dan kuotanya kembali ke orang lain.
8. **E-Tiket** — setelah pembayaran terkonfirmasi, tiket ber-QR muncul di tab tiket dan bisa dibagikan.

> **Menguji di Sandbox?** Uangnya bukan uang nyata. Untuk melunasi pesanan tanpa aplikasi pembayar, buka dashboard Midtrans Sandbox lalu pakai tombol **Simulate Payment** pada transaksi terkait.

### 4. Memindai tiket di gerbang (admin)

1. Masuk dengan akun berperan admin.
2. Buka **Scan Gate** dari dashboard.
3. Arahkan kamera ke QR pada e-tiket penonton.
4. Aplikasi memverifikasi tanda tangan tiket secara **offline** — tidak butuh internet di lokasi acara.
5. Hasilnya `VALID` (tiket berubah menjadi `TERPAKAI`) atau `INVALID` (tiket palsu, sudah dipakai, atau bukan untuk konser ini).

Pemindaian tetap tercatat walau sinyal buruk, lalu diunggah lewat `/sync-offline-scans` ketika perangkat kembali online.

### 5. Menjadi admin

Registrasi hanya menghasilkan akun `user`. Untuk mendapat akses panel admin ada dua jalan.

**Jalan A — lewat akun `super_admin` (cara yang disediakan aplikasi)**

1. Masuk sebagai `super_admin`.
2. Buka **Manajemen Pengguna**.
3. Pilih akun yang ingin dipromosikan, lalu **Promosikan ke Admin**.

**Jalan B — lewat Firebase Console (untuk demo awal)**

1. Buka Firebase Console proyek `flutter-firebase-konser-apps`.
2. Masuk ke **Firestore Database**, koleksi `users`.
3. Cari dokumen yang `id`-nya sama dengan UID akunmu (lihat di **Authentication**).
4. Ubah field `role` dari `user` menjadi `admin` (atau `super_admin`).
5. Keluar dari aplikasi, lalu masuk lagi.

Peran yang dikenal: `user`, `admin`, `super_admin`. Hanya `super_admin` yang boleh mengubah peran orang lain, dan tidak bisa mengubah perannya sendiri.

### 6. Kalau aplikasi tidak bisa memuat data

Aplikasi membaca alamat backend dari Firestore, bukan dari alamat yang ditulis di kode. Kalau muncul pesan server belum siap:

1. Pastikan backend menyala dan tunnel-nya jalan (`node start_tunnel.js`).
2. Pastikan dokumen `app_config/backend` di Firestore punya field `url` berisi alamat tunnel yang aktif.
3. Kalau dokumen itu belum ada, aplikasi otomatis mencoba lokasi lama `events/_backend_config`.
4. Muat ulang aplikasi. Alamat tunnel berubah setiap kali backend dijalankan ulang, jadi dokumen ini harus ikut diperbarui.

---

## Endpoint Backend

Ada 23 rute di `server.js`. Rute yang diawali `/admin/` wajib membawa ID token Firebase milik akun ber-role admin, dan backend menolak permintaan tanpa token itu.

| Kelompok | Rute | Guna |
|---|---|---|
| Checkout | `POST /checkout-atomic` | Potong stok dan tulis pesanan `RESERVED` dalam satu transaksi |
| | `POST /validate-promo` | Periksa kode promo dan hitung potongan di server |
| | `GET /check-status/:orderId` | Status pesanan untuk layar pembayaran |
| | `GET /invoice/:orderId` | Data tagihan untuk halaman invoice |
| Pembayaran | `POST /create-transaction`, `/create-va`, `/create-qris`, `/create-gopay` | Buat transaksi Midtrans sesuai metode yang dipilih |
| | `POST /midtrans-webhook` | Terima notifikasi pembayaran, verifikasi SHA512 |
| | `POST /poll-payment` | Tanya status langsung ke Midtrans bila webhook terlambat |
| | `POST /sweep-expired` | Lepas stok pesanan yang lewat 5 menit |
| | `POST /settle-dev` | Tandai lunas di lingkungan pengembangan, bukan produksi |
| Refund | `POST /request-refund`, `/approve-refund`, `/reject-refund` | Alur refund dari sisi pengguna |
| | `GET /admin/refunds`, `POST /admin/refund/approve`, `POST /admin/refund/reject` | Tinjauan refund dari sisi admin |
| Promo | `GET /admin/promos`, `POST /admin/promo`, `DELETE /admin/promo/:id` | Kelola kode promo |
| Gerbang | `POST /sync-offline-scans` | Unggah hasil pindai offline saat perangkat kembali online |
| Lain | `GET /` | Daftar rute dan status server |

---

## Teknologi

**Aplikasi (Flutter)**

| Kebutuhan | Pilihan |
|---|---|
| State dan DI | `flutter_riverpod` (18 provider) |
| Backend-as-a-service | `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_messaging` |
| Pembayaran | Midtrans Snap lewat backend (HTTP) |
| QR dan pemindaian | `qr_flutter`, `mobile_scanner` |
| Tanda tangan tiket | `cryptography` (Ed25519) |
| Grafik | `fl_chart` |
| Notifikasi lokal | `flutter_local_notifications`, `timezone` |
| Lain-lain | `google_fonts`, `cached_network_image`, `shimmer`, `image_picker`, `share_plus`, `url_launcher`, `intl` |

**Backend (Node.js)**

| Kebutuhan | Pilihan |
|---|---|
| HTTP | `express` |
| Database | `firebase-admin` (Firestore) |
| Pembayaran | `midtrans-client` |
| Konfigurasi | `dotenv` |
| Eksposur lokal | Cloudflare Quick Tunnel (`cloudflared`) |

**Platform**

- Package `com.example.soundwave`, minSdk 24, targetSdk 36
- Versi saat ini 2.4.7+31
- Tema gelap: latar `#000000`, aksen harga `#00E676`, font Rajdhani dan Space Grotesk

---

## Struktur Proyek

```
Soundwave/
├── lib/
│   ├── constants/        app_constants.dart, satu tempat untuk konstanta global
│   ├── core/             diagnostik, errors, media (demo_media, audio_library)
│   ├── data/             lapisan data pendukung
│   ├── models/           11 model data (konser, tiket, pesanan, promo, refund,
│   │                     review, notifikasi, media, statistik, pengguna)
│   ├── providers/        app_providers.dart, 18 provider Riverpod
│   ├── repositories/     akses data yang dipakai provider
│   ├── services/         7 service facade (database, auth, midtrans, notifikasi,
│   │                     storage, tiket offline, audio)
│   ├── screens/
│   │   ├── auth/         login, register
│   │   ├── user/         jelajah, detail, checkout, tiket, invoice, favorit, promo
│   │   └── admin/        dashboard, kelola konser/tiket/promo/refund, laporan,
│   │                     scanner gerbang, manajemen pengguna
│   ├── widgets/          komponen dipakai ulang (animasi, badge, feedback, gate)
│   ├── utils/            tema, hitung mundur, rincian harga, rundown, urutan tiket
│   └── main.dart
├── test/                 768 test (unit + widget) dalam 76 berkas
├── docs/
│   ├── design/           3 berkas draw.io, termasuk 9 halaman diagram sistem
│   └── generators/       skrip Python pembuat diagram
├── android/ · ios/ · web/ · windows/ · linux/ · macos/
├── .github/workflows/    flutter_ci.yml
└── pubspec.yaml
```

Arah ketergantungan selalu satu arah:

```
screens  →  providers  →  services  →  models
```

Model tidak tahu soal UI, dan layar tidak tahu soal Firestore.

### Diagram sistem

Semua diagram ada di [`docs/design/`](docs/design/). Berkas utama **`Soundwave Document.drawio`** berisi 9 halaman dan bisa dibuka di [app.diagrams.net](https://app.diagrams.net) atau VS Code dengan ekstensi Draw.io Integration.

| Halaman | Isi |
|---|---|
| Context Diagram | Batas sistem, aktor, dan arus data masuk dan keluar |
| Data Flow Diagram 0 | Lima proses utama beserta data store `D1` sampai `D5` |
| ERD - Crow's Foot | Relasi tabel dengan notasi kaki gagak |
| ERD - Chen | Entitas, atribut, dan belah ketupat relasi |
| LRS | Skema relasional hasil transformasi ERD |
| Sequence Diagram | Alur checkout dari pilih tiket sampai e-tiket terbit |
| Class Diagram | 5 kelas: `Users`, `Events`, `Tickets`, `Orders`, `Promo` |
| Flow User | Diagram alir pembeli dari buka aplikasi sampai scan gate |
| Flow Admin | Diagram alir admin dari login sampai laporan |

---

## Menjalankan Proyek

### Prasyarat

- Flutter 3.x (Dart ≥ 3.0)
- Node.js ≥ 18
- Proyek Firebase dengan Firestore, Auth, Storage, dan Cloud Messaging aktif
- Akun Midtrans Sandbox (server key dan client key)
- `cloudflared`, sudah disertakan di repo backend

### 1. Backend

```bash
git clone https://github.com/ysnalqdr/soundwave-backend.git
cd soundwave-backend
npm install
# isi .env (lihat tabel Konfigurasi), lalu letakkan serviceAccountKey.json
npm start
```

Backend berjalan di `http://localhost:3000`. Untuk diakses dari HP, jalankan tunnel:

```bash
node start_tunnel.js
```

URL tunnel yang didapat disimpan ke Firestore (`app_config/backend`, dengan cadangan `events/_backend_config`), jadi aplikasi otomatis memakai alamat terbaru tanpa perlu build ulang.

### 2. Aplikasi

```bash
git clone https://github.com/ysnalqdr/SoundWave.git
cd SoundWave
flutter pub get
flutter run
```

Build APK:

```bash
flutter build apk --debug
# hasil: build/app/outputs/flutter-apk/app-debug.apk
```

### 3. Catatan Midtrans Sandbox

- Pakai server key dan client key Sandbox, bukan Production.
- Untuk QRIS, jangan isi `qris.acquirer`. Sandbox menolak `gpn` dengan HTTP 500.
- Webhook butuh URL publik, dan itu alasan tunnel dipakai saat pengujian lokal.

---

## Konfigurasi

Nilai rahasia tidak ditulis di repo. Semuanya lewat `.env` yang sudah masuk `.gitignore`.

**Backend, `soundwave-backend/.env`**

| Variabel | Kegunaan |
|---|---|
| `MIDTRANS_SERVER_KEY` | Server key Sandbox untuk membuat transaksi dan memverifikasi webhook |
| `MIDTRANS_CLIENT_KEY` | Client key Sandbox untuk Snap |
| `MIDTRANS_IS_PRODUCTION` | `false` untuk Sandbox |
| `PORT` | Port backend, default `3000` |
| `FIREBASE_SERVICE_ACCOUNT` | Path ke `serviceAccountKey.json` |

**Aplikasi, `Soundwave/.env`**

| Variabel | Kegunaan |
|---|---|
| `MIDTRANS_CLIENT_KEY` | Client key Sandbox, hanya untuk Snap |
| `BACKEND_BASE_URL` | Alamat backend atau tunnel untuk pengembangan lokal |

> `.env`, `serviceAccountKey.json`, `node_modules/`, dan `build/` tidak ikut ter-commit. Kalau salah satunya pernah terlanjur masuk, rotate key-nya sebelum push berikutnya.

---

## Pengujian dan Kualitas Kode

```bash
flutter analyze     # No issues found!
flutter test        # 768 test lulus
```

Test-nya tidak berhenti di "apakah widget tampil". Yang dijaga adalah aturan bisnis yang paling mudah rusak:

- harga dan stok yang tampil harus berasal dari data tiket asli;
- pesanan `RESERVED` dan `PENDING` dianggap menunggu bayar, dan kedaluwarsa dihitung dari `reservedUntil` dengan fallback 24 jam untuk data lama;
- tombol bayar baru aktif setelah kategori dipilih, dan satu-satunya pintu ke checkout adalah tombol di bar bawah;
- tombol dialog aksi tetap sejajar kiri-kanan sampai lebar layar 240 px;
- angka dashboard dihitung dengan definisi yang sama seperti laporan, sehingga tidak ada dua versi kebenaran;
- versi di `app_constants.dart` harus sama dengan `pubspec.yaml`, dan test gagal kalau keduanya melenceng;
- fitur yang dihapus ikut menghapus test dan pemanggilnya, jadi tidak ada kode mati yang tertinggal.

Sebagian test memeriksa keselarasan rumus harga antara aplikasi dan repo backend. Kalau repo `soundwave-backend` tidak ada di sebelah folder proyek — misalnya saat berjalan di CI — test tersebut otomatis di-`skip`, bukan gagal.

CI menjalankan `flutter analyze` dan `flutter test` pada setiap push ke `main` atau `master` (`.github/workflows/flutter_ci.yml`).

---

## Keamanan

| Area | Penanganan |
|---|---|
| Webhook pembayaran | Signature SHA512 diverifikasi. Permintaan tanpa signature sah ditolak `401` |
| Harga dan stok | Dihitung ulang di server. Nilai kiriman klien diabaikan |
| Balapan stok | Transaksi Firestore dengan `revisionCounter` (optimistic concurrency) |
| Pembayaran ganda | `orderId` idempoten |
| Tiket palsu | Tanda tangan Ed25519, diverifikasi offline dengan public key per `keyId` |
| Pemindaian ganda | Ledger lokal dan `/sync-offline-scans` mencegah satu tiket masuk dua kali |
| Rahasia | `.env` dan `serviceAccountKey.json` tidak masuk repo. Key Sandbox hanya untuk demo |
| Akses data | Firestore Security Rules sebagai lapisan kedua. Rules bukan filter, jadi query tetap harus dibatasi di klien |

---

## Batasan yang Diketahui

Proyek ini disiapkan untuk demo dan tugas kampus, jadi beberapa hal saya biarkan apa adanya:

1. **Tidak ada nomor kursi.** Stok dihitung per kategori. Fitur denah dan pilih kursi sudah dihapus karena tidak pernah benar-benar mengunci kursi.
2. **Backend berjalan di laptop.** Cloudflare Quick Tunnel memberi URL acak setiap kali start, sehingga alamat backend disimpan di Firestore dan bisa berubah.
3. **Firebase Spark punya kuota harian** (20.000 tulis, 50.000 baca). Cukup untuk demo, tidak untuk produksi.
4. **Sandbox, bukan uang nyata.** Tidak ada settlement dan tidak ada rekonsiliasi bank.
5. **Autentikasi rute backend belum diperketat.** Beberapa rute masih mengandalkan ID kiriman klien. Ini butuh verifikasi token Firebase sebelum dipakai di produksi.
6. **Beberapa nilai masih hardcode.** Biaya layanan Rp 5.000 muncul di tujuh tempat di backend dan satu di aplikasi, kandidat kuat untuk dipindah ke satu konfigurasi.
7. **APK masih ditandatangani debug key.** Belum disiapkan untuk distribusi Play Store; itu butuh keystore rilis dan `signingConfig` tersendiri.

---

## Roadmap

- [ ] Verifikasi Firebase ID token di seluruh rute backend
- [ ] Sentralisasi biaya layanan dan daftar kategori ke satu sumber konfigurasi
- [ ] Nomor kursi asli dengan penguncian per kursi, kalau memang dibutuhkan
- [ ] Rekonsiliasi otomatis untuk refund yang tertunda
- [ ] Keystore rilis dan `signingConfig` untuk build Play Store
- [ ] Mode produksi: Midtrans Production, Firebase Blaze, dan backend ter-hosting

---

## Lisensi

Dirilis di bawah MIT License. Bebas dipakai, diubah, dan dibagikan asal atribusinya tetap dicantumkan.

Repo ini dikelola sendiri. Laporan bug lewat Issues tetap diterima, tapi pull request dari luar belum tentu cepat ditinjau.

Dibuat sebagai proyek pembelajaran rekayasa perangkat lunak: satu aplikasi, satu backend, tanpa biaya operasional.
