"""
Whole Table + ERD SoundWave — SATU SHEET, gaya MySQL Workbench.

Rancangan visual mengikuti contoh yang dikirim user (ERD klinik):
  * Tabel berheader bar, sudut tegas, border abu 1 px.
  * PK ditandai kunci kuning, FK ditandai berlian merah.
  * Garis relasi hitam putus-putus dengan ujung crow's foot.
  * Latar putih penuh, teks hitam — nol gradien, nol drop shadow.

Beda dengan contoh: header sengaja memakai abu netral (bukan gradien biru
Aero) supaya tidak terlihat seperti tangkapan layar perangkat lunak lama.
Gaya tetap sama, hanya warnanya dinetralkan.

Isi: 5 tabel (users, events, tickets, promo_codes, orders) x 3 baris data
fiktif + ERD dalam SATU sheet Excel.

Jalankan: python docs/generators/gen_whole_table_erd_sheet.py
"""

from __future__ import annotations

import math
from pathlib import Path

from openpyxl import Workbook
from openpyxl.drawing.image import Image as XLImage
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from PIL import Image, ImageDraw, ImageFont

KELUAR_ROOT = Path(__file__).resolve().parents[2]
KELUAR_XLSX = KELUAR_ROOT / "WHOLE_TABLE_SOUNDWAVE_v2.xlsx"
KELUAR_PNG = KELUAR_ROOT / "docs" / "mockup" / "erd_soundwave_sheet.png"

# ============================== PALET ==============================
PUTIH = "#FFFFFF"
TINTA = "#1A1A1A"
ABU_HEAD = "#D9D9D9"      # header tabel (netral, bukan biru Aero)
ABU_BORDER = "#8C8C8C"
ABU_TEKS = "#595959"
ABU_KUNCI = "#999999"
EMAS = "#E8B33A"          # ikon kunci PK
MERAH = "#D65A5A"         # ikon berlian FK
BARIS_SELANG = "#F7F7F7"

# ============================== DATA ==============================
# urutan kolom: PK paling kiri, FK paling kanan (gaya contoh DreamHome)
TABEL = [
    dict(
        nama="users",
        kolom=[
            ("id_user", "VARCHAR(5)", "PK"),
            ("nama", "VARCHAR(100)", ""),
            ("email", "VARCHAR(100)", ""),
            ("role", "VARCHAR(10)", ""),
            ("no_telepon", "VARCHAR(20)", ""),
            ("created_at", "DATETIME", ""),
        ],
        baris=[
            ["U01", "Rizky Pratama", "rizky.p@mail.com", "user", "0812-3456-7890", "2026-01-15"],
            ["U02", "Salsabila Putri", "salsa.p@mail.com", "user", "0813-9876-5432", "2026-02-03"],
            ["U03", "Bagas Nugroho", "bagas.n@mail.com", "admin", "0857-1122-3344", "2026-01-05"],
        ],
    ),
    dict(
        nama="events",
        kolom=[
            ("id_event", "VARCHAR(5)", "PK"),
            ("judul", "VARCHAR(100)", ""),
            ("lokasi", "VARCHAR(50)", ""),
            ("tanggal", "DATE", ""),
            ("penyelenggara", "VARCHAR(100)", ""),
            ("status", "VARCHAR(15)", ""),
        ],
        baris=[
            ["E01", "Senja Fest 2026", "Medan", "2026-11-16", "SoundWave Live", "publish"],
            ["E02", "Jakarta Night Beat", "Jakarta", "2026-12-05", "Nightbeat Ent", "publish"],
            ["E03", "Surabaya Rock Wave", "Surabaya", "2026-12-20", "Rockwave ID", "draft"],
        ],
    ),
    dict(
        nama="tickets",
        kolom=[
            ("id_tiket", "VARCHAR(5)", "PK"),
            ("kategori", "VARCHAR(20)", ""),
            ("harga", "DECIMAL(12,0)", ""),
            ("stok", "INT", ""),
            ("terjual", "INT", ""),
            ("id_event", "VARCHAR(5)", "FK"),
        ],
        baris=[
            ["T01", "VVIP", 1500000, 100, 42, "E01"],
            ["T02", "Reguler", 500000, 500, 310, "E01"],
            ["T03", "VIP", 950000, 200, 88, "E02"],
        ],
    ),
    dict(
        nama="promo_codes",
        kolom=[
            ("kode_promo", "VARCHAR(20)", "PK"),
            ("tipe", "VARCHAR(15)", ""),
            ("nilai", "DECIMAL(12,0)", ""),
            ("min_pembelian", "DECIMAL(12,0)", ""),
            ("max_pakai", "INT", ""),
            ("sudah_dipakai", "INT", ""),
            ("aktif", "TINYINT(1)", ""),
            ("id_event", "VARCHAR(5)", "FK"),
        ],
        baris=[
            ["EARLYBIRD50", "nominal", 50000, 300000, 200, 37, 1, "E01"],
            ["SENJA10", "persentase", 10, 500000, 100, 12, 1, "E01"],
            ["NIGHTBEAT", "nominal", 100000, 800000, 150, 5, 1, "E02"],
        ],
    ),
    dict(
        nama="orders",
        kolom=[
            ("id_order", "VARCHAR(5)", "PK"),
            ("jumlah_tiket", "INT", ""),
            ("subtotal", "DECIMAL(12,0)", ""),
            ("diskon", "DECIMAL(12,0)", ""),
            ("pajak", "DECIMAL(12,0)", ""),
            ("biaya_layanan", "DECIMAL(12,0)", ""),
            ("total_bayar", "DECIMAL(12,0)", ""),
            ("status", "VARCHAR(15)", ""),
            ("tanggal_beli", "DATE", ""),
            ("id_user", "VARCHAR(5)", "FK"),
            ("id_event", "VARCHAR(5)", "FK"),
            ("id_tiket", "VARCHAR(5)", "FK"),
            ("kode_promo", "VARCHAR(20)", "FK"),
        ],
        baris=[
            ["O01", 2, 1000000, 50000, 95000, 52500, 1097500, "AKTIF", "2026-10-20",
             "U01", "E01", "T02", "EARLYBIRD50"],
            ["O02", 1, 1500000, 0, 150000, 80000, 1730000, "TERPAKAI", "2026-10-21",
             "U02", "E01", "T01", None],
            ["O03", 1, 950000, 100000, 85000, 47500, 982500, "PENDING", "2026-10-22",
             "U01", "E02", "T03", "NIGHTBEAT"],
        ],
    ),
]

