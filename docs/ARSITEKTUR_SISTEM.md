# ARSITEKTUR & ILMU DI BALIK SOUNDWAVE

Dokumen ini menjelaskan **apa yang benar-benar dibangun**, bukan teori umum.
Semua angka dan nama berkas diambil dari kode per 17 Oktober 2026.

| Ukuran | Nilai |
|---|---|
| Kode Flutter | 56 berkas `.dart`, **24.202 baris** |
| Kode backend | `server.js` **2.043 baris**, 23 rute (21 unik + 2 alias) |
| Test Flutter | **319 test** (unit + widget) |
| Skrip uji backend | 6 berkas `test_*.js` (dijalankan manual, bukan jest) |
| Koleksi Firestore | **10** (users, events, tickets, orders, favorites, reviews, notifications, promo_codes, claimed_promos, refunds) |
| Versi terpasang | 2.4.7 (31) |
| Biaya operasional | **Rp 0** (Firebase Spark + Midtrans Sandbox + Cloudflare Quick Tunnel) |

---

## 1. PETA BESAR SISTEM

```
┌──────────────────────────────────────────────────────────────────┐
│  LAPIS 1 — CLIENT (Android, Flutter)                             │
│                                                                  │
│  screens/  ──►  providers/ (Riverpod)  ──►  services/            │
│  (UI)           (state + cache)             (auth, db, midtrans, │
│                                              notif, storage,     │
│                                              offline)            │
│                        │            │              │             │
│                        │            │              └──► HTTP ────┼──┐
│                        │            └──► Firestore (SDK langsung)│  │
│                        └──► Firebase Auth / FCM / Storage        │  │
└──────────────────────────────────────────────────────────────────┘  │
                                                                       │
┌──────────────────────────────────────────────────────────────────────┴─┐
│  LAPIS 2 — IDENTITAS & DATA (Firebase, Spark/free)                     │
│  Auth (email, Google) · Firestore (NoSQL) · FCM (push) · Storage (foto)│
└──────────────────────────────────────────────────────────────────────┬─┘
                                                                       │
┌──────────────────────────────────────────────────────────────────────┴─┐
│  LAPIS 3 — BACKEND (Node.js + Express, di laptop, port 3000)           │
│  /checkout-atomic  /create-va  /create-gopay  /create-qris             │
│  /midtrans-webhook  /poll-payment  /sweep-expired  /settle-dev         │
│  /validate-promo  /request-refund  /admin/*  /invoice/:id              │
│  firebase-admin (tulis Firestore) · midtrans-client (panggil Midtrans) │
└──────────────────────────────────────────────────────────────────────┬─┘
                                                                       │
                                    Cloudflare Quick Tunnel (HTTPS)    │
                                    https://xxx.trycloudflare.com      │
                                                                       │
┌──────────────────────────────────────────────────────────────────────┴─┐
│  LAPIS 4 — PIHAK KETIGA: Midtrans Sandbox (VA, GoPay, QRIS, kartu)     │
│  → mengirim webhook balik ke URL tunnel saat pembayaran berubah status │
└────────────────────────────────────────────────────────────────────────┘
```

**Kunci desainnya:** aplikasi Flutter **tidak** memanggil Midtrans langsung
(tidak boleh — server key harus rahasia), dan **tidak** memakai Cloud Functions
(Spark tidak bisa memanggil jaringan luar). Karena itu ada satu backend Node
kecil di laptop, dibuka ke internet lewat tunnel, dan **URL tunnel-nya
disimpan di Firestore** (`events/_backend_config`) supaya aplikasi selalu tahu
alamat terbaru.

---

## 2. BASE CODE & ARSITEKTUR

### 2.1 Base code

| Bagian | Base code | Kenapa ini |
|---|---|---|
| Mobile | `flutter create` (template resmi) + Material 3 manual | tidak pakai boilerplate pihak ketiga; semua lapisan ditulis sendiri supaya bisa diaudit |
| Backend | `npm init` + Express minimal (5 dependensi) | sekecil mungkin; tidak ada ORM, tidak ada framework berat |
| Database | Firestore (NoSQL dokumen) | gratis di Spark, realtime stream, tanpa server DB |
| Pembayaran | `midtrans-client` (SDK resmi) | menangani signature & format request Midtrans |

### 2.2 Arsitektur client: **layered (berlapis) + feature-first**

```
lib/
├── main.dart              bootstrap: Firebase, notifikasi, ProviderScope
├── firebase_options.dart  kredensial proyek (dibuat flutterfire)
├── constants/             nilai tetap (kategori, 5 menit hold, dsb.)
├── models/                data class murni + getter turunan (isVIP, formatHarga)
├── providers/             state global (Riverpod) — 16 provider
├── services/              satu berkas per tanggung jawab eksternal
├── screens/               UI per peran: auth / user / admin
├── widgets/               komponen dipakai ulang (kotak pending, dialog, tombol dialog sejajar)
└── utils/                 tema, format tanggal, hitung mundur
```

Aturan yang dipakai konsisten:

1. **UI tidak boleh menyentuh Firestore/HTTP langsung.** Semua lewat `services/`.
2. **State tidak disimpan di `setState` lintas layar.** Yang lintas layar pakai provider.
3. **Model tidak tahu UI.** `TiketKonserModel.formatHarga` hanya mengembalikan string.
4. **Satu berkas = satu alasan berubah.** `midtrans_service.dart` hanya soal pembayaran.

Ini bukan "Clean Architecture" penuh (tidak ada `domain/`, `usecase/`, `repository
interface`, tidak ada DI container seperti `get_it`). Untuk 24 ribu baris,
lapisan 4 tingkat ini sudah cukup — menambah usecase layer hanya menambah
berkas tanpa menambah kejelasan.

### 2.3 Arsitektur backend: **monolith satu berkas (deliberate)**

`server.js` berisi 23 rute dalam satu berkas. Ini pilihan sadar, bukan
kemalasan: satu proses, satu `npm start`, satu tempat untuk melihat semua
aturan uang. Konsekuensinya dibahas di §12 (trade-off) dan §15 (kritik).

---

## 3. RANTAI FUNDAMENTAL: HTTP → REQUEST/RESPONSE → CLIENT/SERVER → JSON → ENDPOINT

Ini urutan pemahaman yang benar: dari yang paling fisik ke yang paling abstrak.

### 3.1 HTTP

