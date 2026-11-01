"""
Ubah keempat tabel Bab III menjadi narasi.

  Tabel 3.1  MDLC 6 tahap        -> 6 paragraf naratif
  Tabel 3.2  14 kebutuhan fungsi -> 2 paragraf (dibagi per aktor)
  Tabel 3.3  7 non-fungsional    -> 1 paragraf
  Tabel 3.4  16 layar storyboard -> 4 paragraf (dibagi per tahap pemakaian)

Caption "Tabel 3.x" dihapus karena tabelnya tidak ada lagi, dan rujukan
"pada Tabel 3.x" di paragraf pengantar diganti kalimat langsung.

Pola kalimat: SPOK, subjek eksplisit ("penulis", "aplikasi"), verba aktif,
keterangan di akhir. Satu gagasan per kalimat.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

# ---------------------------------------------------------------- teks baru

INTRO_MDLC = (
    "Penulis menggunakan metode Multimedia Development Life Cycle (MDLC) versi "
    "Luther\u2013Sutopo yang terdiri atas enam tahap berurutan. Penulis menjalankan keenam "
    "tahap itu secara berurutan pada pengembangan aplikasi SoundWave."
)

MDLC = [
    "Tahap pertama adalah concept. Penulis menentukan tujuan aplikasi, pengguna sasaran, dan "
    "batasan pengembangan. Pada tahap ini penulis menetapkan bahwa aplikasi ditujukan bagi "
    "calon pembeli tiket konser di Indonesia dan dibatasi pada platform Android. Luaran tahap "
    "ini berupa dokumen rumusan masalah dan batasan.",

    "Tahap kedua adalah design. Penulis merancang alur pengguna dan admin dalam bentuk "
    "flowchart, merancang sketsa antarmuka setiap layar, serta merancang struktur basis data. "
    "Luaran tahap ini berupa flowchart, storyboard, dan rancangan basis data.",

    "Tahap ketiga adalah material collecting. Penulis mengumpulkan aset multimedia berupa "
    "poster konser, cuplikan audio, URL trailer, animasi vektor, dan model panggung tiga "
    "dimensi. Penulis memverifikasi lisensi setiap aset pada tahap ini. Luaran tahap ini "
    "berupa berkas gambar, audio, animasi, dan model tiga dimensi.",

    "Tahap keempat adalah assembly. Penulis merakit seluruh aset dan logika ke dalam aplikasi "
    "menggunakan Flutter, menghubungkan basis data Firestore, serta menyiapkan layanan backend "
    "untuk pembayaran. Luaran tahap ini berupa aplikasi Android yang berjalan.",

    "Tahap kelima adalah testing. Penulis menguji fungsionalitas dengan metode black box "
    "sebanyak 65 kasus, menjalankan 768 pengujian otomatis, dan mengukur penilaian pengguna "
    "dengan kuesioner. Luaran tahap ini berupa tabel pengujian dan hasil penilaian.",

    "Tahap keenam adalah distribution. Penulis membangun berkas aplikasi Android (APK) dan "
    "mendistribusikannya kepada pengguna terbatas untuk keperluan demonstrasi. Luaran tahap "
    "ini berupa berkas APK.",
]

MDLC_PENUTUP = (
    "Dari keenam tahap tersebut, tahap material collecting menjadi pembeda utama MDLC dibanding "
    "metode pengembangan perangkat lunak umum. Pada aplikasi yang tidak memuat multimedia, aset "
    "visual biasanya dikerjakan sekaligus saat perakitan. Pada SoundWave, penulis mengumpulkan "
    "dan memverifikasi aset multimedia lebih dahulu karena jumlahnya banyak. Sebagian aset itu "
    "berasal dari pihak ketiga dengan lisensi tertentu."
)

INTRO_FUNGSIONAL = (
    "Kebutuhan fungsional merupakan layanan yang harus disediakan aplikasi kepada pengguna. "
    "Penulis membagi kebutuhan tersebut menurut aktor yang memicunya, yaitu pengguna dan admin."
)

FUNGSIONAL = [
    "Aplikasi menyediakan delapan kebutuhan fungsional bagi pengguna. Pengguna dapat mendaftar "
    "dan masuk menggunakan email atau akun Google. Pengguna dapat menelusuri dan mencari konser "
    "berdasarkan kata kunci, tanggal, harga, dan lokasi. Pengguna dapat melihat detail konser "
    "beserta cuplikan audio, trailer video, dan visualisasi panggung. Pengguna dapat memilih "
    "tipe tiket dan jumlahnya sesuai stok tersedia. Pengguna dapat mengklaim kode promo dan "
    "memakainya saat membayar. Pengguna dapat membayar melalui payment gateway dengan berbagai "
    "kanal pembayaran. Pengguna dapat melihat tiket beserta kode QR. Pengguna juga dapat "
    "mengajukan pengembalian tiket.",

    "Aplikasi menyediakan enam kebutuhan fungsional bagi admin. Admin dapat membuat dan "
    "mengubah data konser beserta aset multimedianya. Admin dapat mengatur tipe tiket, harga, "
    "dan kuota. Admin dapat membuat dan mengelola kode promo. Admin dapat memindai kode QR "
    "tiket di gerbang masuk. Admin dapat menyetujui atau menolak pengajuan pengembalian. Admin "
    "juga dapat melihat laporan penjualan dan kehadiran.",
]

INTRO_NONFUNGSIONAL = (
    "Kebutuhan non-fungsional merupakan batasan kualitas yang harus dipenuhi aplikasi. Penulis "
    "menetapkan tujuh batasan kualitas untuk SoundWave."
)

NONFUNGSIONAL = (
    "Ketersediaan menuntut aplikasi tetap dapat dibuka meski koneksi lambat, dengan menampilkan "
    "indikator memuat. Kinerja menuntut pemutaran audio dan video tidak berjalan bersamaan, "
    "sehingga hanya satu sumber bunyi aktif pada satu waktu. Kemudahan penggunaan menuntut alur "
    "pemesanan tidak lebih dari tiga langkah sebelum pembayaran. Keterbacaan menuntut kontras "
    "teks terhadap latar minimal 4,5:1 sesuai pedoman aksesibilitas WCAG. Keandalan menuntut "
    "kuota tiket tidak berkurang dua kali untuk satu pesanan, meski pengguna menekan tombol "
    "berulang. Portabilitas menuntut aplikasi berjalan pada perangkat Android dengan memori "
    "terbatas. Keamanan data menuntut pengguna hanya dapat mengakses data miliknya sendiri."
)

INTRO_STORYBOARD = (
    "Storyboard merupakan sketsa kasar antarmuka setiap layar. Penulis membuat sketsa sebelum "
    "penulisan kode untuk memastikan tata letak dan alur setiap layar telah dipikirkan. Penulis "
    "menggambar enam belas layar dan mengelompokkannya menurut tahap penggunaan."
)

STORYBOARD = [
    "Empat layar pertama melayani pembukaan dan penelusuran konser. Layar Splash menampilkan "
    "animasi equalizer dan logo. Layar Masuk memuat formulir email dan kata sandi serta tombol "
    "masuk. Layar Jelajah memuat bilah pencarian, filter, kartu promo, dan daftar konser. Layar "
    "Detail Konser memuat poster, pemutar audio, trailer video, dan panggung tiga dimensi.",

    "Enam layar berikutnya melayani proses pembelian tiket. Layar Pilih Tiket menampilkan "
    "lembar pilihan tipe tiket beserta harga. Layar Checkout Metode menampilkan empat pilihan "
    "metode pembayaran. Layar Checkout Bayar memuat formulir data pembeli dan kolom voucher. "
    "Layar Checkout Konfirmasi menampilkan rincian harga dan syarat pemesanan. Layar Memproses "
    "Pembayaran menampilkan animasi memuat. Layar Pembayaran Berhasil menampilkan animasi "
    "confetti dan kode booking.",

    "Dua layar berikutnya melayani tiket yang telah dibeli. Layar Tiket Saya menampilkan kartu "
    "tiket, kode QR, dan lencana status. Layar Diskon Saya menampilkan daftar voucher yang "
    "telah diklaim.",

    "Empat layar terakhir melayani keperluan admin. Layar Dashboard Admin menampilkan grafik "
    "dan angka ringkasan. Layar Form Konser memuat pemilih audio, URL trailer, dan pemilih "
    "panggung. Layar Pemindai Gerbang menampilkan pratinjau kamera dan tombol pindai. Layar "
    "Hasil Pemindaian menampilkan animasi centang dan status validasi.",
]


# ---------------------------------------------------------------- util

def tulis(par, teks: str) -> None:
    for r in list(par.runs):
        r._element.getparent().remove(r._element)
    run = par.add_run(teks)
    run.font.name = FONT
    run.font.size = Pt(12)


def sisip_setelah(doc, par, teks: str):
    baru = doc.add_paragraph()
    baru.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    run = baru.add_run(teks)
    run.font.name = FONT
    run.font.size = Pt(12)
    par._element.addnext(baru._element)
    return baru


def main() -> None:
    doc = Document(str(BERKAS))

    # ---------- 1. ganti paragraf pengantar ----------
    peta_intro = {
        "Penulis menggunakan metode Multimedia Development Life Cycle (MDLC) versi Luther": INTRO_MDLC,
        "Kebutuhan fungsional merupakan layanan yang harus disediakan aplikasi": INTRO_FUNGSIONAL,
        "Kebutuhan non-fungsional merupakan batasan kualitas": INTRO_NONFUNGSIONAL,
        "Storyboard merupakan sketsa kasar antarmuka": INTRO_STORYBOARD,
        "Tahap ketiga, yaitu material collecting, menjadi pembeda utama": MDLC_PENUTUP,
    }
    for awalan, baru in peta_intro.items():
        for par in doc.paragraphs:
            if par.text.strip().startswith(awalan):
                tulis(par, baru)
                print(f"  intro diganti: {awalan[:48]}")
                break

    # ---------- 2. hapus caption + tabel, sisipkan narasi ----------
    rencana = [
        ("Tabel 3.1", MDLC),
        ("Tabel 3.2", FUNGSIONAL),
        ("Tabel 3.3", [NONFUNGSIONAL]),
        ("Tabel 3.4", STORYBOARD),
    ]

    for caption, narasi in rencana:
        cap = None
        for par in doc.paragraphs:
            if par.text.strip().startswith(caption):
                cap = par
                break
        if cap is None:
            print(f"  !! caption {caption} tidak ditemukan")
            continue

        # tabel tepat sesudah caption
        tbl = cap._element.getnext()
        if tbl is None or not tbl.tag.endswith("tbl"):
            print(f"  !! tabel setelah {caption} tidak ditemukan")
            continue
        tbl.getparent().remove(tbl)

        # paragraf sebelum caption = jangkar narasi
        jangkar = cap._element.getprevious()
        cap._element.getparent().remove(cap._element)

        # sisipkan narasi berurutan setelah jangkar
        from docx.text.paragraph import Paragraph
        pos = Paragraph(jangkar, cap._parent)
        for teks in narasi:
            pos = sisip_setelah(doc, pos, teks)
        print(f"  {caption}: tabel dihapus, {len(narasi)} paragraf narasi disisipkan")

    doc.save(str(BERKAS))
    print(f"\ntersimpan: {BERKAS}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    ps = [p.text.strip() for p in d.paragraphs]
    teks = "\n".join(ps)
    print(f"\ntabel  : {len(d.tables)}  (sebelumnya 8)")
    print(f"gambar : {len(d.inline_shapes)}")
    print(f"paragraf: {len(d.paragraphs)}")

    print("\n=== CEK CAPTION & RUJUKAN ===")
    for k in ("Tabel 3.1", "Tabel 3.2", "Tabel 3.3", "Tabel 3.4"):
        print(f"  '{k}': {teks.count(k)}")

    print("\n=== SISA CAPTION TABEL ===")
    import re
    for t in ps:
        if re.match(r"^Tabel \d\.\d\s\s", t):
            print(f"  {t}")


if __name__ == "__main__":
    main()
