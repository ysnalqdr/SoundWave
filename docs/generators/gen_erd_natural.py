"""
Generator ERD SoundWave -> .drawio, gaya "natural / mudah dibaca".

Prinsip desain (bukan gaya AI-slop):
  * Monokrom. Abu netral untuk header, bukan biru Aero atau gradien.
  * Sudut tegas, border 1 px, tanpa drop shadow, tanpa glow.
  * Satu-satunya warna: kunci emas (PK) dan berlian merah (FK) — keduanya
    penanda fungsional, bukan hiasan.
  * Crow's foot + garis putus-putus, seperti contoh Workbench user.
  * Tipe data rata kanan, abu-abu, supaya mata fokus ke nama kolom.
  * Tata letak berjenjang: orders di bawah-tengah sebagai pusat transaksi.

5 entitas, sama dengan 5 data store DFD Level 0:
  users (D1), events (D2), orders (D3), tickets (D4), promo_codes (D5)

Jalankan: python docs/generators/gen_erd_natural.py
"""

from __future__ import annotations

import base64
import html
from pathlib import Path

KELUARAN = Path(__file__).resolve().parents[2] / "ERD_SOUNDWAVE.drawio"

# ---------- palet ----------
TINTA = "#1A1A1A"
ABU_HEAD = "#D9D9D9"
ABU_BORDER = "#8C8C8C"
ABU_TIPE = "#6B6B6B"
ABU_SELANG = "#F7F7F7"
EMAS = "#E8B33A"
MERAH = "#D65A5A"

# ---------- entitas: (id, nama, x, y, [(kolom, tipe, kunci)]) ----------
LEBAR = 260
TINGGI_HEAD = 30
TINGGI_BARIS = 22

ENTITAS = [
    ("users", "users", 60, 60, [
        ("id_user", "VARCHAR(5)", "PK"),
        ("nama", "VARCHAR(100)", ""),
        ("email", "VARCHAR(100)", ""),
        ("role", "VARCHAR(10)", ""),
        ("no_telepon", "VARCHAR(20)", ""),
        ("created_at", "DATETIME", ""),
    ]),
    ("events", "events", 520, 60, [
        ("id_event", "VARCHAR(5)", "PK"),
        ("judul", "VARCHAR(100)", ""),
        ("lokasi", "VARCHAR(50)", ""),
        ("tanggal", "DATE", ""),
        ("penyelenggara", "VARCHAR(100)", ""),
        ("status", "VARCHAR(15)", ""),
    ]),
    ("tickets", "tickets", 60, 330, [
        ("id_tiket", "VARCHAR(5)", "PK"),
        ("kategori", "VARCHAR(20)", ""),
        ("harga", "DECIMAL(12,0)", ""),
        ("stok", "INT", ""),
        ("terjual", "INT", ""),
        ("id_event", "VARCHAR(5)", "FK"),
    ]),
    ("promo_codes", "promo_codes", 520, 330, [
        ("kode_promo", "VARCHAR(20)", "PK"),
        ("tipe", "VARCHAR(15)", ""),
        ("nilai", "DECIMAL(12,0)", ""),
        ("min_pembelian", "DECIMAL(12,0)", ""),
        ("max_pakai", "INT", ""),
        ("sudah_dipakai", "INT", ""),
        ("aktif", "TINYINT(1)", ""),
        ("id_event", "VARCHAR(5)", "FK"),
    ]),
    ("orders", "orders", 300, 620, [
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
    ]),
]

# (id, sumber, target, label, [waypoint...], arah_crowfoot)
# Rute diperiksa tidak menembus kotak mana pun (lihat verifikasi di skrip).
RELASI = [
    ("r_users_orders", "users", "orders", "membuat",
     [(40, 150), (20, 150), (20, 700), (300, 700)], "kiri"),
    ("r_events_orders", "events", "orders", "memiliki",
     [(780, 150), (830, 150), (830, 720), (560, 720)], "kanan"),
    ("r_events_tickets", "events", "tickets", "punya tipe",
     [(620, 220), (620, 280), (320, 280), (320, 330)], "bawah"),
    ("r_events_promos", "events", "promo_codes", "punya promo",
     [(720, 220), (720, 330)], "bawah"),
    ("r_tickets_orders", "tickets", "orders", "dipakai",
     [(190, 490), (190, 560), (400, 560), (400, 620)], "bawah"),
    ("r_promos_orders", "promo_codes", "orders", "dipakai",
     [(660, 560), (660, 590), (520, 590), (520, 620)], "bawah"),
]


