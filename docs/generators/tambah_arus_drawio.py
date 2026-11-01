"""
Tambah arus data yang hilang ke halaman "Data Flow Diagram 0"
di docs/soundwave3d.drawio (berkas yang dipakai user di draw.io).

ATURAN KERAS:
  * Tidak ada simpul yang dipindah, diganti nama, atau diubah ukurannya.
  * Hanya <mxCell edge="1"> BARU yang disisipkan.
  * Semua panah memakai entry/exit eksplisit supaya draw.io merutekan sendiri.
  * Titik masuk/keluar dipilih dari slot yang MASIH KOSONG (sudah diperiksa
    terhadap 25 panah lama), jadi tidak ada dua panah menempel di titik sama.

Jalankan: python docs/generators/tambah_arus_drawio.py
"""

from __future__ import annotations

import io
import os
import re
from pathlib import Path

BERKAS = Path(__file__).resolve().parents[1] / "soundwave3d.drawio"

# Gaya disalin dari panah yang sudah ada di berkas user.
GAYA = (
    "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;"
    "html=1;strokeColor=#1E293B;strokeWidth=1.5;fontSize=10;"
    "fontFamily=Courier New;labelBackgroundColor=#FFFFFF;"
)

# id simpul di berkas user
USER = "ZHulSzxLkBeTenciE1mW-2"
ADMIN = "ZHulSzxLkBeTenciE1mW-3"
PG = "ZHulSzxLkBeTenciE1mW-4"
FB = "ZHulSzxLkBeTenciE1mW-5"
P1 = "sZP6oGHXJ8Z-BBgTGArh-1"
P2 = "sZP6oGHXJ8Z-BBgTGArh-7"
P3 = "sZP6oGHXJ8Z-BBgTGArh-15"
P4 = "sZP6oGHXJ8Z-BBgTGArh-13"
P5 = "sZP6oGHXJ8Z-BBgTGArh-17"
D1 = "-t9UeVWZTfoGwahvLvFM-9"
D2 = "-t9UeVWZTfoGwahvLvFM-5"
D3 = "-t9UeVWZTfoGwahvLvFM-7"
D4 = "-t9UeVWZTfoGwahvLvFM-11"
D5 = "-t9UeVWZTfoGwahvLvFM-1"

# (id, sumber, target, label, exitX, exitY, entryX, entryY)
#
# Slot yang dipilih (semua sudah dicek kosong terhadap 25 panah lama):
#   FB  keluar kiri  y=0.70 / 0.90   (lama: masuk 0.0/0.5 & 0.0/0.25)
#   P1  masuk  kiri  y=0.92          (lama: masuk 0/0.5)
#   P5  masuk  kiri  y=0.72          (lama: masuk 1/0.4444)
#   ADMIN keluar kiri y=0.62 / 0.72  (lama: 0.0/0.0319, 0.0/0.553, 0.0/0.9468)
#   D4  masuk  kanan y=0.22          (lama: masuk 0.5/0.0)
#   D3  keluar kanan y=0.30          (lama: keluar 1/0.5)
#   P4  masuk  bawah y=0.35          (lama: masuk 1.0/0.5)
#   P3  masuk  kiri  y=0.15 / 0.92   (lama: masuk 0/0.5, 0/0.25)
#   USER keluar kanan y=0.88         (lama: 1.0/0.0427, 1.0/0.6037)
#   P5  keluar kiri y=0.55           (lama: 0/0.8333)
#   USER masuk kanan y=0.80          (lama: 1/0.158, 1/0.3598, 1/0.6585, 1/0.9207)
ARUS_BARU = [
    # ---- T1: Firebase = entitas eksternal, WAJIB punya arus balik ----
    ("arus_fb_uid", FB, P1,
     "UID &amp; Status Verifikasi", 0.0, 0.70, 0.0, 0.92),

    ("arus_fb_delivery", FB, P5,
     "Delivery Report Notifikasi", 0.0, 0.90, 1.0, 0.72),

    # ---- T4: admin membuat katalog tipe tiket (harga & stok awal) ----
    ("arus_admin_tiket", ADMIN, D4,
     "Katalog Tipe Tiket &amp; Stok Awal", 0.0, 0.72, 1.0, 0.22),

    # ---- T5: notifikasi in-app ke USER (nyata di kode) ----
    ("arus_p5_user", P5, USER,
     "Notifikasi Transaksi &amp; Tiket", 0.0, 0.55, 1.0, 0.80),

    # ---- T6: refund ----
    ("arus_user_refund", USER, P3,
     "Pengajuan Refund", 1.0, 0.88, 0.0, 0.92),

    ("arus_admin_refund", ADMIN, P3,
     "Keputusan Refund", 0.0, 0.62, 0.0, 0.15),

    # ---- T7: 4.0 perlu tahu pesanan mana yang sudah lunas ----
    ("arus_orders_p4", D3, P4,
     "Verifikasi Status Lunas", 1.0, 0.30, 0.35, 1.0),
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


def main() -> None:
    teks = io.open(BERKAS, encoding="utf-8").read()

    if "arus_fb_uid" in teks:
        print("Panah baru sudah ada — tidak dijalankan ulang.")
        return

    # Cari akhir halaman DFD 0 saja, jangan sentuh 2 halaman lain.
    i = teks.find('<diagram name="Data Flow Diagram 0"')
    if i < 0:
        raise SystemExit("Halaman 'Data Flow Diagram 0' tidak ditemukan.")
    j = teks.find("</root>", i)
    if j < 0:
        raise SystemExit("</root> halaman DFD 0 tidak ditemukan.")

    baru = "".join(sel(*a) for a in ARUS_BARU)
    teks = teks[:j] + baru + teks[j:]

    io.open(BERKAS, "w", encoding="utf-8", newline="\n").write(teks)

    halaman = teks[i:teks.find("</diagram>", i)]
    print(f"{len(ARUS_BARU)} arus ditambahkan ke halaman DFD 0")
    print(f"  edge halaman DFD 0 : {len(re.findall(chr(34) + 'edge=1' + chr(34), halaman))}")


if __name__ == "__main__":
    main()
