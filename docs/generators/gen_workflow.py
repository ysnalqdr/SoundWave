"""workflow_beli_tiket.png — alur beli tiket SoundWave v2.4.7 (tanpa denah)."""
from pathlib import Path

from gen_common import Canvas, MONO, MONO_B, WHITE

W, H = 1380, 1730
c = Canvas(W, H, s=2)

c.header(
    "SOUNDWAVE / WORKFLOW",
    "Alur Pembelian Tiket",
    "kotak = proses · belah ketupat = keputusan · panah = perpindahan · cabang kanan = jalur gagal",
    W,
)

NX, NW, NH, GAP = 72, 540, 56, 26
CX = NX + NW // 2          # 342
FX, FW = 700, 470          # kotak gagal
Y0 = 196

simpul = [
    ("MULAI", "detail konser, tab TENTANG · TIKET"),
    ("baca tiket dari Firestore", "harga & stok realtime"),
    ("stok > 0 ?", None),
    ("pilih kategori → [BELI]", "urutan tetap VVIP → VIP → Festival → Tribun → Reguler"),
    ("kode promo (opsional)", "klaim → harga terpotong"),
    ("createPendingOrder()", "status PENDING, stok belum dipotong"),
    ("POST /checkout-atomic", "satu-satunya jalan memotong stok"),
    ("stok cukup ?", None),
    ("TRANSAKSI", "stok −qty · hold 5 menit (jam server) · QR Ed25519"),
    ("tagihan Midtrans", "VA / QRIS / GoPay / kartu"),
    ("dibayar ≤ 5 menit ?", None),
    ("webhook masuk", "SHA512"),
    ("signature valid ?", None),
    ("order PAID → tiket aktif", "FCM push ke HP"),
    ("QR tiket → gate scan", "Ed25519, diverifikasi offline"),
    ("SELESAI", "TERPAKAI, masuk venue"),
]

keputusan = {2, 7, 10, 12}
gagal = {
    2: ("baris HABIS", "harga dicoret, tak bisa diklik"),
    7: ("409", "stok habis / revisi bentrok"),
    10: ("EXPIRED", "stok +qty, promo kembali"),
    12: ("TOLAK 401", "log, abaikan"),
}


def ytop(i):
    return Y0 + i * (NH + GAP)


def ymid(i):
    return ytop(i) + NH // 2


# ---------------------------------------------------------------- simpul
fmain = c.f(MONO_B, 14)
fdet = c.f(MONO, 11)
fnum = c.f(MONO_B, 11.5)

for i, (judul, detail) in enumerate(simpul):
    y = ytop(i)
    c.badge(NX - 36, ymid(i) - 11, str(i + 1), 22, fnum)
    if i in keputusan:
        c.diamond(CX, ymid(i), 420, 76)
        c.text(CX, ymid(i), judul, fmain, anchor="mm")
    else:
        tebal = i in (0, 15)
        c.rect(NX, y, NW, NH, 2.0 if tebal else 1.3)
        c.text(NX + 16, y + (9 if detail else 18), judul, fmain)
        if detail:
            c.text(NX + 16, y + 32, detail, fdet)

# ---------------------------------------------------------------- panah utama
for i in range(len(simpul) - 1):
    atas = ymid(i) + 38 if i in keputusan else ytop(i) + NH
    bawah = ytop(i + 1)
    if i + 1 in keputusan:
        bawah = ymid(i + 1) - 38
    c.arrow([(CX, atas), (CX, bawah)], head=6.5)
    if i in keputusan:
        c.mask_text(CX + 26, (atas + bawah) / 2, "YA", c.f(MONO_B, 10.5))

# ---------------------------------------------------------------- cabang gagal
for i, (judul, detail) in gagal.items():
    cy = ymid(i)
    c.arrow([(CX + 210, cy), (FX, cy)], head=6.5)
    c.mask_text((CX + 210 + FX) / 2, cy - 9, "TIDAK", c.f(MONO_B, 10.5))
    by = cy - 27
    c.rect(FX, by, FW, 54, 1.3)
    c.text(FX + 14, by + 9, judul, c.f(MONO_B, 12.5))
    c.text(FX + 14, by + 29, detail, c.f(MONO, 11))

# ---------------------------------------------------------------- pesan ulang
cy_exp = ymid(10)
cy_pilih = ymid(3)
c.arrow([(FX + FW, cy_exp), (1215, cy_exp), (1215, cy_pilih), (NX + NW, cy_pilih)], head=6.5)
c.mask_text(930, cy_pilih, "PESAN ULANG (user mulai lagi)", c.f(MONO_B, 10.5))

# ---------------------------------------------------------------- refund
c.text(72, 1522, "A L U R   R E F U N D   ·   S E T E L A H   T I K E T   A K T I F", c.f(MONO, 11.5))
refund = [
    ("R1", "user ajukan", "invoice → refund"),
    ("R2", "refunds: PENDING", "menunggu admin"),
    ("R3", "admin tinjau", "dashboard → refund"),
    ("R4", "APPROVED / REJECTED", "dana kembali / alasan"),
    ("R5", "order REFUNDED", "tiket dicabut"),
]
bw, bg, by, bh = 224, 26, 1546, 74
for i, (tag, judul, detail) in enumerate(refund):
    x = 72 + i * (bw + bg)
    c.rect(x, by, bw, bh, 1.3)
    c.text(x + 12, by + 9, tag, c.f(MONO_B, 10.5))
    c.text(x + 12, by + 27, judul, c.f(MONO_B, 12.5))
    c.text(x + 12, by + 48, detail, c.f(MONO, 10.5))
    if i < len(refund) - 1:
        c.arrow([(x + bw, by + bh / 2), (x + bw + bg, by + bh / 2)], head=5.5)

# ---------------------------------------------------------------- catatan
c.text(72, 1658, "sumber: server.js /checkout-atomic · /midtrans-webhook · /sweep-expired · midtrans_service.dart · offline_ticket_service.dart · v2.4.7+31",
       c.f(MONO, 10.5))
c.text(72, 1676, "semua keputusan uang (harga, stok, status) diputuskan di server; HP hanya menampilkan dan mengirim niat.",
       c.f(MONO, 10.5))
c.text(72, 1694, "tidak ada lagi denah atau pilih kursi: pembeli memilih kategori, bukan nomor kursi.",
       c.f(MONO, 10.5))

OUT = Path(__file__).resolve().parents[2] / "docs" / "workflow_beli_tiket.png"
c.save(str(OUT))
