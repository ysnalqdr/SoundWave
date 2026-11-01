"""
Perbaiki daftar pustaka Makalah Multimedia.docx.

TIGA MASALAH YANG DIPERBAIKI
  1. Maftoha & Oktavira (2025) diganti Anmi dkk. (2025).
     Jurnal Maftoha tidak menyediakan PDF sama sekali: tidak ada tombol unduh,
     tidak ada galley, dan tidak ada berkas PDF di servernya. Referensi yang
     tidak bisa diunduh pembaca tidak layak dipakai.

  2. Rosmiati (2021) DITAMBAHKAN.
     Sudah disitasi di Bab IV 4.3 tetapi belum ada di daftar pustaka.

  3. Suharsih dkk. (2021) DITAMBAHKAN.
     Sudah disitasi di Bab IV 4.4 tetapi belum ada di daftar pustaka.

Hasil: 13 entri, urut alfabet, semua punya PDF.

Jalankan: python docs/generators/perbaiki_daftar_pustaka.py
"""

from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm, Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

PUSTAKA = [
    "Anmi, F. H., Jazman, M., Anofrizen, A., Saputra, E., Siregar, S., & "
    "Ahsyar, T. K. (2025). Implementation of Flutter and Firebase technologies "
    "in modern live streaming application development. JOISIE (Journal of "
    "Information Systems and Informatics Engineering), 9(1), 246. "
    "https://doi.org/10.35145/joisie.v9i1.4808",

    "Biørn-Hansen, A., Grønli, T.-M., & Ghinea, G. (2019). Animations in "
    "cross-platform mobile applications: An evaluation of tools, metrics and "
    "performance. Sensors, 19(9), 2081. https://doi.org/10.3390/s19092081",

    "Fauzi, S. N., Yulisusianto, G., & Setiawan, R. B. (2025). Implementasi "
    "database realtime pada aplikasi E-Siku berbasis Firebase. Jurnal "
    "Telkommil, 6(1), 7–25. https://doi.org/10.54317/kom.v6i1.559",

    "Hasibuan, M. I. Z., & Triase, T. (2022). Implementasi sistem database "
    "NoSQL secara realtime menggunakan Firebase Realtime Database pada aplikasi "
    "OurtIcle. SIBATIK JOURNAL, 2(1), 1–24. "
    "https://doi.org/10.54443/sibatik.v2i1.489",

    "Ikhwan, A., Amanda, N., Sinaga, N., & Batubara, N. R. (2026). Pengembangan "
    "multimedia interaktif edukasi internet sehat menggunakan metode Multimedia "
    "Development Life Cycle (MDLC). Journal of Society and Scientific Studies, "
    "2(3), 13–24. https://doi.org/10.62504/scientiva42",

    "Kusumarini, C. D., & Avito, R. F. (2025). Creation of an Android-based AM "
    "Futsal field rental application using Flutter and JS Node with Midtrans "
    "integration as a payment gateway. GLOBAL: Jurnal Lentera BITEP, 3(01), "
    "17–25. https://doi.org/10.59422/global.v3i01.745",

    "Kusumapratiwi, A. C., & Waluyo, A. F. (2023). Mobile application for bus "
    "ticket booking effectiveness. International Journal of Computer "
    "Applications, 185(39), 9–16. https://doi.org/10.5120/ijca2023923195",

    "Lendo, R., Jacobus, A., & Mapaly, H. A. (2023). Rancang bangun aplikasi "
    "perpustakaan digital berbasis mobile menggunakan framework Flutter. Jurnal "
    "Teknik Informatika, 18(1), 353–362. "
    "https://doi.org/10.35793/jti.v18i1.50490",

    "Putra Kang, A., & Fauzi, R. (2025). Perancangan animasi 3D edukatif tentang "
    "modus penipuan WhatsApp dengan metode MDLC. Computer and Science Industrial "
    "Engineering (COMASIE), 13(4), 21–29. "
    "https://doi.org/10.33884/comasiejournal.v13i4.10470",

    "Rosmiati, R. (2021). Analisis dan pengujian sistem menggunakan black box "
    "testing equivalence partitioning. Jurnal Sains Komputer dan Teknologi "
    "Informasi, 3(2), 56–63. https://doi.org/10.33084/jsakti.v3i2.1932",

    "Suharsih, R., Febriani, R., & Triputra, S. (2021). Usability of Jawara "
    "Sains mobile learning application using System Usability Scale (SUS). "
    "Jurnal Online Informatika, 6(1), 41–52. "
    "https://doi.org/10.15575/join.v6i1.700",

    "Supriyono, H. (2020). Android mobile augmented reality application for 3D "
    "visualization of museum collectibles in Surakarta. International Journal of "
    "Emerging Trends in Engineering Research, 8(8), 4293–4300. "
    "https://doi.org/10.30534/ijeter/2020/40882020",

    "Tulus, A., Sitompul, N., Mulyanto, U. H., Wijaya, V., Fiermeiza, N. A., & "
    "Wahyuni, S. (2026). Perancangan animasi 3D jalan Bypass Sedau ke Sei Rasau "
    "menggunakan metode MDLC. Rabit: Jurnal Teknologi dan Sistem Informasi "
    "Univrab, 11(2), 3850–3864. https://doi.org/10.36341/rabit.v11i2.8198",
]


