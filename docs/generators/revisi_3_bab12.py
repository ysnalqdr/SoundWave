"""
TAHAP 3 — Humanisasi + SPOK untuk Kata Pengantar, Bab I, dan Bab II.

PRINSIP
  - Subjek eksplisit di setiap kalimat ("penulis", "Ikhwan dkk. (2026)").
  - Verba aktif: menyatakan, mencatat, membangun, memakai.
  - Keterangan di akhir: waktu, tempat, cara.
  - Kalimat pendek, satu gagasan per kalimat.
  - Sitasi bentuk naratif ("Ikhwan dkk. (2026) mendefinisikan ...") lebih
    banyak daripada bentuk kurung, supaya pelaku kalimat jelas.
  - Paragraf yang sudah wajar hanya dirapikan, bukan ditulis ulang.

Paragraf dicocokkan lewat potongan awal teksnya, bukan nomor, supaya aman
kalau urutan bergeser.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

# (awalan_teks_lama, teks_baru)
GANTI: list[tuple[str, str]] = [

    # ================= KATA PENGANTAR =================
    ("Puji syukur penulis panjatkan",
     "Puji syukur penulis panjatkan kepada Tuhan Yang Maha Esa karena atas rahmat-Nya "
     "makalah Proyek Akhir Sistem Multimedia ini dapat diselesaikan. Penulis menyusun "
     "makalah ini sebagai bagian dari penilaian mata kuliah Sistem Multimedia yang "
     "menggunakan pendekatan Project Based Learning."),

    ("Makalah ini membahas penerapan metode Multimedia Development Life Cycle",
     "Makalah ini membahas penerapan metode Multimedia Development Life Cycle (MDLC) dalam "
     "pengembangan aplikasi ticketing konser berbasis mobile bernama SoundWave. Aplikasi "
     "tersebut memuat elemen teks, gambar, audio, video, animasi, dan objek tiga dimensi "
     "sebagai bagian dari fungsi utamanya. Penulis tidak menempatkan elemen tersebut "
     "sebagai hiasan antarmuka."),

    # ================= BAB I — 1.1 LATAR BELAKANG =================
    ("Konser musik merupakan salah satu bentuk hiburan",
     "Konser musik merupakan salah satu bentuk hiburan yang permintaannya meningkat setiap "
     "tahun. Seiring pertumbuhan itu, cara masyarakat memperoleh tiket ikut berubah. "
     "Masyarakat beralih dari antrean di lokasi penjualan menuju pemesanan daring melalui "
     "aplikasi. Penulis menilai perubahan ini membawa kepraktisan sekaligus memunculkan "
     "persoalan baru yang jarang disadari."),

    # paragraf definisi lama (mengandung field Mendeley) -> DIHAPUS
    ("Multimedia adalah kombinasi teks, gambar, audio, video, dan animasi",
     None),

    ("Keterbatasan tersebut menjadi persoalan",
     "Penulis menilai persoalan itu muncul karena keputusan membeli tiket konser bersifat "
     "emosional, bukan semata transaksional. Seseorang membeli tiket karena tertarik pada "
     "musiknya. Ia juga membayangkan suasana yang akan dialami dan pengalaman yang akan "
     "diperoleh. Ketika aplikasi hanya menampilkan teks dan poster, ketertarikan itu sulit "
     "tumbuh. Akibatnya keputusan pembelian lebih banyak ditentukan oleh faktor luar "
     "aplikasi, misalnya unggahan media sosial atau rekomendasi teman. Informasi dari "
     "penyelenggara sendiri jarang menjadi penentu."),

    ("Sebagian besar aplikasi ticketing yang beredar",
     "Sebagian besar aplikasi ticketing yang beredar saat ini masih berperan sebagai katalog "
     "dan mesin pembayaran. Informasi yang disajikan terbatas pada teks dan gambar statis, "
     "yaitu judul konser, tanggal, lokasi, dan harga tiket. Calon pembeli tidak memperoleh "
     "gambaran mengenai suasana konser. Mereka juga tidak dapat mendengar cuplikan karya "
     "penampil dan tidak dapat membayangkan tata panggung tempat ia akan hadir. Fadhilah dkk. "
     "(2025) mencatat bahwa pemesanan tiket konser secara konvensional masih menghadirkan "
     "kendala akses informasi bagi konsumen. Aplikasi pemesanan tiket yang dikembangkan "
     "sebelumnya memang telah berhasil memindahkan proses transaksi ke perangkat mobile. "
     "Namun aplikasi tersebut belum menyentuh aspek pengalaman sebelum pembelian."),

    ("Perkembangan teknologi multimedia membuka kemungkinan",
     "Perkembangan teknologi multimedia membuka kemungkinan untuk mengatasi keterbatasan "
     "tersebut. Ikhwan dkk. (2026) mendefinisikan multimedia sebagai kombinasi dua unsur atau "
     "lebih dari teks, gambar, suara, animasi, dan video yang disampaikan secara terpadu "
     "melalui perangkat digital. Aplikasi mobile sekarang tidak lagi dibatasi teks dan "
     "gambar. Aplikasi dapat memuat audio, video, animasi vektor, bahkan objek tiga dimensi "
     "tanpa memerlukan perangkat tambahan."),

    ("Penerapan animasi pada aplikasi mobile lintas platform",
     "Habibi dan Athoillah (2024) menunjukkan bahwa pengembangan sistem pemesanan tiket "
     "konser berbasis web dapat meningkatkan pengalaman pengguna. Penulis menarik satu "
     "pelajaran dari temuan tersebut. Penambahan elemen multimedia bukan sekadar urusan "
     "estetika, melainkan keputusan teknis yang perlu direncanakan. Perencanaan itu mencakup "
     "pemilihan format berkas, ukuran aset, dan beban komputasi yang ditanggung perangkat."),

    ("Berdasarkan uraian tersebut, penulis mengembangkan SoundWave",
     "Berdasarkan uraian tersebut, penulis mengembangkan SoundWave. SoundWave merupakan "
     "aplikasi penjualan tiket konser berbasis mobile yang memuat lima elemen multimedia "
     "sebagai bagian dari fungsi utamanya. Aplikasi menyediakan cuplikan audio dua puluh "
     "detik agar calon pembeli dapat mengenal karya penampil sebelum membeli. Video trailer "
     "memberi gambaran suasana konser. Animasi vektor menandai status sistem, seperti proses "
     "memuat, pembayaran berhasil, dan hasil pemindaian tiket. Objek tiga dimensi menampilkan "
     "visualisasi panggung sehingga pembeli dapat membayangkan tata venue."),

    ("Pengembangan aplikasi multimedia memerlukan metode",
     "Pengembangan aplikasi multimedia memerlukan metode yang sesuai. Metode Multimedia "
     "Development Life Cycle (MDLC) versi Luther\u2013Sutopo menyediakan enam tahap berurutan, "
     "yaitu concept, design, material collecting, assembly, testing, dan distribution. Ikhwan "
     "dkk. (2026) menerapkan metode tersebut pada pengembangan multimedia interaktif dan "
     "melaporkan bahwa keenam tahapnya berjalan berurutan. Yang membedakan MDLC dari metode "
     "lain adalah tahap material collecting. Tahap itu memisahkan pengumpulan aset multimedia "
     "sebagai pekerjaan tersendiri sebelum perakitan aplikasi dimulai. Pemisahan tersebut "
     "relevan bagi SoundWave karena aplikasi ini bergantung pada aset audio, video, animasi, "
     "dan model tiga dimensi. Seluruh aset itu harus dikumpulkan dan diverifikasi lisensinya "
     "lebih dahulu."),

    ("MDLC juga telah diterapkan pada pengembangan yang menghasilkan",
     "Margaretha dan Voutama (2023) memanfaatkan Unified Modeling Language untuk merancang "
     "sistem informasi pemesanan tiket konser musik berbasis web. Perancangan semacam itu "
     "menuntut pemetaan alur yang jelas sebelum penulisan kode dimulai. Penulis mengikuti "
     "prinsip yang sama. Karena itu MDLC dipilih sebagai metode pengembangan dalam penelitian "
     "ini, sementara aplikasi SoundWave menjadi objek penerapannya."),

    # ================= BAB I — 1.2 s.d. 1.4 =================
    ("Berdasarkan latar belakang di atas, rumusan masalah",
     "Berdasarkan latar belakang di atas, penulis merumuskan tiga pertanyaan penelitian "
     "sebagai berikut."),

    ("Agar pembahasan terarah, penelitian ini dibatasi",
     "Agar pembahasan terarah, penulis membatasi penelitian ini pada lima hal berikut."),

    ("Penelitian ini bertujuan untuk:",
     "Penulis menetapkan tiga tujuan penelitian sebagai berikut."),

    ("Manfaat yang diharapkan dari penelitian ini adalah",
     "Penulis mengharapkan empat manfaat dari penelitian ini."),

    # ================= BAB II — 2.1 =================
    ("Multimedia merupakan kombinasi dua unsur atau lebih",
     "Ikhwan dkk. (2026) mendefinisikan multimedia sebagai kombinasi dua unsur atau lebih dari "
     "teks, gambar, suara, animasi, dan video yang disampaikan secara terpadu melalui "
     "perangkat digital. Kata terpadu menjadi kunci definisi tersebut. Elemen-elemen itu tidak "
     "berdiri sendiri, melainkan saling melengkapi untuk menyampaikan satu pesan. Sistem "
     "multimedia adalah sistem yang memanfaatkan lebih dari satu elemen tersebut secara "
     "bersamaan untuk mencapai tujuan tertentu."),

    ("Elemen multimedia dibedakan menjadi lima jenis",
     "Penulis membedakan elemen multimedia menjadi lima jenis. Teks merupakan elemen paling "
     "dasar dan paling banyak dipakai karena mampu menyampaikan informasi presisi, seperti "
     "nama, angka, dan prosedur. Gambar menyampaikan informasi visual yang sulit dijelaskan "
     "dengan kata-kata. Audio menambahkan dimensi waktu dan suasana. Video menggabungkan "
     "gambar bergerak dengan suara sehingga mampu menyampaikan urutan kejadian. Animasi "
     "menampilkan perubahan bentuk atau posisi secara berurutan untuk menjelaskan proses atau "
     "menarik perhatian."),

    ("Selain kelima elemen di atas, aplikasi SoundWave",
     "Selain kelima elemen di atas, aplikasi SoundWave juga menerapkan objek tiga dimensi "
     "sebagai elemen tambahan. Aplikasi menghitung visualisasi panggung menggunakan proyeksi "
     "perspektif pada kanvas aplikasi, tanpa memerlukan mesin render tiga dimensi berbasis "
     "peramban. Penulis memilih pendekatan ini setelah pengujian menunjukkan bahwa mesin "
     "render berbasis WebGL tidak dapat diandalkan pada perangkat uji yang digunakan."),

    # ================= BAB II — 2.2 TEKNOLOGI =================
    ("Flutter merupakan kerangka kerja sumber terbuka",
     "Flutter merupakan kerangka kerja sumber terbuka untuk membangun aplikasi mobile dari "
     "satu basis kode. Flutter menggunakan bahasa Dart dan merender antarmuka secara langsung "
     "melalui mesin grafisnya sendiri, sehingga tampilan konsisten di berbagai perangkat. "
     "Lendo dkk. (2023) membangun aplikasi perpustakaan digital berbasis mobile dengan "
     "framework Flutter dan melaporkan bahwa satu basis kode cukup untuk menangani kebutuhan "
     "antarmuka aplikasi tersebut. Anmi dkk. (2025) menerapkan Flutter bersama Firebase pada "
     "aplikasi live streaming dan mencatat hal serupa. Penulis membangun aplikasi SoundWave "
     "dengan Flutter versi 3.47.6 dan bahasa Dart."),

    ("Firebase merupakan layanan backend",
     "Firebase merupakan layanan backend yang menyediakan basis data dokumen berbasis cloud "
     "dengan kemampuan pembaruan secara waktu nyata. Basis data jenis NoSQL ini menyimpan data "
     "dalam bentuk dokumen yang dikelompokkan ke dalam koleksi, sehingga skema dapat berkembang "
     "tanpa migrasi yang rumit. Anmi dkk. (2025) memanfaatkan Firebase pada aplikasi live "
     "streaming dan melaporkan bahwa layanan ini menangani autentikasi serta penyimpanan data "
     "secara terpadu. Penulis memakai Firebase untuk tiga keperluan pada SoundWave, yaitu "
     "autentikasi pengguna, penyimpanan data, dan pengiriman notifikasi."),

    ("Midtrans merupakan penyedia layanan payment gateway",
     "Midtrans merupakan penyedia layanan payment gateway yang memungkinkan aplikasi menerima "
     "pembayaran melalui berbagai kanal, seperti transfer bank, kartu kredit, dan kode "
     "pembayaran. Integrasi payment gateway memindahkan beban penanganan transaksi ke pihak "
     "ketiga, sehingga aplikasi hanya perlu menangani status pembayaran. Kusumarini dan Avito "
     "(2025) mengintegrasikan Midtrans pada aplikasi penyewaan lapangan futsal berbasis "
     "Android dan melaporkan bahwa integrasi tersebut menyederhanakan alur pembayaran. "
     "Nariswari dkk. (2023) membangun sistem e-ticket berbasis payment gateway dan mencatat "
     "manfaat serupa. Penulis memakai Midtrans dalam mode sandbox agar pengujian tidak "
     "melibatkan uang sungguhan."),

    ("Lottie merupakan format animasi berbasis berkas JSON",
     "Lottie merupakan format animasi berbasis berkas JSON yang menyimpan animasi vektor. "
     "Berbeda dari animasi berbasis video, animasi vektor tetap tajam pada segala resolusi dan "
     "berukuran jauh lebih kecil. Anmi dkk. (2025) mencatat bahwa pemilihan format aset perlu "
     "mempertimbangkan beban komputasi perangkat, karena aset yang berat dapat menurunkan "
     "kinerja aplikasi. Penulis memakai empat animasi Lottie untuk menandai status memuat, "
     "galat, pembayaran berhasil, dan pemindaian tiket berhasil."),

    ("Pemutaran audio pada SoundWave menggunakan paket just_audio",
     "Penulis memutar audio pada SoundWave menggunakan paket just_audio. Penulis memutar "
     "trailer menggunakan pemutar video tersemat berbasis YouTube. Salah satu keputusan teknis "
     "yang penting adalah penggunaan satu pemutar bersama, bukan satu pemutar untuk setiap "
     "komponen antarmuka. Tanpa pengaturan ini, dua sumber audio dapat berbunyi bersamaan "
     "ketika pengguna berpindah layar."),

    ("Visualisasi panggung pada SoundWave tidak menggunakan mesin render",
     "Penulis tidak menggunakan mesin render tiga dimensi berbasis peramban untuk visualisasi "
     "panggung pada SoundWave. Penulis menyusun geometri panggung dari sejumlah balok. "
     "Balok-balok itu diproyeksikan ke bidang dua dimensi melalui perhitungan perspektif, lalu "
     "digambar pada kanvas aplikasi. Margaretha dan Voutama (2023) menekankan bahwa "
     "perancangan visual perlu memetakan sudut pandang lebih dahulu agar hasilnya sesuai "
     "harapan. Penulis mengikuti prinsip itu dengan menyesuaikan akurasi proyeksi terhadap "
     "sudut pandang yang diinginkan."),

    # ================= BAB II — 2.3 =================
    ("Perangkat lunak yang digunakan dalam pengembangan aplikasi SoundWave",
     "Penulis merangkum perangkat lunak yang digunakan dalam pengembangan aplikasi SoundWave "
     "pada Tabel 2.2."),

    ("Perangkat keras yang digunakan dalam pengembangan dan pengujian",
     "Penulis merangkum perangkat keras yang digunakan dalam pengembangan dan pengujian pada "
     "Tabel 2.3."),

    ("Spesifikasi perangkat keras di atas perlu dicatat",
     "Penulis mencatat spesifikasi perangkat keras di atas karena berkaitan dengan hasil "
     "pengujian. Perangkat dengan memori terbatas menuntut pengelolaan aset multimedia yang "
     "lebih hati-hati, terutama pada pemuatan gambar dan pemutaran audio yang berjalan "
     "bersamaan."),
]


def main() -> None:
    doc = Document(str(BERKAS))
    terpakai: set[int] = set()
    hapus: list[int] = []
    gagal: list[str] = []

    for awalan, baru in GANTI:
        cocok = None
        for i, par in enumerate(doc.paragraphs):
            if i in terpakai:
                continue
            if par.text.strip().startswith(awalan):
                cocok = i
                break
        if cocok is None:
            gagal.append(awalan[:52])
            continue

        terpakai.add(cocok)
        par = doc.paragraphs[cocok]

        if baru is None:
            hapus.append(cocok)
            continue

        for r in list(par.runs):
            r._element.getparent().remove(r._element)
        run = par.add_run(baru)
        run.font.name = FONT
        run.font.size = Pt(12)

    # hapus paragraf yang ditandai (indeks menurun supaya tidak bergeser)
    for i in sorted(hapus, reverse=True):
        el = doc.paragraphs[i]._element
        el.getparent().remove(el)

    doc.save(str(BERKAS))
    print(f"diganti : {len(terpakai) - len(hapus)}")
    print(f"dihapus : {len(hapus)}")
    if gagal:
        print("GAGAL cocok:")
        for g in gagal:
            print("  -", g)

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    print(f"\nparagraf: {len(d.paragraphs)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")
    teks = "\n".join(p.text for p in d.paragraphs)
    for k in ("[SITASI:", "et al.", "masa kini", "Temuan ini menunjukkan",
              "berfungsi sebagai katalog", "Kekhasan metode"):
        print(f"  '{k}': {teks.count(k)}")


if __name__ == "__main__":
    main()
