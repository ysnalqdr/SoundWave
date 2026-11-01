"""
TAHAP 4b — Perbaikan: paragraf bernomor (Bab V) yang terlewat di tahap 4.

Paragraf bernomor diawali "1.\t" sehingga pencocokan awalan teks gagal.
Skrip ini mencocokkan dengan membuang awalan nomor lebih dahulu, lalu
menulis ulang isinya sambil MEMPERTAHANKAN nomor dan gaya paragraf.
"""

from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

# (potongan_kunci, teks_baru_tanpa_nomor)
GANTI: list[tuple[str, str]] = [
    ("Metode Multimedia Development Life Cycle berhasil diterapkan",
     "Penulis berhasil menerapkan metode Multimedia Development Life Cycle pada pengembangan "
     "aplikasi ticketing konser berbasis mobile. Keenam tahapnya, yaitu concept, design, "
     "material collecting, assembly, testing, dan distribution, terpetakan dengan jelas pada "
     "pekerjaan yang dilakukan. Tahap material collecting terbukti penting karena aplikasi "
     "bergantung pada aset multimedia yang harus dikumpulkan dan diverifikasi lisensinya lebih "
     "dahulu."),

    ("Kelima elemen multimedia berhasil diintegrasikan",
     "Penulis berhasil mengintegrasikan kelima elemen multimedia sebagai bagian dari alur "
     "pengguna, bukan sebagai hiasan. Cuplikan audio membantu pengguna mengenal karya penampil "
     "sebelum membeli. Trailer memberi gambaran suasana konser. Animasi menandai status sistem. "
     "Visualisasi panggung memberi bayangan tata venue."),

    ("Visualisasi panggung tiga dimensi dapat diimplementasikan",
     "Penulis dapat mengimplementasikan visualisasi panggung tiga dimensi tanpa mesin render "
     "berbasis peramban. Proyeksi perspektif yang dihitung pada kanvas aplikasi terbukti "
     "berjalan pada perangkat uji. Pendekatan berbasis WebGL tidak dapat diandalkan pada "
     "perangkat yang sama."),

    ("Hasil pengujian black box menunjukkan 65 dari 65",
     "Hasil pengujian black box menunjukkan 65 dari 65 kasus menghasilkan keluaran sesuai "
     "harapan. Karena itu penulis menyatakan fungsi aplikasi berjalan baik dari sisi pengguna."),

    ("Visualisasi panggung dapat ditingkatkan menjadi model tiga dimensi",
     "Penulis menyarankan peningkatan visualisasi panggung menjadi model tiga dimensi "
     "sesungguhnya yang dimuat dari berkas glTF. Peningkatan itu perlu didahului pemeriksaan "
     "ketersediaan mesin render pada perangkat sasaran."),

    ("Aplikasi dapat dikembangkan ke platform iOS",
     "Penulis menyarankan pengembangan aplikasi ke platform iOS agar jangkauan pengguna lebih "
     "luas."),

    ("Penilaian pengguna dapat dilakukan dengan jumlah responden",
     "Penulis menyarankan penilaian pengguna dilakukan dengan jumlah responden yang lebih besar "
     "dan lebih beragam agar hasilnya dapat digeneralisasi."),

    ("Fitur pencarian dapat dilengkapi dengan rekomendasi",
     "Penulis menyarankan fitur pencarian dilengkapi dengan rekomendasi berbasis riwayat "
     "pembelian pengguna."),

    ("Aspek keamanan dapat ditinjau lebih lanjut",
     "Penulis menyarankan peninjauan aspek keamanan melalui audit keamanan dan uji penetrasi "
     "sebelum aplikasi digunakan secara komersial."),
]

POLA_NOMOR = re.compile(r"^(\d+\.\t)")


def main() -> None:
    doc = Document(str(BERKAS))
    n = 0
    gagal = []

    for kunci, baru in GANTI:
        target = None
        for par in doc.paragraphs:
            if kunci in par.text and not POLA_NOMOR.match(par.text.strip()) is None:
                target = par
                break
        if target is None:
            # cari tanpa syarat nomor
            for par in doc.paragraphs:
                if kunci in par.text:
                    target = par
                    break
        if target is None:
            gagal.append(kunci[:50])
            continue

        m = POLA_NOMOR.match(target.text)
        nomor = m.group(1) if m else ""

        for r in list(target.runs):
            r._element.getparent().remove(r._element)
        run = target.add_run(nomor + baru)
        run.font.name = FONT
        run.font.size = Pt(12)
        n += 1

    doc.save(str(BERKAS))
    print(f"paragraf diperbaiki: {n}")
    if gagal:
        print("masih gagal:")
        for g in gagal:
            print("  -", g)

    d = Document(str(BERKAS))
    print(f"\nparagraf: {len(d.paragraphs)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")

    # tampilkan Bab V untuk dicek
    ps = [p.text.strip() for p in d.paragraphs]
    i = next(i for i, t in enumerate(ps) if t.startswith("5.1"))
    print("\n=== BAB V ===")
    for t in ps[i:i + 16]:
        if t:
            print(f"  {t[:150]}")


if __name__ == "__main__":
    main()
