"""
Perbaiki 2 panah putus + tambah 2 arus yang masih hilang di DFD 0.

Berkas kerja: docs/soundwave3d_v2.drawio (halaman "Data Flow Diagram 0")

YANG DIPERBAIKI
  1. ZHulSzxLkBeTenciE1mW-29 "Atomic Hold Kuota"
     source & target hilang saat perapian manual.
     -> dipulihkan: 3.0 (sZP6oGHXJ8Z-BBgTGArh-15) -> D2 Events (-t9UeVWZTfoGwahvLvFM-5)
  2. ZHulSzxLkBeTenciE1mW-32 "Ambil Tiket Lunas"
     target hilang.
     -> dipulihkan: D4 Tickets (-t9UeVWZTfoGwahvLvFM-11) -> 4.0 (sZP6oGHXJ8Z-BBgTGArh-13)

YANG DITAMBAH
  3. D3 Orders -> 3.0        "Update Status Refund"
     Tanpa ini, keputusan refund dari ADMIN masuk ke 3.0 tapi tidak pernah
     tersimpan. Di kode: server.js:1754/1790/1839 menulis status REFUNDED /
     refundStatus REJECTED ke koleksi orders.
  4. 4.0 -> D3 Orders        "Update Status Gate / Check-in"
     Di kode: server.js:1409 menulis status TERPAKAI ke orders saat scan gate,
     dan /sync-offline-scans juga menulis ke orders.

TIDAK DISENTUH
  * Semua simpul (vertex) — posisi, ukuran, nama, gaya.
  * 29 panah lain.
  * Dua halaman lain (Use Case, Context Diagram).

Jalankan: python docs/generators/perbaiki_dfd0_v2.py
"""

from __future__ import annotations

import io
import re
from pathlib import Path

BERKAS = Path(__file__).resolve().parents[1] / "soundwave3d_v2.drawio"

GAYA = (
    "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;"
    "html=1;strokeColor=#1E293B;strokeWidth=1.5;fontSize=10;"
    "fontFamily=Courier New;labelBackgroundColor=#FFFFFF;"
)

P3 = "sZP6oGHXJ8Z-BBgTGArh-15"   # 3.0 Pemesanan & Pembayaran
P4 = "sZP6oGHXJ8Z-BBgTGArh-13"   # 4.0 Publish Tiket & Validasi Gate
D2 = "-t9UeVWZTfoGwahvLvFM-5"    # Events
D3 = "-t9UeVWZTfoGwahvLvFM-7"    # Orders
D4 = "-t9UeVWZTfoGwahvLvFM-11"   # Tickets

# (id, sumber, target, label, exitX, exitY, entryX, entryY)
ARUS_BARU = [
    # Slot dicek kosong: D3 keluar sudah pakai 0.3 & 0.5; 3.0 masuk sudah
    # pakai 0.15, 0.25, 0.5, 1.0 -> 0.4 aman.
    ("arus_refund_order", D3, P3,
     "Update Status Refund", 1.0, 0.7, 0.0, 0.4),

    # 4.0 keluar sudah pakai 0.5 & 0.83 -> 0.15 aman.
    # D3 masuk sudah pakai 0.25 -> 0.75 aman.
    ("arus_gate_order", P4, D3,
     "Update Status Gate / Check-in", 0.0, 0.15, 1.0, 0.75),
]


def sel(id_: str, src: str, tgt: str, label: str,
        ex: float, ey: float, nx: float, ny: float) -> str:
    style = (
        f"{GAYA}exitX={ex};exitY={ey};exitDx=0;exitDy=0;"
        f"entryX={nx};entryY={ny};entryDx=0;entryDy=0;"
    )
    return (
        f'        <mxCell id="{id_}" value="{label}" style="{style}" '
        f'edge="1" parent="1" source="{src}" target="{tgt}">\n'
        f'          <mxGeometry relative="1" as="geometry" />\n'
        f'        </mxCell>\n'
    )


def pulihkan(teks: str, eid: str, tambahan: str) -> tuple[str, bool]:
    """Sisipkan atribut yang hilang ke <mxCell ...> milik eid."""
    pola = re.compile(r'<mxCell((?=[^>]*id="' + re.escape(eid) + r'")[^>]*)>')
    m = pola.search(teks)
    if not m:
        return teks, False
    attrs = m.group(1)
    # hanya tambahkan kalau memang belum ada
    for nama in ("source", "target"):
        if f'{nama}="' not in tambahan:
            continue
    baru = attrs.rstrip()
    for potong in tambahan.split():
        kunci = potong.split("=")[0]
        if f'{kunci}="' in baru:
            continue
        baru = baru + " " + potong
    if baru == attrs.rstrip():
        return teks, False
    return teks[: m.start()] + "<mxCell" + baru + ">" + teks[m.end():], True


def main() -> None:
    teks = io.open(BERKAS, encoding="utf-8").read()

    if "arus_refund_order" in teks:
        print("Sudah pernah dijalankan — tidak diulang.")
        return

    # --- 1. pulihkan dua panah putus ---
    teks, ok29 = pulihkan(teks, "ZHulSzxLkBeTenciE1mW-29",
                          f'source="{P3}" target="{D2}"')
    teks, ok32 = pulihkan(teks, "ZHulSzxLkBeTenciE1mW-32",
                          f'target="{P4}"')
    print(f"  pulihkan Atomic Hold Kuota : {'OK' if ok29 else 'TIDAK BERUBAH'}")
    print(f"  pulihkan Ambil Tiket Lunas : {'OK' if ok32 else 'TIDAK BERUBAH'}")

    # --- 2. tambah dua arus baru, hanya di halaman DFD 0 ---
    i = teks.find('<diagram name="Data Flow Diagram 0"')
    if i < 0:
        raise SystemExit("Halaman 'Data Flow Diagram 0' tidak ditemukan.")
    j = teks.find("</root>", i)
    if j < 0:
        raise SystemExit("</root> halaman DFD 0 tidak ditemukan.")

    baru = "".join(sel(*a) for a in ARUS_BARU)
    teks = teks[:j] + baru + teks[j:]

    io.open(BERKAS, "w", encoding="utf-8", newline="\n").write(teks)
    print(f"  tambah {len(ARUS_BARU)} arus baru    : OK")


if __name__ == "__main__":
    main()