# Rute ortogonal eksplisit. Semua jalur sudah diperiksa tidak menembus kotak:
#   koridor kiri x=30, koridor tengah x=500, koridor kanan x=1110.
#   Jalur horizontal hanya lewat celah antar-baris.
# (induk, anak, fk, label, [waypoint...], arah_crowfoot)
RELASI = [
    # users -> orders : kelilingi margin kiri (tickets menghalangi di tengah)
    ("users", "orders", "id_user", "membuat",
     [(60, 200), (25, 200), (25, 900), (370, 900)], "kiri"),
    # events -> orders : kelilingi margin kanan (promo_codes menghalangi)
    ("events", "orders", "id_event", "memiliki",
     [(1080, 200), (1155, 200), (1155, 920), (770, 920)], "kanan"),
    # events -> tickets : turun lewat celah, masuk dari atas tickets
    ("events", "tickets", "id_event", "punya tipe",
     [(780, 330), (780, 410), (460, 410), (460, 480)], "bawah"),
    # events -> promo_codes : turun lewat celah kanan
    ("events", "promo_codes", "id_event", "punya promo",
     [(980, 330), (980, 440), (880, 440), (880, 480)], "bawah"),
    # tickets -> orders : turun di jalur tengah-kiri
    ("tickets", "orders", "id_tiket", "dipakai",
     [(260, 710), (260, 810), (500, 810), (500, 860)], "bawah"),
    # promo_codes -> orders : turun di jalur tengah-kanan
    ("promo_codes", "orders", "kode_promo", "dipakai",
     [(880, 770), (880, 830), (650, 830), (650, 860)], "bawah"),
]


# ============================ WARNA SEL ============================
def fill(hex_: str) -> PatternFill:
    return PatternFill("solid", fgColor=hex_.replace("#", ""))


def sisi(hex_: str, gaya: str = "thin") -> Side:
    return Side(style=gaya, color=hex_.replace("#", ""))


