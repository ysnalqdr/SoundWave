"""
Rapikan DAFTAR ISI pada Makalah.docx (versi pemilik).

YANG DIUBAH — hanya blok Daftar Isi (11 entri).
  - Nomor halaman disesuaikan dengan hasil pengukuran Word, bukan perkiraan.
  - Penomoran halaman memakai tab-stop + dot leader (bukan titik literal),
    sehingga titik-titik rata kanan dan nomor halaman lurus sempurna.
  - Sub-sub-bab 1.4.1 Tujuan dan 1.4.2 Manfaat ditambahkan (sebelumnya
    terlewat padahal ada di dokumen).
  - Entri "BAB II LANDASAN TEORI" dihapus karena bab itu TIDAK ADA di
    badan dokumen — hanya tertulis di daftar isi.

NOMOR HALAMAN HASIL UKUR WORD (10 halaman fisik)
  fisik 1  -> sampul                 => i
  fisik 2  -> Kata Pengantar         => ii
  fisik 3  -> Daftar Isi             => iii
  fisik 4  -> Bab I / 1.1            => 1
  fisik 6  -> 1.2 dan 1.3            => 3
  fisik 7  -> 1.4 / 1.4.1 / 1.4.2    => 4
  fisik 8  -> Daftar Pustaka         => 5
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_TAB_ALIGNMENT, WD_TAB_LEADER
from docx.shared import Cm, Pt

MASUK = Path(__file__).resolve().parents[1] / "cek" / "Makalah_user.docx"
KELUAR = Path(__file__).resolve().parents[1] / "cek" / "Makalah_daftar_isi_rapi.docx"

# (teks, halaman, indentasi_cm)
ENTRI = [
    ("HALAMAN JUDUL", "i", 0.0),
    ("KATA PENGANTAR", "ii", 0.0),
    ("DAFTAR ISI", "iii", 0.0),
    ("BAB I   PENDAHULUAN", "1", 0.0),
    ("1.1   Latar Belakang", "1", 0.75),
    ("1.2   Rumusan Masalah", "3", 0.75),
    ("1.3   Batasan Masalah", "3", 0.75),
    ("1.4   Tujuan dan Manfaat", "4", 0.75),
    ("1.4.1   Tujuan", "4", 1.5),
    ("1.4.2   Manfaat", "4", 1.5),
    ("DAFTAR PUSTAKA", "5", 0.0),
]

POSISI_TAB = Cm(14.0)          # 21 - 4 (kiri) - 3 (kanan) = 14 cm
FONT = "Times New Roman"
UKURAN = Pt(12)


def main() -> None:
    doc = Document(str(MASUK))

    # cari blok daftar isi: paragraf setelah judul "DAFTAR ISI"
    paras = doc.paragraphs
    i_judul = next(i for i, p in enumerate(paras) if p.text.strip() == "DAFTAR ISI")

    # entri = paragraf berurutan yang mengandung titik-titik
    blok = []
    for p in paras[i_judul + 1:]:
        if "....." in p.text:
            blok.append(p)
        elif p.text.strip():
            break

    print(f"entri daftar isi lama : {len(blok)}")
    print(f"entri baru            : {len(ENTRI)}")

    for idx, (teks, hal, indent) in enumerate(ENTRI):
        if idx < len(blok):
            p = blok[idx]
        else:
            # butuh paragraf baru: sisipkan setelah entri terakhir
            p = blok[-1].insert_paragraph_before("")
            blok.append(p)

        for r in list(p.runs):
            r._element.getparent().remove(r._element)

        pf = p.paragraph_format
        pf.left_indent = Cm(indent)
        pf.space_before = Pt(0)
        pf.space_after = Pt(6)
        pf.line_spacing = 1.0
        # bersihkan tab lama, pasang satu tab rata kanan berpenuntun titik
        for ts in list(pf.tab_stops):
            pf.tab_stops.clear_all()
        pf.tab_stops.add_tab_stop(POSISI_TAB, WD_TAB_ALIGNMENT.RIGHT, WD_TAB_LEADER.DOTS)

        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        run = p.add_run(f"{teks}\t{hal}")
        run.font.name = FONT
        run.font.size = UKURAN
        if teks.startswith("BAB") or teks in ("DAFTAR PUSTAKA", "HALAMAN JUDUL",
                                              "KATA PENGANTAR", "DAFTAR ISI"):
            run.font.bold = True

    # hapus sisa entri lama yang tidak terpakai
    for p in blok[len(ENTRI):]:
        p._element.getparent().remove(p._element)

    doc.save(str(KELUAR))
    print(f"tersimpan: {KELUAR}")

    # ---------- verifikasi ----------
    d = Document(str(KELUAR))
    ps = d.paragraphs
    j = next(i for i, p in enumerate(ps) if p.text.strip() == "DAFTAR ISI")
    print("\n=== DAFTAR ISI BARU ===")
    for p in ps[j + 1:]:
        t = p.text.strip()
        if not t:
            break
        print(f"  {t}")
    print(f"\nparagraf: {len(ps)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")


if __name__ == "__main__":
    main()