- **WHAT** Protokol teks untuk meminta & mengirim data di jaringan, di atas TCP (biasanya port 443 + TLS).
- **WHY** Komputer perlu kesepakatan bersama: format permintaan, format jawaban, arti kode status.
- **PROBLEM** Tanpa protokol standar, setiap aplikasi harus tahu cara bicara dengan setiap server.
- **HOW** Klien kirim `METHOD /path HTTP/1.1` + header + (opsional) body. Server balas `HTTP/1.1 200 OK` + header + body, lalu koneksi ditutup atau dipakai ulang.
- **WHEN** Semua komunikasi request-initiated: ambil daftar konser, buat transaksi, kirim refund.
- **WHEN NOT** Untuk data yang harus **didorong** server ke klien (chat, harga realtime, status pembayaran berubah). HTTP saja tidak cukup → butuh WebSocket / SSE / push notification. Di sistem ini dipakai **FCM** dan **Firestore stream**.
- **TRADE-OFF** Sederhana, bisa di-cache, mudah di-debug (bisa `curl`) — tapi satu arah, ada overhead header, dan tidak efisien untuk update berfrekuensi tinggi.
- **ALTERNATIVES** WebSocket, gRPC (HTTP/2 biner), MQTT, GraphQL-over-HTTP.
- **FAILURE MODE** Timeout, DNS gagal, TLS ditolak, 502 dari tunnel, koneksi putus di tengah unggah.
- **REAL WORLD** `midtrans_service.dart` memakai `http` dengan `_batasTunggu = 25 detik`; kalau lewat, dilempar `ServerTidakTerhubungException` dan UI menampilkan pesan ramah, bukan stack trace.

### 3.2 Request / Response

- **WHAT** Pola pesan: satu permintaan → satu jawaban.
- **WHY** Model mental paling sederhana untuk transaksi yang punya akhir jelas.
- **PROBLEM** Harus ada kepastian "sudah selesai atau belum" — kalau tidak, klien menunggu selamanya.
- **HOW** Request = method + URL + header + body. Response = status + header + body. Ada `Content-Type`, `Content-Length`, `Authorization`.
- **WHEN** Operasi yang butuh kepastian hasil sebelum lanjut: buat pesanan, validasi promo, minta refund.
- **WHEN NOT** Operasi panjang (render video, kirim massal) — lebih baik 202 Accepted + job id + polling/webhook.
- **TRADE-OFF** Jelas & mudah di-retry — tapi klien harus menunggu (blocking), dan hasil bisa tidak pasti bila koneksi putus setelah server selesai memproses (masalah "unknown outcome").
- **FAILURE MODE** Putus setelah server memproses tapi sebelum klien menerima jawaban → klien mengulang → **dobel charge**. Ini yang dicegah idempotensi (§7).
- **REAL WORLD** `POST /checkout-atomic` mengembalikan `{success, orderId, kodeBooking, total}` — Flutter baru pindah layar setelah response diterima.

### 3.3 Client / Server

- **WHAT** Pembagian peran: satu pihak meminta (client), satu pihak melayani & menyimpan kebenaran (server).
- **WHY** Data & aturan harus terpusat; kalau tiap HP menyimpan kebenaran sendiri, harga bisa berbeda-beda.
- **PROBLEM** Kepercayaan. HP pengguna bisa dimodifikasi (root, patch APK, intercept traffic).
- **HOW** Client mengirim niat ("saya mau 2 tiket VIP"), server memutuskan ("harga 1.000.000, stok cukup, ini order-nya").
- **WHEN** Selalu, untuk apa pun yang menyangkut uang atau stok.
- **WHEN NOT** Untuk data yang murni milik pengguna dan tidak berdampak bisnis (tema, filter terakhir, pilihan tab).
- **TRADE-OFF** Aman & konsisten — tapi menambah latensi, biaya, dan titik gagal.
- **FAILURE MODE** Server jadi bottleneck; kalau mati, seluruh transaksi berhenti (di sistem ini: backend laptop mati = pembayaran mati).
- **REAL WORLD** Harga **selalu** dihitung ulang di server (`server.js:270-292`), walaupun klien mengirim `gross_amount`. Kalau beda, nilai klien ditimpa. Ini anti price-tampering.

### 3.4 JSON

- **WHAT** Format teks untuk data terstruktur: objek, array, string, angka, boolean, null.
- **WHY** Harus ada bahasa data yang dimengerti semua bahasa pemrograman.
- **PROBLEM** Data di memori (objek Dart, objek JS) tidak bisa dikirim mentah lewat jaringan.
- **HOW** Serialisasi: objek → teks. Deserialisasi: teks → objek. Kuncinya selalu string.
- **WHEN** Semua payload HTTP di sistem ini (request Midtrans, response backend, webhook).
- **WHEN NOT** Data biner (gambar, PDF) → pakai multipart / base64 (base64 boros 33%) atau URL Storage. Data sangat besar & kolom tetap → CSV/Parquet. Data antar-service berkinerja tinggi → Protobuf.
- **TRADE-OFF** Mudah dibaca manusia & fleksibel — tapi verbose, tidak ada tipe ketat, angka besar bisa kehilangan presisi di JS (`Number`), dan tidak ada skema wajib.
- **FAILURE MODE** Field hilang/null → `null pointer`; tipe berubah (`"5000"` vs `5000`) → perhitungan salah; JSON tidak valid → parse error 400.
- **REAL WORLD** Model Dart punya `fromJson`/`toJson` manual (tanpa `freezed`/`json_serializable`) dan memakai `(json['x'] as num?)?.toDouble()` supaya angka dari Firestore (`int`/`double`) sama-sama aman.

### 3.5 Endpoint

- **WHAT** Alamat + method yang mengekspresikan satu operasi: `POST /create-va`.
- **WHY** Agar klien punya kontrak yang stabil, tidak perlu tahu isi server.
- **PROBLEM** Tanpa kontrak, perubahan internal server merusak aplikasi.
- **HOW** Server memetakan `(method, path)` → fungsi handler → response.
- **WHEN** Setiap kemampuan yang perlu dipakai pihak lain (aplikasi, webhook Midtrans, skrip admin).
- **WHEN NOT** Kalau yang butuh data adalah kode di proses yang sama (panggil fungsi langsung, bukan HTTP ke diri sendiri).
- **TRADE-OFF** Kontrak jelas & bisa diuji terpisah — tapi menambah lapisan, dan endpoint adalah permukaan serangan.
- **FAILURE MODE** Path berubah → klien 404; endpoint tanpa autentikasi → siapa pun bisa memanggil.
- **REAL WORLD** 23 rute di `server.js`; pengelompokannya di §4.

---

## 4. DAFTAR ENDPOINT (KONTRAK SISTEM)