# ============================ EXCEL ============================
def tulis_relasi(ws, kolom: int, baris: int) -> None:
    """Daftar relasi di sisi kanan whole table — pengganti gambar ERD."""
    ws.column_dimensions[get_column_letter(kolom)].width = 4
    ws.column_dimensions[get_column_letter(kolom + 1)].width = 18
    ws.column_dimensions[get_column_letter(kolom + 2)].width = 18
    ws.column_dimensions[get_column_letter(kolom + 3)].width = 18
    ws.column_dimensions[get_column_letter(kolom + 4)].width = 18
    ws.column_dimensions[get_column_letter(kolom + 5)].width = 46

    ws.cell(baris, kolom + 1, "DAFTAR RELASI").font = Font(
        name="Calibri", size=13, bold=True, color="1A1A1A")
    baris += 1
    ws.cell(baris, kolom + 1,
            "dasar pembuatan ERD · semua 1:N").font = Font(
        name="Calibri", size=9, italic=True, color="595959")
    baris += 2

    kepala = ["Tabel Induk", "Tabel Anak", "Foreign Key", "Kardinalitas", "Arti"]
    for i, h in enumerate(kepala):
        c = ws.cell(baris, kolom + 1 + i, h)
        c.font = Font(name="Calibri", size=9, bold=True, color="1A1A1A")
        c.fill = fill("#EFEFEF")
        c.alignment = Alignment(horizontal="center", vertical="center")
        c.border = Border(left=sisi(ABU_BORDER), right=sisi(ABU_BORDER),
                          top=sisi(ABU_BORDER), bottom=sisi(ABU_BORDER))
    baris += 1

    for induk, anak, fk, arti in [
        ("users", "orders", "id_user", "Satu pengguna dapat membuat banyak pesanan"),
        ("events", "orders", "id_event", "Satu konser dapat memiliki banyak pesanan"),
        ("events", "tickets", "id_event", "Satu konser memiliki banyak tipe tiket"),
        ("events", "promo_codes", "id_event", "Satu konser memiliki banyak kode promo"),
        ("tickets", "orders", "id_tiket", "Satu tipe tiket dipakai di banyak pesanan"),
        ("promo_codes", "orders", "kode_promo", "Satu kode promo dipakai di banyak pesanan"),
    ]:
        for i, v in enumerate([induk, anak, fk, "1 : N", arti]):
            c = ws.cell(baris, kolom + 1 + i, v)
            c.font = Font(name="Consolas", size=9, color="1A1A1A")
            c.border = Border(left=sisi(ABU_BORDER), right=sisi(ABU_BORDER),
                              top=sisi(ABU_BORDER), bottom=sisi(ABU_BORDER))
            c.alignment = Alignment(horizontal="left" if i == 4 else "center",
                                    vertical="center")
        baris += 1

    baris += 2
    ws.cell(baris, kolom + 1, "CATATAN").font = Font(
        name="Calibri", size=10, bold=True, color="1A1A1A")
    baris += 1
    for cat in [
        "PK = Primary Key, ditulis di kolom paling kiri setiap tabel.",
        "FK = Foreign Key, ditulis di kolom paling kanan setiap tabel.",
        "Tabel tickets menyimpan katalog tipe tiket per konser,",
        "bukan tiket yang sudah dibeli (itu tersimpan di orders).",
        "5 tabel ini sama dengan 5 data store pada DFD Level 0:",
        "D1 users, D2 events, D3 orders, D4 tickets, D5 promos.",
    ]:
        ws.cell(baris, kolom + 1, cat).font = Font(
            name="Calibri", size=9, color="595959")
        baris += 1



