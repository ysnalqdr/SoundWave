"""
Bangun 2 halaman drawio dari SATU sumber data:
  - "ERD Chen" : kotak entitas + belah ketupat relasi + elips atribut
  - "LRS"      : kotak tabel + panah berkardinalitas, tanpa belah ketupat

Sumber data identik dengan ERD_SOUNDWAVE.drawio (5 tabel, 6 relasi 1:N).

Jalankan: python docs/generators/gen_erd_chen_lrs.py
Keluaran: docs/ERD_CHEN_LRS_SOUNDWAVE.drawio
"""

from __future__ import annotations

import html
import math
import xml.etree.ElementTree as ET
from pathlib import Path

KELUAR = Path(__file__).resolve().parents[2] / "docs" / "ERD_CHEN_LRS_SOUNDWAVE.drawio"

# ---------------------------------------------------------------------------
# SUMBER DATA TUNGGAL
# ---------------------------------------------------------------------------
TABEL = [
    {"nama": "users", "pk": "id_user", "fk": [],
     "atribut": ["nama", "email", "role", "no_telepon", "created_at"]},
    {"nama": "events", "pk": "id_event", "fk": [],
     "atribut": ["judul", "lokasi", "tanggal", "penyelenggara", "status"]},
    {"nama": "tickets", "pk": "id_tiket", "fk": ["id_event"],
     "atribut": ["kategori", "harga", "stok", "terjual"]},
    {"nama": "promo", "pk": "id_promo", "fk": ["id_event"],
     "atribut": ["tipe", "nilai", "min_pembelian", "max_pakai", "sudah_dipakai", "aktif"]},
    {"nama": "orders", "pk": "id_order", "fk": ["id_user", "id_event", "id_tiket", "id_promo"],
     "atribut": ["jumlah_tiket", "subtotal", "diskon", "pajak", "biaya_layanan",
                 "total_bayar", "status", "tanggal_beli"]},
]

# (tabel_1, tabel_N, kata_kerja)
RELASI = [
    ("users", "orders", "membuat"),
    ("events", "orders", "memiliki"),
    ("tickets", "orders", "dipakai"),
    ("promo", "orders", "dipakai"),
    ("events", "tickets", "punya tipe"),
    ("events", "promo", "punya promo"),
]

# ---------------------------------------------------------------------------
# Gaya
# ---------------------------------------------------------------------------
S_ENTITAS = ("rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#1A1A1A;"
             "strokeWidth=2;align=center;verticalAlign=middle;fontFamily=Helvetica;"
             "fontSize=14;fontStyle=1;fontColor=#1A1A1A;")
S_RELASI = ("rhombus;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#1A1A1A;"
            "strokeWidth=1.6;align=center;verticalAlign=middle;fontFamily=Helvetica;"
            "fontSize=11;fontColor=#1A1A1A;")
S_ATTR = ("ellipse;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#1A1A1A;"
          "strokeWidth=1.2;align=center;verticalAlign=middle;fontFamily=Helvetica;"
          "fontSize=10;fontColor=#1A1A1A;")
S_ATTR_PK = ("ellipse;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#1A1A1A;"
             "strokeWidth=2.2;align=center;verticalAlign=middle;fontFamily=Helvetica;"
             "fontSize=10;fontStyle=4;fontColor=#1A1A1A;")
S_GARIS = ("endArrow=none;html=1;strokeColor=#1A1A1A;strokeWidth=1.2;"
           "fontFamily=Helvetica;fontSize=9;fontColor=#595959;")
S_GARIS_REL = ("endArrow=none;html=1;strokeColor=#1A1A1A;strokeWidth=1.5;"
               "fontFamily=Helvetica;fontSize=9;fontColor=#595959;")
S_KEPALA = ("rounded=0;whiteSpace=wrap;html=1;fillColor=#D9D9D9;strokeColor=#8C8C8C;"
            "strokeWidth=1;align=center;verticalAlign=middle;fontFamily=Helvetica;"
            "fontSize=12;fontStyle=1;fontColor=#1A1A1A;")
S_BADAN = ("rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#8C8C8C;"
           "strokeWidth=1;align=left;verticalAlign=top;fontFamily=Courier New;"
           "fontSize=11;spacingLeft=10;spacingTop=8;fontColor=#1A1A1A;")
S_PANAH = ("edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;"
           "html=1;endArrow=block;endFill=1;endSize=8;strokeColor=#1A1A1A;"
           "strokeWidth=1.4;fontFamily=Helvetica;fontSize=10;fontStyle=1;"
           "fontColor=#1A1A1A;labelBackgroundColor=#FFFFFF;")


