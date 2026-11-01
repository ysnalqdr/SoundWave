"""
Generator WHOLE TABLE SoundWave -> berkas Excel (.xlsx).

Mengikuti gaya contoh DreamHome dosen:
  * PK ditulis di atas kolom paling KIRI
  * FK ditulis di atas kolom paling KANAN
  * Setiap tabel berisi 3 baris data fiktif

5 tabel, sama persis dengan 5 data store di DFD-0:
  users (D1), events (D2), orders (D3), tickets (D4), promo_codes (D5)

Jalankan: python docs/generators/gen_whole_table.py
"""

from __future__ import annotations

from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

KELUARAN = Path(__file__).resolve().parents[1] / "WHOLE_TABLE_SOUNDWAVE.xlsx"

# ---- gaya ----
HITAM = Side(style="thin", color="1E293B")
KOTAK = Border(left=HITAM, right=HITAM, top=HITAM, bottom=HITAM)
F_JUDUL = Font(name="Calibri", size=14, bold=True, color="0F172A")
F_TABEL = Font(name="Calibri", size=12, bold=True, color="FFFFFF")
F_KUNCI = Font(name="Consolas", size=10, bold=True, color="0F172A")
F_HEAD = Font(name="Calibri", size=10, bold=True, color="0F172A")
F_ISI = Font(name="Consolas", size=9, color="1E293B")
ISI_TABEL = PatternFill("solid", fgColor="1E293B")
ISI_HEAD = PatternFill("solid", fgColor="E2E8F0")
ISI_PK = PatternFill("solid", fgColor="FEF3C7")
ISI_FK = PatternFill("solid", fgColor="DBEAFE")