| Kelompok | Endpoint | Fungsi |
|---|---|---|
| Sehat | `GET /` | cek backend hidup (dipakai skrip & debugging) |
| Checkout | `POST /checkout-atomic` | **jantung sistem**: validasi stok + potong stok + buat order dalam satu transaksi |
| Pembayaran | `POST /create-transaction` | Snap (kartu/redirect) |
| | `POST /create-va` | Virtual Account (BCA/BNI/BRI/Permata) |
| | `POST /create-gopay` | GoPay (QR + deeplink) |
| | `POST /create-qris` | QRIS (semua e-wallet) |
| | `POST /poll-payment` | tanya status ke Midtrans (fallback bila webhook telat) |
| | `POST /midtrans-webhook` | **Midtrans memanggil kita** saat status berubah |
| | `GET /check-status/:orderId` | baca status dari Firestore |
| | `POST /settle-dev` | penanda "sudah dibayar" untuk demo (bukan produksi) |
| Reservasi | `POST /sweep-expired` | bersihkan reservasi lewat 5 menit |
| Promo | `POST /validate-promo` | cek kode + hitung diskon di server |
| | `POST/GET/DELETE /admin/promo*` | CRUD promo |
| Refund | `POST /request-refund` | pengajuan refund |
| | `GET /admin/refunds`, `POST /admin/refund/approve`, `POST /admin/refund/reject` (+2 alias lama) | keputusan admin |
| Lain | `GET /invoice/:orderId` | HTML invoice (bisa dibuka browser) |
| | `POST /sync-offline-scans` | unggah hasil scan offline |

Prinsip penamaan yang dipakai: **kata kerja di method, kata benda di path**
(`POST /create-va`, bukan `GET /createVa?x=1`). Rute `/admin/*` memisahkan
wilayah admin — walau saat ini **belum** dilindungi token (§15).

---

## 5. REST & STATUS CODE

- **WHAT** Gaya merancang API: resource sebagai kata benda, method HTTP sebagai aksi, status code sebagai hasil.
- **WHY** Supaya API bisa ditebak dan dipakai alat umum (cache, proxy, `curl`).
- **PROBLEM** API yang "asal jalan" sulit dipelajari, sulit di-cache, sulit di-debug.
- **HOW** `GET` baca, `POST` buat, `PUT/PATCH` ubah, `DELETE` hapus. Status: 2xx sukses, 4xx salah klien, 5xx salah server.
- **WHEN** API publik / dipakai banyak klien.
- **WHEN NOT** Operasi yang bukan CRUD (mis. `POST /settle-dev` — itu *command*, bukan resource) atau butuh satu request banyak data (GraphQL).
- **TRADE-OFF** Universal & mudah di-cache — tapi sering memaksa bentuk data mengikuti URL, dan "REST murni" bisa jadi kaku.
- **FAILURE MODE** Salah status (200 untuk error) → klien menganggap sukses; 500 untuk kesalahan input → sulit dilacak.
- **REAL WORLD** Sistem ini **REST-ish**, bukan REST murni: banyak rute berbentuk perintah (`/create-va`, `/settle-dev`), dan sukses/gagal juga dikirim di body (`{success:false, error}`) karena klien Flutter lebih mudah membaca satu bentuk. Konsisten, walau tidak ortodoks.

---

## 6. API GATEWAY

- **WHAT** Satu pintu masuk yang meneruskan permintaan ke layanan di belakangnya, sambil menangani auth, rate limit, logging, routing.
- **WHY** Klien tidak perlu tahu berapa banyak service di belakang; kebijakan lintas-layanan cukup diurus sekali.
- **PROBLEM** Tanpa gateway, setiap klien harus tahu alamat & aturan setiap service (N klien × M service = kekacauan).
- **HOW** Klien → gateway → (auth, limit, log, routing) → service tujuan → balik lewat gateway.
- **WHEN** Banyak service, banyak klien, butuh kebijakan terpusat (kuota, API key, versi).
- **WHEN NOT** Satu aplikasi kecil dengan satu backend — gateway hanya menambah lompatan jaringan.
- **TRADE-OFF** Terpusat & rapi — tapi satu titik gagal, bisa jadi bottleneck, dan menambah latensi.
- **ALTERNATIVES** BFF (Backend-for-Frontend), ingress Kubernetes, service mesh sidecar, library bersama di klien.
- **FAILURE MODE** Gateway mati → semua mati; salah routing → 404 misterius; limit terlalu ketat → pengguna sah terblokir.
- **REAL WORLD** **Tidak ada gateway terpisah.** Peran itu dipegang dua hal: (1) **Cloudflare Tunnel** sebagai pintu masuk HTTPS tunggal ke laptop, dan (2) **Express** sendiri yang menerima semua rute lalu memanggil Midtrans & Firestore — jadi Express berperan sebagai *BFF* sekaligus gateway. Di sisi klien, `midtrans_service.dart` berperan sebagai *anti-corruption layer*: semua URL, timeout, cache, dan pesan error terjemahan ada di satu tempat, sehingga layar tidak tahu apa-apa soal jaringan.

---

## 7. WEBHOOK = EVENT-DRIVEN (yang dipakai), dan kenapa bukan message broker

- **WHAT** Webhook: server pihak ketiga mengirim HTTP POST ke URL kita saat sebuah peristiwa terjadi.
- **WHY** Pembayaran selesai di sisi Midtrans, bukan di sisi kita. Kita tidak mungkin menebak kapan.
- **PROBLEM** Kalau hanya mengandalkan klien memberi tahu "sudah bayar", pengguna bisa berbohong. Kalau hanya polling, boros & lambat.
- **HOW** Midtrans kirim `{order_id, transaction_status, signature_key, ...}` → backend verifikasi **SHA512(order_id + status_code + gross_amount + serverKey)** → kalau cocok, ubah status order + tiket jadi TERPAKAI/AKTIF.
- **WHEN** Sinkronisasi status dari pihak ketiga yang otoritatif (pembayaran, pengiriman, refund).
- **WHEN NOT** Kalau penyedia tidak punya webhook, atau untuk data yang harus realtime < 1 detik (pakai WebSocket).
- **TRADE-OFF** Cepat & hemat — tapi butuh endpoint publik, harus idempoten (bisa dikirim berkali-kali), dan bisa gagal kirim.
- **ALTERNATIVES** Polling berkala, WebSocket, message queue (RabbitMQ/Kafka), CDC (Change Data Capture).
- **FAILURE MODE** Webhook telat/hilang → status menggantung; dipalsukan → harus ditolak signature; dikirim dobel → harus `already_processed`; URL tunnel berubah → Midtrans kirim ke alamat mati.
- **REAL WORLD** `POST /midtrans-webhook` (`server.js:1008`), signature diverifikasi di `:1023`, dan ada penjaga idempotensi `:1067` (`status: 'already_processed'`). Karena URL tunnel berganti tiap restart, **/poll-payment** disediakan sebagai jaring pengaman: aplikasi bisa menanyakan status langsung ke Midtrans bila webhook tidak sampai.

