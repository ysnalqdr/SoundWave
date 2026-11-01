"""
Perbaiki format paragraf narasi baru hasil penggantian tabel Bab III.

Paragraf baru dibuat lewat add_paragraph() sehingga tidak mewarisi format
paragraf sekitarnya: tidak ada jarak antar-paragraf dan tidak ada indentasi
baris pertama, akibatnya semua paragraf tampak menyatu.

Format yang dipakai sama dengan paragraf asli dokumen:
  rata kanan-kiri (justify), jarak bawah 8 pt, indentasi baris pertama 1,27 cm,
  spasi baris 1,5.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm, Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"

# awalan teks paragraf yang perlu diformat
AWALAN = [
    "Tahap pertama adalah concept",
    "Tahap kedua adalah design",
    "Tahap ketiga adalah material collecting",
    "Tahap keempat adalah assembly",
    "Tahap kelima adalah testing",
    "Tahap keenam adalah distribution",
    "Aplikasi menyediakan delapan kebutuhan fungsional",
    "Aplikasi menyediakan enam kebutuhan fungsional",
    "Ketersediaan menuntut aplikasi",
    "Empat layar pertama melayani",
    "Enam layar berikutnya melayani",
    "Dua layar berikutnya melayani",
    "Empat layar terakhir melayani",
]


def main() -> None:
    doc = Document(str(BERKAS))
    n = 0
    for par in doc.paragraphs:
        t = par.text.strip()
        if not any(t.startswith(a) for a in AWALAN):
            continue
        pf = par.paragraph_format
        par.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        pf.space_before = Pt(0)
        pf.space_after = Pt(8)
        pf.first_line_indent = Cm(1.27)
        pf.line_spacing = 1.5
        n += 1

    doc.save(str(BERKAS))
    print(f"paragraf diformat: {n}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    print("\n=== CEK FORMAT ===")
    for par in d.paragraphs:
        t = par.text.strip()
        if any(t.startswith(a) for a in AWALAN):
            pf = par.paragraph_format
            print(f"  {t[:44]:46} after={pf.space_after.pt if pf.space_after else '-'}pt "
                  f"indent={pf.first_line_indent.cm if pf.first_line_indent else '-'}cm "
                  f"align={par.alignment}")

    print(f"\nparagraf: {len(d.paragraphs)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")


if __name__ == "__main__":
    main()
