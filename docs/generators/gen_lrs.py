"""
Bangun LRS (Logical Record Structure) SoundWave.

CIRI LRS
  kotak berisi daftar field · primary key digaris bawah · foreign key (FK)
  relasi = panah (bukan belah ketupat) · tanpa ikon kunci · tanpa elips
  label "N : 1" = sisi penyimpan FK menuju pemilik PK

PENDEKATAN TATA LETAK
  Posisi kotak dan jalur panah TIDAK ditebak. Skrip ini:
    1. menempatkan 5 kotak pada kisi;
    2. untuk setiap panah, mencoba beberapa kombinasi titik keluar/masuk;
    3. menghitung jalur ortogonal (L atau Z) yang benar-benar dipakai
       draw.io, lalu menguji apakah jalur itu menembus kotak mana pun;
    4. memilih kombinasi pertama yang bersih; kalau tidak ada, GAGAL.

Keluaran: LRS_SOUNDWAVE.drawio
"""

from __future__ import annotations

from pathlib import Path
from xml.sax.saxutils import escape

KELUAR = Path(__file__).resolve().parents[2] / "LRS_SOUNDWAVE.drawio"

HITAM = "#1A1A1A"
ABU = "#595959"
GARIS = "#1A1A1A"
KEPALA = "#EDEDED"
FONT = "Helvetica"

W_BOX = 300
H_KEPALA = 34
H_BARIS = 24
PAD_BAWAH = 10

PAGE_W, PAGE_H = 1900, 1500

ESC = {'"': "&quot;"}


def esc(t: str) -> str:
    return escape(t, ESC)


# nama: (x, y, [(field, "pk"/"fk"/None)])
TABEL = {
    "users": (150, 160, [
        ("id_user", "pk"), ("nama", None), ("email", None),
        ("role", None), ("no_telepon", None), ("created_at", None),
    ]),
    "events": (1400, 160, [
        ("id_event", "pk"), ("judul", None), ("lokasi", None),
        ("tanggal", None), ("penyelenggara", None), ("status", None),
    ]),
    "tickets": (150, 560, [
        ("id_tiket", "pk"), ("kategori", None), ("harga", None),
        ("stok", None), ("terjual", None), ("id_event", "fk"),
    ]),
    "promo": (1400, 560, [
        ("id_promo", "pk"), ("tipe", None), ("nilai", None),
        ("min_pembelian", None), ("max_pakai", None),
        ("sudah_dipakai", None), ("aktif", None), ("id_event", "fk"),
    ]),
    "orders": (775, 980, [
        ("id_order", "pk"), ("jumlah_tiket", None), ("subtotal", None),
        ("diskon", None), ("pajak", None), ("biaya_layanan", None),
        ("total_bayar", None), ("status", None), ("tanggal_beli", None),
        ("id_user", "fk"), ("id_event", "fk"), ("id_tiket", "fk"),
        ("id_promo", "fk"),
    ]),
}


def tinggi(n: int) -> int:
    return H_KEPALA + H_BARIS * n + PAD_BAWAH


def kotak(nama: str):
    x, y, f = TABEL[nama]
    return (x, y, x + W_BOX, y + tinggi(len(f)))


def titik(nama: str, fx: float, fy: float):
    b = kotak(nama)
    return (b[0] + (b[2] - b[0]) * fx, b[1] + (b[3] - b[1]) * fy)


def jalur_ortogonal(p1, p2, keluar_horizontal: bool):
    """Perkiraan jalur yang dipakai draw.io untuk edgeStyle=orthogonalEdgeStyle."""
    (x1, y1), (x2, y2) = p1, p2
    if keluar_horizontal:
        mx = (x1 + x2) / 2
        return [(x1, y1), (mx, y1), (mx, y2), (x2, y2)]
    my = (y1 + y2) / 2
    return [(x1, y1), (x1, my), (x2, my), (x2, y2)]


def segmen_tembus(p1, p2, b, margin=4.0):
    n = 70
    for i in range(1, n):
        t = i / n
        px = p1[0] + (p2[0] - p1[0]) * t
        py = p1[1] + (p2[1] - p1[1]) * t
        if b[0] + margin < px < b[2] - margin and b[1] + margin < py < b[3] - margin:
            return True
    return False


