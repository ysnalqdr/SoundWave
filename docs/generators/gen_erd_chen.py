"""
Bangun ERD Konseptual notasi Chen untuk SoundWave.

PENDEKATAN TATA LETAK
  Posisi elips TIDAK ditebak. Skrip ini:
    1. menaruh entitas & belah ketupat pada kisi tetap;
    2. mengumpulkan semua kotak terlarang (entitas, relasi, elips lain);
    3. untuk setiap atribut, mencoba kandidat posisi pada beberapa radius dan
       sudut, lalu memilih yang PALING DEKAT ke entitasnya sambil tidak
       bertabrakan dengan apa pun dan tidak memotong garis relasi;
    4. memverifikasi hasilnya sendiri (tumpang tindih = 0, garis tembus = 0).

  Kalau ada atribut yang tidak dapat posisi bebas, skrip GAGAL dengan pesan
  jelas, bukan diam-diam menaruh elips bertumpuk.

NOTASI CHEN
  kotak = entitas · elips = atribut · belah ketupat = relasi
  garis bawah = primary key · elips putus = atribut turunan
  foreign key tidak digambar (relasi sudah mewakilinya)

Keluaran: ERD_CHEN_SOUNDWAVE.drawio
"""

from __future__ import annotations

import math
from pathlib import Path
from xml.sax.saxutils import escape

KELUAR = Path(__file__).resolve().parents[2] / "ERD_CHEN_SOUNDWAVE.drawio"

HITAM = "#1A1A1A"
ABU = "#595959"
GARIS = "#1A1A1A"
FILL_ENT = "#FFFFFF"
FILL_REL = "#F2F2F2"
FILL_ATR = "#FFFFFF"
FONT = "Helvetica"

W_ENT, H_ENT = 150, 52
W_RH, H_RH = 116, 60
W_ATR, H_ATR = 108, 34

PAGE_W, PAGE_H = 2000, 1400

ESC = {'"': "&quot;"}


def esc(t: str) -> str:
    return escape(t, ESC)


# ---------------------------------------------------------------- data
# nama: (cx, cy, [atribut], pk)
ENTITAS = {
    "users":   (560, 220, ["id_user", "nama", "email", "role", "no_telepon", "created_at"], "id_user"),
    "events":  (1440, 220, ["id_event", "judul", "lokasi", "tanggal", "penyelenggara", "status"], "id_event"),
    "tickets": (360, 760, ["id_tiket", "kategori", "harga", "stok", "terjual"], "id_tiket"),
    "promo":   (1640, 760, ["id_promo", "tipe", "nilai", "min_pembelian", "max_pakai", "sudah_dipakai", "aktif"], "id_promo"),
    "orders":  (1000, 1120, ["id_order", "jumlah_tiket", "subtotal", "diskon", "pajak", "biaya_layanan", "total_bayar", "status", "tanggal_beli"], "id_order"),
}

TURUNAN = {"terjual", "sudah_dipakai", "total_bayar"}

# (id, label, kiri, kanan, x, y)
RELASI = [
    ("membuat",     "membuat",     "users",   "orders",  740, 640),
    ("memiliki",    "memiliki",    "events",  "orders", 1260, 640),
    ("punya_tipe",  "punya tipe",  "events",  "tickets", 800, 430),
    ("punya_promo", "punya promo", "events",  "promo",  1560, 430),
    ("dipakai",     "dipakai",     "tickets", "orders",  620, 960),
    ("dipakai2",    "dipakai",     "promo",   "orders", 1380, 960),
]


# ---------------------------------------------------------------- geometri
def kotak(cx, cy, w, h):
    return (cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2)


def bertabrakan(a, b, jarak=6.0):
    return not (
        a[2] + jarak <= b[0] or b[2] + jarak <= a[0]
        or a[3] + jarak <= b[1] or b[3] + jarak <= a[1]
    )


def garis_lewat(p1, p2, b, margin=4.0):
    n = 70
    for i in range(1, n):
        t = i / n
        px = p1[0] + (p2[0] - p1[0]) * t
        py = p1[1] + (p2[1] - p1[1]) * t
        if b[0] + margin < px < b[2] - margin and b[1] + margin < py < b[3] - margin:
            return True
    return False