def tulis_sheet(ws) -> int:
    """Tulis seluruh isi ke satu sheet. Mengembalikan baris terakhir."""
    lebar = 15
    for i in range(1, lebar + 1):
        ws.column_dimensions[get_column_letter(i)].width = 16.5

    r = 2
    # ---- kop ----
    ws.cell(r, 2, "WHOLE TABLE — SISTEM INFORMASI SOUNDWAVE").font = Font(
        name="Calibri", size=18, bold=True, color="1A1A1A")
    r += 1
    ws.cell(r, 2,
            "5 tabel · 15 baris data fiktif · 6 relasi 1:N · "
            "konsisten dengan 5 data store pada DFD Level 0"
            ).font = Font(name="Calibri", size=10, color="595959")
    r += 2

    # ================= BAGIAN A — WHOLE TABLE =================
    ws.cell(r, 2, "A.  WHOLE TABLE").font = Font(
        name="Calibri", size=13, bold=True, color="1A1A1A")
    r += 1
    ws.cell(r, 2,
            "PK di kolom paling kiri · FK di kolom paling kanan · "
            "setiap tabel 3 baris data fiktif"
            ).font = Font(name="Calibri", size=9, italic=True, color="595959")
    r += 2

    for t in TABEL:
        n = len(t["kolom"])

        # --- header nama tabel ---
        ws.merge_cells(start_row=r, start_column=2, end_row=r, end_column=2 + n)
        sel = ws.cell(r, 2, t["nama"])
        sel.font = Font(name="Calibri", size=11, bold=True, color="1A1A1A")
        sel.fill = fill(ABU_HEAD)
        sel.alignment = Alignment(horizontal="center", vertical="center")
        for c in range(2, 3 + n):
            ws.cell(r, c).fill = fill(ABU_HEAD)
            ws.cell(r, c).border = Border(
                left=sisi(ABU_BORDER), right=sisi(ABU_BORDER),
                top=sisi(ABU_BORDER), bottom=sisi(ABU_BORDER))
        ws.row_dimensions[r].height = 20
        r += 1

        # --- penanda PK / FK (di atas nama kolom) ---
        for i, (_, _, kunci) in enumerate(t["kolom"], start=2):
            if kunci:
                c = ws.cell(r, i, "PK" if kunci == "PK" else "FK")
                c.font = Font(name="Consolas", size=9, bold=True,
                              color="7A5A0B" if kunci == "PK" else "8C2F2F")
                c.fill = fill("#FFF4D6" if kunci == "PK" else "#FBE4E4")
                c.alignment = Alignment(horizontal="center")
                c.border = Border(left=sisi(ABU_BORDER), right=sisi(ABU_BORDER),
                                  top=sisi(ABU_BORDER), bottom=sisi(ABU_BORDER))
        r += 1

        # --- nama kolom ---
        for i, (kol, _, _) in enumerate(t["kolom"], start=2):
            c = ws.cell(r, i, kol)
            c.font = Font(name="Calibri", size=9, bold=True, color="1A1A1A")
            c.fill = fill("#EFEFEF")
            c.alignment = Alignment(horizontal="center", vertical="center",
                                    wrap_text=True)
            c.border = Border(left=sisi(ABU_BORDER), right=sisi(ABU_BORDER),
                              top=sisi(ABU_BORDER), bottom=sisi(ABU_BORDER))
        ws.row_dimensions[r].height = 22
        r += 1

        # --- 3 baris data ---
        for bi, data in enumerate(t["baris"]):
            for i, nilai in enumerate(data, start=2):
                c = ws.cell(r, i, "-" if nilai is None else nilai)
                c.font = Font(name="Consolas", size=9, color="1A1A1A")
                c.alignment = Alignment(horizontal="left", vertical="center")
                c.border = Border(left=sisi(ABU_BORDER), right=sisi(ABU_BORDER),
                                  top=sisi(ABU_BORDER), bottom=sisi(ABU_BORDER))
                if bi % 2 == 1:
                    c.fill = fill(BARIS_SELANG)
                if isinstance(nilai, (int, float)) and not isinstance(nilai, bool):
                    c.number_format = "#,##0"
            r += 1
        r += 2

    return r


# ============================ GAMBAR ERD ============================
def font(nama: str, ukuran: int):
    for p in (rf"C:\Windows\Fonts\{nama}.ttf", rf"C:\Windows\Fonts\{nama}.TTF"):
        if Path(p).exists():
            return ImageFont.truetype(p, ukuran)
    return ImageFont.load_default()


F_HEAD = font("segoeuib", 26)
F_NAMA = font("consola", 21)
F_TIPE = font("consola", 18)
F_KECIL = font("consolab", 19)
F_TEKS = font("segoeui", 22)


# posisi tabel pada kanvas (x, y) — tata letak berjenjang, tanpa tumpang tindih
POSISI = {
    "users": (60, 100),
    "events": (680, 100),
    "tickets": (60, 480),
    "promo_codes": (680, 480),
    "orders": (370, 860),
}

