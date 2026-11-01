"""
Tambah 3 arus yang hilang ke halaman "Context Diagram"
di docs/soundwave3d_v2.drawio.

KENAPA DITAMBAH
  DFD-0 sudah punya alur refund dan notifikasi, tapi context diagram
  (level tertinggi) belum. Dalam DFD, arus di level bawah harus punya
  jejak di context diagram.

  1. USER   -> Sistem  "Pengajuan Refund Tiket"
  2. ADMIN  -> Sistem  "Keputusan Refund"
  3. Sistem -> USER    "Notifikasi Transaksi & Tiket"

DESAIN TITIK TEMPEL
  * Kotak USER & ADMIN: pakai slot y=0.47 — satu-satunya celah kosong
    (keluar terpakai 0.15/0.28/0.41, masuk terpakai 0.60/0.73/0.86).
  * Lingkaran Sistem: SENGAJA tanpa entryX/entryY supaya draw.io memilih
    titik kosong di perimeter sendiri. Sisi kiri lingkaran sudah padat
    (masuk 0.25/0.38/0.48, keluar 0.58/0.68/0.78).

TIDAK DISENTUH
  * Semua simpul (posisi, ukuran, nama).
  * 16 arus yang sudah ada.
  * Halaman Use Case Diagram & Data Flow Diagram 0.

Jalankan: python docs/generators/tambah_arus_context.py
"""

from __future__ import annotations

import io
import re
from pathlib import Path

BERKAS = Path(__file__).resolve().parents[1] / "soundwave3d_v2.drawio"

SISTEM = "e1quG5n2BHp4WV1Xs9PV-34"
USER = "e1quG5n2BHp4WV1Xs9PV-35"
ADMIN = "e1quG5n2BHp4WV1Xs9PV-36"

# Gaya disalin dari panah context diagram yang sudah ada.
GAYA = (
    "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;"
    "html=1;strokeColor=#000000;strokeWidth=1.4;fontSize=11;"
    "fontFamily=Courier New;labelBackgroundColor=#ffffff;"
)


def sel(id_: str, src: str, tgt: str, label: str, extra: str = "") -> str:
    return (
        f'        <mxCell id="{id_}" edge="1" parent="1" source="{src}" '
        f'target="{tgt}" style="{GAYA}{extra}" value="{label}">\n'
        f'          <mxGeometry relative="1" as="geometry">\n'
        f'            <mxPoint as="offset" />\n'
        f'          </mxGeometry>\n'
        f'        </mxCell>\n'
    )


ARUS_BARU = [
    sel("arus_user_refund_ctx", USER, SISTEM,
        "Pengajuan Refund Tiket",
        "exitX=1.0;exitY=0.47;exitDx=0;exitDy=0;"),

    sel("arus_admin_refund_ctx", ADMIN, SISTEM,
        "Keputusan Refund",
        "exitX=0.0;exitY=0.47;exitDx=0;exitDy=0;"),

    # tanpa entryX/entryY -> draw.io pilih perimeter kosong sendiri
    sel("arus_notif_ctx", SISTEM, USER,
        "Notifikasi Transaksi &amp; Tiket"),
]


def main() -> None:
    teks = io.open(BERKAS, encoding="utf-8").read()

    if "arus_user_refund_ctx" in teks:
        print("Sudah pernah dijalankan — tidak diulang.")
        return

    i = teks.find('<diagram name="Context Diagram"')
    if i < 0:
        raise SystemExit("Halaman 'Context Diagram' tidak ditemukan.")
    j = teks.find("</root>", i)
    if j < 0:
        raise SystemExit("</root> halaman Context Diagram tidak ditemukan.")

    teks = teks[:j] + "".join(ARUS_BARU) + teks[j:]
    io.open(BERKAS, "w", encoding="utf-8", newline="\n").write(teks)

    halaman = teks[i:teks.find("</diagram>", i)]
    print(f"3 arus ditambahkan ke Context Diagram")
    print(f"  edge halaman ini: {len(re.findall(chr(34) + 'edge=1' + chr(34), halaman))}")


if __name__ == "__main__":
    main()
