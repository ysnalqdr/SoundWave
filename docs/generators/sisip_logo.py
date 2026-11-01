"""
Sisipkan logo BSI ke halaman judul Makalah Multimedia.docx.

Menempati paragraf kosong yang sudah disiapkan di antara
"Dosen Pembimbing" dan "Disusun oleh".

Ukuran: lebar 3,2 cm (tinggi mengikuti rasio, logo persegi jadi 3,2 x 3,2 cm).
Dengan ukuran ini halaman judul tetap muat satu halaman.

Jalankan: python docs/generators/sisip_logo.py
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
LOGO = Path(__file__).resolve().parents[2] / "assets" / "images" / "logo" / "logo-bsi.png"

LEBAR = Cm(3.2)


def main() -> None:
    if not LOGO.exists():
        raise SystemExit(f"Logo tidak ditemukan: {LOGO}")

    doc = Document(str(BERKAS))

    # ---- cari paragraf kosong di antara Dosen Pembimbing dan Disusun oleh ----
    paras = doc.paragraphs
    idx_dosen = idx_disusun = None

    for i, par in enumerate(paras):
        t = par.text.strip()
        if t.lower().startswith("dosen pembimbing"):
            idx_dosen = i
        elif t.lower().startswith("disusun oleh"):
            idx_disusun = i
            break

    if idx_dosen is None or idx_disusun is None:
        raise SystemExit("Struktur halaman judul tidak dikenali.")

    target = None
    for i in range(idx_dosen + 1, idx_disusun):
        if not paras[i].text.strip():
            target = paras[i]
            break

    if target is None:
        # tidak ada paragraf kosong -> buat baru sebelum "Disusun oleh"
        target = doc.add_paragraph()
        paras[idx_disusun]._element.addprevious(target._element)

    # ---- bersihkan lalu pasang gambar ----
    for r in list(target.runs):
        r._element.getparent().remove(r._element)

    target.alignment = WD_ALIGN_PARAGRAPH.CENTER
    pf = target.paragraph_format
    pf.space_before = Cm(0.4)
    pf.space_after = Cm(0.6)
    pf.line_spacing = 1.0
    pf.first_line_indent = Cm(0)

    target.add_run().add_picture(str(LOGO), width=LEBAR)

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")
    print(f"  logo dipasang: {LOGO.name}  lebar {LEBAR.cm:.1f} cm")


if __name__ == "__main__":
    main()