LEBAR = 400
TINGGI_HEAD = 42
TINGGI_BARIS = 30


def tinggi_tabel(t: dict) -> int:
    return TINGGI_HEAD + TINGGI_BARIS * len(t["kolom"]) + 8


def gambar_erd(path: Path) -> None:
    W, H = 1180, 1450
    skala = 2
    img = Image.new("RGB", (W * skala, H * skala), PUTIH)
    d = ImageDraw.Draw(img)

    def s(v: float) -> int:
        return int(round(v * skala))

    # ---------- kotak tabel ----------
    kotak = {}
    for t in TABEL:
        x, y = POSISI[t["nama"]]
        w = LEBAR
        h = tinggi_tabel(t)
        kotak[t["nama"]] = (x, y, w, h)

        # kepala
        d.rectangle([s(x), s(y), s(x + w), s(y + TINGGI_HEAD)],
                    fill=ABU_HEAD, outline=ABU_BORDER, width=s(1.5))
        judul = t["nama"]
        tw = d.textlength(judul, font=F_HEAD)
        d.text((s(x + w / 2 - tw / (2 * skala)), s(y + 10)), judul,
               font=F_HEAD, fill=TINTA)

        # badan
        d.rectangle([s(x), s(y + TINGGI_HEAD), s(x + w), s(y + h)],
                    fill=PUTIH, outline=ABU_BORDER, width=s(1.5))

        for i, (kol, tipe, kunci) in enumerate(t["kolom"]):
            ry = y + TINGGI_HEAD + i * TINGGI_BARIS
            if i % 2 == 1:
                d.rectangle([s(x + 1), s(ry), s(x + w - 1),
                             s(ry + TINGGI_BARIS)], fill=BARIS_SELANG)
            # garis pemisah baris
            d.line([s(x + 1), s(ry), s(x + w - 1), s(ry)],
                   fill="#EDEDED", width=s(1))

            ikon_x = x + 16
            if kunci == "PK":
                _kunci(d, s(ikon_x), s(ry + TINGGI_BARIS / 2), s(1))
            elif kunci == "FK":
                _berlian(d, s(ikon_x), s(ry + TINGGI_BARIS / 2), s(7))

            d.text((s(x + 36), s(ry + 6)), kol, font=F_NAMA, fill=TINTA)
            tw = d.textlength(tipe, font=F_TIPE)
            d.text((s(x + w - 12) - tw, s(ry + 8)), tipe,
                   font=F_TIPE, fill=ABU_TEKS)

        # garis tepi ulang agar rapi
        d.rectangle([s(x), s(y), s(x + w), s(y + h)],
                    outline=ABU_BORDER, width=s(1.5))

    # ---------- garis relasi (crow's foot, putus-putus) ----------
    for induk, anak, fk, _label, jalur, arah in RELASI:
        ix, iy, iw, ih = kotak[induk]
        ax, ay, aw, ah = kotak[anak]

        # titik awal: tepi kotak induk terdekat dengan waypoint pertama
        wx, wy = jalur[0]
        px = min(max(wx, ix), ix + iw)
        py = min(max(wy, iy), iy + ih)

        # titik akhir: tepi kotak anak terdekat dengan waypoint terakhir
        vx, vy = jalur[-1]
        qx = min(max(vx, ax), ax + aw)
        qy = min(max(vy, ay), ay + ah)

        titik = [(px, py)] + list(jalur) + [(qx, qy)]
        for a, b in zip(titik, titik[1:]):
            _garis_putus(d, s(a[0]), s(a[1]), s(b[0]), s(b[1]))

        # crow's foot menghadap kotak anak
        if arah == "kiri":
            _crowfoot(d, s(qx), s(qy), s(11), hadap="kanan")
        elif arah == "kanan":
            _crowfoot(d, s(qx), s(qy), s(11), hadap="kiri")
        else:
            _crowfoot(d, s(qx), s(qy), s(11), hadap="atas")

        # garis tegak lurus di ujung induk (sisi "satu")
        _satu(d, s(px), s(py), s(9))

    # ---------- legenda ----------
    lx, ly = 60, 1385
    d.line([s(lx), s(ly - 18), s(W - 60), s(ly - 18)], fill=ABU_BORDER, width=s(1))
    _kunci(d, s(lx + 8), s(ly + 12), s(1))
    d.text((s(lx + 26), s(ly + 1)), "Primary Key", font=F_TEKS, fill=TINTA)
    _berlian(d, s(lx + 178), s(ly + 12), s(7))
    d.text((s(lx + 196), s(ly + 1)), "Foreign Key", font=F_TEKS, fill=TINTA)
    d.text((s(lx + 348), s(ly + 1)),
           "—| satu        >| banyak        garis putus-putus = relasi",
           font=F_TEKS, fill=ABU_TEKS)
    d.text((s(lx), s(ly + 34)),
           "Whole Table & ERD SoundWave · 5 entitas · 6 relasi 1:N · "
           "sinkron dengan DFD Level 0",
           font=font("consola", 17), fill=ABU_TEKS)

    img = img.resize((W, H), getattr(Image, "Resampling", Image).LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"  ERD PNG: {path}  ({W}x{H})")