class Halaman:
    def __init__(self, nama: str, pid: str, lebar: int, tinggi: int) -> None:
        self.nama, self.pid = nama, pid
        self.lebar, self.tinggi = lebar, tinggi
        self.cells: list[str] = []
        self._n = 0

    def _id(self) -> str:
        self._n += 1
        return f"c{self._n}"

    def kotak(self, x, y, w, h, nilai, gaya) -> str:
        cid = self._id()
        self.cells.append(
            f'<mxCell id="{cid}" parent="1" style="{gaya}" '
            f'value="{html.escape(nilai, quote=True)}" vertex="1">'
            f'<mxGeometry height="{h}" width="{w}" x="{x}" y="{y}" as="geometry" />'
            f"</mxCell>")
        return cid

    def garis(self, asal, tujuan, label="", gaya=S_GARIS) -> str:
        cid = self._id()
        self.cells.append(
            f'<mxCell id="{cid}" edge="1" parent="1" source="{asal}" target="{tujuan}" '
            f'style="{gaya}" value="{html.escape(label, quote=True)}">'
            f'<mxGeometry relative="1" as="geometry" /></mxCell>')
        return cid

    def xml(self) -> str:
        isi = "\n        ".join(self.cells)
        return (
            f'  <diagram name="{self.nama}" id="{self.pid}">\n'
            f'    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" '
            f'tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" '
            f'pageWidth="{self.lebar}" pageHeight="{self.tinggi}" math="0" shadow="0">\n'
            f'      <root>\n        <mxCell id="0" />\n        <mxCell id="1" parent="0" />\n'
            f"        {isi}\n      </root>\n    </mxGraphModel>\n  </diagram>")


# ===========================================================================
# HALAMAN 1 — ERD CHEN
# ===========================================================================
def build_chen() -> Halaman:
    h = Halaman("ERD Chen", "chen-soundwave", 1900, 1640)

    ENT = {
        "users":   (280, 250),
        "events":  (1380, 250),
        "tickets": (280, 1080),
        "promo":   (1380, 1040),
        "orders":  (820, 640),
    }
    W_ENT, H_ENT = 180, 72

    REL = {
        ("users", "orders"):   (560, 545),
        ("events", "orders"):  (1070, 400),
        ("tickets", "orders"): (560, 800),
        ("promo", "orders"):   (1070, 880),
        ("events", "tickets"): (330, 640),
        ("events", "promo"):   (1330, 640),
    }
    W_REL, H_REL = 140, 84

    # Elips atribut disusun dua baris (atas & bawah entitas) dengan kolom tetap.
    # Lebih aman daripada sebaran sudut: jarak antar-elips dijamin, tidak mungkin
    # menabrak belah ketupat yang diletakkan di sisi kiri/kanan entitas.
    W_EL, H_EL = 108, 34
    JARAK_KOL = 122

    def tata_elips(nama: str, atribut: list[str]) -> list[tuple[int, int, str, str]]:
        """Kembalikan daftar (x, y, teks, id) untuk atribut satu entitas."""
        ex, ey = ENT[nama]
        cx, cy = ex + W_ENT / 2, ey + H_ENT / 2
        n = len(atribut)
        # bagi rata: separuh atas, separuh bawah
        n_atas = (n + 1) // 2
        hasil = []
        for i, teks in enumerate(atribut):
            if i < n_atas:
                baris_i, jumlah_baris = 0, n_atas
            else:
                baris_i, jumlah_baris = 1, n - n_atas
            idx = i if i < n_atas else i - n_atas
            geser = (idx - (jumlah_baris - 1) / 2) * JARAK_KOL
            x = round(cx + geser - W_EL / 2)
            if baris_i == 0:
                y = round(ey - H_EL - 46)
            else:
                y = round(ey + H_ENT + 46)
            hasil.append((x, y, teks, f"{nama}-{i}"))
        return hasil

    id_ent = {nama: h.kotak(x, y, W_ENT, H_ENT, nama, S_ENTITAS) for nama, (x, y) in ENT.items()}

    for nama in ENT:
        tabel = next(t for t in TABEL if t["nama"] == nama)
        atribut = [tabel["pk"]] + tabel["atribut"] + tabel["fk"]
        for x, y, teks, _ in tata_elips(nama, atribut):
            gaya = S_ATTR_PK if teks == tabel["pk"] else S_ATTR
            aid = h.kotak(x, y, W_EL, H_EL, teks, gaya)
            h.garis(id_ent[nama], aid)

    kata_rel = {(t1, t2): kata for t1, t2, kata in RELASI}
    for (t1, t2), (x, y) in REL.items():
        rid = h.kotak(x, y, W_REL, H_REL, kata_rel[(t1, t2)], S_RELASI)
        h.garis(id_ent[t1], rid, "", S_GARIS_REL)
        h.garis(rid, id_ent[t2], "", S_GARIS_REL)

    lx, ly = 90, 1520
    h.kotak(lx, ly, 200, 40, "KETERANGAN", S_KEPALA)
    h.kotak(lx, ly + 40, 200, 34, "kotak = entitas", S_ATTR)
    h.kotak(lx, ly + 82, 200, 34, "belah ketupat = relasi", S_RELASI)
    h.kotak(lx, ly + 124, 200, 34, "elips = atribut", S_ATTR)
    h.kotak(lx, ly + 166, 200, 34, "tebal + garis bawah = PK", S_ATTR_PK)

    return h


