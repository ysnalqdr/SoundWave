"""
TAHAP 6 — Bangun ulang DAFTAR ISI lengkap dengan nomor halaman asli.

Nomor halaman diambil dari pengukuran Word (bukan perkiraan):
  halaman fisik 4 = halaman tercetak 1  (sampul, kata pengantar, daftar isi
  memakai angka romawi i, ii, iii)

Gaya: tab-stop rata kanan + dot leader, sehingga titik-titik dan nomor
halaman lurus sempurna tanpa spasi manual.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_TAB_ALIGNMENT, WD_TAB_LEADER
from docx.shared import Cm, Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"
POSISI_TAB = Cm(14.0)

# (teks, halaman, indentasi_cm, tebal)
ENTRI: list[tuple[str, str, float, bool]] = [
    ("HALAMAN JUDUL", "i", 0.0, True),
    ("KATA PENGANTAR", "ii", 0.0, True),
    ("DAFTAR ISI", "iii", 0.0, True),
    ("BAB I   PENDAHULUAN", "1", 0.0, True),
    ("1.1   Latar Belakang", "1", 0.75, False),
    ("1.2   Rumusan Masalah", "3", 0.75, False),
    ("1.3   Batasan Masalah", "3", 0.75, False),
    ("1.4   Tujuan dan Manfaat", "4", 0.75, False),
    ("1.4.1   Tujuan", "4", 1.5, False),
    ("1.4.2   Manfaat", "4", 1.5, False),
    ("BAB II   LANDASAN TEORI", "5", 0.0, True),
    ("2.1   Definisi Sistem Multimedia", "5", 0.75, False),
    ("2.2   Teknologi Terkait", "6", 0.75, False),
    ("2.2.1   Flutter", "6", 1.5, False),
    ("2.2.2   Firebase", "6", 1.5, False),
    ("2.2.3   Midtrans", "7", 1.5, False),
    ("2.2.4   Animasi Lottie", "7", 1.5, False),
    ("2.2.5   Pemutar Audio dan Video", "7", 1.5, False),
    ("2.2.6   Proyeksi Tiga Dimensi pada Kanvas", "8", 1.5, False),
    ("2.3   Software dan Hardware", "8", 0.75, False),
    ("2.3.1   Perangkat Lunak", "8", 1.5, False),
    ("2.3.2   Perangkat Keras", "8", 1.5, False),
    ("BAB III   ANALISIS DAN PERANCANGAN", "10", 0.0, True),
    ("3.1   Analisis Kebutuhan", "10", 0.75, False),
    ("3.1.1   Penerapan Tahapan MDLC", "10", 1.5, False),
    ("3.1.2   Kebutuhan Fungsional", "11", 1.5, False),
    ("3.1.3   Kebutuhan Non-Fungsional", "11", 1.5, False),
    ("3.2   Flowchart Sistem", "12", 0.75, False),
    ("3.3   Storyboard", "15", 0.75, False),
    ("BAB IV   IMPLEMENTASI DAN PENGUJIAN", "16", 0.0, True),
    ("4.1   Implementasi Sistem", "16", 0.75, False),
    ("4.1.1   Implementasi Audio", "16", 1.5, False),
    ("4.1.2   Implementasi Video", "16", 1.5, False),
    ("4.1.3   Implementasi Animasi", "17", 1.5, False),
    ("4.1.4   Implementasi Objek Tiga Dimensi", "17", 1.5, False),
    ("4.1.5   Implementasi Pembayaran", "18", 1.5, False),
    ("4.2   Tampilan Antarmuka", "18", 0.75, False),
    ("4.3   Pengujian Black Box", "35", 0.75, False),
    ("4.4   Analisis Hasil", "36", 0.75, False),
    ("BAB V   PENUTUP", "38", 0.0, True),
    ("5.1   Kesimpulan", "38", 0.75, False),
    ("5.2   Saran", "38", 0.75, False),
    ("DAFTAR PUSTAKA", "39", 0.0, True),
]


def main() -> None:
    doc = Document(str(BERKAS))
    paras = doc.paragraphs
    i_judul = next(i for i, p in enumerate(paras) if p.text.strip() == "DAFTAR ISI")

    # entri lama = paragraf bertitik setelah judul
    lama = []
    for p in paras[i_judul + 1:]:
        if "....." in p.text:
            lama.append(p)
        elif p.text.strip():
            break
    print(f"entri lama: {len(lama)}  |  entri baru: {len(ENTRI)}")

    # jangkar: paragraf yang selalu jadi titik sisip, supaya entri baru
    # tetap berurutan (insert_paragraph_before menyisipkan tepat sebelum jangkar)
    jangkar = lama[-1]

    for idx, (teks, hal, indent, tebal) in enumerate(ENTRI):
        if idx < len(lama):
            p = lama[idx]
        else:
            p = jangkar.insert_paragraph_before("")
            lama.append(p)

        for r in list(p.runs):
            r._element.getparent().remove(r._element)

        pf = p.paragraph_format
        pf.left_indent = Cm(indent)
        pf.space_before = Pt(0)
        pf.space_after = Pt(4)
        pf.line_spacing = 1.0
        pf.tab_stops.clear_all()
        pf.tab_stops.add_tab_stop(POSISI_TAB, WD_TAB_ALIGNMENT.RIGHT, WD_TAB_LEADER.DOTS)

        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        run = p.add_run(f"{teks}\t{hal}")
        run.font.name = FONT
        run.font.size = Pt(12)
        run.font.bold = tebal

    # hapus sisa entri lama
    for p in lama[len(ENTRI):]:
        p._element.getparent().remove(p._element)

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    ps = d.paragraphs
    j = next(i for i, p in enumerate(ps) if p.text.strip() == "DAFTAR ISI")
    print("\n=== DAFTAR ISI BARU ===")
    n = 0
    for p in ps[j + 1:]:
        t = p.text.strip()
        if not t:
            break
        n += 1
        print(f"  {t}")
    print(f"\n  total entri: {n}")
    print(f"  paragraf: {len(ps)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")


if __name__ == "__main__":
    main()
