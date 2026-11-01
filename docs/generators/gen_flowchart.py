"""
Flowchart SoundWave -> .drawio, tata letak VERTIKAL (portrait).

Dua halaman:
  1. Alur Pengguna  — dari buka aplikasi sampai scan QR di gate
  2. Alur Admin     — dari login sampai laporan

Gaya mengikuti ERD yang sudah disepakati:
  * Latar putih, teks hitam, tanpa gradien dan tanpa bayangan.
  * Kotak proses persegi, keputusan belah ketupat, mulai/selesai membulat.
  * Garis aliran solid; cabang diberi label "Ya" / "Tidak".

Jalankan: python docs/generators/gen_flowchart.py
"""

from __future__ import annotations

import html
from pathlib import Path

KELUARAN = Path(__file__).resolve().parents[2] / "FLOWCHART_SOUNDWAVE.drawio"

TINTA = "#1A1A1A"
ABU_MULAI = "#EDEDED"

# gaya per jenis simpul
G_PROSES = (
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#1A1A1A;"
    "strokeWidth=1.5;align=center;verticalAlign=middle;fontFamily=Helvetica;"
    "fontSize=11;fontColor=#1A1A1A;"
)
G_KEPUTUSAN = (
    "rhombus;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#1A1A1A;"
    "strokeWidth=1.5;align=center;verticalAlign=middle;fontFamily=Helvetica;"
    "fontSize=11;fontColor=#1A1A1A;"
)
G_TERMINAL = (
    "rounded=1;arcSize=50;whiteSpace=wrap;html=1;fillColor=#EDEDED;"
    "strokeColor=#1A1A1A;strokeWidth=1.5;align=center;verticalAlign=middle;"
    "fontFamily=Helvetica;fontSize=11;fontStyle=1;fontColor=#1A1A1A;"
)
G_GARIS = (
    "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;"
    "html=1;strokeColor=#1A1A1A;strokeWidth=1.5;endArrow=block;endFill=1;"
    "endSize=7;fontFamily=Helvetica;fontSize=9;fontColor=#595959;"
    "labelBackgroundColor=#FFFFFF;"
)

# ===================== HALAMAN 1 — ALUR PENGGUNA =====================
# (id, teks, jenis, x, y, w, h)
PENGGUNA = [
    ("start",    "MULAI", "terminal", 250, 40, 230, 40),
    ("splash",   "Buka aplikasi (splash screen)", "proses", 250, 120, 230, 46),
    ("dec_akun", "Sudah punya akun?", "keputusan", 250, 206, 230, 80),
    ("daftar",   "Daftar akun baru", "proses", 560, 206, 200, 46),
    ("login",    "Login", "proses", 250, 326, 230, 46),
    ("jelajah",  "Jelajah daftar konser", "proses", 250, 412, 230, 46),
    ("detail",   "Detail konser<br>audio · video · panggung 3D", "proses", 250, 498, 230, 56),
    ("tiket",    "Pilih tipe tiket", "proses", 250, 594, 230, 46),
    ("checkout", "Checkout: data pembeli &amp; voucher", "proses", 250, 680, 230, 46),
    ("konfirm",  "Konfirmasi pesanan", "proses", 250, 766, 230, 46),
    ("bayar",    "Bayar via Midtrans", "proses", 250, 852, 230, 46),
    ("dec_lunas", "Pembayaran lunas?", "keputusan", 250, 938, 230, 80),
    ("gagal",    "Reservasi berakhir,<br>kuota dilepas", "terminal", 40, 950, 175, 56),
    ("etiket",   "E-Tiket + QR Code terbit", "proses", 250, 1058, 230, 46),
    ("scan",     "Scan QR di gate venue", "proses", 250, 1144, 230, 46),
    ("end",      "SELESAI", "terminal", 250, 1230, 230, 40),
]

# (id, sumber, target, label, [waypoint], label_posisi)
GARIS_PENGGUNA = [
    ("e1",  "start",    "splash",   "", None),
    ("e2",  "splash",   "dec_akun", "", None),
    ("e3",  "dec_akun", "login",    "Ya", None),
    ("e4",  "dec_akun", "daftar",   "Tidak", None),
    ("e5",  "daftar",   "login",    "", [(660, 349), (480, 349)]),
    ("e6",  "login",    "jelajah",  "", None),
    ("e7",  "jelajah",  "detail",   "", None),
    ("e8",  "detail",   "tiket",    "", None),
    ("e9",  "tiket",    "checkout", "", None),
    ("e10", "checkout", "konfirm",  "", None),
    ("e11", "konfirm",  "bayar",    "", None),
    ("e12", "bayar",    "dec_lunas", "", None),
    ("e13", "dec_lunas", "etiket",  "Ya", None),
    ("e14", "dec_lunas", "gagal",   "Tidak", None),
    ("e15", "etiket",   "scan",     "", None),
    ("e16", "scan",     "end",      "", None),
]

