"""
Kembalikan Tabel 3.4 pada sub-bab 3.3 Storyboard.

YANG DIUBAH
  1. Empat paragraf narasi hasil revisi sebelumnya dihapus.
  2. Tabel 3.4 (16 layar) dipasang kembali sebagai tabel bernomor,
     dengan caption "Tabel 3.4  Daftar Storyboard".
  3. Paragraf pengantar dikembalikan ke bentuk semula (merujuk Tabel 3.4).

Format tabel mengikuti tabel lain di dokumen: garis penuh, kepala tabel
bercetak tebal, huruf Times New Roman 11 pt agar muat di halaman.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

INTRO = (
    "Storyboard merupakan sketsa kasar antarmuka setiap layar. Penulis membuat sketsa sebelum "
    "penulisan kode untuk memastikan tata letak dan alur setiap layar telah dipikirkan. "
    "Tabel 3.4 memuat daftar enam belas layar yang digambar."
)

CAPTION = "Tabel 3.4  Daftar Storyboard"

NARASI_LAMA = [
    "Empat layar pertama melayani pembukaan dan penelusuran konser",
    "Enam layar berikutnya melayani proses pembelian tiket",
    "Dua layar berikutnya melayani tiket yang telah dibeli",
    "Empat layar terakhir melayani keperluan admin",
]

BARIS = [
    ("1", "Splash", "Animasi equalizer, logo"),
    ("2", "Masuk", "Formulir email dan kata sandi, tombol masuk"),
    ("3", "Jelajah", "Bilah pencarian, filter, kartu promo, daftar konser"),
    ("4", "Detail Konser", "Poster, pemutar audio, trailer video, panggung 3D"),
    ("5", "Pilih Tiket", "Lembar pilihan tipe tiket beserta harga"),
    ("6", "Checkout Metode", "Empat pilihan metode pembayaran"),
    ("7", "Checkout Bayar", "Formulir data pembeli dan kolom voucher"),
    ("8", "Checkout Konfirmasi", "Rincian harga dan syarat pemesanan"),
    ("9", "Memproses Pembayaran", "Animasi memuat"),
    ("10", "Pembayaran Berhasil", "Animasi confetti, kode booking"),
    ("11", "Tiket Saya", "Kartu tiket, kode QR, lencana status"),
    ("12", "Diskon Saya", "Daftar voucher yang telah diklaim"),
    ("13", "Dashboard Admin", "Grafik dan angka ringkasan"),
    ("14", "Form Konser", "Pemilih audio, URL trailer, pemilih panggung"),
    ("15", "Pemindai Gerbang", "Pratinjau kamera, tombol pindai"),
    ("16", "Hasil Pemindaian", "Animasi centang, status validasi"),
]


def garis(sel) -> None:
    """Pasang garis penuh pada sel tabel."""
    tcPr = sel._tc.get_or_add_tcPr()
    borders = OxmlElement("w:tcBorders")
    for sisi in ("top", "left", "bottom", "right"):
        el = OxmlElement(f"w:{sisi}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:color"), "000000")
        borders.append(el)
    tcPr.append(borders)


def isi(sel, teks: str, tebal=False, tengah=False) -> None:
    sel.text = ""
    par = sel.paragraphs[0]
    par.paragraph_format.space_before = Pt(2)
    par.paragraph_format.space_after = Pt(2)
    par.paragraph_format.line_spacing = 1.0
    if tengah:
        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = par.add_run(teks)
    run.font.name = FONT
    run.font.size = Pt(11)
    run.font.bold = tebal


def main() -> None:
    doc = Document(str(BERKAS))

    # ---------- 1. hapus 4 paragraf narasi ----------
    hapus = []
    for par in doc.paragraphs:
        if any(par.text.strip().startswith(a) for a in NARASI_LAMA):
            hapus.append(par)
    for par in hapus:
        par._element.getparent().remove(par._element)
    print(f"paragraf narasi dihapus: {len(hapus)}")

    # ---------- 2. kembalikan paragraf pengantar ----------
    for par in doc.paragraphs:
        if par.text.strip().startswith("Storyboard merupakan sketsa kasar antarmuka"):
            for r in list(par.runs):
                r._element.getparent().remove(r._element)
            run = par.add_run(INTRO)
            run.font.name = FONT
            run.font.size = Pt(12)
            print("paragraf pengantar dikembalikan")
            jangkar = par._element
            break
    else:
        print("!! paragraf pengantar tidak ditemukan")
        return

    # ---------- 3. caption ----------
    cap = doc.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cap.paragraph_format.space_before = Pt(6)
    cap.paragraph_format.space_after = Pt(4)
    run = cap.add_run(CAPTION)
    run.font.name = FONT
    run.font.size = Pt(11)
    run.font.bold = True
    jangkar.addnext(cap._element)

    # ---------- 4. tabel ----------
    tabel = doc.add_table(rows=1 + len(BARIS), cols=3)
    tabel.alignment = WD_TABLE_ALIGNMENT.CENTER
    tabel.autofit = False

    lebar = [Cm(1.6), Cm(5.4), Cm(7.0)]
    kepala = ["No", "Layar", "Elemen Multimedia yang Ditampilkan"]

    for i, teks in enumerate(kepala):
        sel = tabel.rows[0].cells[i]
        sel.width = lebar[i]
        isi(sel, teks, tebal=True, tengah=True)
        garis(sel)

    for r, (no, layar, elemen) in enumerate(BARIS, start=1):
        nilai = [no, layar, elemen]
        for i, teks in enumerate(nilai):
            sel = tabel.rows[r].cells[i]
            sel.width = lebar[i]
            isi(sel, teks, tengah=(i == 0))
            garis(sel)

    cap._element.addnext(tabel._element)

    doc.save(str(BERKAS))
    print(f"Tabel 3.4 dipasang: {len(BARIS)} baris data")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    print(f"\ntabel  : {len(d.tables)}  gambar: {len(d.inline_shapes)}  paragraf: {len(d.paragraphs)}")

    ps = [p.text.strip() for p in d.paragraphs]
    i = next(k for k, t in enumerate(ps) if t.startswith("3.3") and "Storyboard" in t and k > 100)
    print("\n=== 3.3 STORYBOARD ===")
    for t in ps[i:i + 5]:
        if t:
            print(f"  {t[:120]}")

    tb = d.tables[-1]
    print(f"\n=== ISI TABEL 3.4 ({len(tb.rows)} baris) ===")
    for row in tb.rows[:5]:
        print("  | " + " | ".join(c.text.strip()[:34] for c in row.cells))
    print(f"  ... ({len(tb.rows) - 1} baris data)")

    teks = "\n".join(ps)
    for k in ("Tabel 3.4", "Empat layar pertama melayani", "Enam layar berikutnya"):
        print(f"  '{k}': {teks.count(k)}")


if __name__ == "__main__":
    main()
