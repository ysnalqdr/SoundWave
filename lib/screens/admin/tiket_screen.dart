import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/tiket_konser_model.dart';
import '../../providers/app_providers.dart';
import 'form_tiket_screen.dart';
import 'package:soundwave/widgets/gambar_widget.dart';

class TiketScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onBukaSidebar;

  const TiketScreen({
    super.key,
    required this.user,
    required this.onBukaSidebar,
  });

  @override
  ConsumerState<TiketScreen> createState() => _TiketScreenState();
}

class _TiketScreenState extends ConsumerState<TiketScreen> {
  String _filterKonser = 'Semua';

  void _hapusTiket(TiketKonserModel tiket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Hapus Tiket?',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Tiket ${tiket.kategori} - ${tiket.judulKonser} akan dihapus permanen dari Firestore.',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textSecondary,
            fontSize: 13,
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
                await ref.read(databaseServiceProvider).deleteTicket(tiket.id);
                if (!mounted) return;
                _tampilSnackbar(
                  'Tiket berhasil dihapus',
                  AppColors.success,
                  Icons.check_circle_outline,
                );
              } catch (e) {
                if (!mounted) return;
                _tampilSnackbar(
                  'Gagal menghapus tiket: $e',
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
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopbar(),
            ticketsAsync.when(
              data: (allTickets) {
                final concertNames = _extractConcertNames(allTickets);
                return _buildFilterChips(concertNames);
              },
              loading: () => const SizedBox(height: 36),
              error: (_, __) => const SizedBox(height: 36),
            ),
            Expanded(
              child: ticketsAsync.when(
                data: (allTickets) {
                  final filtered = _filterTickets(allTickets);
                  return _buildDaftarTiket(filtered);
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
                          'Gagal memuat tiket dari Firestore: $e',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ditambah = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const FormTiketScreen(),
            ),
          );
          if (ditambah == true) {
            _tampilSnackbar(
              'Tiket berhasil ditambahkan',
              AppColors.success,
              Icons.check_circle_outline,
            );
          }
        },
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Tambah Tiket',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<String> _extractConcertNames(List<TiketKonserModel> tickets) {
    final namaSet = tickets
        .map((k) => k.judulKonser.split('•').first.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return ['Semua', ...namaSet];
  }

  List<TiketKonserModel> _filterTickets(List<TiketKonserModel> tickets) {
    if (_filterKonser == 'Semua') return tickets;
    return tickets
        .where((t) => t.judulKonser.contains(_filterKonser))
        .toList();
  }

  Widget _buildTopbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBukaSidebar,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
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
            'Manage Tiket',
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'ADMIN',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<String> namaKonser) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: namaKonser.length,
        itemBuilder: (_, i) {
          final nama = namaKonser[i];
          final aktif = nama == _filterKonser;
          return GestureDetector(
            onTap: () => setState(() => _filterKonser = nama),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: aktif ? Colors.white : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: aktif ? Colors.white : AppColors.divider,
                ),
              ),
              child: Text(
                nama,
                style: GoogleFonts.spaceGrotesk(
                  color: aktif ? Colors.black : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
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
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.surfaceLight,
        highlightColor: AppColors.card,
        child: Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDaftarTiket(List<TiketKonserModel> tiketList) {
    if (tiketList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada tiket di Firestore',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: tiketList.length,
      itemBuilder: (_, i) => _buildTiketCard(tiketList[i]),
    );
  }

  Widget _buildTiketCard(TiketKonserModel tiket) {
    final Map<String, Color> colorMap = {
      'oke': AppColors.success,
      'hampir': AppColors.warning,
      'habis': AppColors.error,
    };
    final warnaBadge = colorMap[tiket.statusStok] ?? AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GambarWidget(
                        url: tiket.gambarKonser.isEmpty
                            ? 'assets/images/logo/default.jpg'
                            : tiket.gambarKonser,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        ikonDefault: Icons.music_note_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 50),
                            child: Text(
                              tiket.judulKonser,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.divider.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              tiket.kategori.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.divider,
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      tiket.formatHarga,
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: warnaBadge.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: warnaBadge.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Stok: ${tiket.stok} — ${tiket.labelStok}',
                        style: GoogleFonts.spaceGrotesk(
                          color: warnaBadge,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 13,
            right: 13,
            child: Row(
              children: [
                _tombolAksiKecil(
                  ikon: Icons.edit_outlined,
                  warna: AppColors.primary,
                  onTap: () async {
                    final diperbarui = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormTiketScreen(tiket: tiket),
                      ),
                    );
                    if (diperbarui == true) {
                      _tampilSnackbar(
                        'Tiket berhasil diperbarui',
                        AppColors.success,
                        Icons.check_circle_outline,
                      );
                    }
                  },
                ),
                const SizedBox(width: 6),
                _tombolAksiKecil(
                  ikon: Icons.delete_outline_rounded,
                  warna: AppColors.error,
                  onTap: () => _hapusTiket(tiket),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombolAksiKecil({
    required IconData ikon,
    required Color warna,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(ikon, color: warna, size: 12),
      ),
    );
  }
}