### 7.1 Kenapa TIDAK pakai Kafka/RabbitMQ

Konsepnya benar (event-driven), tapi: butuh server yang selalu hidup, butuh biaya, butuh operasi. Untuk satu laptop + Spark, **webhook + Firestore stream + FCM** sudah memberi sifat event-driven tanpa broker. Kalau nanti ada 10.000 order/menit, broker baru masuk akal.

---

## 8. MICROSERVICES

- **WHAT** Memecah sistem jadi layanan kecil yang berdiri sendiri, deploy sendiri, database sendiri.
- **WHY** Supaya tim besar bisa bergerak paralel tanpa saling menunggu, dan satu bagian bisa diskalakan sendiri.
- **PROBLEM** Monolith besar: satu perubahan berisiko menjatuhkan semuanya; satu tim memblokir tim lain; sulit diskalakan per bagian.
- **HOW** Setiap service punya API, komunikasi lewat jaringan (HTTP/gRPC/queue), data terpisah (database per service).
- **WHEN** Organisasi > ~3 tim, domain jelas terpisah, beban tidak merata, butuh rilis independen.
- **WHEN NOT** Satu tim kecil, domain masih berubah cepat, transaksi butuh konsistensi kuat. **Microservices dini = distributed monolith** (lebih lambat, lebih rapuh).
- **TRADE-OFF** Skalabilitas & otonomi tim — tapi biaya operasi naik drastis: tracing, versioning API, konsistensi data, latensi jaringan, duplikasi kode.
- **ALTERNATIVES** Modular monolith (pilih ini), monolith + modul jelas, serverless function per use case.
- **FAILURE MODE** Kegagalan berantai (cascade), data tidak konsisten antar service, sulit melacak satu request (butuh distributed tracing), deploy jadi rumit.
- **REAL WORLD** **Sengaja tidak dipakai.** Sistem ini **monolith modular**: satu backend, tapi batas tanggung jawab jelas (checkout / pembayaran / refund / promo / gerbang). Kalau nanti dipecah, garis potongnya sudah kelihatan: *payment service*, *order/stock service*, *notification service* — dan tiap potongan itu sekarang sudah punya berkas sendiri (`notifikasi.js`, `pengumuman.js`, `reconcile_refund_orders.js`).

---

## 9. SERVICE MESH

- **WHAT** Lapisan infrastruktur (sidecar proxy seperti Envoy/Istio) yang mengurus komunikasi antar-service: mTLS, retry, timeout, circuit breaker, tracing, traffic shifting.
- **WHY** Di microservices, logika jaringan (retry, TLS, telemetry) tidak seharusnya ditulis ulang di setiap service.
- **PROBLEM** 50 service × retry manual = 50 implementasi berbeda dan 50 bug berbeda.
- **HOW** Proxy kecil di samping tiap pod menerima semua trafik keluar/masuk; control plane membagikan kebijakan.
- **WHEN** Puluhan/ratusan service, banyak tim, butuh mTLS & observability seragam, butuh canary/blue-green.
- **WHEN NOT** Monolith, atau < 5 service. Overhead-nya (CPU, latensi, kompleksitas) tidak terbayar. **Di sistem ini jelas tidak dipakai.**
- **TRADE-OFF** Kebijakan seragam & observability kuat — tapi berat, mahal, butuh keahlian Kubernetes.
- **FAILURE MODE** Sidecar salah konfigurasi → semua trafik gagal; control plane mati → kebijakan beku; debugging jadi berlapis.
- **REAL WORLD** Tidak ada. Penggantinya di skala ini: **satu tempat** untuk timeout/retry/pesan error (`midtrans_service.dart`) dan **satu logger** (`logger.js`). Prinsip mesh ("jaringan diurus terpusat") tetap dipegang, hanya tanpa infrastrukturnya.

---

## 10. RESERVASI 5 MENIT: SAGA + COMPENSATING TRANSACTION + SWEEPER

Ini bagian paling "engineering" di sistem, dan sering ditanya.

- **WHAT** Saat user membuka pembayaran, stok **dipotong sementara** selama 5 menit. Kalau tidak dibayar, stok dikembalikan otomatis.
- **WHY** Mencegah dua orang membeli kursi terakhir di waktu yang sama (oversell), tanpa mengunci stok selamanya untuk orang yang batal.
- **PROBLEM** Tanpa hold: stok bisa terjual dobel (race condition) atau "hilang" karena keranjang terbengkalai.
- **HOW**
  1. `POST /checkout-atomic` menjalankan **Firestore transaction**: baca stok → cek cukup → kurangi stok → tulis order `PENDING` + `reservedUntil = now + 5 menit`.
  2. Transaksi Firestore bersifat **atomic & serializable** untuk dokumen yang dibaca: kalau dua request bersamaan, satu akan gagal & diulang, jadi stok tidak bisa minus.
  3. Bila pembayaran sukses (webhook): status jadi `PAID`, stok **tidak** dikurangi lagi (sudah dipotong saat hold).
  4. Bila lewat 5 menit: `POST /sweep-expired` (juga dipanggil berkala) mengubah order jadi `EXPIRED` dan **mengembalikan stok**.
- **WHEN** Barang berstok terbatas yang dibayar tidak instan (tiket, kamar hotel, kursi pesawat).
- **WHEN NOT** Stok tak terbatas, atau pembayaran instan satu langkah (tidak perlu hold).
- **TRADE-OFF** Adil & aman dari oversell — tapi stok "tertahan" orang yang tidak jadi bayar, dan butuh proses pembersih yang jalan terus.
- **ALTERNATIVES** Kunci baris database (pessimistic lock), antrean (queue) satu-per-satu, optimistic concurrency dengan versi, pembayaran dulu baru potong stok.
- **FAILURE MODE** Sweeper mati → stok tertahan selamanya (perlu tombol/manual `/sweep-expired`); jam server vs jam HP beda → **karena itu timer memakai `reservedUntil` dari server, bukan jam HP**; webhook telat setelah EXPIRED → harus ditangani sebagai "terlambat bayar" (refund/manual).
- **REAL WORLD** `HOLD_MENIT = 5`, `sapuReservasiKedaluwarsa()`, `POST /sweep-expired`, `POST /settle-dev` untuk demo. Di Flutter: `KotakPendingTiket` menampilkan hitung mundur dan tombol **Pesan Ulang** saat `RESERVASI BERAKHIR`. Ini pola **saga** dengan **kompensasi** (batalkan + kembalikan stok), bukan transaksi terdistribusi 2PC.