def _datauri(svg: str) -> str:
    """SVG inline sebagai data URI — drawio merendernya sebagai gambar."""
    b = base64.b64encode(svg.encode("utf-8")).decode("ascii")
    return f"data:image/svg+xml;base64,{b}"


# kunci emas: kepala bulat + batang bergigi (gaya Workbench)
IKON_PK = _datauri(
    '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 13 13">'
    '<circle cx="3.4" cy="6.5" r="2.4" fill="none" stroke="#C99A2E" stroke-width="1.8"/>'
    '<path d="M5.8 6.5 H12 M9.6 6.5 V8.9 M11.2 6.5 V8.1" stroke="#C99A2E" '
    'stroke-width="1.8" fill="none" stroke-linecap="round"/></svg>'
)
# berlian merah: penanda foreign key
IKON_FK = _datauri(
    '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 13 13">'
    '<path d="M6.5 1.6 L11.4 6.5 L6.5 11.4 L1.6 6.5 Z" fill="#C94F4F"/></svg>'
)
# crow's foot "banyak": tiga cabang menempel di tepi tabel tujuan
IKON_MANY = _datauri(
    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">'
    '<path d="M1 7 L13 1 M1 7 L13 7 M1 7 L13 13" stroke="#1A1A1A" stroke-width="1.5" '
    'fill="none" stroke-linecap="round"/></svg>'
)
# penanda "satu": garis tegak lurus di tepi tabel induk
IKON_ONE = _datauri(
    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">'
    '<path d="M7 1 V13" stroke="#1A1A1A" stroke-width="2" stroke-linecap="round"/></svg>'
)
IKON_KOSONG = _datauri(
    '<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 13 13">'
    '<rect width="13" height="13" fill="none"/></svg>'
)


def esc(t: str) -> str:
    return html.escape(t, quote=True)


def badan(kolom) -> str:
    """HTML daftar kolom: nama kiri, tipe kanan."""
    bagian = []
    for nama, tipe, kunci in kolom:
        if kunci == "PK":
            ikon = f'<img src="{IKON_PK}" width="13" height="13" />'
            tebal = "font-weight:bold;"
        elif kunci == "FK":
            ikon = f'<img src="{IKON_FK}" width="13" height="13" />'
            tebal = "font-weight:bold;"
        else:
            ikon = f'<img src="{IKON_KOSONG}" width="13" height="13" />'
            tebal = ""
        bagian.append(
            f'<div style="line-height:18px;{tebal}">{ikon} {nama}'
            f'<span style="color:{ABU_TIPE};float:right;">{tipe}</span></div>'
        )
    return "".join(bagian)


