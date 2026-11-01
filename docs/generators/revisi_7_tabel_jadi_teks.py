"""
Ubah Tabel 2.2 dan Tabel 2.3 pada sub-bab 2.3 menjadi narasi teks.

Tabel 2.2 (perangkat lunak, 9 baris) dan Tabel 2.3 (perangkat keras, 8 baris)
dihapus, isinya dipindahkan ke paragraf naratif dengan pola SPOK.
Caption "Tabel 2.2" dan "Tabel 2.3" ikut dihapus karena tabelnya tidak ada lagi.
Rujukan "pada Tabel 2.2/2.3" di paragraf pengantar diganti kalimat baru.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.oxml.ns import qn
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

TEKS_LUNAK = (
    "Penulis menggunakan sembilan perangkat lunak dalam pengembangan aplikasi SoundWave. "
    "Pertama, sistem operasi Windows 11 Home Single Language versi 64-bit sebagai lingkungan "
    "pengembangan. Kedua, kerangka kerja Flutter 3.47.6 versi stable untuk membangun antarmuka "
    "aplikasi. Ketiga, bahasa Dart untuk menuliskan logika aplikasi. Keempat, editor kode Visual "
    "Studio Code dan Android Studio untuk menulis serta menjalankan kode. Kelima, basis data "
    "Cloud Firestore untuk menyimpan data aplikasi. Keenam, backend Node.js dengan Express untuk "
    "menangani transaksi pembayaran. Ketujuh, payment gateway Midtrans dalam mode sandbox untuk "
    "memproses pembayaran. Kedelapan, draw.io untuk membuat flowchart, ERD, dan DFD. Kesembilan, "
    "Mendeley dengan gaya APA edisi ke-7 untuk mengelola sitasi dan daftar pustaka."
)

TEKS_KERAS = (
    "Penulis menggunakan satu laptop HP Laptop 14s-dk1xxx sebagai perangkat pengembangan dan "
    "pengujian. Perangkat ini memakai prosesor AMD Ryzen 3 3250U with Radeon Graphics dengan dua "
    "inti dan empat thread. Memori yang tersedia sebesar 8 GB, dan 5,9 GB di antaranya dapat "
    "dipakai sistem. Kartu grafis yang digunakan adalah AMD Radeon Graphics terintegrasi. "
    "Penyimpanan terdiri atas SSD NVMe berkapasitas 256 GB dan HDD berkapasitas 1 TB. Sistem "
    "operasi yang dipakai adalah Windows 11 Home Single Language versi 64-bit. Untuk pengujian "
    "pada perangkat bergerak, penulis memakai [MEREK DAN TIPE HP ANDROID] dengan sistem operasi "
    "[VERSI ANDROID]."
)


def isi_ulang(par, teks: str) -> None:
    for r in list(par.runs):
        r._element.getparent().remove(r._element)
    run = par.add_run(teks)
    run.font.name = FONT
    run.font.size = Pt(12)


def teks_par(el) -> str:
    return "".join(n.text or "" for n in el.iter(qn("w:t"))).strip()


def main() -> None:
    doc = Document(str(BERKAS))
    body = doc.element.body

    # ---------- 1. ganti paragraf pengantar ----------
    n_ubah = 0
    for par in doc.paragraphs:
        t = par.text.strip()
        if t.startswith("Penulis merangkum perangkat lunak"):
            isi_ulang(par, TEKS_LUNAK)
            n_ubah += 1
        elif t.startswith("Penulis merangkum perangkat keras"):
            isi_ulang(par, TEKS_KERAS)
            n_ubah += 1
    print(f"paragraf pengantar diganti: {n_ubah}")

    # ---------- 2. hapus kedua tabel + caption-nya ----------
    anak = list(body.iterchildren())
    hapus = []
    for i, el in enumerate(anak):
        if el.tag != qn("w:tbl"):
            continue
        baris = el.findall(qn("w:tr"))
        if not baris:
            continue
        sel_awal = [teks_par(tc) for tc in baris[0].findall(qn("w:tc"))]
        kepala = sel_awal[0] if sel_awal else ""

        if kepala not in ("Kategori", "Perangkat"):
            continue

        hapus.append(el)
        print(f"  tabel '{kepala}' ditandai hapus ({len(baris)} baris)")

        # caption sesudah tabel: "Tabel 2.2 ..." / "Tabel 2.3 ..."
        for j in range(i + 1, min(i + 3, len(anak))):
            if anak[j].tag == qn("w:p"):
                if teks_par(anak[j]).startswith("Tabel 2."):
                    hapus.append(anak[j])
                    print(f"    caption dihapus: {teks_par(anak[j])[:50]}")
                break

    for el in hapus:
        el.getparent().remove(el)

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    print(f"\ntabel  : {len(d.tables)}  (sebelumnya 10)")
    print(f"gambar : {len(d.inline_shapes)}")
    print(f"paragraf: {len(d.paragraphs)}")

    ps = [p.text.strip() for p in d.paragraphs]
    i = next(k for k, t in enumerate(ps) if t.startswith("2.3  Software"))
    print("\n=== SUB-BAB 2.3 SEKARANG ===")
    for t in ps[i:i + 7]:
        if t:
            print(f"\n{t}")

    teks = "\n".join(ps)
    print("\n=== CEK ===")
    for k in ("Tabel 2.2", "Tabel 2.3", "Kategori", "Spesifikasi"):
        print(f"  '{k}': {teks.count(k)}")


if __name__ == "__main__":
    main()