def dekat_tepi(a, b2, batas=10.0):
    """True kalau segmen berjalan sejajar & sangat dekat tepi kotak lain."""
    for nama in TABEL:
        k = kotak(nama)
        # segmen horizontal
        if abs(a[1] - b2[1]) < 0.5:
            y = a[1]
            x1, x2 = sorted((a[0], b2[0]))
            if (abs(y - k[1]) < batas or abs(y - k[3]) < batas) and x2 > k[0] and x1 < k[2]:
                return True
        # segmen vertikal
        if abs(a[0] - b2[0]) < 0.5:
            x = a[0]
            y1, y2 = sorted((a[1], b2[1]))
            if (abs(x - k[0]) < batas or abs(x - k[2]) < batas) and y2 > k[1] and y1 < k[3]:
                return True
    return False


def skor_jalur(nama_src, nama_tgt, p1, p2, horizontal):
    """Skor lebih kecil = lebih baik. None kalau jalur tidak layak."""
    titik_jalur = jalur_ortogonal(p1, p2, horizontal)
    total = 0.0
    for i in range(len(titik_jalur) - 1):
        a, b2 = titik_jalur[i], titik_jalur[i + 1]
        for nama in TABEL:
            if nama in (nama_src, nama_tgt):
                continue
            if segmen_tembus(a, b2, kotak(nama)):
                return None
            if dekat_tepi(a, b2):
                total += 3000          # hindari garis menempel tepi kotak
        total += abs(a[0] - b2[0]) + abs(a[1] - b2[1])
    return total


def pilih_jalur():
    hasil = {}
    masalah = []
    for aid, src, tgt in HUBUNGAN:
        terbaik = None
        for fsx, fsy in KANDIDAT:
            for ftx, fty in KANDIDAT:
                p1, p2 = titik(src, fsx, fsy), titik(tgt, ftx, fty)
                for horizontal in (True, False):
                    s = skor_jalur(src, tgt, p1, p2, horizontal)
                    if s is None:
                        continue
                    if terbaik is None or s < terbaik[0]:
                        terbaik = (s, fsx, fsy, ftx, fty)
        if terbaik:
            hasil[aid] = terbaik[1:]
        else:
            masalah.append(aid)
    return hasil, masalah


# kandidat titik keluar/masuk (fx, fy) yang wajar untuk kotak
KANDIDAT = [
    (0.50, 0.00), (0.50, 1.00), (0.00, 0.50), (1.00, 0.50),
    (0.25, 0.00), (0.75, 0.00), (0.25, 1.00), (0.75, 1.00),
    (0.00, 0.25), (0.00, 0.75), (1.00, 0.25), (1.00, 0.75),
]

# (id, sumber_fk, tujuan_pk)
HUBUNGAN = [
    ("a_users",   "orders",  "users"),
    ("a_events",  "orders",  "events"),
    ("a_tickets", "orders",  "tickets"),
    ("a_promo",   "orders",  "promo"),
    ("a_t_ev",    "tickets", "events"),
    ("a_p_ev",    "promo",   "events"),
]


def isi_kotak(nama: str, field):
    baris = []
    for nama_field, jenis in field:
        if jenis == "pk":
            isi = f"<b><u>{esc(nama_field)}</u></b>"
        elif jenis == "fk":
            isi = f'{esc(nama_field)}<span style="color:{ABU};"> (FK)</span>'
        else:
            isi = esc(nama_field)
        baris.append(
            f'<div style="line-height:24px;text-align:left;padding-left:10px;">{isi}</div>'
        )
    return (
        f'<div style="line-height:34px;font-weight:bold;font-size:13px;'
        f'text-align:center;background:{KEPALA};border-bottom:1px solid {GARIS};">'
        f"{esc(nama)}</div>" + "".join(baris)
    )