def _kunci(d, cx, cy, r):
    """Ikon kunci kecil (PK)."""
    # kepala kunci: lingkaran
    d.ellipse([cx - 6 * r, cy - 6 * r, cx + 1 * r, cy + 1 * r],
              fill=EMAS, outline="#A87914", width=1 * r)
    # batang
    d.rectangle([cx - 1 * r, cy - 2 * r, cx + 9 * r, cy + 1 * r],
                fill=EMAS, outline="#A87914", width=1 * r)
    # gigi
    d.rectangle([cx + 5 * r, cy + 1 * r, cx + 7 * r, cy + 4 * r],
                fill=EMAS, outline="#A87914", width=1 * r)
    d.rectangle([cx + 8 * r, cy + 1 * r, cx + 10 * r, cy + 3 * r],
                fill=EMAS, outline="#A87914", width=1 * r)


def _berlian(d, cx, cy, r):
    """Ikon berlian merah (FK)."""
    d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)],
              fill=MERAH, outline="#9E3838")


def _garis_putus(d, x1, y1, x2, y2, panjang=9, jeda=6):
    """Garis putus-putus (gaya Workbench)."""
    total = math.hypot(x2 - x1, y2 - y1)
    if total == 0:
        return
    ux, uy = (x2 - x1) / total, (y2 - y1) / total
    t = 0.0
    while t < total:
        akhir = min(t + panjang, total)
        d.line([x1 + ux * t, y1 + uy * t, x1 + ux * akhir, y1 + uy * akhir],
               fill=TINTA, width=2)
        t += panjang + jeda


def _crowfoot(d, x, y, r, hadap="atas"):
    """Tiga cabang crow's foot di ujung 'banyak', menghadap kotak tujuan."""
    if hadap == "atas":
        d.line([x, y, x - r, y - r], fill=TINTA, width=2)
        d.line([x, y, x, y - r], fill=TINTA, width=2)
        d.line([x, y, x + r, y - r], fill=TINTA, width=2)
    elif hadap == "kiri":
        d.line([x, y, x + r, y - r], fill=TINTA, width=2)
        d.line([x, y, x + r, y], fill=TINTA, width=2)
        d.line([x, y, x + r, y + r], fill=TINTA, width=2)
    else:  # kanan
        d.line([x, y, x - r, y - r], fill=TINTA, width=2)
        d.line([x, y, x - r, y], fill=TINTA, width=2)
        d.line([x, y, x - r, y + r], fill=TINTA, width=2)


def _satu(d, x, y, r):
    """Penanda 'satu': garis tegak lurus pendek."""
    d.line([x - r, y, x + r, y], fill=TINTA, width=3)


# ============================ MAIN ============================
def main() -> None:
    wb = Workbook()
    ws = wb.active
    ws.title = "Whole Table"
    ws.sheet_view.showGridLines = False

    baris_akhir = tulis_sheet(ws)

    # daftar relasi di sisi kanan (pengganti gambar ERD — ERD ada di drawio)
    tulis_relasi(ws, 17, 2)

    wb.save(KELUAR_XLSX)
    print(f"  Excel  : {KELUAR_XLSX}")
    print(f"  {len(TABEL)} tabel, {sum(len(t['baris']) for t in TABEL)} baris data, "
          f"{len(RELASI)} relasi — satu sheet")


if __name__ == "__main__":
    main()
