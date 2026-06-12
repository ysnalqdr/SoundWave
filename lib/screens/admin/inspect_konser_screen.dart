import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../models/konser_model.dart';
import '../../models/tiket_konser_model.dart';
import '../../data/dummy_data.dart';
import 'form_konser_screen.dart';

class InspectKonserScreen extends StatefulWidget {
  final KonserModel konser;

  const InspectKonserScreen({super.key, required this.konser});

  @override
  State<InspectKonserScreen> createState() => _InspectKonserScreenState();
}

class _InspectKonserScreenState
    extends State<InspectKonserScreen>
    with SingleTickerProviderStateMixin {

  //TODO Tab Ctrl 3 Tab
  late TabController _tabController;

  //! Data Tiket
  List<TiketKonserModel> get _tiketKonser =>
      DummyData.ambilTiketPerKonser(widget.konser.id);

  @override
  void initState() {
    super.initState();
    //! 3 tab Deskripsi, Tiket, Syarat
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        //! NestedScrollView
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.background,

              //! Button Back
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),

              //TODO: Button Edit, Delete In Card
              actions: [
                GestureDetector(
                  onTap: () async {
                    final diperbarui = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormKonserScreen(
                          konser: widget.konser,
                        ),
                      ),
                    );
                    if (diperbarui == true) {
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Konser berhasil diperbarui',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _hapusKonser(context),
                  child: Container(
                    margin: const EdgeInsets.only(
                      top: 8, bottom: 8, right: 8,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                ),
              ],

              //TODO Gambar Konser Background AppBar
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    //! Gmabar
                    Image.network(
                      widget.konser.gambarUrl.isEmpty
                          ? 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600'
                          : widget.konser.gambarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                      ),
                    ),
                    //! Dark Overlay
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background,
                          ],
                          stops: [0.4, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //TODO TapBar Di Bawah AppBar
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Deskripsi'),
                  Tab(text: 'Tiket'),
                  Tab(text: 'Syarat'),
                ],
              ),
            ),
          ];
        },

        //TODO: Isi Tab
        body: TabBarView(
          controller: _tabController,
          children: [
            _tabDeskripsi(),
            _tabTiket(),
            _tabSyarat(),
          ],
        ),
      ),

      //TODO: Banner Harga Button Kelola
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga mulai dari',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    widget.konser.formatHarga,
                    style: GoogleFonts.rajdhani(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final diperbarui = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormKonserScreen(
                          konser: widget.konser,
                        ),
                      ),
                    );
                    if (diperbarui == true) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Kelola Konser',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //TODO: Tab Deskripsi
  Widget _tabDeskripsi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //! Judul Genre
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.konser.judul,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.konser.genre,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          //TODO: Info Lokasi Tanggal Penyelenggara
          _bariInfo(
            Icons.location_on_outlined,
            widget.konser.lokasi,
          ),
          const SizedBox(height: 10),
          _bariInfo(
            Icons.calendar_today_outlined,
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                .format(widget.konser.tanggal),
          ),
          const SizedBox(height: 10),
          if (widget.konser.penyelenggara != null)
            _bariInfo(
              Icons.business_outlined,
              'Diselenggarakan oleh ${widget.konser.penyelenggara}',
            ),

          const SizedBox(height: 20),

          //! Deskripsi
          if (widget.konser.deskripsi != null &&
              widget.konser.deskripsi!.isNotEmpty) ...[
            Text(
              'Tentang Konser',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.konser.deskripsi!,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
          ],

          //! Tagar
          Text(
            'Tagar Event',
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              widget.konser.genre,
              widget.konser.lokasi.split(',').last.trim(),
              'Konser2025',
              'SoundWave',
            ].map((tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                '#$tag',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 24),

          //TODO Konser Lain/Rekomen Konser
          Text(
            'Konser Lainnya',
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: DummyData.daftarKonser
                  .where((k) => k.id != widget.konser.id)
                  .length,
              itemBuilder: (_, i) {
                final lainnya = DummyData.daftarKonser
                    .where((k) => k.id != widget.konser.id)
                    .toList();
                final k = lainnya[i];
                return GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspectKonserScreen(konser: k),
                    ),
                  ),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            k.gambarUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceLight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                k.judul,
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                k.formatHarga,
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  //TODO: Tab Tiket
  Widget _tabTiket() {
    if (_tiketKonser.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada tiket untuk konser ini',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: const Border(
                left: BorderSide(color: AppColors.divider),
                right: BorderSide(color: AppColors.divider),
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Platform SoundWave',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_tiketKonser.length} kategori tiket',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          //! List Tiket
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: _tiketKonser.map((tiket) {
                final warnaDot = {
                  'oke'    : AppColors.success,
                  'hampir' : AppColors.warning,
                  'habis'  : AppColors.error,
                }[tiket.statusStok]!;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tiket == _tiketKonser.last
                            ? Colors.transparent
                            : AppColors.divider,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Dot status
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: warnaDot,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info tiket
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tiket.kategori,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Stok: ${tiket.stok} tiket',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: warnaDot.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: warnaDot.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                tiket.labelStok,
                                style: GoogleFonts.spaceGrotesk(
                                  color: warnaDot,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Harga
                      Text(
                        tiket.formatHarga,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  //TODO: Tab Syarat
  Widget _tabSyarat() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seksiSyarat(
            'Registrasi',
            Icons.list_alt_rounded,
            [
              'Peserta wajib melakukan registrasi dan melengkapi data diri dengan benar dan lengkap.',
              'Tiket yang telah dibeli tidak dapat dibatalkan, ditukarkan kembali (refund), maupun dipindahtangankan kepada pihak lain.',
              'Tiket akan dikirimkan melalui e-mail/WhatsApp maksimal H-3 event.',
            ],
          ),
          const SizedBox(height: 16),
          _seksiSyarat(
            'Pelaksanaan',
            Icons.event_available_outlined,
            [
              'Peserta wajib membawa identitas diri dan barcode tiket saat proses registrasi.',
              'Peserta diharapkan menjunjung tinggi sportivitas dan keselamatan selama acara berlangsung.',
              'Panitia berhak menolak masuk peserta yang tidak memenuhi syarat.',
            ],
          ),
          const SizedBox(height: 16),
          _seksiSyarat(
            'Larangan',
            Icons.block_rounded,
            [
              'Dilarang membawa benda berbahaya ke dalam venue.',
              'Dilarang menjual kembali tiket di atas harga normal (scalping).',
              'Dilarang merekam pertunjukan secara profesional tanpa izin panitia.',
            ],
          ),
          const SizedBox(height: 16),
          _seksiSyarat(
            'Force Majeure',
            Icons.warning_amber_rounded,
            [
              'Panitia berhak melakukan perubahan jadwal atau lokasi apabila terjadi keadaan kahar.',
              'Dengan mendaftar, peserta dianggap telah membaca dan menyetujui seluruh syarat dan ketentuan.',
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  //TODO: Helper Widget
  Widget _bariInfo(IconData ikon, String teks) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(ikon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              teks,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _seksiSyarat(
    String judul,
    IconData ikon,
    List<String> poin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(ikon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              judul,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...poin.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _hapusKonser(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Hapus Konser?',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${widget.konser.judul}" akan dihapus permanen.',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              DummyData.daftarKonser.removeWhere(
                (k) => k.id == widget.konser.id,
              );
              // Tutup dialog lalu kembali ke halaman konser
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.spaceGrotesk(),
            ),
          ),
        ],
      ),
    );
  }
}