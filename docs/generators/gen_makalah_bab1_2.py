"""
Generator Bab I + II Makalah Sistem Multimedia SoundWave -> .docx

Judul: Penerapan Metode Multimedia Development Life Cycle dalam
       Pengembangan Aplikasi Ticketing Konser Berbasis Mobile

Format: Times New Roman 12 pt, spasi 1,5, rata kanan-kiri, margin 4-4-3-3 cm.
Sitasi ditulis sebagai teks APA; user menggantinya dengan Mendeley Cite.

Jalankan: python docs/generators/gen_makalah_bab1_2.py
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.shared import Cm, Pt, RGBColor

KELUARAN = Path(__file__).resolve().parents[2] / "MAKALAH_BAB1_2.docx"

FONT = "Times New Roman"


def atur_dokumen(doc: Document) -> None:
    """Margin, font dasar, dan spasi baris."""
    for s in doc.sections:
        s.left_margin = Cm(4)
        s.right_margin = Cm(3)
        s.top_margin = Cm(4)
        s.bottom_margin = Cm(3)

    g = doc.styles["Normal"]
    g.font.name = FONT
    g.font.size = Pt(12)
    g.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    g.paragraph_format.space_after = Pt(0)
    g.paragraph_format.space_before = Pt(0)


def p(doc, teks: str = "", *, rata="justify", tebal=False, miring=False,
      ukuran=12, spasi_setelah=0, indentasi=None, jarak=1.5):
    par = doc.add_paragraph()
    par.alignment = {
        "justify": WD_ALIGN_PARAGRAPH.JUSTIFY,
        "center": WD_ALIGN_PARAGRAPH.CENTER,
        "left": WD_ALIGN_PARAGRAPH.LEFT,
        "right": WD_ALIGN_PARAGRAPH.RIGHT,
    }[rata]
    pf = par.paragraph_format
    pf.line_spacing = jarak
    pf.space_after = Pt(spasi_setelah)
    if indentasi is not None:
        pf.first_line_indent = Cm(indentasi)
    if teks:
        r = par.add_run(teks)
        r.font.name = FONT
        r.font.size = Pt(ukuran)
        r.bold = tebal
        r.italic = miring
    return par


def judul_bab(doc, teks: str) -> None:
    p(doc, teks, rata="center", tebal=True, spasi_setelah=12)


def sub(doc, teks: str) -> None:
    p(doc, teks, rata="left", tebal=True, spasi_setelah=6, spasi_setelah_=None) \
        if False else None
    par = p(doc, teks, rata="left", tebal=True)
    par.paragraph_format.space_before = Pt(10)
    par.paragraph_format.space_after = Pt(6)


def daftar(doc, item: str, nomor: str | None = None) -> None:
    par = doc.add_paragraph()
    par.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    pf = par.paragraph_format
    pf.line_spacing = 1.5
    pf.left_indent = Cm(1.27)
    pf.first_line_indent = Cm(-0.63) if nomor else Cm(0)
    if nomor:
        r = par.add_run(f"{nomor}\t")
        r.font.name = FONT
        r.font.size = Pt(12)
    r = par.add_run(item)
    r.font.name = FONT
    r.font.size = Pt(12)


def tabel(doc, kepala: list[str], isi: list[list[str]], lebar=None) -> None:
    t = doc.add_table(rows=1, cols=len(kepala))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER

    for i, h in enumerate(kepala):
        c = t.rows[0].cells[i]
        c.text = ""
        par = c.paragraphs[0]
        par.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = par.add_run(h)
        r.font.name = FONT
        r.font.size = Pt(10)
        r.bold = True

    for baris in isi:
        sel = t.add_row().cells
        for i, v in enumerate(baris):
            sel[i].text = ""
            par = sel[i].paragraphs[0]
            par.alignment = WD_ALIGN_PARAGRAPH.LEFT
            r = par.add_run(v)
            r.font.name = FONT
            r.font.size = Pt(10)

    if lebar:
        for baris in t.rows:
            for i, w in enumerate(lebar):
                baris.cells[i].width = Cm(w)


def buat() -> None:
    doc = Document()
    atur_dokumen(doc)

    # ==================== HALAMAN JUDUL ====================
    p(doc, "MAKALAH PROJECT AKHIR SISTEM MULTIMEDIA", rata="center",
      tebal=True, ukuran=14, spasi_setelah=30)

    p(doc, "PENERAPAN METODE MULTIMEDIA DEVELOPMENT LIFE CYCLE "
           "DALAM PENGEMBANGAN APLIKASI TICKETING KONSER BERBASIS MOBILE",
      rata="center", tebal=True, ukuran=16, spasi_setelah=36)

    p(doc, "Disusun oleh:", rata="center", spasi_setelah=6)
    p(doc, "[NAMA MAHASISWA 1]", rata="center", tebal=True)
    p(doc, "NIM: [..............]", rata="center", spasi_setelah=12)
    p(doc, "[NAMA MAHASISWA 2]", rata="center", tebal=True)
    p(doc, "NIM: [..............]", rata="center", spasi_setelah=36)

    p(doc, "PROGRAM STUDI [NAMA PROGRAM STUDI]", rata="center", tebal=True)
    p(doc, "[NAMA FAKULTAS]", rata="center", tebal=True)
    p(doc, "[NAMA UNIVERSITAS]", rata="center", tebal=True)
    p(doc, "2026", rata="center", tebal=True)

    doc.add_page_break()

    # ==================== KATA PENGANTAR ====================
    p(doc, "KATA PENGANTAR", rata="center", tebal=True, ukuran=14,
      spasi_setelah=18)

    p(doc, "Puji syukur penulis panjatkan kepada Tuhan Yang Maha Esa karena "
           "atas rahmat-Nya makalah Project Akhir Sistem Multimedia ini dapat "
           "diselesaikan. Makalah ini disusun sebagai bagian dari penilaian "
           "mata kuliah Sistem Multimedia yang menggunakan pendekatan "
           "Project Based Learning.", indentasi=1.27, spasi_setelah=10)

    p(doc, "Makalah ini membahas penerapan metode Multimedia Development Life "
           "Cycle (MDLC) dalam pengembangan aplikasi ticketing konser berbasis "
           "mobile bernama SoundWave. Aplikasi tersebut memuat elemen teks, "
           "gambar, audio, video, animasi, dan objek tiga dimensi sebagai "
           "bagian dari fungsi utamanya, bukan sekadar hiasan antarmuka.",
      indentasi=1.27, spasi_setelah=10)

    p(doc, "Penulis menyadari makalah ini masih memiliki kekurangan. Kritik dan "
           "saran yang membangun sangat diharapkan untuk perbaikan ke depan. "
           "Semoga makalah ini bermanfaat bagi pembaca.", indentasi=1.27,
      spasi_setelah=24)

    p(doc, "[Kota], 27 Oktober 2026", rata="right", spasi_setelah=36)
    p(doc, "Penulis", rata="right")

    doc.add_page_break()

    # ==================== DAFTAR ISI ====================
    p(doc, "DAFTAR ISI", rata="center", tebal=True, ukuran=14,
      spasi_setelah=18)
    p(doc, "HALAMAN JUDUL ........................................................................ i",
      rata="left", jarak=1.15)
    p(doc, "KATA PENGANTAR ...................................................................... ii",
      rata="left", jarak=1.15)
    p(doc, "DAFTAR ISI ............................................................................. iii",
      rata="left", jarak=1.15)
    p(doc, "BAB I PENDAHULUAN .............................................................. 1",
      rata="left", jarak=1.15, tebal=True)
    p(doc, "     1.1  Latar Belakang ............................................................ 1",
      rata="left", jarak=1.15)
    p(doc, "     1.2  Rumusan Masalah ....................................................... 3",
      rata="left", jarak=1.15)
    p(doc, "     1.3  Batasan Masalah ........................................................ 3",
      rata="left", jarak=1.15)
    p(doc, "     1.4  Tujuan dan Manfaat ................................................... 4",
      rata="left", jarak=1.15)
    p(doc, "BAB II LANDASAN TEORI ........................................................ 5",
      rata="left", jarak=1.15, tebal=True)
    p(doc, "     2.1  Definisi Sistem Multimedia ......................................... 5",
      rata="left", jarak=1.15)
    p(doc, "     2.2  Teknologi Terkait ......................................................... 7",
      rata="left", jarak=1.15)
    p(doc, "     2.3  Software dan Hardware .............................................. 9",
      rata="left", jarak=1.15)
    p(doc, "DAFTAR PUSTAKA .................................................................... 11",
      rata="left", jarak=1.15)

    doc.add_page_break()

    # ==================== BAB I ====================
    judul_bab(doc, "BAB I\nPENDAHULUAN")

    sub(doc, "1.1  Latar Belakang")
    p(doc, "Konser musik merupakan salah satu bentuk hiburan yang permintaannya "
           "terus meningkat setiap tahun. Seiring pertumbuhan tersebut, cara "
           "masyarakat memperoleh tiket ikut berubah: dari antrean di lokasi "
           "penjualan menjadi pemesanan daring melalui aplikasi. Perubahan ini "
           "didorong oleh kepraktisan, tetapi juga menimbulkan persoalan baru "
           "yang jarang disadari.", indentasi=1.27, spasi_setelah=10)

    p(doc, "Sebagian besar aplikasi ticketing yang beredar saat ini berfungsi "
           "sebagai katalog dan mesin pembayaran. Informasi yang disajikan "
           "terbatas pada teks dan gambar statis, yaitu judul konser, tanggal, "
           "lokasi, dan harga tiket. Calon pembeli tidak memperoleh gambaran "
           "mengenai suasana konser, tidak dapat mendengar cuplikan karya "
           "penampil, dan tidak dapat membayangkan tata panggung tempat ia "
           "akan hadir. Aplikasi pemesanan tiket yang dikembangkan sebelumnya "
           "memang telah berhasil memindahkan proses transaksi ke perangkat "
           "mobile, namun belum menyentuh aspek pengalaman sebelum pembelian "
           "(Kusumapratiwi & Waluyo, 2023).", indentasi=1.27, spasi_setelah=10)

    p(doc, "Keterbatasan tersebut menjadi persoalan karena keputusan membeli "
           "tiket konser bersifat emosional, bukan semata transaksional. "
           "Seseorang membeli tiket karena tertarik pada musiknya, pada suasana "
           "yang dibayangkan, dan pada pengalaman yang akan dialami. Ketika "
           "aplikasi hanya menampilkan teks dan poster, ketertarikan itu sulit "
           "tumbuh. Akibatnya, keputusan pembelian lebih banyak ditentukan oleh "
           "faktor luar aplikasi, misalnya unggahan media sosial atau "
           "rekomendasi teman, bukan oleh informasi yang disediakan "
           "penyelenggara.", indentasi=1.27, spasi_setelah=10)

    p(doc, "Perkembangan teknologi multimedia membuka kemungkinan untuk "
           "mengatasi keterbatasan tersebut. Multimedia didefinisikan sebagai "
           "kombinasi dua unsur atau lebih dari teks, gambar, suara, animasi, "
           "dan video yang disampaikan secara terpadu melalui perangkat "
           "digital, dengan tujuan menyampaikan informasi secara lebih hidup "
           "daripada media tunggal (Ikhwan dkk., 2026). Aplikasi mobile masa "
           "kini tidak lagi dibatasi teks dan gambar; ia dapat memuat audio, "
           "video, animasi vektor, bahkan objek tiga dimensi tanpa memerlukan "
           "perangkat tambahan.", indentasi=1.27, spasi_setelah=10)

    p(doc, "Penerapan animasi pada aplikasi mobile lintas platform juga telah "
           "dikaji secara empiris dan terbukti memengaruhi persepsi pengguna "
           "terhadap kualitas aplikasi, dengan catatan bahwa pemilihan teknik "
           "animasi harus mempertimbangkan beban komputasi perangkat "
           "(Biørn-Hansen dkk., 2019). Temuan ini menunjukkan bahwa penambahan "
           "elemen multimedia bukan sekadar urusan estetika, melainkan "
           "keputusan teknis yang perlu direncanakan.", indentasi=1.27,
      spasi_setelah=10)

    p(doc, "Berdasarkan uraian tersebut, penulis mengembangkan SoundWave, yaitu "
           "aplikasi penjualan tiket konser berbasis mobile yang memuat lima "
           "elemen multimedia sebagai bagian dari fungsi utamanya. Cuplikan "
           "audio dua puluh detik disediakan agar calon pembeli dapat mengenal "
           "karya penampil sebelum membeli. Video trailer memberi gambaran "
           "suasana konser. Animasi vektor menandai status sistem, seperti "
           "proses memuat, pembayaran berhasil, dan hasil pemindaian tiket. "
           "Objek tiga dimensi menampilkan visualisasi panggung sehingga "
           "pembeli dapat membayangkan tata venue.", indentasi=1.27,
      spasi_setelah=10)

    p(doc, "Pengembangan aplikasi multimedia memerlukan metode yang sesuai. "
           "Metode Multimedia Development Life Cycle (MDLC) versi Luther–Sutopo "
           "menyediakan enam tahap berurutan, yaitu concept, design, material "
           "collecting, assembly, testing, dan distribution. Kekhasan metode "
           "ini terletak pada tahap material collecting, yang memisahkan "
           "pengumpulan aset multimedia sebagai pekerjaan tersendiri sebelum "
           "perakitan aplikasi dimulai (Ikhwan dkk., 2026). Pemisahan itu "
           "relevan bagi SoundWave, karena aplikasi ini bergantung pada aset "
           "audio, video, animasi, dan model tiga dimensi yang harus "
           "dikumpulkan dan diverifikasi lisensinya lebih dahulu.", indentasi=1.27,
      spasi_setelah=10)

    p(doc, "MDLC juga telah diterapkan pada pengembangan yang menghasilkan "
           "objek tiga dimensi, sehingga diketahui mampu menangani proyek yang "
           "tidak sekadar berbasis teks dan gambar (Putra Kang & Fauzi, 2025; "
           "Tulus dkk., 2026). Dengan demikian, MDLC dipilih sebagai metode "
           "pengembangan dalam penelitian ini, sementara aplikasi SoundWave "
           "menjadi objek penerapannya.", indentasi=1.27, spasi_setelah=10)

    sub(doc, "1.2  Rumusan Masalah")
    p(doc, "Berdasarkan latar belakang di atas, rumusan masalah dalam penelitian "
           "ini adalah sebagai berikut.", indentasi=1.27, spasi_setelah=6)
    daftar(doc, "Bagaimana menerapkan metode Multimedia Development Life Cycle "
                "dalam pengembangan aplikasi ticketing konser berbasis mobile?",
           "1.")
    daftar(doc, "Bagaimana mengintegrasikan elemen audio, video, animasi, dan "
                "objek tiga dimensi ke dalam aplikasi ticketing konser sehingga "
                "berfungsi sebagai bagian dari alur pengguna, bukan sekadar "
                "hiasan antarmuka?", "2.")
    daftar(doc, "Bagaimana hasil pengujian fungsional dan penilaian pengguna "
                "terhadap aplikasi yang dikembangkan?", "3.")

    sub(doc, "1.3  Batasan Masalah")
    p(doc, "Agar pembahasan terarah, penelitian ini dibatasi pada hal-hal "
           "berikut.", indentasi=1.27, spasi_setelah=6)
    daftar(doc, "Aplikasi dikembangkan untuk platform Android dan tidak "
                "mencakup platform iOS.", "1.")
    daftar(doc, "Transaksi pembayaran menggunakan Midtrans dalam mode sandbox, "
                "sehingga tidak melibatkan uang sungguhan.", "2.")
    daftar(doc, "Pembahasan basis data dibatasi pada lima tabel utama, yaitu "
                "pengguna, konser, tiket, pesanan, dan kode promo.", "3.")
    daftar(doc, "Aspek keamanan tingkat lanjut, seperti audit keamanan dan uji "
                "penetrasi, tidak dibahas.", "4.")
    daftar(doc, "Penilaian pengguna dilakukan dengan kuesioner terbatas pada "
                "responden yang dapat dijangkau penulis, sehingga hasilnya "
                "tidak dapat digeneralisasi ke seluruh pengguna aplikasi "
                "ticketing.", "5.")

    sub(doc, "1.4  Tujuan dan Manfaat")

    p(doc, "1.4.1  Tujuan", rata="left", tebal=True, spasi_setelah=6)
    p(doc, "Penelitian ini bertujuan untuk:", indentasi=1.27, spasi_setelah=6)
    daftar(doc, "Menerapkan metode Multimedia Development Life Cycle pada "
                "pengembangan aplikasi ticketing konser berbasis mobile.",
           "1.")
    daftar(doc, "Menghasilkan aplikasi yang memuat elemen teks, gambar, audio, "
                "video, animasi, dan objek tiga dimensi secara terpadu.", "2.")
    daftar(doc, "Menguji kelayakan aplikasi melalui pengujian fungsional dan "
                "penilaian pengguna.", "3.")

    p(doc, "1.4.2  Manfaat", rata="left", tebal=True, spasi_setelah=6)
    p(doc, "Manfaat yang diharapkan dari penelitian ini adalah sebagai berikut.",
      indentasi=1.27, spasi_setelah=6)
    daftar(doc, "Bagi penulis, menjadi sarana menerapkan pengetahuan mengenai "
                "multimedia dan rekayasa perangkat lunak pada proyek nyata.",
           "1.")
    daftar(doc, "Bagi pengguna, memberikan pengalaman memilih tiket konser yang "
                "lebih informatif karena menyertakan cuplikan audio, trailer, "
                "dan gambaran panggung.", "2.")
    daftar(doc, "Bagi penyelenggara konser, menyediakan contoh penerapan "
                "multimedia yang dapat meningkatkan daya tarik penjualan tiket.",
           "3.")
    daftar(doc, "Bagi peneliti berikutnya, menjadi rujukan penerapan MDLC pada "
                "aplikasi ticketing berbasis mobile.", "4.")

    doc.add_page_break()

    # ==================== BAB II ====================
    judul_bab(doc, "BAB II\nLANDASAN TEORI")

    sub(doc, "2.1  Definisi Sistem Multimedia")
    p(doc, "Multimedia merupakan kombinasi dua unsur atau lebih dari teks, "
           "gambar, suara, animasi, dan video yang disampaikan secara terpadu "
           "melalui perangkat digital. Kata terpadu menjadi kunci: elemen-"
           "elemen tersebut tidak berdiri sendiri, melainkan saling melengkapi "
           "untuk menyampaikan satu pesan (Ikhwan dkk., 2026). Sistem "
           "multimedia, dengan demikian, adalah sistem yang memanfaatkan lebih "
           "dari satu elemen tersebut secara bersamaan untuk mencapai tujuan "
           "tertentu.", indentasi=1.27, spasi_setelah=10)

    p(doc, "Elemen multimedia dibedakan menjadi lima jenis. Teks merupakan "
           "elemen paling dasar dan paling banyak dipakai karena mampu "
           "menyampaikan informasi presisi, seperti nama, angka, dan prosedur. "
           "Gambar menyampaikan informasi visual yang sulit dijelaskan dengan "
           "kata-kata. Audio menambahkan dimensi waktu dan suasana. Video "
           "menggabungkan gambar bergerak dengan suara sehingga mampu "
           "menyampaikan urutan kejadian. Animasi menampilkan perubahan bentuk "
           "atau posisi secara berurutan untuk menjelaskan proses atau menarik "
           "perhatian.", indentasi=1.27, spasi_setelah=10)

    p(doc, "Tabel 2.1 memetakan kelima elemen tersebut terhadap penerapannya "
           "dalam aplikasi SoundWave.", indentasi=1.27, spasi_setelah=8)

    p(doc, "Tabel 2.1  Elemen Multimedia dan Penerapannya pada Aplikasi "
           "SoundWave", rata="center", tebal=True, ukuran=11, spasi_setelah=6)

    tabel(doc,
          ["Elemen", "Bentuk Penerapan", "Fungsi bagi Pengguna"],
          [
              ["Teks", "Label antarmuka, deskripsi konser, syarat dan "
                       "ketentuan, laporan admin",
               "Menyampaikan informasi yang memerlukan ketepatan"],
              ["Gambar", "Poster konser, banner promo, kartu promo",
               "Menampilkan identitas visual konser"],
              ["Audio", "Cuplikan lagu 20 detik; efek suara validasi tiket",
               "Mengenalkan karya penampil; memberi umpan balik operasional"],
              ["Video", "Trailer konser melalui pemutar tersemat",
               "Menggambarkan suasana konser"],
              ["Animasi", "Animasi vektor untuk status memuat, galat, "
                          "pembayaran berhasil, dan pemindaian tiket",
               "Menandai status sistem secara visual"],
              ["Objek 3D", "Visualisasi panggung dengan proyeksi perspektif",
               "Memberi gambaran tata venue"],
          ],
          lebar=[2.6, 6.4, 5.6])

    p(doc, "", spasi_setelah=6)
    p(doc, "Selain kelima elemen di atas, aplikasi SoundWave juga menerapkan "
           "objek tiga dimensi sebagai elemen tambahan. Visualisasi panggung "
           "dihitung menggunakan proyeksi perspektif pada kanvas aplikasi, "
           "tanpa memerlukan mesin render tiga dimensi berbasis peramban. "
           "Pendekatan ini dipilih setelah pengujian menunjukkan bahwa mesin "
           "render berbasis WebGL tidak dapat diandalkan pada perangkat uji "
           "yang digunakan.", indentasi=1.27, spasi_setelah=10)

    sub(doc, "2.2  Teknologi Terkait")

    p(doc, "2.2.1  Flutter", rata="left", tebal=True, spasi_setelah=6)
    p(doc, "Flutter merupakan kerangka kerja sumber terbuka untuk membangun "
           "aplikasi mobile dari satu basis kode. Flutter menggunakan bahasa "
           "Dart dan merender antarmuka secara langsung melalui mesin grafisnya "
           "sendiri, sehingga tampilan konsisten di berbagai perangkat. "
           "Penggunaan Flutter memungkinkan pengembangan aplikasi mobile yang "
           "efisien dari sisi waktu dan pemeliharaan (Lendo dkk., 2023; Patil "
           "dkk., 2022). Aplikasi SoundWave dibangun dengan Flutter versi "
           "3.47.6 dan bahasa Dart.", indentasi=1.27, spasi_setelah=10)

    p(doc, "2.2.2  Firebase", rata="left", tebal=True, spasi_setelah=6)
    p(doc, "Firebase merupakan layanan backend yang menyediakan basis data "
           "dokumen berbasis cloud dengan kemampuan pembaruan secara waktu "
           "nyata. Basis data jenis NoSQL ini menyimpan data dalam bentuk "
           "dokumen yang dikelompokkan ke dalam koleksi, sehingga skema dapat "
           "berkembang tanpa migrasi yang rumit (Hasibuan & Triase, 2022; "
           "Fauzi dkk., 2025). SoundWave memakai Firebase untuk autentikasi "
           "pengguna, penyimpanan data, dan pengiriman notifikasi.", indentasi=1.27,
      spasi_setelah=10)

    p(doc, "2.2.3  Midtrans", rata="left", tebal=True, spasi_setelah=6)
    p(doc, "Midtrans merupakan penyedia layanan payment gateway yang "
           "memungkinkan aplikasi menerima pembayaran melalui berbagai kanal, "
           "seperti transfer bank, kartu kredit, dan kode pembayaran. Integrasi "
           "payment gateway memindahkan beban penanganan transaksi ke pihak "
           "ketiga, sehingga aplikasi hanya perlu menangani status pembayaran "
           "(Kusumarini & Avito, 2025). SoundWave memakai Midtrans dalam mode "
           "sandbox agar pengujian tidak melibatkan uang sungguhan.", indentasi=1.27,
      spasi_setelah=10)

    p(doc, "2.2.4  Animasi Lottie", rata="left", tebal=True, spasi_setelah=6)
    p(doc, "Lottie merupakan format animasi berbasis berkas JSON yang "
           "menyimpan animasi vektor. Berbeda dari animasi berbasis video, "
           "animasi vektor tetap tajam pada segala resolusi dan berukuran jauh "
           "lebih kecil. Pemilihan teknik animasi perlu mempertimbangkan beban "
           "komputasi perangkat, karena animasi yang berat dapat menurunkan "
           "kinerja aplikasi (Biørn-Hansen dkk., 2019). SoundWave memakai empat "
           "animasi Lottie untuk menandai status memuat, galat, pembayaran "
           "berhasil, dan pemindaian tiket berhasil.", indentasi=1.27,
      spasi_setelah=10)

    p(doc, "2.2.5  Pemutar Audio dan Video", rata="left", tebal=True,
      spasi_setelah=6)
    p(doc, "Pemutaran audio pada SoundWave menggunakan paket just_audio, "
           "sedangkan pemutaran trailer menggunakan pemutar video tersemat "
           "berbasis YouTube. Salah satu keputusan teknis yang penting adalah "
           "penggunaan satu pemutar bersama, bukan satu pemutar untuk setiap "
           "komponen antarmuka. Tanpa pengaturan ini, dua sumber audio dapat "
           "berbunyi bersamaan ketika pengguna berpindah layar.", indentasi=1.27,
      spasi_setelah=10)

    p(doc, "2.2.6  Proyeksi Tiga Dimensi pada Kanvas", rata="left", tebal=True,
      spasi_setelah=6)
    p(doc, "Visualisasi panggung pada SoundWave tidak menggunakan mesin render "
           "tiga dimensi berbasis peramban. Geometri panggung disusun dari "
           "sejumlah balok yang diproyeksikan ke bidang dua dimensi melalui "
           "perhitungan perspektif, lalu digambar pada kanvas aplikasi. "
           "Pendekatan serupa telah dipakai pada visualisasi objek tiga dimensi "
           "di perangkat Android, dengan catatan bahwa akurasi proyeksi perlu "
           "disesuaikan dengan sudut pandang yang diinginkan (Supriyono, 2020).",
      indentasi=1.27, spasi_setelah=10)

    sub(doc, "2.3  Software dan Hardware")

    p(doc, "2.3.1  Perangkat Lunak", rata="left", tebal=True, spasi_setelah=6)
    p(doc, "Perangkat lunak yang digunakan dalam pengembangan aplikasi SoundWave "
           "dirangkum pada Tabel 2.2.", indentasi=1.27, spasi_setelah=8)

    p(doc, "Tabel 2.2  Perangkat Lunak yang Digunakan", rata="center",
      tebal=True, ukuran=11, spasi_setelah=6)

    tabel(doc,
          ["Kategori", "Nama dan Versi", "Kegunaan"],
          [
              ["Sistem operasi", "Windows 11 Home Single Language (64-bit)",
               "Lingkungan pengembangan"],
              ["Kerangka kerja", "Flutter 3.47.6 (stable)",
               "Membangun antarmuka aplikasi"],
              ["Bahasa", "Dart", "Menuliskan logika aplikasi"],
              ["Editor kode", "Visual Studio Code, Android Studio",
               "Menulis dan menjalankan kode"],
              ["Basis data", "Cloud Firestore", "Menyimpan data aplikasi"],
              ["Backend", "Node.js dengan Express", "Menangani transaksi "
                                                     "pembayaran"],
              ["Payment gateway", "Midtrans (mode sandbox)",
               "Memproses pembayaran"],
              ["Perancangan", "draw.io", "Membuat flowchart, ERD, dan DFD"],
              ["Manajemen referensi", "Mendeley (gaya APA edisi ke-7)",
               "Mengelola sitasi dan daftar pustaka"],
          ],
          lebar=[3.2, 5.8, 5.6])

    p(doc, "", spasi_setelah=6)

    p(doc, "2.3.2  Perangkat Keras", rata="left", tebal=True, spasi_setelah=6)
    p(doc, "Perangkat keras yang digunakan dalam pengembangan dan pengujian "
           "dirangkum pada Tabel 2.3.", indentasi=1.27, spasi_setelah=8)

    p(doc, "Tabel 2.3  Perangkat Keras yang Digunakan", rata="center",
      tebal=True, ukuran=11, spasi_setelah=6)

    tabel(doc,
          ["Perangkat", "Spesifikasi"],
          [
              ["Laptop", "HP Laptop 14s-dk1xxx"],
              ["Prosesor", "AMD Ryzen 3 3250U with Radeon Graphics "
                           "(2 inti, 4 thread)"],
              ["Memori", "8 GB"],
              ["Kartu grafis", "AMD Radeon Graphics (terintegrasi)"],
              ["Penyimpanan", "SSD NVMe 256 GB dan HDD 1 TB"],
              ["Sistem operasi", "Windows 11 Home Single Language 64-bit"],
              ["Perangkat uji", "[MEREK DAN TIPE HP ANDROID]"],
              ["Versi Android", "[VERSI ANDROID]"],
          ],
          lebar=[4.4, 10.2])

    p(doc, "", spasi_setelah=6)
    p(doc, "Spesifikasi perangkat keras di atas perlu dicatat karena berkaitan "
           "dengan hasil pengujian. Perangkat dengan memori terbatas menuntut "
           "pengelolaan aset multimedia yang lebih hati-hati, terutama pada "
           "pemuatan gambar dan pemutaran audio yang berjalan bersamaan.",
      indentasi=1.27, spasi_setelah=10)

    doc.add_page_break()

    # ==================== DAFTAR PUSTAKA ====================
    p(doc, "DAFTAR PUSTAKA", rata="center", tebal=True, ukuran=14,
      spasi_setelah=18)

    pustaka = [
        "Biørn-Hansen, A., Grønli, T.-M., & Ghinea, G. (2019). Animations in "
        "cross-platform mobile applications: An evaluation of tools, metrics "
        "and performance. Sensors, 19(9), 2081. "
        "https://doi.org/10.3390/s19092081",

        "Fauzi, S. N., Yulisusianto, G., & Setiawan, R. B. (2025). Implementasi "
        "database realtime pada aplikasi E-Siku berbasis Firebase. Jurnal "
        "Telkommil, 6(1), 7–25. https://doi.org/10.54317/kom.v6i1.559",

        "Hasibuan, M. I. Z., & Triase, T. (2022). Implementasi sistem database "
        "NoSQL secara realtime menggunakan Firebase Realtime Database pada "
        "aplikasi OurtIcle. SIBATIK JOURNAL, 2(1), 1–24. "
        "https://doi.org/10.54443/sibatik.v2i1.489",

        "Ikhwan, A., Amanda, N., Sinaga, N., & Batubara, N. R. (2026). "
        "Pengembangan multimedia interaktif edukasi internet sehat menggunakan "
        "metode Multimedia Development Life Cycle (MDLC). Journal of Society "
        "and Scientific Studies, 2(3), 13–24. "
        "https://doi.org/10.62504/scientiva42",

        "Kusumarini, C. D., & Avito, R. F. (2025). Creation of an Android-based "
        "AM Futsal field rental application using Flutter and JS Node with "
        "Midtrans integration as a payment gateway. GLOBAL: Jurnal Lentera "
        "BITEP, 3(01), 17–25. https://doi.org/10.59422/global.v3i01.745",

        "Kusumapratiwi, A. C., & Waluyo, A. F. (2023). Mobile application for "
        "bus ticket booking effectiveness. International Journal of Computer "
        "Applications, 185(39), 9–16. "
        "https://doi.org/10.5120/ijca2023923195",

        "Lendo, R., Jacobus, A., & Mapaly, H. A. (2023). Rancang bangun "
        "aplikasi perpustakaan digital berbasis mobile menggunakan framework "
        "Flutter. Jurnal Teknik Informatika, 18(1), 353–362. "
        "https://doi.org/10.35793/jti.v18i1.50490",

        "Patil, S. G., Jadimath, V., Elemmi, M. C., Dhumale, P., & N. M, N. "
        "(2022). Mobile application development using Flutter SDK. Journal of "
        "Computer Science Engineering and Software Testing, 8(1), 50–64. "
        "https://doi.org/10.46610/jocses.2022.v08i01.004",

        "Putra Kang, A., & Fauzi, R. (2025). Perancangan animasi 3D edukatif "
        "tentang modus penipuan WhatsApp dengan metode MDLC. Computer and "
        "Science Industrial Engineering (COMASIE), 13(4), 21–29. "
        "https://doi.org/10.33884/comasiejournal.v13i4.10470",

        "Supriyono, H. (2020). Android mobile augmented reality application for "
        "3D visualization of museum collectibles in Surakarta. International "
        "Journal of Emerging Trends in Engineering Research, 8(8), 4293–4300. "
        "https://doi.org/10.30534/ijeter/2020/40882020",

        "Tulus, A., Sitompul, N., Mulyanto, U. H., Wijaya, V., Fiermeiza, N. A., "
        "& Wahyuni, S. (2026). Perancangan animasi 3D jalan Bypass Sedau ke Sei "
        "Rasau menggunakan metode MDLC. Rabit: Jurnal Teknologi dan Sistem "
        "Informasi Univrab, 11(2), 3850–3864. "
        "https://doi.org/10.36341/rabit.v11i2.8198",
    ]

    for s in pustaka:
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

    doc.save(KELUARAN)
    print(f"tersimpan: {KELUARAN}")
    print("  Bab I + II + Daftar Pustaka (11 referensi)")
    print("  Format: Times New Roman 12, spasi 1,5, margin 4-4-3-3")


if __name__ == "__main__":
    buat()
