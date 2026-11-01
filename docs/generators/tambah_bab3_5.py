"""
Tambahkan Bab III, IV, V ke Makalah Multimedia.docx.

Bab III : Analisis dan Perancangan (kebutuhan, MDLC, flowchart, storyboard)
Bab IV  : Implementasi dan Pengujian (kode, screenshot, black box, SUS)
Bab V   : Penutup

Gambar dan screenshot TIDAK disisipkan — hanya diberi penanda [GAMBAR x.x]
supaya user mengisinya sendiri.

Jalankan: python docs/generators/tambah_bab3_5.py
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"
MONO = "Consolas"


def p(doc, teks="", *, rata="justify", tebal=False, miring=False, ukuran=12,
      setelah=0, sebelum=0, indentasi=None, jarak=1.5, font=FONT):
    par = doc.add_paragraph()
    par.alignment = {"justify": WD_ALIGN_PARAGRAPH.JUSTIFY,
                     "center": WD_ALIGN_PARAGRAPH.CENTER,
                     "left": WD_ALIGN_PARAGRAPH.LEFT,
                     "right": WD_ALIGN_PARAGRAPH.RIGHT}[rata]
    pf = par.paragraph_format
    pf.line_spacing = jarak
    pf.space_after = Pt(setelah)
    pf.space_before = Pt(sebelum)
    if indentasi is not None:
        pf.first_line_indent = Cm(indentasi)
    if teks:
        r = par.add_run(teks)
        r.font.name = font
        r.font.size = Pt(ukuran)
        r.bold = tebal
        r.italic = miring
    return par


def bab(doc, teks):
    p(doc, teks, rata="center", tebal=True, ukuran=14, setelah=12)


def sub(doc, teks):
    p(doc, teks, rata="left", tebal=True, sebelum=10, setelah=6)


def daftar(doc, teks, nomor):
    par = doc.add_paragraph()
    par.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    pf = par.paragraph_format
    pf.line_spacing = 1.5
    pf.left_indent = Cm(1.27)
    pf.first_line_indent = Cm(-0.63)
    r = par.add_run(f"{nomor}\t")
    r.font.name = FONT
    r.font.size = Pt(12)
    r = par.add_run(teks)
    r.font.name = FONT
    r.font.size = Pt(12)


def _border(t):
    tblPr = t._tbl.tblPr
    b = OxmlElement("w:tblBorders")
    for s in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{s}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), "000000")
        b.append(el)
    tblPr.append(b)


def tabel(doc, kepala, isi, lebar, ukuran=10):
    t = doc.add_table(rows=1, cols=len(kepala))
    _border(t)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(kepala):
        c = t.rows[0].cells[i]
        c.text = ""
        par = c.paragraphs[0]
        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = par.add_run(h)
        r.font.name = FONT
        r.font.size = Pt(ukuran)
        r.bold = True
    for baris in isi:
        sel = t.add_row().cells
        for i, v in enumerate(baris):
            sel[i].text = ""
            par = sel[i].paragraphs[0]
            par.alignment = WD_ALIGN_PARAGRAPH.LEFT
            r = par.add_run(v)
            r.font.name = FONT
            r.font.size = Pt(ukuran)
    for baris in t.rows:
        for i, w in enumerate(lebar):
            baris.cells[i].width = Cm(w)
    return t


def kode(doc, baris_kode: list[str], keterangan: str = ""):
    """Blok kode monospace dengan latar abu."""
    for b in baris_kode:
        par = doc.add_paragraph()
        par.alignment = WD_ALIGN_PARAGRAPH.LEFT
        pf = par.paragraph_format
        pf.line_spacing = 1.0
        pf.space_after = Pt(0)
        pf.left_indent = Cm(1.0)
        pf.right_indent = Cm(0.5)
        shd = OxmlElement("w:shd")
        shd.set(qn("w:val"), "clear")
        shd.set(qn("w:fill"), "F2F2F2")
        par._p.get_or_add_pPr().append(shd)
        r = par.add_run(b if b else " ")
        r.font.name = MONO
        r.font.size = Pt(8.5)
    if keterangan:
        p(doc, keterangan, rata="left", miring=True, ukuran=9, setelah=10)


def penanda(doc, teks):
    """Penanda tempat gambar/screenshot yang harus diisi user."""
    par = doc.add_paragraph()
    par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    pf = par.paragraph_format
    pf.space_before = Pt(8)
    pf.space_after = Pt(4)
    r = par.add_run(teks)
    r.font.name = FONT
    r.font.size = Pt(11)
    r.bold = True
    r.font.color.rgb = RGBColor(0xB0, 0x00, 0x00)


def caption(doc, teks):
    p(doc, teks, rata="center", ukuran=10, setelah=10, jarak=1.0)


def main() -> None:
    doc = Document(str(BERKAS))

    # ==================== BAB III ====================
    doc.add_page_break()
    bab(doc, "BAB III\nANALISIS DAN PERANCANGAN")

    sub(doc, "3.1  Analisis Kebutuhan")

    p(doc, "3.1.1  Penerapan Tahapan MDLC", rata="left", tebal=True, setelah=6)
    p(doc, "Penelitian ini menggunakan metode Multimedia Development Life Cycle "
           "(MDLC) versi Luther–Sutopo yang terdiri atas enam tahap berurutan. "
           "Tabel 3.1 memetakan setiap tahap terhadap pekerjaan yang dilakukan "
           "pada pengembangan aplikasi SoundWave.", indentasi=1.27, setelah=8)

    p(doc, "Tabel 3.1  Penerapan Tahapan MDLC pada Pengembangan SoundWave",
      rata="center", tebal=True, ukuran=11, setelah=6)

    tabel(doc,
          ["Tahap", "Kegiatan", "Luaran"],
          [["1. Concept",
            "Menentukan tujuan aplikasi, pengguna sasaran, dan batasan. "
            "Ditetapkan bahwa aplikasi ditujukan bagi calon pembeli tiket "
            "konser di Indonesia dan dibatasi pada platform Android.",
            "Dokumen rumusan masalah dan batasan"],
           ["2. Design",
            "Merancang alur pengguna dan admin dalam bentuk flowchart, "
            "merancang sketsa antarmuka setiap layar, serta merancang struktur "
            "basis data.",
            "Flowchart, storyboard, dan rancangan basis data"],
           ["3. Material Collecting",
            "Mengumpulkan aset multimedia: poster konser, cuplikan audio, URL "
            "trailer, animasi vektor, dan model panggung tiga dimensi. Setiap "
            "aset diverifikasi lisensinya.",
            "Berkas gambar, audio, animasi, dan model 3D"],
           ["4. Assembly",
            "Merakit seluruh aset dan logika ke dalam aplikasi menggunakan "
            "Flutter, menghubungkan basis data Firestore, serta menyiapkan "
            "layanan backend untuk pembayaran.",
            "Aplikasi Android yang berjalan"],
           ["5. Testing",
            "Menguji fungsionalitas dengan metode black box sebanyak 65 kasus, "
            "menjalankan 768 pengujian otomatis, dan mengukur penilaian "
            "pengguna dengan kuesioner.",
            "Tabel pengujian dan hasil penilaian"],
           ["6. Distribution",
            "Membangun berkas aplikasi Android (APK) dan mendistribusikannya "
            "kepada pengguna terbatas untuk keperluan demonstrasi.",
            "Berkas APK"]],
          [3.0, 7.4, 4.2], ukuran=9)

    p(doc, "", setelah=8)
    p(doc, "Tahap ketiga, yaitu material collecting, menjadi pembeda utama MDLC "
           "dibanding metode pengembangan perangkat lunak umum. Pada aplikasi "
           "yang tidak memuat multimedia, aset visual biasanya dikerjakan "
           "sekaligus saat perakitan. Pada SoundWave, aset multimedia "
           "dikumpulkan dan diverifikasi lebih dahulu karena jumlahnya banyak "
           "dan sebagian berasal dari pihak ketiga dengan lisensi tertentu.",
      indentasi=1.27, setelah=10)

    p(doc, "3.1.2  Kebutuhan Fungsional", rata="left", tebal=True, setelah=6)
    p(doc, "Kebutuhan fungsional adalah layanan yang harus disediakan aplikasi "
           "kepada pengguna. Tabel 3.2 merangkum kebutuhan tersebut beserta "
           "aktor yang memicunya.", indentasi=1.27, setelah=8)

    p(doc, "Tabel 3.2  Kebutuhan Fungsional", rata="center", tebal=True,
      ukuran=11, setelah=6)

    tabel(doc,
          ["Kode", "Kebutuhan", "Aktor"],
          [["F-01", "Pengguna dapat mendaftar dan masuk menggunakan email atau "
                    "akun Google", "Pengguna, Admin"],
           ["F-02", "Pengguna dapat menelusuri dan mencari konser berdasarkan "
                    "kata kunci, tanggal, harga, dan lokasi", "Pengguna"],
           ["F-03", "Pengguna dapat melihat detail konser beserta cuplikan "
                    "audio, trailer video, dan visualisasi panggung",
            "Pengguna"],
           ["F-04", "Pengguna dapat memilih tipe tiket dan jumlahnya sesuai "
                    "stok tersedia", "Pengguna"],
           ["F-05", "Pengguna dapat mengklaim kode promo dan memakainya saat "
                    "membayar", "Pengguna"],
           ["F-06", "Pengguna dapat membayar melalui payment gateway dengan "
                    "berbagai kanal pembayaran", "Pengguna"],
           ["F-07", "Pengguna dapat melihat tiket beserta kode QR", "Pengguna"],
           ["F-08", "Pengguna dapat mengajukan pengembalian tiket", "Pengguna"],
           ["F-09", "Admin dapat membuat dan mengubah data konser beserta aset "
                    "multimedianya", "Admin"],
           ["F-10", "Admin dapat mengatur tipe tiket, harga, dan kuota", "Admin"],
           ["F-11", "Admin dapat membuat dan mengelola kode promo", "Admin"],
           ["F-12", "Admin dapat memindai kode QR tiket di gerbang masuk",
            "Admin"],
           ["F-13", "Admin dapat menyetujui atau menolak pengajuan pengembalian",
            "Admin"],
           ["F-14", "Admin dapat melihat laporan penjualan dan kehadiran",
            "Admin"]],
          [1.8, 10.4, 2.4], ukuran=9)

    p(doc, "", setelah=8)
    p(doc, "3.1.3  Kebutuhan Non-Fungsional", rata="left", tebal=True, setelah=6)
    p(doc, "Kebutuhan non-fungsional adalah batasan kualitas yang harus dipenuhi "
           "aplikasi. Tabel 3.3 merangkum kebutuhan tersebut.", indentasi=1.27,
      setelah=8)

    p(doc, "Tabel 3.3  Kebutuhan Non-Fungsional", rata="center", tebal=True,
      ukuran=11, setelah=6)

    tabel(doc,
          ["Kode", "Kebutuhan", "Keterangan"],
          [["N-01", "Ketersediaan",
            "Aplikasi harus tetap dapat dibuka meski koneksi lambat, dengan "
            "menampilkan indikator memuat"],
           ["N-02", "Kinerja",
            "Pemutaran audio dan video tidak boleh berjalan bersamaan; hanya "
            "satu sumber bunyi aktif pada satu waktu"],
           ["N-03", "Kemudahan penggunaan",
            "Alur pemesanan tidak lebih dari tiga langkah sebelum pembayaran"],
           ["N-04", "Keterbacaan",
            "Kontras teks terhadap latar minimal 4,5:1 sesuai pedoman "
            "aksesibilitas WCAG"],
           ["N-05", "Keandalan",
            "Kuota tiket tidak boleh berkurang dua kali untuk satu pesanan, "
            "meski pengguna menekan tombol berulang"],
           ["N-06", "Portabilitas",
            "Aplikasi berjalan pada perangkat Android dengan memori terbatas"],
           ["N-07", "Keamanan data",
            "Pengguna hanya dapat mengakses data miliknya sendiri"]],
          [1.8, 3.6, 9.2], ukuran=9)

    sub(doc, "3.2  Flowchart Sistem")
    p(doc, "Alur kerja aplikasi digambarkan dalam dua flowchart. Flowchart "
           "pertama menunjukkan alur pengguna dari membuka aplikasi hingga "
           "memindai tiket di gerbang masuk. Flowchart kedua menunjukkan alur "
           "admin dari masuk hingga menyusun laporan.", indentasi=1.27,
      setelah=8)

    penanda(doc, "[GAMBAR 3.1  FLOWCHART ALUR PENGGUNA — sisipkan di sini]")
    caption(doc, "Gambar 3.1  Flowchart Alur Pengguna")

    p(doc, "Alur pengguna dimulai dari halaman splash, dilanjutkan pemeriksaan "
           "status akun. Pengguna yang belum memiliki akun diarahkan ke halaman "
           "pendaftaran, sedangkan yang sudah memiliki akun langsung masuk. "
           "Setelah masuk, pengguna menelusuri daftar konser, membuka detail "
           "konser, memilih tipe tiket, mengisi data pembelian, dan melanjutkan "
           "ke pembayaran. Bila pembayaran berhasil, tiket digital beserta kode "
           "QR diterbitkan. Bila pembayaran tidak diselesaikan dalam batas "
           "waktu, reservasi berakhir dan kuota tiket dikembalikan.",
      indentasi=1.27, setelah=8)

    penanda(doc, "[GAMBAR 3.2  FLOWCHART ALUR ADMIN — sisipkan di sini]")
    caption(doc, "Gambar 3.2  Flowchart Alur Admin")

    p(doc, "Alur admin dimulai dari halaman masuk, dilanjutkan ke dashboard. "
           "Admin membuat data konser beserta aset multimedia, mengatur tipe "
           "tiket dan kuota, lalu mempublikasikan konser. Pada hari "
           "penyelenggaraan, admin memindai kode QR tiket di gerbang masuk. "
           "Pemindaian yang sah mengubah status tiket menjadi terpakai, "
           "sedangkan pemindaian yang tidak sah ditolak.", indentasi=1.27,
      setelah=10)

    sub(doc, "3.3  Storyboard")
    p(doc, "Storyboard merupakan sketsa kasar antarmuka setiap layar. Sketsa "
           "dibuat sebelum penulisan kode untuk memastikan tata letak dan alur "
           "setiap layar telah dipikirkan. Tabel 3.4 memuat daftar enam belas "
           "layar yang digambar.", indentasi=1.27, setelah=8)

    p(doc, "Tabel 3.4  Daftar Storyboard", rata="center", tebal=True,
      ukuran=11, setelah=6)

    tabel(doc,
          ["No", "Layar", "Elemen Multimedia yang Ditampilkan"],
          [["1", "Splash", "Animasi equalizer, logo"],
           ["2", "Masuk", "Formulir email dan kata sandi, tombol masuk"],
           ["3", "Jelajah", "Bilah pencarian, filter, kartu promo, daftar konser"],
           ["4", "Detail Konser", "Poster, pemutar audio, trailer video, "
                                  "panggung 3D"],
           ["5", "Pilih Tiket", "Lembar pilihan tipe tiket beserta harga"],
           ["6", "Checkout Metode", "Empat pilihan metode pembayaran"],
           ["7", "Checkout Bayar", "Formulir data pembeli dan kolom voucher"],
           ["8", "Checkout Konfirmasi", "Rincian harga dan syarat pemesanan"],
           ["9", "Memproses Pembayaran", "Animasi memuat"],
           ["10", "Pembayaran Berhasil", "Animasi confetti, kode booking"],
           ["11", "Tiket Saya", "Kartu tiket, kode QR, lencana status"],
           ["12", "Diskon Saya", "Daftar voucher yang telah diklaim"],
           ["13", "Dashboard Admin", "Grafik dan angka ringkasan"],
           ["14", "Form Konser", "Pemilih audio, URL trailer, pemilih panggung"],
           ["15", "Pemindai Gerbang", "Pratinjau kamera, tombol pindai"],
           ["16", "Hasil Pemindaian", "Animasi centang, status validasi"]],
          [1.2, 4.6, 8.8], ukuran=9)

    p(doc, "", setelah=8)
    p(doc, "Storyboard lengkap disajikan pada Lampiran. Layar Detail Konser "
           "menjadi layar terpenting karena memuat empat elemen multimedia "
           "sekaligus, yaitu teks, gambar, audio, video, dan objek tiga dimensi.",
      indentasi=1.27, setelah=10)

    penanda(doc, "[GAMBAR 3.3  STORYBOARD LAYAR DETAIL KONSER — sisipkan di sini]")
    caption(doc, "Gambar 3.3  Storyboard Layar Detail Konser")

    # ==================== BAB IV ====================
    doc.add_page_break()
    bab(doc, "BAB IV\nIMPLEMENTASI DAN PENGUJIAN")

    sub(doc, "4.1  Implementasi Sistem")
    p(doc, "Aplikasi dibangun menggunakan Flutter 3.47.6 dengan bahasa Dart. "
           "Kode organisasi dibagi menjadi empat lapisan: layar sebagai "
           "antarmuka, komponen sebagai bagian antarmuka yang dapat dipakai "
           "ulang, layanan sebagai penghubung ke sumber data, dan model sebagai "
           "representasi data. Pemisahan ini memudahkan pengujian karena setiap "
           "lapisan dapat diuji secara terpisah.", indentasi=1.27, setelah=10)

    p(doc, "4.1.1  Implementasi Audio", rata="left", tebal=True, setelah=6)
    p(doc, "Pemutaran audio menggunakan paket just_audio. Terdapat dua keputusan "
           "teknis yang perlu dijelaskan. Pertama, aplikasi hanya memakai satu "
           "pemutar untuk cuplikan lagu dan satu pemutar untuk efek suara, bukan "
           "membuat pemutar baru pada setiap komponen. Kedua, karena cuplikan "
           "lagu dibatasi dua puluh detik sementara berkasnya bisa lebih "
           "panjang, posisi pemutaran diperiksa secara berkala lalu dijeda "
           "secara paksa. Kode 4.1 memperlihatkan mekanisme tersebut.",
      indentasi=1.27, setelah=8)

    p(doc, "Kode 4.1  Pengawas batas potongan audio", rata="center",
      tebal=True, ukuran=10, setelah=4)
    kode(doc, [
        "void _pasangPengawasPreview() {",
        "  _pengawasPreview?.cancel();",
        "  if (_batasAkhirPreview <= 0) return;",
        "  _pengawasPreview = Timer.periodic(",
        "    const Duration(milliseconds: 400), (_) {",
        "      final posisi = _previewPlayer.position.inSeconds;",
        "      if (posisi >= _batasAkhirPreview) {",
        "        _pengawasPreview?.cancel();",
        "        _previewPlayer.pause();",
        "      }",
        "    });",
        "}",
    ], "Tanpa pengawas ini, memilih potongan dua puluh detik dari lagu berdurasi "
       "empat menit akan memutar seluruh lagu.")

    p(doc, "4.1.2  Implementasi Video", rata="left", tebal=True, setelah=6)
    p(doc, "Trailer konser diputar menggunakan pemutar video tersemat berbasis "
           "YouTube. Video tidak dimuat sebelum pengguna menekan tombol putar. "
           "Keputusan ini diambil karena memuat pemutar video secara otomatis di "
           "dalam daftar panjang akan menghabiskan memori dan memperlambat "
           "penggulungan halaman. Berbeda dari audio, trailer tidak memiliki "
           "sumber cadangan: bila URL tidak valid, seksi trailer tidak "
           "ditampilkan sama sekali, karena trailer yang salah lebih "
           "membingungkan daripada tidak ada trailer.", indentasi=1.27,
      setelah=10)

    p(doc, "4.1.3  Implementasi Animasi", rata="left", tebal=True, setelah=6)
    p(doc, "Animasi memakai format Lottie, yaitu animasi vektor berbasis berkas "
           "JSON. Empat animasi dipakai untuk menandai status sistem, yaitu "
           "status memuat, status galat, pembayaran berhasil, dan pemindaian "
           "tiket berhasil. Animasi vektor dipilih karena tetap tajam pada "
           "segala resolusi dan berukuran jauh lebih kecil dibanding animasi "
           "berbasis video.", indentasi=1.27, setelah=10)

    p(doc, "4.1.4  Implementasi Objek Tiga Dimensi", rata="left", tebal=True,
      setelah=6)
    p(doc, "Visualisasi panggung diimplementasikan tanpa mesin render tiga "
           "dimensi berbasis peramban. Pendekatan awal menggunakan pemutar "
           "model berbasis WebGL, namun pengujian pada perangkat uji "
           "menunjukkan bahwa halaman berhasil dimuat sementara skripnya tidak "
           "dieksekusi, sehingga model tidak pernah tampil. Karena itu, "
           "proyeksi dihitung sendiri menggunakan kanvas Flutter. Geometri "
           "panggung disusun dari sejumlah balok yang diproyeksikan ke bidang "
           "dua dimensi, seperti diperlihatkan Kode 4.2.", indentasi=1.27,
      setelah=8)

    p(doc, "Kode 4.2  Geometri panggung yang diproyeksikan", rata="center",
      tebal=True, ukuran=10, setelah=4)
    kode(doc, [
        "/// Geometri panggung. Satuan bebas; yang penting proporsinya.",
        "/// Sumbu: x = kiri-kanan, y = atas-bawah, z = depan-belakang",
        "static const List<StageBalok> balok = [",
        "  // Lantai panggung utama.",
        "  StageBalok(-1.0, 0.0, -0.9, 1.0, 0.10, 0.5, isi: true),",
        "  // Runway menjorok ke depan.",
        "  StageBalok(-0.34, 0.0, 0.5, 0.34, 0.10, 1.45, isi: true),",
        "  // Empat tiang truss.",
        "  StageBalok(-1.0, 0.10, -0.90, -0.88, 1.15, -0.78, isi: false),",
        "  StageBalok(0.88, 0.10, -0.90, 1.0, 1.15, -0.78, isi: false),",
        "  // Rangka atas: depan, belakang, kiri, kanan.",
        "  StageBalok(-1.0, 1.05, -0.88, 1.0, 1.20, -0.76, isi: false),",
        "];",
    ], "Setiap balok diproyeksikan dengan perhitungan perspektif lalu digambar "
       "pada kanvas. Panggung juga diskalakan otomatis agar seluruh bagiannya "
       "muat di dalam bingkai.")

    p(doc, "4.1.5  Implementasi Pembayaran", rata="left", tebal=True, setelah=6)
    p(doc, "Pembayaran ditangani oleh Midtrans dalam mode sandbox. Aplikasi "
           "mengirim rincian tagihan ke layanan backend, backend meneruskannya "
           "ke Midtrans, dan Midtrans mengembalikan token pembayaran. Setelah "
           "pembayaran diselesaikan, Midtrans mengirim pemberitahuan ke backend "
           "yang kemudian mengubah status pesanan dan menerbitkan tiket.",
      indentasi=1.27, setelah=10)

    p(doc, "Perhitungan harga dilakukan di satu tempat saja, yaitu modul "
           "perhitungan yang sama dipakai oleh aplikasi dan backend. Urutannya "
           "adalah subtotal, dikurangi diskon, lalu ditambah pajak, ditambah "
           "biaya layanan, dan ditambah biaya tetap. Penyeragaman ini penting "
           "agar angka yang dilihat pengguna sama persis dengan angka yang "
           "ditagih.", indentasi=1.27, setelah=10)

    sub(doc, "4.2  Tampilan Antarmuka")
    p(doc, "Bagian ini memuat tangkapan layar hasil akhir aplikasi. Seluruh "
           "gambar diambil langsung dari perangkat uji, bukan dari rancangan.",
      indentasi=1.27, setelah=8)

    layar = [
        ("4.1", "Halaman Jelajah", "Bilah pencarian, filter, dan kartu promo"),
        ("4.2", "Detail Konser — Bagian Atas",
         "Poster, judul, tanggal, lokasi, dan genre"),
        ("4.3", "Detail Konser — Pemutar Audio",
         "Pemutar cuplikan lagu dengan durasi berjalan"),
        ("4.4", "Detail Konser — Trailer Video",
         "Pemutar trailer yang sedang berjalan"),
        ("4.5", "Detail Konser — Panggung 3D",
         "Visualisasi panggung hasil proyeksi"),
        ("4.6", "Pilih Tipe Tiket",
         "Lembar pilihan VVIP, VIP, dan Reguler beserta harga"),
        ("4.7", "Checkout — Metode Pembayaran",
         "Empat kanal pembayaran yang tersedia"),
        ("4.8", "Checkout — Data Pembeli",
         "Formulir data pembeli dan kolom voucher"),
        ("4.9", "Checkout — Konfirmasi",
         "Rincian harga: subtotal, diskon, pajak, layanan, total"),
        ("4.10", "Memproses Pembayaran",
         "Animasi memuat beserta pesan peringatan"),
        ("4.11", "Pembayaran Berhasil",
         "Animasi confetti dan kode booking"),
        ("4.12", "Tiket Saya", "Kartu tiket, kode QR, dan lencana status"),
        ("4.13", "Diskon Saya", "Daftar voucher yang telah diklaim"),
        ("4.14", "Dashboard Admin", "Ringkasan angka dan grafik"),
        ("4.15", "Form Konser",
         "Pemilih audio, URL trailer, dan pemilih panggung"),
        ("4.16", "Pemindai Gerbang", "Pratinjau kamera dan tombol pindai"),
        ("4.17", "Hasil Pemindaian Berhasil", "Animasi centang dan status"),
        ("4.18", "Hasil Pemindaian Gagal", "Pesan penolakan tiket"),
    ]
    for nomor, judul, ket in layar:
        penanda(doc, f"[GAMBAR {nomor}  {judul.upper()} — sisipkan screenshot di sini]")
        caption(doc, f"Gambar {nomor}  {judul}")

    sub(doc, "4.3  Pengujian Black Box")
    p(doc, "Pengujian black box dilakukan untuk memastikan setiap fungsi "
           "berjalan sesuai harapan tanpa meninjau struktur kode. Pengujian "
           "memakai dua teknik, yaitu equivalence partitioning dan boundary "
           "value analysis. Equivalence partitioning mengelompokkan input ke "
           "kelas yang dianggap setara sehingga cukup satu wakil dari setiap "
           "kelas diuji. Boundary value analysis menguji nilai tepat di batas "
           "kelas, karena kesalahan paling sering muncul di titik tersebut "
           "(Rosmiati, 2021).", indentasi=1.27, setelah=10)

    p(doc, "Pengujian mencakup tujuh kelompok fitur dengan total enam puluh lima "
           "kasus uji. Tabel 4.1 memuat rekapitulasi hasilnya, sedangkan tabel "
           "lengkap disajikan pada Lampiran.", indentasi=1.27, setelah=8)

    p(doc, "Tabel 4.1  Rekapitulasi Hasil Pengujian Black Box", rata="center",
      tebal=True, ukuran=11, setelah=6)

    tabel(doc,
          ["Kelompok Fitur", "Jumlah Kasus", "Sesuai", "Tidak Sesuai"],
          [["Autentikasi", "9", "9", "0"],
           ["Jelajah dan pencarian", "9", "9", "0"],
           ["Detail konser dan multimedia", "8", "8", "0"],
           ["Pemesanan dan checkout", "15", "15", "0"],
           ["Pembayaran", "6", "6", "0"],
           ["Tiket saya", "5", "5", "0"],
           ["Panel admin", "13", "13", "0"],
           ["Total", "65", "65", "0"]],
          [6.4, 3.0, 2.4, 2.8], ukuran=9)

    p(doc, "", setelah=8)
    p(doc, "Seluruh enam puluh lima kasus menghasilkan keluaran sesuai harapan, "
           "sehingga persentase keberhasilan pengujian fungsional mencapai "
           "100%. Selain pengujian manual tersebut, aplikasi memiliki 768 "
           "pengujian otomatis yang dijalankan pada setiap perubahan kode. "
           "Keduanya berbeda peran: pengujian black box membuktikan perilaku "
           "aplikasi benar dari sisi pengguna, sedangkan pengujian otomatis "
           "menjaga agar perilaku tersebut tidak rusak ketika kode diubah.",
      indentasi=1.27, setelah=10)

    p(doc, "Tiga kasus dalam pengujian ini merupakan kesalahan nyata yang "
           "ditemukan saat pengembangan dan kemudian diperbaiki. Pertama, filter "
           "harga pada halaman Jelajah tidak berpengaruh karena baris terakhir "
           "fungsi filter selalu menimpa hasilnya dengan pengurutan tanggal. "
           "Kedua, kode promo yang dibuat admin tidak pernah ditemukan backend "
           "karena disimpan dengan pengenal acak sementara backend mencari "
           "berdasarkan kode. Ketiga, formulir konser menerima harga nol dan "
           "negatif. Ketiganya kini dipertahankan sebagai uji regresi.",
      indentasi=1.27, setelah=10)

    sub(doc, "4.4  Analisis Hasil")
    p(doc, "Selain pengujian fungsional, dilakukan penilaian terhadap pengalaman "
           "pengguna menggunakan System Usability Scale (SUS). SUS dipilih "
           "karena merupakan instrumen yang telah luas dipakai dan hasilnya "
           "dapat dibandingkan antar aplikasi (Suharsih dkk., 2021). Kuesioner "
           "terdiri atas sepuluh pernyataan dengan skala Likert satu sampai "
           "lima.", indentasi=1.27, setelah=10)

    p(doc, "Penilaian melibatkan [JUMLAH] responden yang mencoba aplikasi "
           "secara langsung. Responden diminta menilai lima aspek: kemudahan "
           "penggunaan, kemenarikan tampilan, kejelasan audio, kejelasan video, "
           "dan manfaat visualisasi panggung tiga dimensi.", indentasi=1.27,
      setelah=8)

    p(doc, "Tabel 4.2  Hasil Penilaian Pengguna", rata="center", tebal=True,
      ukuran=11, setelah=6)

    tabel(doc,
          ["Aspek yang Dinilai", "Skor Rata-rata", "Kategori"],
          [["Kemudahan penggunaan", "[...]", "[...]"],
           ["Kemenarikan tampilan", "[...]", "[...]"],
           ["Kejelasan audio", "[...]", "[...]"],
           ["Kejelasan video", "[...]", "[...]"],
           ["Manfaat visualisasi panggung 3D", "[...]", "[...]"],
           ["Skor SUS keseluruhan", "[...]", "[...]"]],
          [7.4, 3.6, 3.6], ukuran=9)

    p(doc, "", setelah=8)
    p(doc, "Perhitungan skor SUS mengikuti prosedur baku. Setiap pernyataan "
           "bernomor ganjil dinilai dengan mengurangi skor responden satu, "
           "sedangkan pernyataan bernomor genap dinilai dengan mengurangi lima "
           "dengan skor responden. Jumlah seluruh nilai dikalikan 2,5 sehingga "
           "diperoleh rentang skor 0 sampai 100. Skor di atas 68 dianggap di "
           "atas rata-rata, sedangkan skor di bawah 68 dianggap di bawah "
           "rata-rata.", indentasi=1.27, setelah=10)

    p(doc, "[ISI DENGAN PEMBAHASAN HASIL: jelaskan skor yang diperoleh, aspek "
           "mana yang paling tinggi dan paling rendah, serta apa artinya bagi "
           "perbaikan aplikasi.]", indentasi=1.27, setelah=10)

    # ==================== BAB V ====================
    doc.add_page_break()
    bab(doc, "BAB V\nPENUTUP")

    sub(doc, "5.1  Kesimpulan")
    p(doc, "Berdasarkan hasil perancangan, implementasi, dan pengujian, dapat "
           "disimpulkan beberapa hal berikut.", indentasi=1.27, setelah=6)
    daftar(doc, "Metode Multimedia Development Life Cycle berhasil diterapkan "
                "pada pengembangan aplikasi ticketing konser berbasis mobile. "
                "Keenam tahapnya, yaitu concept, design, material collecting, "
                "assembly, testing, dan distribution, terpetakan dengan jelas "
                "pada pekerjaan yang dilakukan. Tahap material collecting "
                "terbukti penting karena aplikasi bergantung pada aset "
                "multimedia yang harus dikumpulkan dan diverifikasi lisensinya "
                "lebih dahulu.", "1.")
    daftar(doc, "Kelima elemen multimedia berhasil diintegrasikan sebagai bagian "
                "dari alur pengguna, bukan sebagai hiasan. Cuplikan audio "
                "membantu pengguna mengenal karya penampil sebelum membeli, "
                "trailer memberi gambaran suasana konser, animasi menandai "
                "status sistem, dan visualisasi panggung memberi bayangan tata "
                "venue.", "2.")
    daftar(doc, "Visualisasi panggung tiga dimensi dapat diimplementasikan tanpa "
                "mesin render berbasis peramban. Proyeksi perspektif yang "
                "dihitung pada kanvas aplikasi terbukti berjalan pada perangkat "
                "uji, sementara pendekatan berbasis WebGL tidak dapat "
                "diandalkan.", "3.")
    daftar(doc, "Hasil pengujian black box menunjukkan 65 dari 65 kasus "
                "menghasilkan keluaran sesuai harapan, sehingga fungsi aplikasi "
                "dinyatakan berjalan baik dari sisi pengguna.", "4.")

    sub(doc, "5.2  Saran")
    p(doc, "Beberapa hal yang dapat dikembangkan lebih lanjut adalah sebagai "
           "berikut.", indentasi=1.27, setelah=6)
    daftar(doc, "Visualisasi panggung dapat ditingkatkan menjadi model tiga "
                "dimensi sesungguhnya yang dimuat dari berkas glTF, dengan "
                "terlebih dahulu memastikan ketersediaan mesin render pada "
                "perangkat sasaran.", "1.")
    daftar(doc, "Aplikasi dapat dikembangkan ke platform iOS agar jangkauan "
                "pengguna lebih luas.", "2.")
    daftar(doc, "Penilaian pengguna dapat dilakukan dengan jumlah responden "
                "yang lebih besar dan lebih beragam agar hasilnya dapat "
                "digeneralisasi.", "3.")
    daftar(doc, "Fitur pencarian dapat dilengkapi dengan rekomendasi berbasis "
                "riwayat pembelian pengguna.", "4.")
    daftar(doc, "Aspek keamanan dapat ditinjau lebih lanjut melalui audit "
                "keamanan dan uji penetrasi sebelum aplikasi digunakan secara "
                "komersial.", "5.")

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")
    print("  Bab III + IV + V ditambahkan")
    print("  18 penanda screenshot, 3 penanda gambar")


if __name__ == "__main__":
    main()