def bangun(jalur) -> str:
    sel: list[str] = []

    sel.append(
        f'<mxCell id="judul" value="{esc("LRS SOUNDWAVE — LOGICAL RECORD STRUCTURE")}" '
        f'parent="1" vertex="1" style="text;html=1;align=center;fontFamily={FONT};'
        f'fontSize=16;fontStyle=1;fontColor={HITAM};">'
        f'<mxGeometry x="550" y="50" width="800" height="28" as="geometry"/></mxCell>'
    )
    sel.append(
        f'<mxCell id="subjudul" value="{esc("Garis bawah = Primary Key · (FK) = Foreign Key · Panah N : 1 menuju pemilik Primary Key")}" '
        f'parent="1" vertex="1" style="text;html=1;align=center;fontFamily={FONT};'
        f'fontSize=10;fontColor={ABU};">'
        f'<mxGeometry x="450" y="80" width="1000" height="20" as="geometry"/></mxCell>'
    )

    for nama, (x, y, field) in TABEL.items():
        sel.append(
            f'<mxCell id="tbl_{nama}" value="{esc(isi_kotak(nama, field))}" parent="1" vertex="1" '
            f'style="rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor={GARIS};'
            f'strokeWidth=1.5;align=left;verticalAlign=top;fontFamily={FONT};fontSize=11;'
            f'fontColor={HITAM};spacing=0;">'
            f'<mxGeometry x="{x}" y="{y}" width="{W_BOX}" height="{tinggi(len(field))}" as="geometry"/>'
            f'</mxCell>'
        )

    for aid, src, tgt in HUBUNGAN:
        fsx, fsy, ftx, fty = jalur[aid]
        gaya = (
            "edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;"
            "html=1;endArrow=block;endFill=1;endSize=7;"
            f"strokeColor={GARIS};strokeWidth=1.4;fontFamily={FONT};fontSize=11;"
            f"fontStyle=1;fontColor={HITAM};labelBackgroundColor=#FFFFFF;"
            f"exitX={fsx};exitY={fsy};exitDx=0;exitDy=0;"
            f"entryX={ftx};entryY={fty};entryDx=0;entryDy=0;"
        )
        sel.append(
            f'<mxCell id="{aid}" edge="1" parent="1" source="tbl_{src}" target="tbl_{tgt}" '
            f'value="N : 1" style="{gaya}">'
            f'<mxGeometry relative="1" as="geometry">'
            f'<mxPoint x="0" y="-4" as="offset"/></mxGeometry></mxCell>'
        )

    sel.append(
        f'<mxCell id="legenda" value="{esc("<b>Keterangan</b><br>N : 1 — banyak baris di tabel sumber merujuk satu baris di tabel tujuan<br>Panah berangkat dari tabel yang menyimpan foreign key<br>LRS tidak memakai belah ketupat maupun ikon kunci")}" '
        f'parent="1" vertex="1" style="text;html=1;align=left;verticalAlign=top;'
        f'fontFamily={FONT};fontSize=10;fontColor={ABU};spacingLeft=4;">'
        f'<mxGeometry x="150" y="1340" width="620" height="90" as="geometry"/></mxCell>'
    )

    return (
        '<mxfile host="app.diagrams.net" pages="1">\n'
        '  <diagram name="LRS" id="lrs_soundwave">\n'
        f'    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" '
        f'tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" '
        f'pageWidth="{PAGE_W}" pageHeight="{PAGE_H}" math="0" shadow="0">\n'
        '      <root>\n'
        '        <mxCell id="0"/>\n'
        '        <mxCell id="1" parent="0"/>\n'
        "        " + "\n        ".join(sel) + "\n"
        '      </root>\n'
        '    </mxGraphModel>\n'
        '  </diagram>\n'
        '</mxfile>\n'
    )


if __name__ == "__main__":
    jalur, masalah = pilih_jalur()
    print(f"panah dengan jalur bersih: {len(jalur)}/{len(HUBUNGAN)}")
    if masalah:
        print("GAGAL — tidak ada jalur bersih untuk:", ", ".join(masalah))
        raise SystemExit(1)
    KELUAR.write_text(bangun(jalur), encoding="utf-8")
    print(f"tersimpan: {KELUAR}  ({KELUAR.stat().st_size} byte)")
    for aid, src, tgt in HUBUNGAN:
        print(f"  {aid:10} {src:8} -> {tgt:8}  {jalur[aid]}")
