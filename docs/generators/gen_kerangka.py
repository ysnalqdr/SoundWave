"""kerangka_sistem.png — komponen & alur request SoundWave v2.4.7."""
from pathlib import Path

from gen_common import Canvas, MONO, MONO_B, WHITE

W, H = 1600, 1180
c = Canvas(W, H, s=2)

c.header(
    "SOUNDWAVE / ARCHITECTURE",
    "Kerangka Sistem & Alur Request",
    "kotak = komponen · panah penuh = request · panah putus-putus = respons / notifikasi",
    W,
)

# ---------------------------------------------------------------- kotak
CW, CH = 440, 300
COLS = [72, 580, 1088]
ROW1, ROW2 = 200, 556


def komponen(x, y, huruf, judul, catatan, baris, tinggi=CH):
    c.rect(x, y, CW, tinggi, 1.3)
    c.badge(x - 11, y - 11, huruf, 22)
    c.text(x + 16, y + 13, judul, c.f(MONO_B, 15.5))
    if catatan:
        c.text(x + CW - 16, y + 17, catatan, c.f(MONO, 10.5), anchor="ra")
    c.line(x, y + 42, x + CW, y + 42, 1.1)
    ly = y + 58
    for t in baris:
        if t:
            c.text(x + 16, ly, t, c.f(MONO, 13.2))
        ly += 26


komponen(COLS[0], ROW1, "A", "APLIKASI · FLUTTER", "penonton + admin", [
    "screens/    26 layar",
    "providers/  16 state",
    "services/   6 facade",
    "",
    "penonton : jelajah → tiket",
    "admin    : dashboard → kelola",
    "",
    "baca Firestore langsung",
    "tulis uang lewat backend",
])

komponen(COLS[1], ROW1, "B", "FIREBASE API", "lewat SDK", [
    "AUTH     → login · peran",
    "FCM      → push notifikasi",
    "STORAGE  → poster · bukti",
    "",
    "diakses langsung dari APK",
    "bukan lewat backend",
    "",
    "peran menentukan menu :",
    "admin · super_admin · user",
])

komponen(COLS[2], ROW1, "E", "MIDTRANS · PAYMENT GATEWAY", "sandbox", [
    "VA / QRIS / GoPay",
    "kartu lewat halaman Snap",
    "",
    "user membayar di bank",
    "atau e-wallet",
    "",
    "status berubah di Midtrans",
    "bukan di APK",
])

komponen(COLS[0], ROW2, "C", "CLOUDFLARE TUNNEL", "gratis", [
    "alamat HTTPS publik",
    "→ localhost:3000",
    "",
    "perlu karena backend",
    "jalan di laptop (Rp 0)",
    "URL disimpan di Firestore",
    "",
    "dinyalakan lewat",
    "START_SOUNDWAVE.bat",
])

komponen(COLS[1], ROW2, "D", "BACKEND · NODE + EXPRESS", "23 rute", [
    "/checkout-atomic   stok · qty",
    "/midtrans-webhook  SHA512",
    "/poll-payment · /sweep-expired",
    "/refund · /sync-offline-scans",
    "",
    "satu-satunya pemegang",
    "server key Midtrans",
    "& service account Firebase",
])

komponen(COLS[2], ROW2, "F", "FIRESTORE · DATABASE", "10 koleksi", [
    "transaksi atomik",
    "realtime stream",
    "rules bukan filter",
    "",
    "sumber kebenaran :",
    "stok · harga · status",
    "",
    "dibaca HP, ditulis backend",
])

# ---------------------------------------------------------------- panah
fnum = c.f(MONO_B, 12)


def nomor(x, y, n):
    c.fill_rect(x - 11, y - 11, 22, 22, WHITE)
    c.badge(x - 11, y - 11, str(n), 22, fnum)


