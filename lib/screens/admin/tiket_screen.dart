import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/tiket_konser_model.dart';
import '../../data/dummy_data.dart';
import 'form_tiket_screen.dart';

class TiketScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onBukaSidebar;

  const TiketScreen({
    super.key,
    required this.user,
    required this.onBukaSidebar,
  });

  @override
  State<TiketScreen> createState() => _TiketScreenState();
}

class _TiketScreenState extends State<TiketScreen> {

  bool _sedangLoading = true;
  String _filterKonser = 'Semua';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _sedangLoading = false);
    });
  }

  //TODO: Done Filter Tiket Konser
  List<TiketKonserModel> get _tiketTerfilter {
    if (_filterKonser == 'Semua') return DummyData.daftarTiket;
    return DummyData.daftarTiket
        .where((t) => t.judulKonser.contains(_filterKonser))
        .toList();
  }

  //TODO: Done Daftar Nama Konser Yang Di Filter
  List<String> get _namaKonser {
    final namaSet = DummyData.daftarKonser
        .map((k) => k.judul.split('•').first.trim())
        .toSet()
        .toList();
    return ['Semua', ...namaSet];
  }

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
          'Tiket ${tiket.kategori} - ${tiket.judulKonser} akan dihapus.',
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                DummyData.daftarTiket.removeWhere(
                  (t) => t.id == tiket.id,
                );
              });
              _tampilSnackbar(
                'Tiket berhasil dihapus',
                AppColors.success,
                Icons.check_circle_outline,
              );
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
            Text(
              pesan,
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopbar(),
            _buildFilterChips(),
            Expanded(
              child: _sedangLoading
                  ? _buildSkeleton()
                  : _buildDaftarTiket(),
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
            setState(() {});
            _tampilSnackbar(
              'Tiket berhasil ditambahkan',
              AppColors.success,
              Icons.check_circle_outline,
            );
          }
        },
        backgroundColor: AppColors.accent,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _namaKonser.length,
        itemBuilder: (_, i) {
          final nama  = _namaKonser[i];
          final aktif = nama == _filterKonser;
          return GestureDetector(
            onTap: () => setState(() => _filterKonser = nama),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: aktif
                    ? AppColors.accent
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: aktif
                      ? AppColors.accent
                      : AppColors.divider,
                ),
              ),
              child: Text(
                nama,
                style: GoogleFonts.spaceGrotesk(
                  color: aktif
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: aktif
                      ? FontWeight.w600
                      : FontWeight.normal,
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

  Widget _buildDaftarTiket() {
    final tiketList = _tiketTerfilter;

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
              'Belum ada tiket',
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
    //! Warna Badge Stok
    final warnaBadge = {
      'oke'    : AppColors.success,
      'hampir' : AppColors.warning,
      'habis'  : AppColors.error,
    }[tiket.statusStok]!;

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
              //! Bagian Atas Ada Gambar Info
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    //! Gambar Kecil Konser
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        tiket.gambarKonser,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    //! Info Tiket
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
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  DummyData.daftarKonser
                                      .firstWhere(
                                        (k) => k.id == tiket.idKonser,
                                        orElse: () =>
                                            DummyData.daftarKonser.first,
                                      )
                                      .lokasi,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Badge kategori
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              tiket.kategori,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              //! Tiket Style(Line)
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

              //! Bagian Bawah Harga Stok
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Harga
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        tiket.formatHarga,
                        style: GoogleFonts.rajdhani(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Badge stok
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: warnaBadge.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: warnaBadge.withOpacity(0.3),
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

          //! Button Act Di pojok kanan atas card
          Positioned(
            top: 13,
            right: 13,
            child: Row(
              children: [
                _tombolAksiKecil(
                  ikon: Icons.edit_outlined,
                  warna: AppColors.primary,
                  onTap: () async {
                    final diperbarui =
                        await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FormTiketScreen(tiket: tiket),
                      ),
                    );
                    if (diperbarui == true) {
                      setState(() {});
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
          color: AppColors.background.withOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(ikon, color: warna, size: 12),
      ),
    );
  }
}