"""
Sisipkan 18 screenshot ke Makalah Multimedia.docx, menggantikan penanda.

Sumber gambar: C:\\Users\\HP\\Downloads\\SS
Target: paragraf penanda [GAMBAR 4.x ...] di Bab IV 4.2

Cara kerja:
  1. Cari paragraf yang memuat penanda "[GAMBAR 4.x"
  2. Hapus teks penanda, ganti dengan gambar
  3. Caption di paragraf berikutnya dibiarkan (sudah ada)
  4. Lebar gambar diseragamkan agar muat di halaman (area teks ±10,5 cm)

Jalankan: python docs/generators/sisip_screenshot.py
"""

from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
SUMBER = Path(r"C:\Users\HP\Downloads\SS")

# nomor gambar -> nama berkas di folder SS
PETA = {
    "4.1": "Jelajah.jpeg",
    "4.2": "Detail Atas.jpeg",
    "4.3": "Detail Audio.jpeg",
    "4.4": "Detail Trailer.jpeg",
    "4.5": "Detail 3D.jpeg",
    "4.6": "Pilih Tiket.jpeg",
    "4.7": "Checkout Metode.jpeg",
    "4.8": "Checkout Bayar.jpeg",
    "4.9": "Checkout Konfirmasi.jpeg",
    "4.10": "Loading.jpeg",
    "4.11": "Berhasil.jpeg",
    "4.12": "Tiket Saya.jpeg",
    "4.13": "Diskon Saya.jpeg",
    "4.14": "Dashboard Admin.jpeg",
    "4.15": "Form Konser.jpeg",
    "4.16": "Scanner.jpeg",
    "4.17": "Scan berhasil.jpeg",
    "4.18": "Scan gagal.jpeg",
}

# gambar potret dan lanskap butuh lebar berbeda agar tingginya wajar
LEBAR_POTRET = Cm(6.2)
LEBAR_LANSKAP = Cm(10.5)


def main() -> None:
    doc = Document(str(BERKAS))

    dipasang = []
    gagal = []

    for par in doc.paragraphs:
        teks = par.text.strip()
        m = re.match(r"\[GAMBAR (4\.\d+)", teks)
        if not m:
            continue

        nomor = m.group(1)
        nama = PETA.get(nomor)
        if not nama:
            gagal.append((nomor, "tidak ada di peta"))
            continue

        jalur = SUMBER / nama
        if not jalur.exists():
            gagal.append((nomor, f"berkas tidak ada: {nama}"))
            continue

        # bersihkan paragraf penanda
        for r in list(par.runs):
            r._element.getparent().remove(r._element)
        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
        par.paragraph_format.space_before = Cm(0.3)
        par.paragraph_format.space_after = Cm(0.15)
        par.paragraph_format.first_line_indent = Cm(0)

        # potret atau lanskap?
        from PIL import Image
        with Image.open(jalur) as im:
            w, h = im.size
        lebar = LEBAR_POTRET if h > w else LEBAR_LANSKAP

        par.add_run().add_picture(str(jalur), width=lebar)
        dipasang.append((nomor, nama, f"{w}x{h}", "potret" if h > w else "lanskap"))

    doc.save(str(BERKAS))

    print(f"tersimpan: {BERKAS}")
    print(f"  berhasil dipasang: {len(dipasang)}/18")
    for n, nama, dim, orient in dipasang:
        print(f"    {n:5} {nama:26} {dim:10} {orient}")
    if gagal:
        print("  GAGAL:")
        for n, alasan in gagal:
            print(f"    {n}: {alasan}")


if __name__ == "__main__":
    main()
