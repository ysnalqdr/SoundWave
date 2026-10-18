import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../models/konser_model.dart';
import '../../models/tiket_konser_model.dart';
import '../../providers/app_providers.dart';
import 'form_konser_screen.dart';
import 'package:soundwave/widgets/gambar_widget.dart';

class InspectKonserScreen extends ConsumerStatefulWidget {
  final KonserModel konser;

  const InspectKonserScreen({super.key, required this.konser});

  @override
  ConsumerState<InspectKonserScreen> createState() => _InspectKonserScreenState();
}

class _InspectKonserScreenState extends ConsumerState<InspectKonserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsByEventProvider(widget.konser.id));
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final diperbarui = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormKonserScreen(
                          konser: widget.konser,
                        ),
                      ),
                    );
                    if (diperbarui == true && mounted) {
                      messenger.showSnackBar(
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
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
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
                      top: 8,
                      bottom: 8,
                      right: 8,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
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
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    GambarWidget(
                      url: widget.konser.gambarUrl.isEmpty
                          ? 'assets/images/logo/default.jpg'
                          : widget.konser.gambarUrl,
                      fit: BoxFit.cover,
                      ikonDefault: Icons.broken_image_outlined,
                    ),
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
        body: TabBarView(
          controller: _tabController,
          children: [
            _tabDeskripsi(eventsAsync),
            _tabTiket(ticketsAsync),
            _tabSyarat(),
          ],
        ),
      ),
    );
  }

  Widget _tabDeskripsi(AsyncValue<List<KonserModel>> eventsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.konser.genre.map((genre) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      genre,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          const SizedBox(height: 16),
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
              if (widget.konser.genre.isNotEmpty) widget.konser.genre.first,
              widget.konser.lokasi.split(',').last.trim(),
              'Konser2026',
              'SoundWave',
            ]
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
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
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Konser Lainnya',
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          eventsAsync.when(
            data: (allEvents) {
              final lainnya = allEvents.where((k) => k.id != widget.konser.id).toList();
              if (lainnya.isEmpty) {
                return Text(
                  'Tidak ada konser lain',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 13),
                );
              }
              return SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: lainnya.length,
                  itemBuilder: (_, i) {
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
                              child: GambarWidget(
                                url: k.gambarUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                ikonDefault: Icons.music_note_rounded,
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
              );
            },
            loading: () => const SizedBox(height: 130, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tabTiket(AsyncValue<List<TiketKonserModel>> ticketsAsync) {
    return ticketsAsync.when(
      data: (tiketKonser) {
        if (tiketKonser.isEmpty) {
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
                  'Belum ada tiket untuk konser ini di Firestore',
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  border: Border(
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
                      '${tiketKonser.length} kategori tiket',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: tiketKonser.map((tiket) {
                    final Map<String, Color> colorMap = {
                      'oke': AppColors.success,
                      'hampir': AppColors.warning,
                      'habis': AppColors.error,
                    };
                    final warnaDot = colorMap[tiket.statusStok] ?? AppColors.success;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: tiket == tiketKonser.last
                                ? Colors.transparent
                                : AppColors.divider,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: warnaDot,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: warnaDot.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: warnaDot.withValues(alpha: 0.3),
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
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Gagal memuat tiket: $e',
            style: GoogleFonts.spaceGrotesk(color: AppColors.error),
          ),
        ),
      ),
    );
  }

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

  Widget _bariInfo(IconData ikon, String teks) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
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
          '"${widget.konser.judul}" akan dihapus permanen dari Firestore.',
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
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await ref.read(databaseServiceProvider).deleteEvent(widget.konser.id);
                if (!mounted) return;
                nav.pop(true);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus konser: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
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