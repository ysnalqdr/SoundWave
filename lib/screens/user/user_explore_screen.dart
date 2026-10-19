import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/konser_model.dart';
import '../../models/promo_model.dart';
import '../../models/claimed_promo_model.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../widgets/gambar_widget.dart';
import '../../widgets/notifikasi_bell.dart';
import 'user_konser_detail_screen.dart';

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
  double? _minPrice;
  double? _maxPrice;

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

    // Rentang harga
    if (_minPrice != null && _minPrice! > 0) {
      list = list.where((k) => k.harga >= _minPrice!).toList();
    }
    if (_maxPrice != null && _maxPrice! > 0) {
      list = list.where((k) => k.harga <= _maxPrice!).toList();
    }

    // Urutan tetap: konser terdekat dulu.
    list.sort((a, b) => a.tanggal.compareTo(b.tanggal));

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
          content: Text('Gagal memperbarui favorit: $e'),
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
                            color: AppColors.warnaHarga,
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
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              ],
              error: (err, stack) => [
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            'Gagal Memuat Konser',
                            style: GoogleFonts.rajdhani(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => ref.refresh(eventsProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(140, 44),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                              'KONSER SPESIAL',
                              style: GoogleFonts.rajdhani(
                                color: AppColors.warnaHarga,
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
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
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
                            'JADWAL KONSER TERDEKAT',
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
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: InkWell(
                                    onTap: () => _bukaDetail(k),
                                    borderRadius: BorderRadius.circular(16),
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
                                                          BorderRadius.circular(6),
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

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 30),
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
        borderRadius: BorderRadius.circular(10),
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
  final Set<String> _claiming = <String>{};

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

  String _rp(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $s';
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

  Future<void> _claim(PromoCodeModel promo) async {
    final uid = widget.currentUserId;
    if (uid == null) {
      _snack('Masuk ke akun dulu untuk mengklaim promo', error: true);
      return;
    }
    setState(() => _claiming.add(promo.id));
    try {
      await ref.read(databaseServiceProvider).claimPromo(uid, promo);
      _snack('Promo ${promo.kode} tersimpan di "Diskon Saya"');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _claiming.remove(promo.id));
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
                        'PROMO & DISKON',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.warnaHarga,
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
                  height: 172,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: promos.length,
                    itemBuilder: (context, i) => _card(
                      promos[i],
                      claimed: claimedIds.contains(promos[i].id),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _card(PromoCodeModel promo, {required bool claimed}) {
    final busy = _claiming.contains(promo.id);
    final tersedia = promo.isValid;
    final disabled = claimed || busy || !tersedia;

    final String btnText;
    if (claimed) {
      btnText = 'TERSIMPAN';
    } else if (busy) {
      btnText = 'MENGKLAIM...';
    } else if (!tersedia) {
      btnText = 'TIDAK TERSEDIA';
    } else {
      btnText = 'KLAIM';
    }

    return Container(
      width: 236,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11301F), Color(0xFF0B0B0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warnaHarga.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warnaHarga,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promo.labelNilai,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.local_offer_rounded,
                  color: AppColors.warnaHarga, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            promo.kode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (promo.deskripsi?.trim().isNotEmpty ?? false)
                ? promo.deskripsi!.trim()
                : (promo.tipe == 'percentage'
                    ? 'Diskon ${promo.labelNilai}'
                    : 'Potongan ${promo.labelNilai}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary, fontSize: 11),
          ),
          const Spacer(),
          Text(
            promo.minPembelian > 0
                ? 'Min. belanja ${_rp(promo.minPembelian)}'
                : 'Tanpa minimum belanja',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              onPressed: disabled ? null : () => _claim(promo),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warnaHarga,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.surfaceLight,
                disabledForegroundColor: AppColors.textMuted,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
              ),
              child: Text(
                btnText,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