# ===================== HALAMAN 2 — ALUR ADMIN =====================
ADMIN = [
    ("start",    "MULAI", "terminal", 250, 40, 230, 40),
    ("login",    "Login sebagai admin", "proses", 250, 120, 230, 46),
    ("dash",     "Dashboard admin", "proses", 250, 206, 230, 46),
    ("konser",   "Buat / edit konser<br>form: audio · trailer · 3D", "proses", 250, 292, 230, 60),
    ("tipe",     "Atur tipe tiket &amp; kuota", "proses", 250, 392, 230, 46),
    ("publish",  "Publish konser", "proses", 250, 478, 230, 46),
    ("promo",    "Kelola kode promo (opsional)", "proses", 250, 564, 230, 46),
    ("scan",     "Hari-H: scan QR di gate", "proses", 250, 650, 230, 46),
    ("dec_valid", "QR valid?", "keputusan", 250, 736, 230, 80),
    ("tolak",    "Tolak masuk", "terminal", 560, 751, 190, 50),
    ("terpakai", "Status tiket &rarr; TERPAKAI", "proses", 250, 856, 230, 46),
    ("laporan",  "Laporan penjualan &amp; kehadiran", "proses", 250, 942, 230, 46),
    ("end",      "SELESAI", "terminal", 250, 1028, 230, 40),
]

GARIS_ADMIN = [
    ("a1",  "start",    "login",     "", None),
    ("a2",  "login",    "dash",      "", None),
    ("a3",  "dash",     "konser",    "", None),
    ("a4",  "konser",   "tipe",      "", None),
    ("a5",  "tipe",     "publish",   "", None),
    ("a6",  "publish",  "promo",     "", None),
    ("a7",  "promo",    "scan",      "", None),
    ("a8",  "scan",     "dec_valid", "", None),
    ("a9",  "dec_valid", "terpakai", "Ya", None),
    ("a10", "dec_valid", "tolak",    "Tidak", None),
    ("a11", "terpakai", "laporan",   "", None),
    ("a12", "laporan",  "end",       "", None),
]


def esc(t: str) -> str:
    """Escape untuk atribut XML; teks HTML di dalamnya sudah ditulis sebagai entity."""
    return t.replace("&amp;", "\x00AMP\x00").replace("&", "&amp;") \
            .replace("\x00AMP\x00", "&amp;").replace('"', "&quot;") \
            .replace("<br>", "&lt;br&gt;")


def simpul(daftar) -> list[str]:
    out = []
    for nid, teks, jenis, x, y, w, h in daftar:
        gaya = {"proses": G_PROSES, "keputusan": G_KEPUTUSAN,
                "terminal": G_TERMINAL}[jenis]
        out.append(
            f'<mxCell id="{nid}" value="{esc(teks)}" style="{gaya}" '
            f'vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" '
            f'as="geometry" /></mxCell>'
        )
    return out


def garis(daftar) -> list[str]:
    out = []
    for eid, src, tgt, label, wp in daftar:
        titik = ""
        if wp:
            titik = '<Array as="points">' + "".join(
                f'<mxPoint x="{p[0]}" y="{p[1]}" />' for p in wp
            ) + "</Array>"
        out.append(
            f'<mxCell id="{eid}" value="{esc(label)}" style="{G_GARIS}" '
            f'edge="1" parent="1" source="{src}" target="{tgt}">'
            f'<mxGeometry relative="1" x="-0.15" as="geometry">{titik}'
            f'</mxGeometry></mxCell>'
        )
    return out


def halaman(nama: str, pid: str, tinggi: int, daftar_simpul, daftar_garis) -> str:
    isi = "".join(f"        {c}\n" for c in simpul(daftar_simpul))
    isi += "".join(f"        {c}\n" for c in garis(daftar_garis))
    return (
        f'  <diagram name="{nama}" id="{pid}">\n'
        f'    <mxGraphModel dx="900" dy="900" grid="1" gridSize="10" guides="1"'
        f' tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1"'
        f' pageWidth="850" pageHeight="{tinggi}" math="0" shadow="0">\n'
        '      <root>\n'
        '        <mxCell id="0" />\n'
        '        <mxCell id="1" parent="0" />\n'
        + isi +
        '      </root>\n'
        '    </mxGraphModel>\n'
        '  </diagram>\n'
    )


def main() -> None:
    xml = (
        '<mxfile host="app.diagrams.net" pages="2">\n'
        + halaman("Alur Pengguna", "flow-pengguna", 1320, PENGGUNA, GARIS_PENGGUNA)
        + halaman("Alur Admin", "flow-admin", 1120, ADMIN, GARIS_ADMIN)
        + "</mxfile>\n"
    )
    KELUARAN.write_text(xml, encoding="utf-8")
    print(f"tersimpan: {KELUARAN}")
    print(f"  halaman 1: Alur Pengguna ({len(PENGGUNA)} simpul, {len(GARIS_PENGGUNA)} garis)")
    print(f"  halaman 2: Alur Admin    ({len(ADMIN)} simpul, {len(GARIS_ADMIN)} garis)")


if __name__ == "__main__":
    main()
