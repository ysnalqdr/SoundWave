import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/konser_model.dart';
import '../../models/tiket_konser_model.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/rundown_helper.dart';
import '../../widgets/gambar_widget.dart';
import 'checkout_screen.dart';
import 'share_konser_screen.dart';
import 'dart:async';

class UserKonserDetailScreen extends ConsumerStatefulWidget {
  final KonserModel konser;

  const UserKonserDetailScreen({super.key, required this.konser});

  @override
  ConsumerState<UserKonserDetailScreen> createState() => _UserKonserDetailScreenState();
}

class _UserKonserDetailScreenState extends ConsumerState<UserKonserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _kategoriDipilih;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // Mulai refresh saat user buka tab TIKET (index 1)
    if (_tabController.index == 1) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  /// Petunjuk di bar bawah bisa disentuh -> pindah ke tab TIKET (index 1).
  /// Gerbang pembayaran tetap di `_pesanTiket`; ini cuma jalan pintas visual.
  void _keTabTiket() {
    if (!mounted) return;
    _tabController.animateTo(1);
  }

  void _startAutoRefresh() {
    _stopAutoRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Refresh tiket data
      ref.invalidate(ticketsByEventProvider(widget.konser.id));
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorit() async {
    final currentUserId = ref.read(authStateProvider).valueOrNull?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masuk akun terlebih dahulu untuk menyimpan favorit',
            style: GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: AppColors.surfaceLight,
        ),
      );
      return;
    }

    try {
      await ref.read(databaseServiceProvider).toggleFavorite(currentUserId, widget.konser.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui favorit: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Tiket yang cocok dengan kategori terpilih. `null` = user belum memilih
  /// jenis tiket (atau kategorinya tidak ada di daftar).
  TiketKonserModel? _tiketUntukKategori(List<TiketKonserModel> daftarTiket) {
    final kategori = _kategoriDipilih;
    if (kategori == null) return null;
    for (final t in daftarTiket) {
      if (t.kategori == kategori) return t;
    }
    // Sengaja TIDAK memakai `contains`: 'VVIP'.contains('VIP') bernilai true,
    // sehingga memilih VIP bisa menampilkan harga VVIP.
    return null;
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: AppColors.error,
      ),
    );
  }

  /// Pintu masuk pembayaran. HANYA jalan kalau user sudah memilih jenis tiket
  /// dan kuotanya masih ada — tidak ada lagi jalur yang melompat ke wizard
  /// 3 langkah tanpa pemilihan.
  Future<void> _pesanTiket(List<TiketKonserModel> daftarTiket) async {
    if (daftarTiket.isEmpty) {
      _pesan('Tiket untuk konser ini belum tersedia');
      return;
    }
    if (_kategoriDipilih == null) {
      _pesan('Pilih jenis tiket dulu sebelum memesan');
      return;
    }
    final tiket = _tiketUntukKategori(daftarTiket);
    if (tiket == null) {
      _pesan('Tiket kategori $_kategoriDipilih belum tersedia');
      return;
    }
    if (tiket.stok <= 0) {
      _pesan('Tiket ${tiket.kategori} sudah habis');
      return;
    }
    await _bukaCheckout(tiket);
  }

  Future<void> _bukaCheckout(TiketKonserModel tiket) async {
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          konser: widget.konser,
          tiketDipilih: tiket,
        ),
      ),
    );

    if (hasil == true && mounted) {
      Navigator.pop(context, true); // Kembali ke katalog jika pesanan sukses
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid;
    final favoriteIds = currentUserId != null
        ? (ref.watch(favoriteIdsProvider(currentUserId)).valueOrNull ?? const <String>[])
        : const <String>[];
    final isFavorit = favoriteIds.contains(widget.konser.id);

    final ticketsAsync = ref.watch(ticketsByEventProvider(widget.konser.id));
    final rundown = RundownHelper.rundownFor(widget.konser.id);

    // ── Status pemilihan jenis tiket (menggerakkan tombol di bar bawah) ──
    final daftarTiketSemua = ticketsAsync.valueOrNull ?? const <TiketKonserModel>[];
    final tiketTerpilih = _tiketUntukKategori(daftarTiketSemua);
    final tiketHabis = tiketTerpilih != null && tiketTerpilih.stok <= 0;
    final bisaPesanTiket = tiketTerpilih != null && !tiketHabis;

    final String labelKiriAtas;
    final String labelKiriBawah;
    final Color warnaKiriBawah;
    if (tiketTerpilih == null) {
      labelKiriAtas = 'Pilih jenis tiket dulu';
      labelKiriBawah = 'Mulai dari ${widget.konser.formatHarga}';
      warnaKiriBawah = AppColors.textMuted;
    } else if (tiketHabis) {
      labelKiriAtas = 'Kuota habis';
      labelKiriBawah = '${tiketTerpilih.kategori} · habis';
      warnaKiriBawah = AppColors.error;
    } else {
      labelKiriAtas = 'Pilihan kamu';
      labelKiriBawah =
          '${tiketTerpilih.kategori} · ${tiketTerpilih.formatHarga}';
      warnaKiriBawah = AppColors.warnaHarga;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              // Pinned: bar (tombol back/share/favorit) tetap terlihat saat
              // di-scroll & tidak ikut tertutup. Floating+snap: muncul cepat
              // lagi saat user scroll ke atas.
              pinned: true,
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    final userId = ref.read(authStateProvider).valueOrNull?.uid;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShareKonserScreen(
                          konser: widget.konser,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorit ? Icons.favorite : Icons.favorite_border,
                      color: isFavorit ? Colors.redAccent : Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: _toggleFavorit,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                titlePadding: const EdgeInsetsDirectional.only(
                    start: 56, bottom: 16, end: 56),
                // Judul hanya tampil (fade-in) ketika header mengempis, agar
                // bar yang di-pin tidak terlihat kosong saat di-scroll.
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final settings = context.dependOnInheritedWidgetOfExactType<
                        FlexibleSpaceBarSettings>();
                    final deltaExtent = settings == null
                        ? 1.0
                        : (settings.maxExtent - settings.minExtent);
                    final t = deltaExtent <= 0
                        ? 1.0
                        : (1.0 -
                                (settings!.currentExtent - settings.minExtent) /
                                    deltaExtent)
                            .clamp(0.0, 1.0);
                    return Opacity(
                      opacity: t,
                      child: Text(
                        widget.konser.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    GambarWidget(
                      url: widget.konser.gambarUrl,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.4),
                            AppColors.background,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: widget.konser.genre.map((g) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warnaHarga.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.warnaHarga.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  g,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.warnaHarga,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.konser.judul,
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          if (widget.konser.penyelenggara != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Diselenggarakan oleh ${widget.konser.penyelenggara}',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Tab Bar
            Container(
              color: AppColors.background,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.warnaHarga,
                indicatorWeight: 3,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
                tabs: const [
                  Tab(text: 'TENTANG'),
                  Tab(text: 'TIKET'),
                ],
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Tentang & Info Konser
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildInfoBar(
                        Icons.calendar_today_rounded,
                        '${widget.konser.tanggal.day}/${widget.konser.tanggal.month}/${widget.konser.tanggal.year}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoBar(
                        Icons.access_time_rounded,
                        '${widget.konser.tanggal.hour.toString().padLeft(2, '0')}:${widget.konser.tanggal.minute.toString().padLeft(2, '0')} WIB - Selesai',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoBar(
                        Icons.location_on_rounded,
                        widget.konser.lokasi,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'DESKRIPSI ACARA',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.konser.deskripsi ??
                            'Nikmati konser musik live bersama musisi favoritmu dalam panggung spektakuler SoundWave.',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'RUNDOWN ACARA',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...rundown.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 90,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Text(
                                  item['waktu'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.warnaHarga,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item['kegiatan'] ?? item['item'] ?? '',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 30),

                      // ─── Syarat & Ketentuan ───
                      const Divider(color: AppColors.divider, height: 32),
                      Text(
                        'SYARAT & KETENTUAN',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
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

                  // Tab 2: Kategori Tiket
                  ticketsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                            const SizedBox(height: 12),
                            Text('Gagal memuat kategori tiket', style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => ref.refresh(ticketsByEventProvider(widget.konser.id)),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (daftarTiket) {
                      if (daftarTiket.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 56,
                                color: AppColors.textMuted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tiket Belum Tersedia',
                                style: GoogleFonts.rajdhani(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Penjualan tiket untuk konser ini belum dibuka oleh panitia.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: daftarTiket.length,
                        itemBuilder: (ctx, i) {
                          final t = daftarTiket[i];
                          final isTerpilih = _kategoriDipilih == t.kategori;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: isTerpilih
                                  ? AppColors.surfaceLight
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isTerpilih
                                    ? AppColors.warnaHarga
                                    : AppColors.divider,
                                width: isTerpilih ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.kategori,
                                            style: GoogleFonts.rajdhani(
                                              color: AppColors.textPrimary,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            t.zonaVenue,
                                            style: GoogleFonts.spaceGrotesk(
                                              color: t.isVVIP
                                                  ? const Color(0xFFFFD700)
                                                  : (t.isVIP
                                                      ? const Color(0xFFFF9100)
                                                      : AppColors.textMuted),
                                              fontSize: 11,
                                              fontWeight: (t.isVVIP || t.isVIP)
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        t.formatHarga,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: AppColors.warnaHarga,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    t.deskripsi ?? 'Akses tiket konser resmi SoundWave.',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Sisa kuota: ${t.stok} tiket',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: t.stok < 20
                                              ? AppColors.error
                                              : AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      ElevatedButton(
                                        // PILIH = memilih jenis tiket saja.
                                        // Tidak membuka pembayaran; user lanjut
                                        // lewat tombol "PESAN TIKET" di bawah.
                                        onPressed: t.stok <= 0
                                            ? null
                                            : () {
                                                setState(() {
                                                  _kategoriDipilih = t.kategori;
                                                });
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isTerpilih
                                              ? AppColors.warnaHarga
                                              : AppColors.warnaTombolBg,
                                          foregroundColor: Colors.black,
                                          minimumSize: const Size(100, 36),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                        ),
                                        child: Text(
                                          t.stok <= 0
                                              ? 'HABIS'
                                              : (isTerpilih ? 'DIPILIH' : 'PILIH'),
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                ],
              ),
            ),

            // Sticky Bottom Button — satu-satunya pintu ke pembayaran.
            // Tombol baru bisa ditekan setelah user MEMILIH jenis tiket
            // di tab TIKET.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          // Petunjuk ini bisa DISENTUH: langsung pindah ke tab
                          // TIKET (tempat daftar jenis tiket), supaya user tidak
                          // perlu menebak ke mana harus mencari.
                          onTap: tiketTerpilih == null ? _keTabTiket : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        labelKiriAtas,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: tiketHabis
                                              ? AppColors.error
                                              : (tiketTerpilih == null
                                                  ? AppColors.textSecondary
                                                  : AppColors.textMuted),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    if (tiketTerpilih == null) ...[
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  labelKiriBawah,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: warnaKiriBawah,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: bisaPesanTiket
                            ? () => _pesanTiket(daftarTiketSemua)
                            : null,
                        style: ElevatedButton.styleFrom(
                          // Tombol mati harus kelihatan jelas "belum bisa
                          // ditekan", bukan tombol putih yang pudar.
                          disabledBackgroundColor: AppColors.surfaceLight,
                          disabledForegroundColor: AppColors.textMuted,
                        ),
                        child: Text(
                          bisaPesanTiket ? 'PESAN TIKET' : 'PILIH TIKET DULU',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.warnaHarga, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textSecondary,
              fontSize: 13,
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
            Icon(ikon, color: AppColors.warnaHarga, size: 18),
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
                      color: AppColors.warnaHarga,
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
}