# 1  APK -> Firebase (login, katalog)
c.arrow([(512, 240), (580, 240)], head=6.5)
nomor(546, 240, 1)
# 8  Firebase -> APK (push FCM)
c.arrow([(580, 282), (512, 282)], dashed=True, head=6.5)
nomor(546, 282, 8)
# 2  APK -> Tunnel (HTTPS)
c.arrow([(292, 500), (292, 556)], head=6.5)
nomor(292, 528, 2)
# 3  Tunnel -> Backend
c.arrow([(512, 700), (580, 700)], head=6.5)
nomor(546, 700, 3)
# 4  Backend -> Firestore (admin SDK)
c.arrow([(1020, 700), (1088, 700)], head=6.5)
nomor(1054, 700, 4)
# 5  Backend -> Midtrans (createTransaction)
c.arrow([(800, 556), (800, 520), (1150, 520), (1150, 500)], head=6.5)
nomor(975, 520, 5)
# 7  Midtrans -> Backend (webhook, verifikasi SHA512)
c.arrow([(1250, 500), (1250, 536), (880, 536), (880, 556)], dashed=True, head=6.5)
nomor(1180, 536, 7)

# ---------------------------------------------------------------- strip
c.text(72, 890, "U R U T A N   R E Q U E S T   ·   S A T U   P E M B E L I A N", c.f(MONO, 11.5))
strip = [
    ("1", "login", "APK → Firebase Auth"),
    ("2", "checkout", "APK → Tunnel (HTTPS)"),
    ("3", "diteruskan", "Tunnel → Backend :3000"),
    ("4", "potong stok", "Backend → Firestore"),
    ("5", "tagih", "Backend → Midtrans"),
    ("6", "bayar", "user → bank / e-wallet"),
    ("7", "webhook", "Midtrans → Backend"),
    ("8", "tiket aktif", "Backend → FCM → APK"),
]
cw = (1528 - 72) // 8
for i, (n, judul, detail) in enumerate(strip):
    x = 72 + i * cw
    c.rect(x, 910, cw, 62, 1.1)
    c.text(x + 10, 920, n, c.f(MONO_B, 10.5))
    c.text(x + 26, 918, judul, c.f(MONO_B, 13))
    c.text(x + 10, 942, detail, c.f(MONO, 10.5))

# ---------------------------------------------------------------- catatan
c.line(72, 1000, 1528, 1000, 1.4)
notes = [
    ("dua jalur data", "APK membaca Firestore langsung (stream realtime). Penulisan yang menyangkut uang selalu lewat backend."),
    ("pemegang kunci", "server key Midtrans & service account Firebase hanya ada di backend. APK tidak menyimpannya."),
    ("dashboard admin", "4 KPI, grafik 7 hari, daftar perlu tindakan. Semua dari stream orders / tickets / events yang sudah ada."),
    ("istilah", "Midtrans adalah payment gateway, bukan API gateway. Pintu masuk sistem = Cloudflare Tunnel + Express."),
    ("sumber kebenaran", "harga, stok, status pesanan. HP hanya menampilkan dan mengirim niat, bukan keputusan."),
    ("penjaga admin", "rute /admin/* wajib ID token Firebase milik akun ber-role admin, diverifikasi auth_admin.js."),
]
y = 1018
for k, v in notes:
    c.text(72, y, "–", c.f(MONO, 11.5))
    c.text(88, y, k, c.f(MONO_B, 11.5))
    c.text(88 + c.tw(k, c.f(MONO_B, 11.5)) + 8, y, ": " + v, c.f(MONO, 11.5))
    y += 20

c.text(72, 1138, "sumber: server.js (23 rute) · lib/services (6 berkas) · lib/providers/app_providers.dart · v2.4.7+31 · 319 test",
       c.f(MONO, 10.5))
c.text(72, 1156, "Firestore dan Firebase API satu platform; dipisah di gambar karena perannya berbeda (database vs layanan API).",
       c.f(MONO, 10.5))

OUT = Path(__file__).resolve().parents[2] / "docs" / "kerangka_sistem.png"
c.save(str(OUT))