def tata_letak():
    """Kembalikan (posisi_elips, daftar_masalah)."""
    terlarang = []          # kotak yang tidak boleh ditimpa elips
    garis = []              # (p1, p2) segmen relasi

    for nama, (cx, cy, _a, _p) in ENTITAS.items():
        terlarang.append(kotak(cx, cy, W_ENT, H_ENT))

    for rid, _l, kiri, kanan, x, y in RELASI:
        terlarang.append(kotak(x, y, W_RH, H_RH))
        kcx, kcy = ENTITAS[kiri][0], ENTITAS[kiri][1]
        ncx, ncy = ENTITAS[kanan][0], ENTITAS[kanan][1]
        garis.append(((kcx, kcy), (x, y)))
        garis.append(((x, y), (ncx, ncy)))

    hasil = {}
    masalah = []

    # sudut kandidat: kiri/kanan dulu, lalu diagonal
    sudut = [180, 0, 150, 210, 30, 330, 120, 240, 60, 300, 90, 270]
    radius = [140, 165, 190, 215, 240, 265, 290, 320, 350, 380, 410]

    for nama, (cx, cy, atribut, _pk) in ENTITAS.items():
        for at in atribut:
            ketemu = None
            for r in radius:
                if ketemu:
                    break
                for deg in sudut:
                    rad = math.radians(deg)
                    ex = cx + math.cos(rad) * r
                    ey = cy + math.sin(rad) * r
                    b = kotak(ex, ey, W_ATR, H_ATR)

                    if b[0] < 10 or b[1] < 100 or b[2] > PAGE_W - 10 or b[3] > PAGE_H - 10:
                        continue
                    if any(bertabrakan(b, t) for t in terlarang):
                        continue
                    if any(garis_lewat(p1, p2, b) for p1, p2 in garis):
                        continue
                    # garis penghubung entitas -> elips juga tidak boleh
                    # menembus elips/kotak lain yang sudah ada
                    ent_box = kotak(cx, cy, W_ENT, H_ENT)
                    tertimpa = False
                    for t in terlarang:
                        if t == ent_box:
                            continue
                        if garis_lewat((cx, cy), (ex, ey), t):
                            tertimpa = True
                            break
                    if tertimpa:
                        continue
                    ketemu = (ex, ey, b)
                    break
            if not ketemu:
                masalah.append(f"{nama}.{at}: tidak dapat posisi bebas")
                continue
            ex, ey, b = ketemu
            terlarang.append(b)
            hasil[f"{nama}.{at}"] = (ex, ey)
    return hasil, masalah


# ---------------------------------------------------------------- XML
def mx(cell_id, value, style, x, y, w, h):
    return (
        f'<mxCell id="{cell_id}" value="{esc(value)}" parent="1" vertex="1" style="{style}">'
        f'<mxGeometry x="{x:.1f}" y="{y:.1f}" width="{w}" height="{h}" as="geometry"/></mxCell>'
    )


def edge(cell_id, src, tgt, label="", tebal=1.5, ox=0, oy=0):
    lab = f' value="{esc(label)}"' if label else ""
    geo = '<mxGeometry relative="1" as="geometry">'
    if ox or oy:
        geo += f'<mxPoint x="{ox}" y="{oy}" as="offset"/>'
    geo += "</mxGeometry>"
    return (
        f'<mxCell id="{cell_id}" edge="1" parent="1" source="{src}" target="{tgt}"{lab} '
        f'style="endArrow=none;html=1;strokeColor={GARIS};strokeWidth={tebal};'
        f'fontFamily={FONT};fontSize=12;fontStyle=1;fontColor={HITAM};'
        f'labelBackgroundColor=#FFFFFF;">{geo}</mxCell>'
    )


