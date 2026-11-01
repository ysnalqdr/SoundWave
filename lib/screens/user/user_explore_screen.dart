import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/konser_model.dart';
import '../../models/promo_model.dart';
import '../../models/claimed_promo_model.dart';
import '../../widgets/promo/promo_card.dart';
import '../../widgets/promo/promo_lembar.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/feedback/app_state_views.dart';
import '../../constants/app_constants.dart';
import '../../widgets/gambar_widget.dart';
import '../../widgets/notifikasi_bell.dart';
import 'user_konser_detail_screen.dart';
import '../../core/errors/pesan_galat.dart';

class UserExploreScreen extends ConsumerStatefulWidget {
  const UserExploreScreen({super.key});

  @override
  ConsumerState<UserExploreScreen> createState() => _UserExploreScreenState();
}

class _UserExploreScreenState extends ConsumerState<UserExploreScreen> {
  final _searchCtrl = TextEditingController();

  String _selectedKota = 'Semua Kota';
  String _selectedDatePreset = 'Semua Tanggal';
  String _selectedPriceSort = 'Semua'; // 'Semua', 'Termurah', 'Termahal' // 'Semua Tanggal', '7 Hari Ke Depan', '30 Hari Ke Depan', 'Bulan Ini', 'Custom Rentang'
  DateTimeRange? _customDateRange;
  // `_minPrice` / `_maxPrice` dihapus: keduanya tidak pernah diberi nilai,
  // sehingga blok filter yang memakainya adalah kode mati.

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<KonserModel> _filterAndSortKonser(List<KonserModel> rawList) {
    var list = List<KonserModel>.from(rawList);

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((k) {
        final judul = k.judul.toLowerCase();
        final lokasi = k.lokasi.toLowerCase();
        final deskripsi = (k.deskripsi ?? '').toLowerCase();
        final pen = (k.penyelenggara ?? '').toLowerCase();
        return judul.contains(query) ||
            lokasi.contains(query) ||
            deskripsi.contains(query) ||
            pen.contains(query);
      }).toList();
    }

    // Urutan harga
    if (_selectedPriceSort == 'Termurah') {
      list.sort((a, b) => a.harga.compareTo(b.harga));
    } else if (_selectedPriceSort == 'Termahal') {
      list.sort((a, b) => b.harga.compareTo(a.harga));
    }

    // Kota filter, mendukung lokasi terstruktur dan teks lama yang digabung.
    if (_selectedKota != 'Semua Kota') {
      final targetKota = _selectedKota.toLowerCase();
      list = list.where((k) {
        final lokasi = k.lokasi.toLowerCase();
        if (lokasi.contains(targetKota)) return true;
        if (targetKota == 'yogyakarta' &&
            (lokasi.contains('jogja') || lokasi.contains('diy'))) {
          return true;
        }
        if (targetKota == 'jakarta' && lokasi.contains('dki')) return true;
        return false;
      }).toList();
    }

    // Filter tanggal
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    if (_selectedDatePreset == '7 Hari Ke Depan') {
      final end7 = todayStart.add(const Duration(days: 7, hours: 23, minutes: 59));
      list = list
          .where((k) =>
              k.tanggal.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
              k.tanggal.isBefore(end7))
          .toList();
    } else if (_selectedDatePreset == '30 Hari Ke Depan') {
      final end30 = todayStart.add(const Duration(days: 30, hours: 23, minutes: 59));
      list = list
          .where((k) =>
              k.tanggal.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
              k.tanggal.isBefore(end30))
          .toList();
    } else if (_selectedDatePreset == 'Bulan Ini') {
      final endMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      list = list
          .where((k) =>
              k.tanggal.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
              k.tanggal.isBefore(endMonth))
          .toList();
    } else if (_selectedDatePreset == 'Custom Rentang' && _customDateRange != null) {
      final start = DateTime(
        _customDateRange!.start.year,
        _customDateRange!.start.month,
        _customDateRange!.start.day,
      );
      final end = DateTime(
        _customDateRange!.end.year,
        _customDateRange!.end.month,
        _customDateRange!.end.day,
        23,
        59,
        59,
      );
      list = list
          .where((k) =>
              k.tanggal.isAfter(start.subtract(const Duration(seconds: 1))) &&
              k.tanggal.isBefore(end))
          .toList();
    }

    // Urutan akhir.
    //
    // Dulu baris ini SELALU mengurutkan berdasarkan tanggal, sehingga
    // pilihan "Termurah"/"Termahal" ditimpa dan tidak berefek apa pun —
    // filter harga terasa "tidak bisa dipakai". Sekarang urutan tanggal
    // hanya dipakai kalau pengguna tidak memilih sortir harga.
    if (_selectedPriceSort == 'Semua') {
      list.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    }

