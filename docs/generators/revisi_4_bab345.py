"""
TAHAP 4 — Humanisasi + SPOK untuk Bab III, IV, dan V.

PERHATIAN: Bab IV memuat 2 blok kode dan 18 caption gambar.
Blok kode TIDAK disentuh sama sekali. Hanya narasi di sekitarnya yang diubah.
Paragraf dicocokkan lewat awalan teks, dan paragraf berisi field Mendeley
atau blok kode dilewati otomatis.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

GANTI: list[tuple[str, str]] = [

    # ================= BAB III =================
    ("Penelitian ini menggunakan metode Multimedia Development Life Cycle (MDLC) versi Luther",
     "Penulis menggunakan metode Multimedia Development Life Cycle (MDLC) versi "
     "Luther\u2013Sutopo yang terdiri atas enam tahap berurutan. Tabel 3.1 memetakan setiap "
     "tahap terhadap pekerjaan yang dilakukan pada pengembangan aplikasi SoundWave."),

    ("Tahap ketiga, yaitu material collecting, menjadi pembeda utama",
     "Tahap ketiga, yaitu material collecting, menjadi pembeda utama MDLC dibanding metode "
     "pengembangan perangkat lunak umum. Pada aplikasi yang tidak memuat multimedia, aset "
     "visual biasanya dikerjakan sekaligus saat perakitan. Pada SoundWave, penulis "
     "mengumpulkan dan memverifikasi aset multimedia lebih dahulu karena jumlahnya banyak. "
     "Sebagian aset itu berasal dari pihak ketiga dengan lisensi tertentu."),

    ("Kebutuhan fungsional adalah layanan yang harus disediakan",
     "Kebutuhan fungsional merupakan layanan yang harus disediakan aplikasi kepada pengguna. "
     "Penulis merangkum kebutuhan tersebut beserta aktor yang memicunya pada Tabel 3.2."),

    ("Kebutuhan non-fungsional adalah batasan kualitas",
     "Kebutuhan non-fungsional merupakan batasan kualitas yang harus dipenuhi aplikasi. "
     "Penulis merangkum kebutuhan tersebut pada Tabel 3.3."),

    ("Alur kerja aplikasi digambarkan dalam dua flowchart",
     "Penulis menggambarkan alur kerja aplikasi dalam dua flowchart. Flowchart pertama "
     "menunjukkan alur pengguna dari membuka aplikasi hingga memindai tiket di gerbang masuk. "
     "Flowchart kedua menunjukkan alur admin dari masuk hingga menyusun laporan."),

    ("Alur pengguna dimulai dari halaman splash",
     "Alur pengguna dimulai dari halaman splash, lalu dilanjutkan dengan pemeriksaan status "
     "akun. Pengguna yang belum memiliki akun diarahkan ke halaman pendaftaran. Pengguna yang "
     "sudah memiliki akun langsung masuk. Setelah masuk, pengguna menelusuri daftar konser, "
     "membuka detail konser, memilih tipe tiket, mengisi data pembelian, dan melanjutkan ke "
     "pembayaran. Bila pembayaran berhasil, sistem menerbitkan tiket digital beserta kode QR. "
     "Bila pembayaran tidak diselesaikan dalam batas waktu, reservasi berakhir dan sistem "
     "mengembalikan kuota tiket."),

    ("Alur admin dimulai dari halaman masuk",
     "Alur admin dimulai dari halaman masuk, lalu dilanjutkan ke dashboard. Admin membuat data "
     "konser beserta aset multimedia, mengatur tipe tiket dan kuota, lalu mempublikasikan "
     "konser. Pada hari penyelenggaraan, admin memindai kode QR tiket di gerbang masuk. "
     "Pemindaian yang sah mengubah status tiket menjadi terpakai. Pemindaian yang tidak sah "
     "sistem tolak."),

    ("Storyboard merupakan sketsa kasar antarmuka",
     "Storyboard merupakan sketsa kasar antarmuka setiap layar. Penulis membuat sketsa sebelum "
     "penulisan kode untuk memastikan tata letak dan alur setiap layar telah dipikirkan. "
     "Tabel 3.4 memuat daftar enam belas layar yang digambar."),

    ("Storyboard lengkap disajikan pada Lampiran",
     "Penulis menyajikan storyboard lengkap pada Lampiran. Layar Detail Konser menjadi layar "
     "terpenting karena memuat lima elemen multimedia sekaligus, yaitu teks, gambar, audio, "
     "video, dan objek tiga dimensi."),

    # ================= BAB IV =================
    ("Aplikasi dibangun menggunakan Flutter 3.47.6",
     "Penulis membangun aplikasi menggunakan Flutter 3.47.6 dengan bahasa Dart. Penulis "
     "membagi kode organisasi menjadi empat lapisan. Lapisan pertama adalah layar sebagai "
     "antarmuka. Lapisan kedua adalah komponen sebagai bagian antarmuka yang dapat dipakai "
     "ulang. Lapisan ketiga adalah layanan sebagai penghubung ke sumber data. Lapisan keempat "
     "adalah model sebagai representasi data. Pemisahan ini memudahkan pengujian karena "
     "setiap lapisan dapat diuji secara terpisah."),

    ("Pemutaran audio menggunakan paket just_audio",
     "Penulis memutar audio menggunakan paket just_audio. Terdapat dua keputusan teknis yang "
     "perlu dijelaskan. Pertama, aplikasi hanya memakai satu pemutar untuk cuplikan lagu dan "
     "satu pemutar untuk efek suara. Aplikasi tidak membuat pemutar baru pada setiap komponen. "
     "Kedua, cuplikan lagu dibatasi dua puluh detik sementara berkasnya bisa lebih panjang. "
     "Karena itu aplikasi memeriksa posisi pemutaran secara berkala lalu menjeda secara paksa. "
     "Kode 4.1 memperlihatkan mekanisme tersebut."),

    ("Tanpa pengawas ini, memilih potongan dua puluh detik",
     "Tanpa pengawas ini, memilih potongan dua puluh detik dari lagu berdurasi empat menit "
     "akan memutar seluruh lagu."),

    ("Trailer konser diputar menggunakan pemutar video tersemat",
     "Penulis memutar trailer konser menggunakan pemutar video tersemat berbasis YouTube. "
     "Aplikasi tidak memuat video sebelum pengguna menekan tombol putar. Penulis mengambil "
     "keputusan ini karena memuat pemutar video secara otomatis di dalam daftar panjang akan "
     "menghabiskan memori dan memperlambat penggulungan halaman. Berbeda dari audio, trailer "
     "tidak memiliki sumber cadangan. Bila URL tidak valid, aplikasi tidak menampilkan seksi "
     "trailer sama sekali. Penulis menilai trailer yang salah lebih membingungkan daripada "
     "tidak ada trailer."),

    ("Animasi memakai format Lottie",
     "Penulis memakai format Lottie untuk animasi, yaitu animasi vektor berbasis berkas JSON. "
     "Aplikasi memakai empat animasi untuk menandai status sistem, yaitu status memuat, status "
     "galat, pembayaran berhasil, dan pemindaian tiket berhasil. Penulis memilih animasi "
     "vektor karena tetap tajam pada segala resolusi dan berukuran jauh lebih kecil dibanding "
     "animasi berbasis video."),

    ("Visualisasi panggung diimplementasikan tanpa mesin render",
     "Penulis mengimplementasikan visualisasi panggung tanpa mesin render tiga dimensi berbasis "
     "peramban. Pendekatan awal menggunakan pemutar model berbasis WebGL. Namun pengujian pada "
     "perangkat uji menunjukkan bahwa halaman berhasil dimuat sementara skripnya tidak "
     "dieksekusi, sehingga model tidak pernah tampil. Karena itu penulis menghitung proyeksi "
     "sendiri menggunakan kanvas Flutter. Penulis menyusun geometri panggung dari sejumlah "
     "balok yang diproyeksikan ke bidang dua dimensi, seperti diperlihatkan Kode 4.2."),

    ("Setiap balok diproyeksikan dengan perhitungan perspektif",
     "Setiap balok diproyeksikan dengan perhitungan perspektif lalu digambar pada kanvas. "
     "Aplikasi juga menskalakan panggung secara otomatis agar seluruh bagiannya muat di dalam "
     "bingkai."),

    ("Pembayaran ditangani oleh Midtrans dalam mode sandbox",
     "Midtrans menangani pembayaran dalam mode sandbox. Aplikasi mengirim rincian tagihan ke "
     "layanan backend. Backend meneruskannya ke Midtrans, lalu Midtrans mengembalikan token "
     "pembayaran. Setelah pembayaran diselesaikan, Midtrans mengirim pemberitahuan ke backend. "
     "Backend kemudian mengubah status pesanan dan menerbitkan tiket."),

    ("Perhitungan harga dilakukan di satu tempat saja",
     "Penulis melakukan perhitungan harga di satu tempat saja. Modul perhitungan yang sama "
     "dipakai oleh aplikasi dan backend. Urutannya adalah subtotal, dikurangi diskon, lalu "
     "ditambah pajak, ditambah biaya layanan, dan ditambah biaya tetap. Penyeragaman ini "
     "penting agar angka yang dilihat pengguna sama persis dengan angka yang ditagih."),

    ("Bagian ini memuat tangkapan layar hasil akhir",
     "Bagian ini memuat tangkapan layar hasil akhir aplikasi. Penulis mengambil seluruh gambar "
     "langsung dari perangkat uji, bukan dari rancangan."),

    ("Pengujian black box dilakukan untuk memastikan",
     "Penulis melakukan pengujian black box untuk memastikan setiap fungsi berjalan sesuai "
     "harapan tanpa meninjau struktur kode. Pengujian memakai dua teknik, yaitu equivalence "
     "partitioning dan boundary value analysis. Equivalence partitioning mengelompokkan input "
     "ke kelas yang dianggap setara sehingga cukup satu wakil dari setiap kelas diuji. Boundary "
     "value analysis menguji nilai tepat di batas kelas karena kesalahan paling sering muncul "
     "di titik tersebut. Rosmiati (2021) menerapkan kedua teknik itu pada pengujian sistem dan "
     "melaporkan bahwa keduanya membantu menemukan kesalahan pada batas nilai."),

    ("Pengujian mencakup tujuh kelompok fitur",
     "Pengujian mencakup tujuh kelompok fitur dengan total enam puluh lima kasus uji. Tabel 4.1 "
     "memuat rekapitulasi hasilnya, sedangkan tabel lengkap penulis sajikan pada Lampiran."),

    ("Seluruh enam puluh lima kasus menghasilkan keluaran",
     "Seluruh enam puluh lima kasus menghasilkan keluaran sesuai harapan, sehingga persentase "
     "keberhasilan pengujian fungsional mencapai 100%. Selain pengujian manual tersebut, "
     "aplikasi memiliki 768 pengujian otomatis yang dijalankan pada setiap perubahan kode. "
     "Keduanya berbeda peran. Pengujian black box membuktikan perilaku aplikasi benar dari sisi "
     "pengguna. Pengujian otomatis menjaga agar perilaku tersebut tidak rusak ketika kode "
     "diubah."),

    ("Tiga kasus dalam pengujian ini merupakan kesalahan nyata",
     "Tiga kasus dalam pengujian ini merupakan kesalahan nyata yang penulis temukan saat "
     "pengembangan dan kemudian perbaiki. Pertama, filter harga pada halaman Jelajah tidak "
     "berpengaruh karena baris terakhir fungsi filter selalu menimpa hasilnya dengan pengurutan "
     "tanggal. Kedua, kode promo yang dibuat admin tidak pernah ditemukan backend karena "
     "aplikasi menyimpannya dengan pengenal acak sementara backend mencari berdasarkan kode. "
     "Ketiga, formulir konser menerima harga nol dan negatif. Penulis mempertahankan ketiganya "
     "sebagai uji regresi."),

    ("Selain pengujian fungsional, dilakukan penilaian",
     "Selain pengujian fungsional, penulis melakukan penilaian terhadap pengalaman pengguna "
     "menggunakan System Usability Scale (SUS). Penulis memilih SUS karena instrumen ini telah "
     "luas dipakai dan hasilnya dapat dibandingkan antar aplikasi. Habibi dan Athoillah (2024) "
     "juga menempatkan pengalaman pengguna sebagai ukuran keberhasilan sistem pemesanan tiket. "
     "Kuesioner terdiri atas sepuluh pernyataan dengan skala Likert satu sampai lima."),

    ("Penilaian melibatkan [JUMLAH] responden",
     "Penilaian melibatkan [JUMLAH] responden yang mencoba aplikasi secara langsung. Penulis "
     "meminta responden menilai lima aspek, yaitu kemudahan penggunaan, kemenarikan tampilan, "
     "kejelasan audio, kejelasan video, dan manfaat visualisasi panggung tiga dimensi."),

    ("Perhitungan skor SUS mengikuti prosedur baku",
     "Penulis menghitung skor SUS mengikuti prosedur baku. Setiap pernyataan bernomor ganjil "
     "dinilai dengan mengurangi skor responden satu. Pernyataan bernomor genap dinilai dengan "
     "mengurangi lima dengan skor responden. Jumlah seluruh nilai dikalikan 2,5 sehingga "
     "diperoleh rentang skor 0 sampai 100. Skor di atas 68 dianggap di atas rata-rata, "
     "sedangkan skor di bawah 68 dianggap di bawah rata-rata."),

    # ================= BAB V =================
    ("Berdasarkan hasil perancangan, implementasi, dan pengujian",
     "Berdasarkan hasil perancangan, implementasi, dan pengujian, penulis menyimpulkan empat "
     "hal berikut."),

    ("Metode Multimedia Development Life Cycle berhasil diterapkan pada pengembangan aplikasi ticketing",
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

    ("Beberapa hal yang dapat dikembangkan lebih lanjut",
     "Penulis mencatat lima hal yang dapat dikembangkan lebih lanjut."),

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


def main() -> None:
    doc = Document(str(BERKAS))
    terpakai: set[int] = set()
    gagal: list[str] = []
    n_ubah = 0

    for awalan, baru in GANTI:
        cocok = None
        for i, par in enumerate(doc.paragraphs):
            if i in terpakai:
                continue
            if par.text.strip().startswith(awalan):
                cocok = i
                break
        if cocok is None:
            gagal.append(awalan[:56])
            continue

        terpakai.add(cocok)
        par = doc.paragraphs[cocok]

        # pengaman: jangan sentuh blok kode atau field Mendeley
        teks = par.text
        if ("fldChar" in par._element.xml
                or "void " in teks or "final " in teks
                or "static const" in teks or "StageBalok(" in teks
                or teks.strip().startswith("//")):
            gagal.append("DILEWATI (kode/field): " + awalan[:44])
            continue

        for r in list(par.runs):
            r._element.getparent().remove(r._element)
        run = par.add_run(baru)
        run.font.name = FONT
        run.font.size = Pt(12)
        n_ubah += 1

    doc.save(str(BERKAS))
    print(f"paragraf diubah: {n_ubah}")
    if gagal:
        print("tidak cocok / dilewati:")
        for g in gagal:
            print("  -", g)

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    print(f"\nparagraf: {len(d.paragraphs)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")
    teks = "\n".join(p.text for p in d.paragraphs)
    print("\ncek blok kode masih utuh:")
    for k in ("void _pasangPengawasPreview()", "StageBalok(-1.0, 0.0, -0.9",
              "static const List<StageBalok> balok", "Timer.periodic"):
        print(f"  {k[:42]:44} {'ADA' if k in teks else '!! HILANG'}")
    print("\nsisa penanda:")
    for k in ("[SITASI:", "[JUMLAH]", "[ISI DENGAN", "[GAMBAR 3.3"):
        print(f"  {k:16} {teks.count(k)}")


if __name__ == "__main__":
    main()
