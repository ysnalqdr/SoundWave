"""
TAHAP 1 — Ganti Daftar Pustaka: 13 entri lama -> 10 entri final.

Kriteria yang dipenuhi (lihat 10_REFERENSI_FINAL.md):
  PDF tersedia · tautan aktif · akses terbuka · sesuai isi proyek ·
  terbit maksimal 5 tahun terakhir (2021-2026).

Yang dikeluarkan:
  Biørn-Hansen dkk. (2019)  -> 7 tahun, lewat batas
  Supriyono (2020)          -> 6 tahun, lewat batas
  Hasibuan & Triase (2022)  -> PDF 403, tidak bisa diunduh
  Fauzi dkk. (2025)         -> digantikan Anmi (topik lebih dekat)
  Kusumapratiwi & Waluyo (2023) -> digantikan Fadhilah (topik ticketing konser)
  Putra Kang & Fauzi (2025) -> topik animasi 3D kedokteran gigi, jauh
  Syahputra dkk. (2023)     -> topik animasi 3D kedokteran gigi, jauh
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.shared import Cm, Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

PUSTAKA = [
    "Anmi, F. H., Jazman, M., Anofrizen, A., Saputra, E., Siregar, S., & Ahsyar, T. K. "
    "(2025). Implementation of Flutter and Firebase technologies in modern live streaming "
    "application development. JOISIE (Journal of Information System and Informatics "
    "Engineering), 9(1), 246. https://doi.org/10.35145/joisie.v9i1.4808",

    "Fadhilah, T. N., Nurvaliza, F., & Absharina, E. D. (2025). Analisis dan perancangan "
    "sistem informasi pemesanan tiket konser online berbasis terstruktur. Jurnal Ilmiah "
    "Kajian Multidisipliner, 9(6), 43\u201357. "
    "https://oaj.jurnalhst.com/index.php/jikm/article/view/11869",

    "Habibi, A., & Athoillah, M. I. (2024). Pengembangan sistem pemesanan tiket konser "
    "berbasis web untuk meningkatkan pengalaman pengguna. Jurnal Penelitian Teknologi "
    "Informasi dan Sains, 2(1), 13\u201321. https://doi.org/10.54066/jptis.v2i1.1635",

    "Ikhwan, A., Amanda, N., Sinaga, N., & Batubara, N. R. (2026). Pengembangan multimedia "
    "interaktif edukasi internet sehat menggunakan metode Multimedia Development Life Cycle "
    "(MDLC). Journal of Society and Scientific Studies, 2(3), 13\u201324. "
    "https://doi.org/10.62504/scientiva42",

    "Kusumarini, C. D., & Avito, R. F. (2025). Creation of an Android-based AM Futsal field "
    "rental application using Flutter and JS Node with Midtrans integration as a payment "
    "gateway. GLOBAL: Jurnal Lentera BITEP, 3(1), 17\u201325. "
    "https://doi.org/10.59422/global.v3i01.745",

    "Lendo, R., Jacobus, A., & Mapaly, H. A. (2023). Rancang bangun aplikasi perpustakaan "
    "digital berbasis mobile menggunakan framework Flutter. Jurnal Teknik Informatika, "
    "18(1), 353\u2013362. https://doi.org/10.35793/jti.v18i1.50490",

    "Margaretha, J., & Voutama, A. (2023). Perancangan sistem informasi pemesanan tiket "
    "konser musik berbasis web menggunakan Unified Modeling Language (UML). Journal of "
    "Information System, 8(1), 20\u201331. https://doi.org/10.33633/joins.v8i1.7107",

    "Nariswari, A. I., Sumiati, Hay's, R. N., & Repi, V. V. R. (2023). Rancang bangun sistem "
    "e-ticket berbasis payment gateway. JSiI (Jurnal Sistem Informasi), 10(2), 137\u2013141. "
    "https://doi.org/10.30656/jsii.v10i2.8183",

    "Pratama, A., Ferbiyanto, A., Alfianto, M. R., Almubarok, R., Sediyawan, F., Aisyah, S., "
    "& Faisal, M. (2025). Aplikasi tiket online web dengan validasi QR Code sekali pakai "
    "menggunakan metode Waterfall. BIIKMA (Buletin Ilmiah Ilmu Komputer dan Multimedia), "
    "3(2), 215\u2013218. https://jurnalmahasiswa.com/index.php/biikma/article/view/2697",

    "Rosmiati, R. (2021). Analisis dan pengujian sistem menggunakan black box testing "
    "equivalence partitioning. Jurnal Sains Komputer dan Teknologi Informasi, 3(2), "
    "56\u201363. https://doi.org/10.33084/jsakti.v3i2.1932",
]


def main() -> None:
    doc = Document(str(BERKAS))
    paras = doc.paragraphs

    i_judul = next(i for i, p in enumerate(paras) if p.text.strip() == "DAFTAR PUSTAKA")
    print(f"'DAFTAR PUSTAKA' di paragraf {i_judul}")

    # entri lama = paragraf sesudah judul yang tidak kosong
    lama = []
    for p in paras[i_judul + 1:]:
        if p.text.strip():
            lama.append(p)
        elif lama:
            break
    print(f"entri lama: {len(lama)}  |  entri baru: {len(PUSTAKA)}")

    # tulis ulang entri yang ada
    for idx, teks in enumerate(PUSTAKA):
        if idx < len(lama):
            p = lama[idx]
        else:
            p = lama[-1].insert_paragraph_before("")
            lama.append(p)

        for r in list(p.runs):
            r._element.getparent().remove(r._element)

        pf = p.paragraph_format
        pf.left_indent = Cm(1.0)
        pf.first_line_indent = Cm(-1.0)      # hanging indent APA
        pf.space_after = Pt(6)
        pf.line_spacing = 1.0
        run = p.add_run(teks)
        run.font.name = FONT
        run.font.size = Pt(12)

    # hapus sisa entri lama
    for p in lama[len(PUSTAKA):]:
        p._element.getparent().remove(p._element)

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    ps = [p.text.strip() for p in d.paragraphs]
    j = next(i for i, t in enumerate(ps) if t == "DAFTAR PUSTAKA")
    entri = [t for t in ps[j + 1:] if t]
    print(f"\n=== VERIFIKASI: {len(entri)} entri ===")
    for n, e in enumerate(entri, 1):
        print(f"  {n:2}. {e[:88]}")
    print(f"\nparagraf: {len(d.paragraphs)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")

    # cek nama yang seharusnya hilang
    teks = "\n".join(ps)
    for nama in ("Biørn-Hansen", "Supriyono", "Hasibuan", "Fauzi, S. N.",
                 "Kusumapratiwi", "Putra Kang", "Syahputra"):
        print(f"  sisa '{nama}': {'MASIH ADA' if nama in teks else 'bersih'}")


if __name__ == "__main__":
    main()
