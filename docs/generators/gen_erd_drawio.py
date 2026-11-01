"""
Generator ERD SoundWave -> berkas .drawio (bisa diedit di draw.io).

5 entitas, sama persis dengan 5 data store di DFD-0:
  users (D1), events (D2), orders (D3), tickets (D4), promo_codes (D5)

6 relasi 1:N:
  users       -> orders
  events      -> orders
  events      -> tickets
  events      -> promo_codes
  tickets     -> orders
  promo_codes -> orders

Kardinalitas ditulis di kedua ujung panah (1 di induk, N di anak),
mengikuti notasi Chen yang umum dipakai di tugas akademik.

Jalankan: python docs/generators/gen_erd_drawio.py
"""

from __future__ import annotations

import html
from pathlib import Path

KELUARAN = Path(__file__).resolve().parents[2] / "ERD_SOUNDWAVE.drawio"


def esc(teks: str) -> str:
    """Escape HTML untuk dipakai sebagai nilai atribut XML drawio.

    drawio menyimpan HTML di dalam atribut `value`, jadi `<`, `>`, `&`, dan `"`
    harus di-escape supaya XML-nya sah. Setelah XML diurai, drawio membaca
    kembali sebagai HTML (karena style memakai html=1).
    """
    return html.escape(teks, quote=True)

# ---- gaya ----
GARIS = "strokeColor=#1E293B;strokeWidth=1.5;fontFamily=Courier New;fontSize=10;"
KEPALA = (
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#1E293B;fontColor=#FFFFFF;"
    "strokeColor=#1E293B;strokeWidth=2;align=center;verticalAlign=middle;"
    "fontFamily=Helvetica;fontSize=13;fontStyle=1;"
)
BADAN = (
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;fontColor=#1E293B;"
    "strokeColor=#1E293B;strokeWidth=2;align=left;verticalAlign=top;"
    "fontFamily=Courier New;fontSize=10;spacingLeft=6;spacingTop=4;"
)
JUDUL = (
    "text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;"
    "fontFamily=Helvetica;fontSize=16;fontStyle=1;fontColor=#0F172A;"
)
CATATAN = (
    "text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;"
    "fontFamily=Helvetica;fontSize=10;fontStyle=2;fontColor=#475569;"
)
KARDINAL = (
    "text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;"
    "fontFamily=Helvetica;fontSize=14;fontStyle=1;fontColor=#0F172A;"
)

# ---- entitas: (id, nama, x, y, w, h, [(kolom, kunci)]) ----
# Jarak antar kotak minimal 40 px supaya garis tidak menempel di tepi.
ENTITAS = [
    ("events", "events", 430, 40, 190, 175, [
        ("id_event", "PK"), ("judul", ""), ("lokasi", ""),
        ("tanggal", ""), ("penyelenggara", ""), ("status", ""),
    ]),
    ("tickets", "tickets", 190, 285, 190, 175, [
        ("id_tiket", "PK"), ("kategori", ""), ("harga", ""),
        ("stok", ""), ("terjual", ""), ("id_event", "FK"),
    ]),
    ("promos", "promo_codes", 670, 285, 195, 225, [
        ("kode_promo", "PK"), ("tipe", ""), ("nilai", ""),
        ("min_pembelian", ""), ("max_pakai", ""), ("sudah_dipakai", ""),
        ("aktif", ""), ("id_event", "FK"),
    ]),
    ("users", "users", 100, 620, 185, 175, [
        ("id_user", "PK"), ("nama", ""), ("email", ""),
        ("role", ""), ("no_telepon", ""), ("created_at", ""),
    ]),
    ("orders", "orders", 430, 565, 215, 345, [
        ("id_order", "PK"), ("jumlah_tiket", ""), ("subtotal", ""),
        ("diskon", ""), ("pajak", ""), ("biaya_layanan", ""),
        ("total_bayar", ""), ("status", ""), ("tanggal_beli", ""),
        ("id_user", "FK"), ("id_event", "FK"), ("id_tiket", "FK"),
        ("kode_promo", "FK"),
    ]),
]

# (id, sumber, target, label_relasi, exitX, exitY, entryX, entryY)
# Setiap titik masuk ke orders berbeda supaya garis tidak bertumpuk.
RELASI = [
    ("r1", "users", "orders", "membuat", 1.0, 0.40, 0.0, 0.70),
    ("r2", "events", "orders", "memiliki", 0.50, 1.0, 0.5, 0.0),
    ("r3", "events", "tickets", "punya tipe", 0.25, 1.0, 0.5, 0.0),
    ("r4", "events", "promos", "punya promo", 0.75, 1.0, 0.5, 0.0),
    ("r5", "tickets", "orders", "dipakai", 1.0, 0.70, 0.0, 0.25),
    ("r6", "promos", "orders", "dipakai", 0.0, 0.70, 1.0, 0.25),
]


def isi_badan(kolom: list[tuple[str, str]]) -> str:
    """HTML daftar kolom. PK/FK ditebalkan seperti di whole table."""
    bagian = []
    for nama, kunci in kolom:
        if kunci:
            bagian.append(
                f'<div style="line-height:17px;"><b>{nama}</b>'
                f' &nbsp;<span style="color:#B45309;font-size:9px;">{kunci}</span></div>'
            )
        else:
            bagian.append(
                f'<div style="line-height:17px;">{nama}</div>'
            )
    return "".join(bagian)


