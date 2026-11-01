"""
Sisipkan dua flowchart ke Bab III Makalah Multimedia.

Mengganti paragraf penanda:
  [GAMBAR 3.1  FLOWCHART ALUR PENGGUNA — sisipkan di sini]
  [GAMBAR 3.2  FLOWCHART ALUR ADMIN — sisipkan di sini]

dengan gambar asli, di paragraf yang sama (posisi tidak bergeser).
Gambar diratakan tengah, lebar 10,5 cm agar muat satu halaman A4 dan
kedua gambar tampil dengan skala sama (rasio keduanya 0,704).
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm

AKAR = Path(__file__).resolve().parents[2]
BERKAS = AKAR / "Makalah Multimedia.docx"

GAMBAR = [
    ("[GAMBAR 3.1", AKAR / "docs/mockup/flow/flow_pengguna_final.png",
     "Flowchart Alur Pengguna"),
    ("[GAMBAR 3.2", AKAR / "docs/mockup/flow/flow_admin_final.png",
     "Flowchart Alur Admin"),
]

LEBAR = Cm(10.5)


def main() -> None:
    doc = Document(str(BERKAS))

    for penanda, path, nama in GAMBAR:
        if not path.exists():
            print(f"  !! gambar tidak ada: {path}")
            return

        target = None
        for par in doc.paragraphs:
            if par.text.strip().startswith(penanda):
                target = par
                break

        if target is None:
            print(f"  !! penanda {penanda} tidak ditemukan")
            return

        # hapus isi paragraf (teks penanda) lalu sisipkan gambar
        for r in list(target.runs):
            r._element.getparent().remove(r._element)
        target.alignment = WD_ALIGN_PARAGRAPH.CENTER
        target.add_run().add_picture(str(path), width=LEBAR)
        print(f"  {nama}: disisipkan ({path.stat().st_size // 1024} KB)")

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    teks = "\n".join(p.text for p in d.paragraphs)
    print("\n=== VERIFIKASI ===")
    print(f"  paragraf     : {len(d.paragraphs)}")
    print(f"  tabel        : {len(d.tables)}")
    print(f"  gambar       : {len(d.inline_shapes)}")
    print(f"  sisa penanda GAMBAR 3.1/3.2: "
          f"{'MASIH ADA' if '[GAMBAR 3.1' in teks or '[GAMBAR 3.2' in teks else 'bersih'}")

    for n, shape in enumerate(d.inline_shapes, 1):
        print(f"    gambar {n:2}: {shape.width.cm:.1f} x {shape.height.cm:.1f} cm")


if __name__ == "__main__":
    main()