### 10.1 Pembukuan stok simetris

Setiap perubahan stok punya pasangan yang berlawanan:

| Kejadian | Stok | Order |
|---|---|---|
| Checkout (hold) | **−qty** | PENDING |
| Bayar sukses | tidak berubah | PAID |
| Lewat 5 menit | **+qty** | EXPIRED |
| Refund disetujui | **+qty** (kecuali tiket sudah discan) | REFUNDED |
| Scan di gate | tidak berubah (tiket → TERPAKAI) | tetap PAID |

Aturan "tiket yang sudah discan tidak mengembalikan stok" mencegah penjualan ulang tiket yang sudah dipakai.

---

## 11. STATE MANAGEMENT: RIVERPOD

- **WHAT** Pustaka pengelola state: nilai global yang bisa dibaca banyak widget, di-cache, dan dibangun ulang otomatis saat berubah.
- **WHY** `setState` hanya hidup di satu widget. Data yang dipakai beberapa layar (user login, daftar tiket, jumlah notifikasi) butuh satu sumber.
- **PROBLEM** "Prop drilling" (oper data lewat 6 lapis widget) dan state ganda yang tidak sinkron (satu layar bilang 40 tiket, layar lain bilang 38).
- **HOW** `ProviderScope` di akar app → `ref.watch` (ikut berubah) / `ref.read` (ambil sekali) → provider bisa `StreamProvider` (dengar Firestore), `FutureProvider` (sekali ambil + cache), `StateProvider` (nilai sederhana), `Provider.family` (per-id, mis. `ticketsByEventProvider(konserId)`).
- **WHEN** Aplikasi dengan state lintas layar, data server, dan banyak turunan (filter, sorting, gabungan).
- **WHEN NOT** Aplikasi satu layar; atau tim yang belum paham reaktivitas — `setState` lebih jujur.
- **TRADE-OFF** Kompilasi aman, tanpa `BuildContext`, mudah diuji, auto-dispose — tapi kurva belajar (family, autoDispose, `ref.listen`), dan salah pakai `ref.watch` di dalam callback bisa jadi bug halus.
- **ALTERNATIVES** `setState`, Provider, Bloc/Cubit (event-driven, lebih banyak boilerplate), GetX, MobX, Redux.
- **FAILURE MODE** Provider di-`watch` dari `initState` → error; lupa `autoDispose` → data basi; stream tidak di-`cancel` → kebocoran memori; `ref.read` untuk data yang berubah → UI tidak update.
- **REAL WORLD** 16 provider di `app_providers.dart`: `authStateProvider` (StreamProvider<User?>), `currentUserStreamProvider`, `ticketsByEventProvider` (family), dan **`permintaanTabUserProvider`** — `StateProvider<int>` yang berfungsi sebagai **event bus internal**: layar checkout menulis `state = 1`, `user_main_screen` mendengarkan lewat `ref.listen` lalu pindah tab. Ini menghindari oper callback lewat 4 lapis navigasi.

---

## 12. DATA LAYER: FIRESTORE (NoSQL DOKUMEN)

- **WHAT** Database dokumen: data disimpan sebagai JSON-like document di dalam collection; query per collection, realtime stream.
- **WHY** Tidak perlu server DB, gratis di Spark, dan klien bisa mendengar perubahan langsung (`.snapshots()`).
- **PROBLEM** SQL butuh skema kaku & server; untuk aplikasi mobile yang butuh realtime dan offline, NoSQL + SDK lebih praktis.
- **HOW** `collection('events').doc(id).get()`; tulis via `set/update`; dengar via `snapshots()`; transaksi via `runTransaction`.
- **WHEN** Data yang dibaca per-dokumen, butuh realtime, skema masih berkembang.
- **WHEN NOT** Butuh join kompleks, agregasi berat (SUM/GROUP BY atas jutaan baris), transaksi lintas banyak entitas, laporan keuangan serius.
- **TRADE-OFF** Fleksibel & realtime — tapi **tidak ada join**, denormalisasi wajib, biaya baca dihitung per dokumen, dan **rules bukan filter** (lihat bawah).
- **FAILURE MODE** N+1 read (baca 100 dokumen untuk satu layar) → kuota harian habis; dokumen > 1 MB ditolak; query tanpa index → gagal; data ganda karena denormalisasi tidak disinkron.
- **REAL WORLD**
  - Denormalisasi dipakai sadar: `orders` menyimpan `judulKonser`, `kategori`, `harga` **salinan** supaya invoice & laporan tidak perlu join.
  - **`firestore.rules` bukan filter.** Rules hanya menentukan boleh/tidak; kalau klien menulis query yang lebih luas dari aturan, hasilnya **error**, bukan "disaring otomatis". Ini penyebab banyak bug pemula.
  - **Kuota Spark: 20.000 tulis & 50.000 baca per hari.** Karena itu: cache URL backend 60 detik, hindari `.snapshots()` di layar yang tidak perlu, dan laporan admin dihitung di klien dari data yang sudah ada.

---

## 13. OFFLINE-FIRST (TIKET & SCAN)

- **WHAT** Aplikasi tetap bisa menampilkan & memvalidasi tiket tanpa internet.
- **WHY** Di pintu masuk konser, sinyal sering mati — justru saat paling butuh.
- **PROBLEM** Kalau validasi tiket bergantung 100% pada server, antrean berhenti saat jaringan putus.
- **HOW** Tiket disimpan lokal + diberi **tanda tangan hash** (`sha256`, potongan 16 karakter) dan kode QR; scan offline dicatat ke **ledger berkas lokal**; saat online, `POST /sync-offline-scans` mengunggah semuanya, server menolak duplikat.
- **WHEN** Validasi tiket, absensi, pengiriman lapangan, aplikasi kasir.
- **WHEN NOT** Kalau konsistensi mutlak diperlukan dan konflik tidak bisa ditoleransi (mis. saldo dompet).
- **TRADE-OFF** Tetap jalan saat jaringan mati — tapi risiko konflik (tiket yang sama discan di dua gate), dan hash lokal bukan pengganti validasi server.
- **ALTERNATIVES** Cache HTTP, SQLite penuh, CRDT, sinkronisasi berbasis vector clock.
- **FAILURE MODE** Ledger lokal hilang (app di-clear) → scan hilang; jam perangkat salah → urutan konflik salah; tiket dipalsukan (hash bisa dihitung siapa pun yang tahu algoritmanya — karena itu validasi final tetap di server).
- **REAL WORLD** `offline_ticket_service.dart` (ledger `File`), `POST /sync-offline-scans` (`server.js:1320`), `gate_scanner_screen.dart` (mobile_scanner).

