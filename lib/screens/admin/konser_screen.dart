import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/app_theme.dart';
import '../../widgets/badge_status.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/konser_model.dart';
import '../../providers/app_providers.dart';
import 'form_konser_screen.dart';
import 'inspect_konser_screen.dart';
import 'package:soundwave/widgets/gambar_widget.dart';
import '../../core/errors/pesan_galat.dart';

class KonserScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onBukaSidebar;

  const KonserScreen({
    super.key,
    required this.user,
    required this.onBukaSidebar,
  });

  @override
  ConsumerState<KonserScreen> createState() => _KonserScreenState();
}

class _KonserScreenState extends ConsumerState<KonserScreen> {
  String _genreAktif = 'Semua';
  String _kataCari = '';

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<KonserModel> _filterKonser(List<KonserModel> allKonser) {
    return allKonser.where((k) {
      final cocokGenre =
          _genreAktif == 'Semua' || k.genre.contains(_genreAktif);
      final cocokCari = _kataCari.isEmpty ||
          k.judul.toLowerCase().contains(_kataCari.toLowerCase()) ||
          k.lokasi.toLowerCase().contains(_kataCari.toLowerCase());
      return cocokGenre && cocokCari;
    }).toList();
  }

  void _hapusKonser(KonserModel konser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
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
          '"${konser.judul}" akan dihapus permanen, termasuk semua tiketnya.',
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
              Navigator.pop(ctx);
              try {
                await ref.read(databaseServiceProvider).deleteEvent(konser.id);
                if (!mounted) return;
                _tampilSnackbar(
                  'Konser berhasil dihapus',
                  AppColors.aksi,
                  Icons.check_circle_outline,
                );
              } catch (e) {
                if (!mounted) return;
                _tampilSnackbar(
                  PesanGalat.untuk(e, awalan: 'Gagal menghapus konser'),
                  AppColors.error,
                  Icons.error_outline,
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

  void _tampilSnackbar(String pesan, Color warna, IconData ikon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(ikon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pesan,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rMd,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopbar(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: eventsAsync.when(
                data: (allKonser) {
                  final terfilter = _filterKonser(allKonser);
                  return _buildDaftarKonser(terfilter);
                },
                loading: () => _buildSkeleton(),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          PesanGalat.untuk(e, awalan: 'Gagal memuat daftar konser'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildTopbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBukaSidebar,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppRadius.rSm,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Manage Konser',
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const BadgeStatus(
            'ADMIN',
            nada: BadgeNada.jalan,
            ikon: BadgeIkon.kunci,
            ukuran: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari nama konser atau kota...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  setState(() => _kataCari = val);
                },
              ),
            ),
            if (_kataCari.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _kataCari = '');
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final genres = ['Semua', ...AppConstants.genres];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        itemBuilder: (_, i) {
          final aktif = genres[i] == _genreAktif;
          return GestureDetector(
            onTap: () => setState(() => _genreAktif = genres[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: aktif ? AppColors.aksi : AppColors.surfaceLight,
                borderRadius: AppRadius.rLg,
                border: Border.all(
                  color: aktif ? AppColors.aksi : AppColors.divider,
                ),
              ),
              child: Text(
                genres[i],
                style: GoogleFonts.spaceGrotesk(
                  color: aktif ? Colors.black : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: aktif ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.surfaceLight,
        highlightColor: AppColors.card,
        child: Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.rLg,
          ),
        ),
      ),
    );
  }

  Widget _buildDaftarKonser(List<KonserModel> konserList) {
    if (konserList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_off_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _kataCari.isNotEmpty
                  ? 'Tidak ada hasil untuk "$_kataCari"'
                  : 'Belum ada konser',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: konserList.length,
      itemBuilder: (_, i) => _buildCardKonser(konserList[i]),
    );
  }

  Widget _buildCardKonser(KonserModel konser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: GambarWidget(
                    url: konser.gambarUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.card.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _tombolAksi(
                        ikon: Icons.remove_red_eye_outlined,
                        warna: AppColors.aksi,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InspectKonserScreen(konser: konser),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _tombolAksi(
                        ikon: Icons.edit_outlined,
                        warna: AppColors.aksi,
                        onTap: () async {
                          final diperbarui = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FormKonserScreen(konser: konser),
                            ),
                          );
                          if (diperbarui == true) {
                            _tampilSnackbar(
                              'Konser berhasil diperbarui',
                              AppColors.aksi,
                              Icons.check_circle_outline,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      _tombolAksi(
                        ikon: Icons.delete_outline_rounded,
                        warna: AppColors.error,
                        onTap: () => _hapusKonser(konser),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  konser.judul,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        konser.lokasi,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${konser.tanggal.day}/${konser.tanggal.month}/${konser.tanggal.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.panelGradient,
                        borderRadius: AppRadius.rSm,
                      ),
                      child: Text(
                        konser.formatHarga,
                        style: GoogleFonts.spaceGrotesk(
                          // Hijau: ini angka uang. Sapu hijau sebelumnya
                          // mengubahnya jadi putih — keliru, karena
                          // `warnaHarga` justru penanda uang.
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombolAksi({
    required IconData ikon,
    required Color warna,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.7),
          borderRadius: AppRadius.rSm,
        ),
        child: Icon(ikon, color: warna, size: 15),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final ditambah = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const FormKonserScreen()),
        );
        if (ditambah == true) {
          _tampilSnackbar(
            'Konser berhasil ditambahkan',
            AppColors.aksi,
            Icons.check_circle_outline,
          );
        }
      },
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rMd,
        side: const BorderSide(color: AppColors.divider),
      ),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'Tambah Konser',
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