    return list;
  }

  void _bukaDetail(KonserModel k) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserKonserDetailScreen(konser: k),
      ),
    );
  }

  Future<void> _toggleFavorit(String eventId) async {
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
      await ref.read(databaseServiceProvider).toggleFavorite(currentUserId, eventId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(PesanGalat.untuk(e, awalan: 'Gagal memperbarui favorit')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid;
    final favoriteIds = currentUserId != null
        ? (ref.watch(favoriteIdsProvider(currentUserId)).valueOrNull ?? const <String>[])
        : const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOUNDWAVE',
                          style: GoogleFonts.rajdhani(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        Text(
                          'Feel the Pulse of Live Music',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Lonceng notifikasi dengan badge jumlah belum dibaca.
                    // Isinya ditulis backend, bukan manual.
                    NotifikasiBell(userId: currentUserId),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari artis, konser, atau kota...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                          tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Tiga filter: tanggal, harga, lokasi.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        icon: Icons.calendar_today_outlined,
                        label: _selectedDatePreset == 'Semua Tanggal' ? 'Tanggal' : _selectedDatePreset,
                        value: _selectedDatePreset,
                        items: ['Semua Tanggal', '7 Hari Ke Depan', '30 Hari Ke Depan', 'Bulan Ini'],
                        onChanged: (val) => setState(() => _selectedDatePreset = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        icon: Icons.monetization_on_outlined,
                        label: _selectedPriceSort == 'Semua' ? 'Harga' : _selectedPriceSort,
                        value: _selectedPriceSort,
                        items: ['Semua', 'Termurah', 'Termahal'],
                        onChanged: (val) => setState(() => _selectedPriceSort = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        icon: Icons.location_on_outlined,
                        label: _selectedKota == 'Semua Kota' ? 'Lokasi' : _selectedKota,
                        value: _selectedKota,
                        items: ['Semua Kota', ...AppConstants.cities],
                        onChanged: (val) => setState(() => _selectedKota = val!),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Kartu promo, bisa digeser dan diketuk untuk klaim.
            SliverToBoxAdapter(
              child: _PromoBannerRow(
                currentUserId: ref.watch(authStateProvider).valueOrNull?.uid,
              ),
            ),

            ...eventsAsync.when(
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: AppLoading(label: 'Menyiapkan daftar konser'),
                  ),
                ),
              ],
              error: (err, stack) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorState(
                    title: 'Gagal memuat konser',
                    message: err.toString(),
                    onRetry: () => ref.refresh(eventsProvider),
                    retryLabel: 'Coba lagi',
                  ),
                ),
              ],
              data: (rawEvents) {
                final listKonser = _filterAndSortKonser(rawEvents);
                final konserSpesial = rawEvents.take(3).toList(); // Max 3 concerts for horizontal scroll

                return [
                  // Banner utama, disembunyikan saat user mencari.
                  if (_searchCtrl.text.isEmpty &&
                      _selectedKota == 'Semua Kota' &&
                      _selectedPriceSort == 'Semua' &&
                      rawEvents.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Konser spesial',
                              style: GoogleFonts.rajdhani(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 190,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: konserSpesial.length,
                                itemBuilder: (ctx, i) {
                                  final konser = konserSpesial[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () => _bukaDetail(konser),
                                      child: Container(
                                        width: 260,
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.rLg,
                                  border: Border.all(
                                    color: AppColors.badgeJalanBorder,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: AppRadius.rLg,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      GambarWidget(
                                        url: konser.gambarUrl,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.85),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        right: 16,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              konser.judul,
                                              style: GoogleFonts.rajdhani(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  color: AppColors.textMuted,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    konser.lokasi,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.spaceGrotesk(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  konser.formatHarga,
                                                  style: GoogleFonts.spaceGrotesk(
                                                    color: AppColors.warnaHarga,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

                  // Judul bagian.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jadwal konser terdekat',
                            style: GoogleFonts.rajdhani(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '${listKonser.length} Acara',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  listKonser.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 40,
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_busy_outlined,
                                    size: 56,
                                    color: AppColors.textMuted.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak Ada Konser Ditemukan',
                                    style: GoogleFonts.rajdhani(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rawEvents.isEmpty
                                        ? 'Jadwal konser dari penyelenggara akan segera hadir.'
                                        : 'Coba ubah kata kunci pencarian atau filter yang dipilih.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final k = listKonser[i];
                                final isFav = favoriteIds.contains(k.id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: AppRadius.rLg,
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: InkWell(
                                    onTap: () => _bukaDetail(k),
                                    borderRadius: AppRadius.rLg,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: 160,
                                                child: GambarWidget(
                                                  url: k.gambarUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: GestureDetector(
                                                onTap: () => _toggleFavorit(k.id),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    isFav
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: isFav
                                                        ? Colors.redAccent
                                                        : Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 12,
                                              left: 12,
                                              child: Wrap(
                                                spacing: 6,
                                                children: k.genre.take(2).map((g) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.7),
                                                      borderRadius:
                                                          AppRadius.rXs,
                                                    ),
                                                    child: Text(
                                                      g,
                                                      style: GoogleFonts.spaceGrotesk(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      k.judul,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.rajdhani(
                                                        color: AppColors.textPrimary,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    k.formatHarga,
                                                    style: GoogleFonts.spaceGrotesk(
                                                      color: AppColors.warnaHarga,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 14,
                                                    color: AppColors.textMuted,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      k.lokasi,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.spaceGrotesk(
                                                        color: AppColors.textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today_outlined,
                                                    size: 14,
                                                    color: AppColors.textMuted,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${k.tanggal.day}/${k.tanggal.month}/${k.tanggal.year}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.spaceGrotesk(
                                                      color: AppColors.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: listKonser.length,
                            ),
                          ),
                        ),

                  // 30 -> ruangNavbar: navbar kaca mengambang menutupi bagian
                  // bawah layar, jadi kartu terakhir harus bisa digulir naik.
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.ruangNavbar),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFilterDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Value harus ada di dalam items, kalau tidak DropdownButton crash.
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rSm,
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.textMuted),
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          // Item default tampil dengan label ringkas, value tetap nilai asli.
          selectedItemBuilder: (context) => items
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item == safeValue ? label : item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

}

/// Kartu promo horizontal yang bisa diklaim user.
///
/// Sumbernya koleksi `promo_codes`. Hasil klaim disimpan di
/// `users/{uid}/claimed_promos`, tampil di Akun, dan dipakai sebagai
/// potongan harga saat checkout.
class _PromoBannerRow extends ConsumerStatefulWidget {
  final String? currentUserId;
  const _PromoBannerRow({required this.currentUserId});

  @override
  ConsumerState<_PromoBannerRow> createState() => _PromoBannerRowState();
}

class _PromoBannerRowState extends ConsumerState<_PromoBannerRow> {
  late Stream<List<PromoCodeModel>> _promoStream;
  late Stream<List<ClaimedPromoModel>> _claimStream;
  // `_claiming` dihapus: status memproses klaim kini hidup di dalam
  // `PromoLembar`, karena tombol klaim sudah pindah ke sana.

  @override
  void initState() {
    super.initState();
    _promoStream = FirebaseFirestore.instance
        .collection('promo_codes')
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PromoCodeModel.fromMap(d.data(), d.id))
            .toList());
    _bindClaims();
  }

  @override
  void didUpdateWidget(covariant _PromoBannerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUserId != widget.currentUserId) _bindClaims();
  }

  void _bindClaims() {
    final uid = widget.currentUserId;
    _claimStream = uid == null
        ? const Stream<List<ClaimedPromoModel>>.empty()
        : ref.read(databaseServiceProvider).streamClaimedPromos(uid);
  }


  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
        backgroundColor: error ? AppColors.error : AppColors.surfaceLight,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Buka lembaran ketentuan. Klaim dilakukan DI DALAM lembaran.
  Future<void> _bukaKetentuan(
    PromoCodeModel promo,
    TemaPromo tema,
    bool sudah,
  ) async {
    final tersimpan = await PromoLembar.tampilkan(
      context,
      promo: promo,
      tema: tema,
      sudahDiklaim: sudah,
      onKlaim: () async {
        final uid = widget.currentUserId;
        if (uid == null) {
          return 'Masuk ke akun dulu untuk mengklaim voucher.';
        }
        try {
          await ref.read(databaseServiceProvider).claimPromo(uid, promo);
          return null;
        } catch (e) {
          return e.toString().replaceFirst('Exception: ', '');
        }
      },
    );
    if (tersimpan == true && mounted) {
      _snack('Voucher ${promo.kode} tersimpan di "Diskon Saya"');
    }
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PromoCodeModel>>(
      stream: _promoStream,
      builder: (context, promoSnap) {
        if (promoSnap.hasError) return const SizedBox.shrink();
        final promos = promoSnap.data ?? const <PromoCodeModel>[];
        if (promos.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<List<ClaimedPromoModel>>(
          stream: _claimStream,
          builder: (context, claimSnap) {
            final claimedIds = (claimSnap.data ?? const <ClaimedPromoModel>[])
                .map((c) => c.promoId)
                .toSet();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        'Promo & diskon',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'klaim dulu, pakai saat bayar',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  // 172px tidak cukup: isi PromoCard butuh ±195px, dan
                  // Flutter melaporkan "BOTTOM OVERFLOWED BY 13 PIXELS".
                  //
                  // 200px masih menyisakan overflow 1px pada kartu tertentu
                  // (label panjang / nominal besar), jadi diberi ruang aman
                  // 8px. Angka ini harus sedikit lebih besar dari kebutuhan
                  // isi, bukan pas — selisih 1px pun terlihat sebagai garis
                  // kuning-hitam di layar.
                  height: 208,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: promos.length,
                    itemBuilder: (context, i) {
                      final promo = promos[i];
                      final sudah = claimedIds.contains(promo.id);
                      final tema = TemaPromo.untuk(promo, i);
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: PromoCard(
                          promo: promo,
                          tema: tema,
                          sudahDiklaim: sudah,
                          // Ketuk kartu = buka ketentuan. Tombol klaim ada
                          // di dalam lembaran, bukan di kartu.
                          onKetuk: () => _bukaKetentuan(promo, tema, sudah),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