---

## 14. NOTIFIKASI: FCM + LOCAL NOTIFICATION

- **WHAT** Push dari server ke perangkat lewat Firebase Cloud Messaging; notifikasi lokal untuk menampilkannya saat app di foreground.
- **WHY** Supaya pengguna tahu ada perubahan (pembayaran berhasil, refund disetujui) tanpa membuka app.
- **PROBLEM** App tidak boleh terus-menerus bertanya ke server (boros baterai & kuota).
- **HOW** App mendaftar → dapat **FCM token** → token disimpan di `users/{uid}.fcmToken` → backend kirim pesan ke token itu → OS menampilkan di tray.
- **WHEN** Peristiwa penting yang tidak dipantau user secara aktif.
- **WHEN NOT** Data yang harus realtime saat app terbuka (pakai stream), atau notifikasi yang tidak actionable (jadi spam).
- **TRADE-OFF** Murah & andal — tapi tidak dijamin sampai (Doze mode), butuh izin (Android 13+), token bisa kedaluwarsa.
- **FAILURE MODE** Token basi setelah reinstall → kirim gagal; izin ditolak → tidak muncul; app di-force-stop → tidak diterima; payload salah → tap tidak membuka halaman.
- **REAL WORLD** Kanal `soundwave_updates`; `FcmGateway` membungkus app dan menyimpan token saat login; tap di tray → halaman akun (user → Jelajah, admin → Konser); tap di dalam app hanya menandai sudah dibaca (notifikasi = informasi, bukan navigasi paksa).

---

## 15. PEMBAYARAN: MIDTRANS SANDBOX

- **WHAT** Penyedia payment gateway; kita memakai **Core API** (VA, GoPay, QRIS) dan **Snap** (halaman/redirect untuk kartu).
- **WHY** Tidak mungkin menangani VA bank & e-wallet sendiri; Midtrans menyediakan integrasi + rekonsiliasi.
- **PROBLEM** Menerima uang butuh kepatuhan, keamanan, dan koneksi ke banyak kanal. Membangun sendiri = proyek bertahun-tahun.
- **HOW** Backend buat transaksi (server key) → dapat nomor VA / QR / link → klien menampilkan → user bayar → Midtrans kirim webhook → backend ubah status.
- **WHEN** Butuh pembayaran online multi-kanal dengan rekonsiliasi.
- **WHEN NOT** Untuk uji coba tanpa uang nyata (pakai `settle-dev` / mode demo), atau kalau hanya butuh transfer manual.
- **TRADE-OFF** Cepat & aman — tapi ada biaya per transaksi (di sandbox gratis), ketergantungan vendor, dan alur status yang harus dipahami (`pending`/`settlement`/`expire`/`deny`/`cancel`).
- **FAILURE MODE** Kunci salah → 401; order_id duplikat → 406; VA kedaluwarsa → user bayar ke nomor mati; webhook tidak sampai → status menggantung (mitigasi: polling).
- **REAL WORLD** Empat jalur: VA (`/create-va`), GoPay (`/create-gopay`), QRIS (`/create-qris`), kartu via Snap (`/create-transaction`). **Instrumen dipakai ulang**: kalau user menekan "Bayar Sekarang" lagi dalam 5 menit, backend mengembalikan nomor VA/QR **yang sama** (kalau belum kedaluwarsa) → tidak ada tagihan ganda (`server.js:577`, `:704`, `:817`). Kartu tidak bisa dipakai ulang karena Midtrans tidak menyimpan sesi kartu. Catatan penting: **QRIS Sandbox menolak `acquirer: gpn` (HTTP 500)** — karena itu parameter itu tidak dipasang.

---

## 16. KEAMANAN: YANG SUDAH DAN YANG BELUM

### Sudah

| Pertahanan | Di mana |
|---|---|
| Harga dihitung ulang di server (anti price tampering) | `server.js:270-292` |
| Webhook diverifikasi SHA512 dengan server key | `server.js:1023` |
| Server key **hanya** di backend (`.env`), tidak pernah di APK | `.env` + `midtrans-client` |
| Service account Firebase hanya di backend | `serviceAccountKey.json` (jangan di-commit) |
| Transaksi Firestore atomik (anti oversell) | `/checkout-atomic` |
| Validasi promo di server (bukan di klien) | `/validate-promo` |
| Idempotensi webhook (`already_processed`) | `server.js:1067` |
| Tiket yang sudah discan tidak mengembalikan stok | `:1659` |
| Deep link `soundwave://` untuk kembali dari browser | `AndroidManifest.xml` |

### Belum (jujur, ini utang teknis)

| Celah | Dampak | Perbaikan |
|---|---|---|
| **Tidak ada autentikasi di endpoint backend** | siapa pun yang tahu URL tunnel bisa memanggil `/admin/refund/approve`, `/settle-dev`, `/sweep-expired` | tambah middleware verifikasi Firebase ID token + daftar email admin |
| URL tunnel berubah tiap restart | webhook bisa nyasar ke alamat mati | Cloudflare Named Tunnel (butuh domain) atau `ngrok --domain` |
| `serviceAccountKey.json` ada di folder proyek | bocor bila folder dibagikan | pindah ke environment variable / secret manager |
| Tanpa rate limit | endpoint bisa dibanjiri | `express-rate-limit` |
| Tanpa HTTPS di sisi lokal (hanya tunnel) | aman dari luar, tapi port 3000 terbuka di LAN | bind ke `127.0.0.1` |
| Tanpa git | tidak ada riwayat, tidak bisa rollback | `git init` + commit + `.gitignore` untuk kunci |

---

## 17. BIAYA Rp 0: KEPUTUSAN DAN KONSEKUENSINYA

| Kebutuhan | Pilihan gratis | Konsekuensi yang diterima |
|---|---|---|
| Auth & database | Firebase Spark | kuota harian (20k tulis / 50k baca), tanpa Cloud Functions |
| Push notifikasi | FCM | gratis, tanpa jaminan pengiriman |
| Backend | Node.js di laptop | laptop harus hidup; IP rumah; port terbuka |
| Akses publik | Cloudflare Quick Tunnel | **URL berubah tiap restart** → disimpan di Firestore |
| Pembayaran | Midtrans Sandbox | tidak ada uang nyata; QRIS tanpa `acquirer` |
| Hosting gambar | Firebase Storage | kuota 5 GB |
| Font | Google Fonts (runtime) | butuh internet saat pertama render (karena itu test render PNG harus memuat font lokal) |