# ---- definisi tabel ----
# urutan kolom sengaja: PK paling kiri, FK paling kanan
TABEL = [
    dict(
        nama="users",
        catatan="D1 · Menyimpan akun pengguna dan admin",
        kolom=[
            ("id_user", "PK", "string"),
            ("nama", "", "string"),
            ("email", "", "string"),
            ("role", "", "string"),
            ("no_telepon", "", "string"),
            ("created_at", "", "timestamp"),
        ],
        baris=[
            ["U01", "Rizky Pratama", "rizky.p@mail.com", "user", "0812-3456-7890", "2026-01-15"],
            ["U02", "Salsabila Putri", "salsa.p@mail.com", "user", "0813-9876-5432", "2026-02-03"],
            ["U03", "Bagas Nugroho", "bagas.n@mail.com", "admin", "0857-1122-3344", "2026-01-05"],
        ],
    ),
    dict(
        nama="events",
        catatan="D2 · Menyimpan data konser yang dijual",
        kolom=[
            ("id_event", "PK", "string"),
            ("judul", "", "string"),
            ("lokasi", "", "string"),
            ("tanggal", "", "date"),
            ("penyelenggara", "", "string"),
            ("status", "", "string"),
        ],
        baris=[
            ["E01", "Senja Fest 2026", "Medan", "2026-11-16", "SoundWave Live", "publish"],
            ["E02", "Jakarta Night Beat", "Jakarta", "2026-12-05", "Nightbeat Ent", "publish"],
            ["E03", "Surabaya Rock Wave", "Surabaya", "2026-12-20", "Rockwave ID", "draft"],
        ],
    ),
    dict(
        nama="tickets",
        catatan="D4 · Katalog tipe tiket per konser (bukan tiket yang sudah dibeli)",
        kolom=[
            ("id_tiket", "PK", "string"),
            ("kategori", "", "string"),
            ("harga", "", "number"),
            ("stok", "", "number"),
            ("terjual", "", "number"),
            ("id_event", "FK", "string"),
        ],
        baris=[
            ["T01", "VVIP", 1500000, 100, 42, "E01"],
            ["T02", "Reguler", 500000, 500, 310, "E01"],
            ["T03", "VIP", 950000, 200, 88, "E02"],
        ],
    ),
    dict(
        nama="promo_codes",
        catatan="D5 · Kode promo dan batas pemakaiannya",
        kolom=[
            ("kode_promo", "PK", "string"),
            ("tipe", "", "string"),
            ("nilai", "", "number"),
            ("min_pembelian", "", "number"),
            ("max_pakai", "", "number"),
            ("sudah_dipakai", "", "number"),
            ("aktif", "", "boolean"),
            ("id_event", "FK", "string"),
        ],
        baris=[
            ["EARLYBIRD50", "nominal", 50000, 300000, 200, 37, True, "E01"],
            ["SENJA10", "persentase", 10, 500000, 100, 12, True, "E01"],
            ["NIGHTBEAT", "nominal", 100000, 800000, 150, 5, True, "E02"],
        ],
    ),
    dict(
        nama="orders",
        catatan="D3 · Transaksi pembelian tiket (4 FK ke tabel lain)",
        kolom=[
            ("id_order", "PK", "string"),
            ("jumlah_tiket", "", "number"),
            ("subtotal", "", "number"),
            ("diskon", "", "number"),
            ("pajak", "", "number"),
            ("biaya_layanan", "", "number"),
            ("total_bayar", "", "number"),
            ("status", "", "string"),
            ("tanggal_beli", "", "date"),
            ("id_user", "FK", "string"),
            ("id_event", "FK", "string"),
            ("id_tiket", "FK", "string"),
            ("kode_promo", "FK", "string"),
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


def tulis_judul(ws, baris: int) -> int:
    ws.cell(baris, 1, "WHOLE TABLE — SISTEM INFORMASI SOUNDWAVE").font = F_JUDUL
    baris += 1
    ws.cell(baris, 1,
            "PK = Primary Key (kolom paling kiri) · FK = Foreign Key (kolom paling kanan) · 3 data fiktif per tabel"
            ).font = Font(name="Calibri", size=9, italic=True, color="475569")
    return baris + 2


def tulis_tabel(ws, t: dict, baris: int) -> int:
    n = len(t["kolom"])

    # nama tabel
    ws.cell(baris, 1, f"Tabel: {t['nama']}").font = F_TABEL
    for c in range(1, n + 1):
        ws.cell(baris, c).fill = ISI_TABEL
    ws.merge_cells(start_row=baris, start_column=1, end_row=baris, end_column=n)
    ws.cell(baris, 1).alignment = Alignment(horizontal="left", vertical="center")
    baris += 1

    # catatan
    ws.cell(baris, 1, t["catatan"]).font = Font(name="Calibri", size=9, italic=True, color="475569")
    baris += 1

    # penanda PK / FK (di atas nama kolom, seperti contoh DreamHome)
    for i, (_, kunci, _) in enumerate(t["kolom"], start=1):
        if kunci:
            sel = ws.cell(baris, i, kunci)
            sel.font = F_KUNCI
            sel.alignment = Alignment(horizontal="center")
            sel.fill = ISI_PK if kunci == "PK" else ISI_FK
    baris += 1

    # nama kolom
    for i, (kol, kunci, _) in enumerate(t["kolom"], start=1):
        sel = ws.cell(baris, i, kol)
        sel.font = F_HEAD
        sel.fill = ISI_HEAD
        sel.border = KOTAK
        sel.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    baris += 1

    # 3 baris data
    for data in t["baris"]:
        for i, nilai in enumerate(data, start=1):
            sel = ws.cell(baris, i, "-" if nilai is None else nilai)
            sel.font = F_ISI
            sel.border = KOTAK
            sel.alignment = Alignment(horizontal="left", vertical="center")
            if isinstance(nilai, (int, float)) and not isinstance(nilai, bool):
                sel.number_format = "#,##0"
        baris += 1

    return baris + 2


def main() -> None:
    wb = Workbook()

    # ---------- Sheet 1: Whole Table ----------
    ws = wb.active
    ws.title = "Whole Table"
    baris = tulis_judul(ws, 1)

    for t in TABEL:
        baris = tulis_tabel(ws, t, baris)

    # lebar kolom
    for i in range(1, 14):
        ws.column_dimensions[get_column_letter(i)].width = 15

    # ---------- Sheet 2: Kamus Data ----------
    ws2 = wb.create_sheet("Kamus Data")
    ws2.cell(1, 1, "KAMUS DATA").font = F_JUDUL
    ws2.cell(2, 1, "Tipe data setiap kolom pada whole table").font = Font(
        name="Calibri", size=9, italic=True, color="475569")

    h = 4
    for judul, i in [("Tabel", 1), ("Kolom", 2), ("Tipe", 3), ("Kunci", 4)]:
        sel = ws2.cell(h, i, judul)
        sel.font = F_HEAD
        sel.fill = ISI_HEAD
        sel.border = KOTAK
    h += 1

    for t in TABEL:
        for kol, kunci, tipe in t["kolom"]:
            ws2.cell(h, 1, t["nama"]).font = F_ISI
            ws2.cell(h, 2, kol).font = F_ISI
            ws2.cell(h, 3, tipe).font = F_ISI
            ws2.cell(h, 4, kunci or "-").font = F_ISI
            for c in range(1, 5):
                ws2.cell(h, c).border = KOTAK
            h += 1

    for i, w in [(1, 18), (2, 20), (3, 14), (4, 10)]:
        ws2.column_dimensions[get_column_letter(i)].width = w

    # ---------- Sheet 3: Relasi ----------
    ws3 = wb.create_sheet("Relasi")
    ws3.cell(1, 1, "DAFTAR RELASI (dasar pembuatan ERD)").font = F_JUDUL
    ws3.cell(2, 1, "Semua relasi 1:N — tidak ada N:M pada 5 tabel ini").font = Font(
        name="Calibri", size=9, italic=True, color="475569")

    h = 4
    for judul, i in [("No", 1), ("Tabel Induk", 2), ("Tabel Anak", 3),
                     ("Foreign Key", 4), ("Kardinalitas", 5), ("Arti", 6)]:
        sel = ws3.cell(h, i, judul)
        sel.font = F_HEAD
        sel.fill = ISI_HEAD
        sel.border = KOTAK
    h += 1

    relasi = [
        ("users", "orders", "id_user", "1 : N", "Satu pengguna bisa membuat banyak pesanan"),
        ("events", "orders", "id_event", "1 : N", "Satu konser bisa memiliki banyak pesanan"),
        ("tickets", "orders", "id_tiket", "1 : N", "Satu tipe tiket dipakai di banyak pesanan"),
        ("promo_codes", "orders", "kode_promo", "1 : N", "Satu kode promo bisa dipakai banyak pesanan"),
        ("events", "tickets", "id_event", "1 : N", "Satu konser punya banyak tipe tiket"),
        ("events", "promo_codes", "id_event", "1 : N", "Satu konser punya banyak kode promo"),
    ]
    for i, (induk, anak, fk, kard, arti) in enumerate(relasi, start=1):
        for c, v in enumerate([i, induk, anak, fk, kard, arti], start=1):
            sel = ws3.cell(h, c, v)
            sel.font = F_ISI
            sel.border = KOTAK
            sel.alignment = Alignment(horizontal="left" if c == 6 else "center")
        h += 1

    for i, w in [(1, 6), (2, 16), (3, 16), (4, 16), (5, 14), (6, 50)]:
        ws3.column_dimensions[get_column_letter(i)].width = w

    wb.save(KELUARAN)
    print(f"tersimpan: {KELUARAN}")
    print(f"  {len(TABEL)} tabel, {sum(len(t['baris']) for t in TABEL)} baris data")
    print(f"  sheet: Whole Table, Kamus Data, Relasi")


if __name__ == "__main__":
    main()