def main() -> None:
    doc = Document(str(BERKAS))

    # ---------- 1. ganti sitasi Maftoha -> Anmi dalam teks ----------
    n = 0
    for par in doc.paragraphs:
        teks = par.text
        if "Maftoha" not in teks:
            continue
        if "fldChar" in par._element.xml:
            continue
        baru = (teks.replace("Maftoha & Oktavira, 2025", "Anmi dkk., 2025")
                    .replace("Maftoha", "Anmi"))
        for r in list(par.runs):
            r._element.getparent().remove(r._element)
        r = par.add_run(baru)
        r.font.name = FONT
        r.font.size = Pt(12)
        n += 1
    print(f"  sitasi Maftoha -> Anmi: {n} paragraf")

    # ---------- 3. cari batas daftar pustaka ----------
    # Daftar pustaka ada di AKHIR dokumen. Yang dihapus hanya paragraf yang
    # benar-benar berupa entri pustaka (berpola "Nama, X. (Tahun)."), bukan
    # semua paragraf sesudah judul — itu pernah menghapus seluruh Bab III-V.
    paras = doc.paragraphs
    idx_judul = None
    for i, par in enumerate(paras):
        if par.text.strip() == "DAFTAR PUSTAKA":
            idx_judul = i
            break

    if idx_judul is None:
        raise SystemExit("Judul DAFTAR PUSTAKA tidak ditemukan")

    pola_entri = re.compile(r"^[A-ZÀ-Ý][^.]{1,60},\s.*\(\d{4}\)\.")

    dihapus = 0
    for par in paras[idx_judul + 1:]:
        if pola_entri.match(par.text.strip()):
            el = par._element
            if el.getparent() is not None:
                el.getparent().remove(el)
                dihapus += 1
    print(f"  entri lama dihapus: {dihapus}")

    # ---------- 4. tulis ulang 13 entri ----------
    anchor = paras[idx_judul]._element
    sebelumnya = anchor
    for s in PUSTAKA:
        par = doc.add_paragraph()
        par.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        pf = par.paragraph_format
        pf.line_spacing = 1.0
        pf.left_indent = Cm(1.27)
        pf.first_line_indent = Cm(-1.27)
        pf.space_after = Pt(8)
        r = par.add_run(s)
        r.font.name = FONT
        r.font.size = Pt(12)
        sebelumnya.addnext(par._element)
        sebelumnya = par._element

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")
    print(f"  {len(PUSTAKA)} entri daftar pustaka")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    teks_semua = " ".join(p.text for p in d.paragraphs)
    print("\n=== VERIFIKASI ===")
    print("sisa 'Maftoha':", "ADA" if "Maftoha" in teks_semua else "TIDAK ADA")
    for nama in ["Anmi", "Rosmiati", "Suharsih", "Pirdaus"]:
        print(f"  {nama:12} disebut={teks_semua.count(nama)}")


if __name__ == "__main__":
    main()