**Kenapa tidak Cloud Functions?** Spark tidak mengizinkan deployment Cloud Functions, dan Cloud Functions tidak boleh memanggil jaringan luar pada paket gratis — padahal kita harus memanggil Midtrans. Karena itu backend dipisah ke laptop + tunnel. Ini **bukan** arsitektur ideal untuk produksi, tapi ini arsitektur yang benar untuk **biaya nol**.

---

## 18. UI/UX & DESIGN SYSTEM

- **WHAT** Kumpulan aturan visual & interaksi yang konsisten: warna, tipografi, jarak, komponen, bahasa.
- **WHY** Konsistensi mengurangi beban kognitif; pengguna tidak perlu belajar ulang di tiap layar.
- **PROBLEM** Tanpa sistem, tiap layar punya tombol beda warna, ukuran beda, istilah beda.
- **HOW** Token (`AppColors.background #000000`, `surface #0B0B0F`, `warnaHarga #00E676`, `error #FF5252`), tipografi (Rajdhani untuk judul/angka tegas, Space Grotesk untuk teks), komponen bersama (`TombolDialogSejajar`, `KotakPendingTiket`, `NotifikasiBell`, `GambarWidget`), dan pola state (loading = shimmer, kosong = ilustrasi + ajakan, error = pesan ramah + tombol coba lagi).
- **WHEN** Selalu, sejak layar pertama.
- **WHEN NOT** Prototipe sekali pakai / eksperimen.
- **TRADE-OFF** Konsisten & cepat — tapi kaku, dan token yang salah desain menyebar ke semua layar.
- **FAILURE MODE** Kontras rendah (teks abu di latar hitam), target sentuh < 44 px, teks terpotong di layar kecil, overflow layout.
- **REAL WORLD** Prinsip yang dipegang: warna latar dan warna teks tombol **dipisah** (jangan hijau di hijau); `AlertDialog.actions` adalah `OverflowBar` sehingga tombol bisa turun baris → dibuat `TombolDialogSejajar`; setiap teks kritis diberi `maxLines` + `ellipsis`.

---

## 19. SISI BISNIS

| Konsep | Implementasi | Alasan |
|---|---|---|
| Katalog & filter | hanya 3 filter: tanggal, harga, lokasi | filter lebih banyak = pengguna bingung; 3 sudah cukup untuk keputusan beli |
| Pilih dulu, baru pesan | `PILIH` hanya menandai; `PESAN TIKET` mati sampai ada pilihan | mencegah pesanan tak sengaja |
| Harga berjenjang | VVIP > VIP > Festival > Tribun > Reguler | segmentasi daya beli; harga & stok dibaca langsung dari dokumen tiket |
| Promo | `promo_codes` + `claimed_promos` + `/validate-promo` | diskon terkontrol, satu kode satu kali per user |
| Refund | `request-refund` → admin approve/reject | butuh keputusan manusia; stok kembali hanya bila tiket belum discan |
| Laporan | `laporan_penjualan`, `laporan_revenue`, `fl_chart` | keputusan harga & jadwal butuh data, bukan feeling |
| Hold 5 menit | `HOLD_MENIT = 5` | cukup untuk transfer/VA, tidak terlalu lama menahan stok |
| Notifikasi informatif | tap hanya menandai dibaca | tidak memaksa navigasi; pengguna tetap punya kendali |

**Metrik yang relevan** (belum diinstrumentasi, tapi penting): konversi checkout→paid, waktu rata-rata bayar, rasio EXPIRED, refund rate, okupansi per kategori.

---

## 20. TOOLS YANG DIPAKAI

| Kategori | Tool | Kegunaan di proyek ini |
|---|---|---|
| Bahasa | **Dart 3** | seluruh aplikasi |
| Framework mobile | **Flutter (Material 3)** | UI Android (juga siap iOS/web) |
| State | **Riverpod 2.6** | 16 provider, family, stream |
| Backend runtime | **Node.js 18+** | menjalankan `server.js` |
| Framework backend | **Express 4** | routing, JSON body, CORS |
| DB | **Firestore** | 10 koleksi, realtime, transaksi |
| Auth | **Firebase Auth** | email/password + Google Sign-In |
| Push | **FCM + flutter_local_notifications** | notifikasi tray & in-app |
| File | **Firebase Storage** | poster konser, bukti refund |
| Pembayaran | **midtrans-client** | Snap + Core API |
| Tunnel | **cloudflared** | membuka laptop ke HTTPS publik |
| Admin SDK | **firebase-admin** | backend menulis Firestore/Storage dengan hak penuh |
| Konfig | **dotenv** | kunci rahasia di `.env` |
| CORS | **cors** | mengizinkan klien web/HP memanggil backend |
| UI lib | `google_fonts`, `shimmer`, `cached_network_image`, `fl_chart`, `qr_flutter` | font, skeleton loading, cache gambar, grafik laporan, QR tiket |
| Utilitas | `intl`, `timezone`, `crypto`, `cryptography`, `path` | format tanggal id_ID, zona waktu, hash tiket offline |
| Perangkat | `mobile_scanner`, `image_picker`, `share_plus`, `url_launcher` | scan QR gate, unggah bukti, bagikan konser, buka browser |
| CLI | `flutter run/build/test/analyze`, `dart format`, `npm start`, `cloudflared`, `adb`, `aapt2` | siklus kerja harian & verifikasi APK |
| Build | **Gradle (AGP)** | `assembleDebug`, signing debug |
| Editor | VS Code / Android Studio | — |

**Yang sengaja TIDAK dipakai:** `freezed`/`json_serializable` (codegen menambah langkah build; model ditulis tangan), `get_it` (Riverpod sudah jadi DI), `Bloc` (terlalu banyak boilerplate untuk 1 tim), `dio` (`http` cukup), `go_router` (navigasi imperatif masih memadai), Docker/Kubernetes (tidak ada gunanya untuk 1 proses di 1 laptop).

---

## 21. KATALOG FAILURE MODE