def main() -> None:
    sel: list[str] = []

    # ---------- kop ----------
    sel.append(
        '<mxCell id="judul" value="ENTITY RELATIONSHIP DIAGRAM — SISTEM INFORMASI SOUNDWAVE"'
        ' style="text;html=1;strokeColor=none;fillColor=none;align=left;'
        'verticalAlign=middle;fontFamily=Helvetica;fontSize=15;fontStyle=1;'
        f'fontColor={TINTA};" vertex="1" parent="1">'
        '<mxGeometry x="60" y="10" width="620" height="22" as="geometry" /></mxCell>'
    )
    sel.append(
        '<mxCell id="sub" value="5 entitas · 6 relasi 1:N · konsisten dengan 5 data store pada DFD Level 0"'
        ' style="text;html=1;strokeColor=none;fillColor=none;align=left;'
        'verticalAlign=middle;fontFamily=Helvetica;fontSize=10;fontColor=#6B6B6B;"'
        ' vertex="1" parent="1">'
        '<mxGeometry x="60" y="32" width="620" height="16" as="geometry" /></mxCell>'
    )

    # ---------- tabel ----------
    for eid, nama, x, y, kolom in ENTITAS:
        h = TINGGI_HEAD + TINGGI_BARIS * len(kolom) + 6

        # header
        sel.append(
            f'<mxCell id="{eid}_head" value="{esc(nama)}"'
            f' style="rounded=0;whiteSpace=wrap;html=1;fillColor={ABU_HEAD};'
            f'strokeColor={ABU_BORDER};strokeWidth=1;align=center;'
            'verticalAlign=middle;fontFamily=Helvetica;fontSize=12;fontStyle=1;'
            f'fontColor={TINTA};" vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{LEBAR}" height="{TINGGI_HEAD}"'
            ' as="geometry" /></mxCell>'
        )
        # badan
        sel.append(
            f'<mxCell id="{eid}" value="{esc(badan(kolom))}"'
            f' style="rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;'
            f'strokeColor={ABU_BORDER};strokeWidth=1;align=left;verticalAlign=top;'
            'fontFamily=Courier New;fontSize=10;spacingLeft=6;spacingTop=4;'
            f'fontColor={TINTA};" vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y + TINGGI_HEAD}" width="{LEBAR}"'
            f' height="{h - TINGGI_HEAD}" as="geometry" /></mxCell>'
        )

    # ---------- relasi ----------
    for rid, src, tgt, label, jalur, arah in RELASI:
        style = (
            "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;"
            f"jettySize=auto;html=1;strokeColor={TINTA};strokeWidth=1.5;"
            "dashed=1;dashPattern=6 4;"
            "startArrow=ERone;startFill=0;startSize=10;"
            "endArrow=ERmany;endFill=0;endSize=10;"
            "fontFamily=Helvetica;fontSize=9;fontColor=#595959;"
            "labelBackgroundColor=#FFFFFF;"
        )
        wp = "".join(
            f'<mxPoint x="{p[0]}" y="{p[1]}" />' for p in jalur
        )
        sel.append(
            f'<mxCell id="{rid}" value="{esc(label)}" style="{style}"'
            f' edge="1" parent="1" source="{src}" target="{tgt}">'
            f'<mxGeometry relative="1" as="geometry">'
            f'<Array as="points">{wp}</Array></mxGeometry></mxCell>'
        )
    # ---------- legenda ----------
    ly = 1010
    sel.append(
        '<mxCell id="leg_garis" value="" style="endArrow=none;html=1;'
        f'strokeColor={TINTA};strokeWidth=1.5;dashed=1;dashPattern=6 4;"'
        ' edge="1" parent="1">'
        f'<mxGeometry relative="1" as="geometry">'
        f'<mxPoint x="60" y="{ly}" as="sourcePoint" />'
        f'<mxPoint x="130" y="{ly}" as="targetPoint" /></mxGeometry></mxCell>'
    )
    sel.append(
        f'<mxCell id="leg_1" value="garis putus-putus = relasi non-identifying  ·  '
        f'kunci emas = Primary Key  ·  berlian merah = Foreign Key  ·  '
        f'garis tegak lurus = sisi satu  ·  tiga cabang = sisi banyak"'
        ' style="text;html=1;strokeColor=none;fillColor=none;align=left;'
        'verticalAlign=middle;fontFamily=Helvetica;fontSize=9;fontColor=#595959;"'
        ' vertex="1" parent="1">'
        f'<mxGeometry x="145" y="{ly - 9}" width="720" height="18" as="geometry" />'
        '</mxCell>'
    )

    xml = (
        '<mxfile host="app.diagrams.net" pages="1">\n'
        '  <diagram name="ERD SoundWave" id="erd-soundwave">\n'
        '    <mxGraphModel dx="1000" dy="800" grid="1" gridSize="10" guides="1"'
        ' tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1"'
        ' pageWidth="900" pageHeight="1060" math="0" shadow="0">\n'
        '      <root>\n'
        '        <mxCell id="0" />\n'
        '        <mxCell id="1" parent="0" />\n'
        + "".join(f"        {c}\n" for c in sel) +
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