# ===========================================================================
# HALAMAN 2 — LRS
# ===========================================================================
def build_lrs() -> Halaman:
    h = Halaman("LRS", "lrs-soundwave", 1560, 1180)

    POS = {
        "users":   (90, 70),
        "events":  (1210, 70),
        "tickets": (90, 620),
        "promo":   (1210, 560),
        "orders":  (640, 400),
    }
    W, KEPALA = 250, 34

    id_judul: dict[str, str] = {}
    for t in TABEL:
        x, y = POS[t["nama"]]
        baris = [t["pk"] + "  (PK)"] + t["atribut"] + [f + "  (FK)" for f in t["fk"]]
        tinggi = KEPALA + len(baris) * 21 + 14
        hid = h.kotak(x, y, W, KEPALA, t["nama"], S_KEPALA)
        bagian = []
        for b in baris:
            if b.endswith("(PK)"):
                bagian.append(f'<div style="line-height:21px;"><u>{html.escape(b)}</u></div>')
            else:
                bagian.append(f'<div style="line-height:21px;">{html.escape(b)}</div>')
        h.kotak(x, y + KEPALA, W, tinggi - KEPALA, "".join(bagian), S_BADAN)
        id_judul[t["nama"]] = hid

    pk_map = {t["nama"]: t["pk"] for t in TABEL}
    fk_map = {t["nama"]: t["fk"] for t in TABEL}
    for t1, t2, kata in RELASI:
        asal, tujuan = (t2, t1) if pk_map[t1] in fk_map[t2] else (t1, t2)
        h.garis(id_judul[asal], id_judul[tujuan], "N : 1", S_PANAH)

    lx, ly = 90, 1030
    h.kotak(lx, ly, 300, 34, "KETERANGAN LRS", S_KEPALA)
    h.kotak(lx, ly + 34, 300, 62,
            '<div style="line-height:21px;"><u>(PK)</u> = kunci primer</div>'
            '<div style="line-height:21px;">(FK) = kunci asing, menunjuk tabel lain</div>',
            S_BADAN)
    h.kotak(lx, ly + 100, 300, 34,
            "arah panah: N (pemilik FK) ke 1 (pemilik PK)", S_BADAN)

    return h


def main() -> None:
    chen, lrs = build_chen(), build_lrs()
    isi = ('<mxfile host="app.diagrams.net" pages="2">\n'
           + chen.xml() + "\n" + lrs.xml() + "\n</mxfile>\n")

    KELUAR.parent.mkdir(parents=True, exist_ok=True)
    KELUAR.write_text(isi, encoding="utf-8")

    akar = ET.fromstring(isi)
    halaman = akar.findall("diagram")
    print(f"tersimpan : {KELUAR.name}  ({KELUAR.stat().st_size / 1024:.1f} KB)")
    for d in halaman:
        v = len(d.findall(".//mxCell[@vertex='1']"))
        e = len(d.findall(".//mxCell[@edge='1']"))
        print(f"  {d.get('name'):10} {v:3} simpul  {e:3} garis")

    print("\n=== VALIDASI: garis menggantung ===")
    for d in halaman:
        ids = {c.get("id") for c in d.findall(".//mxCell[@vertex='1']")}
        rusak = [c.get("id") for c in d.findall(".//mxCell[@edge='1']")
                 if not c.get("source") or not c.get("target")
                 or c.get("source") not in ids or c.get("target") not in ids]
        print(f"  {d.get('name'):10} {len(rusak)}")

    print("\n=== KELENGKAPAN ATRIBUT CHEN ===")
    teks = " ".join(c.get("value") or "" for c in halaman[0].findall(".//mxCell[@vertex='1']"))
    for t in TABEL:
        butuh = [t["pk"]] + t["atribut"] + t["fk"]
        hilang = [b for b in butuh if b not in teks]
        print(f"  {t['nama']:8} {len(butuh):2} atribut -> "
              f"{'lengkap' if not hilang else 'HILANG ' + str(hilang)}")

    print(f"\nrelasi: {len(RELASI)} (semua 1:N)")


if __name__ == "__main__":
    main()