def bangun(posisi: dict[str, tuple[float, float]]) -> str:
    sel: list[str] = []

    sel.append(mx(
        "judul", "ERD KONSEPTUAL SOUNDWAVE — NOTASI CHEN",
        f"text;html=1;align=center;fontFamily={FONT};fontSize=16;fontStyle=1;fontColor={HITAM};",
        600, 40, 800, 28,
    ))
    sel.append(mx(
        "subjudul",
        "Kotak = entitas · Elips = atribut · Belah ketupat = relasi · "
        "Garis bawah = Primary Key · Elips putus = atribut turunan",
        f"text;html=1;align=center;fontFamily={FONT};fontSize=10;fontColor={ABU};",
        500, 70, 1000, 20,
    ))

    for nama, (cx, cy, _a, _p) in ENTITAS.items():
        sel.append(mx(
            f"ent_{nama}", nama,
            f"rounded=0;whiteSpace=wrap;html=1;fillColor={FILL_ENT};strokeColor={GARIS};"
            f"strokeWidth=2;fontFamily={FONT};fontSize=13;fontStyle=1;fontColor={HITAM};",
            cx - W_ENT / 2, cy - H_ENT / 2, W_ENT, H_ENT,
        ))

    for rid, label, kiri, kanan, x, y in RELASI:
        sel.append(mx(
            f"rel_{rid}", label,
            f"rhombus;whiteSpace=wrap;html=1;fillColor={FILL_REL};strokeColor={GARIS};"
            f"strokeWidth=1.5;fontFamily={FONT};fontSize=11;fontColor={HITAM};",
            x - W_RH / 2, y - H_RH / 2, W_RH, H_RH,
        ))
        sel.append(edge(f"ln_{rid}_1", f"ent_{kiri}", f"rel_{rid}", "1", ox=-8, oy=-8))
        sel.append(edge(f"ln_{rid}_n", f"rel_{rid}", f"ent_{kanan}", "N", ox=8, oy=-8))

    for nama, (cx, cy, atribut, pk) in ENTITAS.items():
        for at in atribut:
            kunci = f"{nama}.{at}"
            if kunci not in posisi:
                continue
            ex, ey = posisi[kunci]
            aid = f"at_{nama}_{at}"
            sel.append(edge(f"{aid}_ln", f"ent_{nama}", aid, tebal=1))
            label = f"<u>{at}</u>" if at == pk else at
            gaya = (
                "ellipse;whiteSpace=wrap;html=1;"
                f"fillColor={FILL_ATR};strokeColor={GARIS};strokeWidth=1;"
                f"fontFamily={FONT};fontSize=11;fontColor={HITAM};"
            )
            if at in TURUNAN:
                gaya += "dashed=1;dashPattern=4 3;"
            sel.append(
                f'<mxCell id="{aid}" value="{esc(label)}" parent="1" vertex="1" style="{gaya}">'
                f'<mxGeometry x="{ex - W_ATR / 2:.1f}" y="{ey - H_ATR / 2:.1f}" '
                f'width="{W_ATR}" height="{H_ATR}" as="geometry"/></mxCell>'
            )

    sel.append(mx(
        "legenda",
        "<b>Keterangan</b><br>"
        "1 : N — satu baris entitas kiri memiliki banyak baris entitas kanan<br>"
        "Atribut turunan dihitung sistem, tidak diisi manual<br>"
        "Foreign key tidak digambar: relasi sudah mewakilinya",
        f"text;html=1;align=left;verticalAlign=top;fontFamily={FONT};fontSize=10;"
        f"fontColor={ABU};spacingLeft=4;",
        60, PAGE_H - 130, 620, 90,
    ))

    return (
        '<mxfile host="app.diagrams.net" pages="1">\n'
        '  <diagram name="ERD Chen" id="erd_chen">\n'
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
    posisi, masalah = tata_letak()
    total = sum(len(v[2]) for v in ENTITAS.values())
    print(f"atribut ditempatkan: {len(posisi)}/{total}")
    if masalah:
        print("GAGAL:")
        for m in masalah:
            print("  -", m)
        raise SystemExit(1)
    KELUAR.write_text(bangun(posisi), encoding="utf-8")
    print(f"tersimpan: {KELUAR}  ({KELUAR.stat().st_size} byte)")