| Yang gagal | Gejala di pengguna | Penanganan sekarang | Saran |
|---|---|---|---|
| Backend laptop mati | "Server pembayaran sedang tidak bisa dihubungi" | pesan ramah + tombol coba lagi | health check + banner status |
| URL tunnel berubah | pembayaran gagal total | URL disimpan di Firestore, cache 60 s, `lupakanCacheUrl()` | Named Tunnel |
| Webhook tidak sampai | status tetap PENDING padahal sudah bayar | `/poll-payment` + tombol cek status | job rekonsiliasi berkala |
| Sweeper tidak jalan | stok tertahan | tombol manual `/sweep-expired` | cron di backend |
| Stok habis di tengah checkout | tombol `HABIS`, baris tidak bisa diketuk | validasi ulang di `/checkout-atomic` | tampilkan sisa realtime |
| Kuota Firestore harian habis | data tidak termuat | — | cache lokal + kurangi listener |
| Internet putus saat scan | gate macet | ledger offline + `sync-offline-scans` | indikator "menunggu sinkron" |
| Font gagal diunduh | teks fallback | — | bundle font di aset |
| APK tidak terpasang | install gagal | — | cek `minSdk 24`, signature |
| Pengguna menutup app saat bayar | order menggantung | hold 5 menit + EXPIRED + Pesan Ulang | push "pembayaran belum selesai" |

---

## 22. DEVIL'S ADVOCATE: KRITIK TERHADAP SISTEM INI

Bagian ini sengaja tidak menyenangkan. Semua ini nyata.

1. **Backend tanpa autentikasi adalah masalah terbesar.** Satu URL tunnel bocor = siapa pun bisa menyetujui refund dan menandai pesanan lunas. Mitigasi sekarang hanya "URL-nya panjang dan berganti". Itu **bukan** keamanan, itu kebetulan. Perbaikan: verifikasi Firebase ID token + allowlist email admin. (Usaha: ±1 jam.)
2. **Ketergantungan pada satu laptop.** Backend mati = tidak ada yang bisa membeli tiket. Tidak ada redundansi, tidak ada health monitoring, tidak ada notifikasi saat mati.
3. **`server.js` 2.176 baris satu berkas.** Sulit dinavigasi, rawan konflik, tidak bisa di-unit-test per fungsi. Ini monolith yang benar secara biaya tapi salah secara perawatan jangka panjang.
4. **Tidak ada git.** Tidak ada riwayat, tidak ada rollback, tidak ada review. Satu `rm` salah = hilang.
5. **Test backend bukan test otomatis.** 7 skrip `test_*.js` harus dijalankan manual; tidak ada CI yang menjalankan `flutter test` + skrip itu setiap perubahan.
6. **Denah venue sudah dihapus (Opsi A).** Pilihan kursi dulu murni hiasan — stok hanya per kategori, jadi dua orang bisa "memilih" kursi yang sama. Daripada menjanjikan hal yang tidak ada, seluruh tab denah dibuang; pembelian hanya lewat daftar tiket per kategori.
7. **Harga & stok di denah dulu hardcode** — contoh nyata bagaimana UI bisa berbohong tanpa error apa pun. Pelajaran yang dibawa: **UI yang menampilkan angka harus membaca dari satu sumber kebenaran** (sekarang `TiketKonserModel` dari Firestore).
8. **Tidak ada observability.** `logger.js` menulis log, tapi tidak ada metrik, alert, atau tracing. Kalau pembayaran gagal jam 2 pagi, tidak ada yang tahu sampai ada komplain.
9. **Refund adalah proses setengah manual.** Persetujuan admin mengembalikan stok & status, tapi pengembalian dana sebenarnya di Midtrans harus dilakukan terpisah (sandbox tidak punya API refund penuh untuk semua kanal).
10. **Kuota Spark bisa habis di hari ramai.** 20.000 tulis/hari habis kalau ada ~1.000 order dengan beberapa update status. Tidak ada backpressure atau peringatan.
11. **Tidak ada versi API.** Kalau `server.js` berubah bentuk response, APK lama di HP pengguna langsung rusak. Tidak ada `/v1/`.
12. **Keamanan data pengguna minimal.** Tidak ada enkripsi tambahan untuk data sensitif, tidak ada audit log siapa mengubah apa.

Yang **sudah benar** dan jarang ada di proyek sekelas ini: verifikasi signature webhook, hitung ulang harga di server, transaksi atomik untuk stok, idempotensi webhook, pemisahan warna tombol/teks, dan test penjaga (guard test) yang memastikan perbaikan tidak diam-diam dibatalkan.

---

## 23. ROADMAP YANG MASUK AKAL (urut dampak)

1. **Auth di backend** — verifikasi ID token + allowlist admin. *(paling mendesak)*
2. **`git init` + `.gitignore`** untuk `.env` & `serviceAccountKey.json`.
3. **Cron sweeper** di dalam proses backend (bukan manual).
4. **Named tunnel** (butuh domain gratis) supaya URL tetap.
5. **Pecah `server.js`** jadi `routes/`, `services/`, `middleware/` — masih satu proses, tapi terbaca.
6. **CI lokal**: satu skrip `npm run verifikasi` yang menjalankan `flutter analyze`, `flutter test`, dan 7 skrip backend.
7. **Metrik minimal**: hitung checkout vs paid per hari, tulis ke satu dokumen `stats/harian`.

---

## 24. GLOSARIUM SINGKAT

| Istilah | Arti praktis di sini |
|---|---|
| **Atomic** | Semua langkah berhasil atau semua dibatalkan |
| **Idempotent** | Dijalankan berkali-kali, hasilnya sama (webhook dobel tidak dobel-charge) |
| **Saga** | Rangkaian langkah dengan kompensasi bila gagal (hold → bayar → atau kembalikan) |
| **Compensating transaction** | Aksi pembatalan yang mengembalikan keadaan (stok +qty saat EXPIRED) |
| **Race condition** | Dua proses membaca nilai sama lalu menulis bersamaan → hasil salah |
| **Oversell** | Menjual lebih banyak dari stok karena race condition |
| **Denormalisasi** | Menyimpan salinan data di dokumen lain agar tidak perlu join |
| **BFF** | Backend khusus untuk satu frontend, menyembunyikan detail layanan lain |
| **Webhook** | HTTP callback dari pihak ketiga saat ada peristiwa |
| **Polling** | Klien bertanya berkala "sudah?" |
| **Deep link** | Tautan yang membuka halaman tertentu di app (`soundwave://`) |
| **Guard test** | Test yang gagal bila sebuah perbaikan dibatalkan orang lain |
| **Cold start** | Waktu tambahan saat proses/fungsi pertama kali dijalankan |
| **Backpressure** | Kemampuan sistem memperlambat permintaan saat kelebihan beban |

---

*Dokumen ini ditulis berdasarkan kode per 17 Oktober 2026, versi aplikasi 2.4.4 (28).*