def main() -> None:
    cells: list[str] = []

    # ---------- judul ----------
    cells.append(
        '<mxCell id="judul" value="ENTITY RELATIONSHIP DIAGRAM — SISTEM INFORMASI SOUNDWAVE"'
        f' style="{JUDUL}" vertex="1" parent="1">'
        '<mxGeometry x="70" y="10" width="700" height="26" as="geometry" /></mxCell>'
    )
    cells.append(
        '<mxCell id="sub" value="5 entitas · 6 relasi 1:N · konsisten dengan 5 data store DFD Level 0"'
        f' style="{CATATAN}" vertex="1" parent="1">'
        '<mxGeometry x="70" y="36" width="700" height="18" as="geometry" /></mxCell>'
    )

    # ---------- entitas ----------
    for eid, nama, x, y, w, h, kolom in ENTITAS:
        # kepala tabel
        cells.append(
            f'<mxCell id="{eid}_head" value="{esc(nama)}" style="{KEPALA}"'
            f' vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{w}" height="30" as="geometry" /></mxCell>'
        )
        # badan tabel
        cells.append(
            f'<mxCell id="{eid}" value="{esc(isi_badan(kolom))}" style="{BADAN}"'
            f' vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y + 30}" width="{w}" height="{h - 30}" as="geometry" /></mxCell>'
        )

    # ---------- relasi ----------
    for rid, src, tgt, label, ex, ey, nx, ny in RELASI:
        style = (
            f"edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;"
            f"jettySize=auto;html=1;{GARIS}"
            f"exitX={ex};exitY={ey};exitDx=0;exitDy=0;"
            f"entryX={nx};entryY={ny};entryDx=0;entryDy=0;"
            f"endArrow=block;endFill=1;"
        )
        cells.append(
            f'<mxCell id="{rid}" value="{esc(label)}" style="{style}"'
            f' edge="1" parent="1" source="{src}" target="{tgt}">'
            f'<mxGeometry relative="1" as="geometry" /></mxCell>'
        )
        # kardinalitas "1" di ujung induk
        cells.append(
            f'<mxCell id="{rid}_1" value="1" style="{KARDINAL}" vertex="1"'
            f' parent="{rid}">'
            f'<mxGeometry x="-0.86" relative="1" as="geometry">'
            f'<mxPoint as="offset" /></mxGeometry></mxCell>'
        )
        # kardinalitas "N" di ujung anak
        cells.append(
            f'<mxCell id="{rid}_n" value="N" style="{KARDINAL}" vertex="1"'
            f' parent="{rid}">'
            f'<mxGeometry x="0.86" relative="1" as="geometry">'
            f'<mxPoint as="offset" /></mxGeometry></mxCell>'
        )

    # ---------- legenda ----------
    lx, ly = 70, 950
    cells.append(
        '<mxCell id="leg_box" value="" style="rounded=0;whiteSpace=wrap;html=1;'
        'fillColor=#F8FAFC;strokeColor=#CBD5E1;strokeWidth=1;" vertex="1" parent="1">'
        f'<mxGeometry x="{lx}" y="{ly}" width="780" height="70" as="geometry" /></mxCell>'
    )
    cells.append(
        '<mxCell id="leg_t" value="KETERANGAN" style="text;html=1;strokeColor=none;'
        'fillColor=none;align=left;verticalAlign=middle;fontFamily=Helvetica;'
        'fontSize=11;fontStyle=1;fontColor=#0F172A;" vertex="1" parent="1">'
        f'<mxGeometry x="{lx + 14}" y="{ly + 8}" width="200" height="18" as="geometry" /></mxCell>'
    )
    cells.append(
        '<mxCell id="leg_isi" value="PK = Primary Key   ·   FK = Foreign Key'
        '   ·   1 = satu   ·   N = banyak'
        '   ·   Panah menunjuk dari tabel induk ke tabel anak (1 : N)"'
        ' style="text;html=1;strokeColor=none;fillColor=none;align=left;'
        'verticalAlign=middle;fontFamily=Helvetica;fontSize=10;fontColor=#334155;"'
        ' vertex="1" parent="1">'
        f'<mxGeometry x="{lx + 14}" y="{ly + 30}" width="750" height="18" as="geometry" /></mxCell>'
    )

    xml = (
        '<mxfile host="app.diagrams.net" pages="1">\n'
        '  <diagram name="ERD SoundWave" id="erd-soundwave">\n'
        '    <mxGraphModel dx="1200" dy="900" grid="1" gridSize="10" guides="1"'
        ' tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1"'
        ' pageWidth="1100" pageHeight="1060" math="0" shadow="0">\n'
        '      <root>\n'
        '        <mxCell id="0" />\n'
        '        <mxCell id="1" parent="0" />\n'
        + "".join(f"        {c}\n" for c in cells) +
        '      </root>\n'
        '    </mxGraphModel>\n'
        '  </diagram>\n'
        '</mxfile>\n'
    )

    KELUARAN.write_text(xml, encoding="utf-8")
    print(f"tersimpan: {KELUARAN}")
    print(f"  {len(ENTITAS)} entitas, {len(RELASI)} relasi")


if __name__ == "__main__":
    main()
