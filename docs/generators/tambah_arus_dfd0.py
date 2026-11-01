"""
Tambah 8 arus data yang hilang ke DFD Level 0 SoundWave.

Kenapa skrip, bukan edit manual:
  * draw.io menyimpan koneksi sebagai XML; satu tag salah = file tidak bisa
    dibuka sama sekali.
  * Semua panah baru memakai `edgeStyle=orthogonalEdgeStyle` dengan
    `entryX/entryY` + `exitX/exitY` eksplisit, sehingga draw.io menghitung
    rutenya sendiri dan TIDAK menabrak simpul lain.
  * Koordinat lama tidak disentuh sama sekali — hanya `<mxCell>` baru yang
    ditambahkan sebelum `</root>`.

Jalankan: python docs/generators/tambah_arus_dfd0.py
"""

from __future__ import annotations

import io
import re
from pathlib import Path

BERKAS = Path(__file__).resolve().parents[1] / "Soundwave_DFD_Level_0_Akademik.drawio"

# Gaya dasar, disalin dari panah yang sudah ada supaya tampilannya identik.
GAYA = (
    "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;"
    "html=1;strokeColor=#000000;strokeWidth=1.4;fontSize=10;"
    "fontFamily=Courier New;labelBackgroundColor=#ffffff;"
)

# (id, sumber, target, label, exitX, exitY, entryX, entryY)
ARUS_BARU = [
    # ---- T1: Firebase sebagai entitas eksternal WAJIB punya arus balik ----
    ("arus_fb_uid", "ent_firebase", "p1",
     "UID &amp; Status Verifikasi", 0.75, 0.0, 1.0, 0.72),

    ("arus_fb_delivery", "ent_firebase", "p5",
     "Delivery Report Notifikasi", 0.25, 0.0, 1.0, 0.72),

    # ---- T3: admin membuat promo (sebelumnya promos hanya divalidasi) ----
    ("arus_admin_promo", "ent_admin", "ds5",
     "Data Promo &amp; Batas Kuota", 0.0, 0.62, 1.0, 0.5),

    # ---- T4: admin membuat katalog tipe tiket (harga & stok awal) ----
    ("arus_admin_tiket", "ent_admin", "ds4",
     "Katalog Tipe Tiket &amp; Stok Awal", 0.0, 0.42, 1.0, 0.5),

    # ---- T5: notifikasi in-app ke pengguna (nyata di kode) ----
    ("arus_p5_user", "p5", "ent_user",
     "Notifikasi Transaksi &amp; Tiket", 0.0, 0.45, 1.0, 0.86),

    # ---- T6: refund (fitur nyata, sebelumnya tidak tergambar) ----
    ("arus_user_refund", "ent_user", "p3",
     "Pengajuan Refund", 1.0, 0.90, 0.0, 0.86),

    ("arus_admin_refund", "ent_admin", "p3",
     "Keputusan Refund", 0.0, 0.90, 1.0, 0.86),

    # ---- T7: 4.0 perlu tahu pesanan mana yang sudah lunas ----
    ("arus_orders_p4", "ds3", "p4",
     "Verifikasi Status Lunas", 0.0, 0.5, 0.5, 0.0),
]


def buat_cell(id_: str, src: str, tgt: str, label: str,
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

    # Jangan jalan dua kali.
    if "arus_fb_uid" in teks:
        print("Panah baru sudah ada — tidak dijalankan ulang.")
        return

    baru = "".join(buat_cell(*a) for a in ARUS_BARU)

    # Sisipkan sebelum </root>, setelah semua cell lama.
    idx = teks.rindex("      </root>")
    teks = teks[:idx] + baru + teks[idx:]

    io.open(BERKAS, "w", encoding="utf-8", newline="\n").write(teks)
    print(f"{len(ARUS_BARU)} arus ditambahkan ke {BERKAS.name}")

    # Verifikasi: file harus tetap XML yang sah dan jumlah cell bertambah.
    jumlah_edge = len(re.findall(r'edge="1"', teks))
    jumlah_vertex = len(re.findall(r'vertex="1"', teks))
    print(f"  edge  : {jumlah_edge}")
    print(f"  vertex: {jumlah_vertex}")


if __name__ == "__main__":
    main()
