import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/konser_model.dart';
import '../../data/dummy_data.dart';
import 'form_konser_screen.dart';
import 'inspect_konser_screen.dart';

class KonserScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onBukaSidebar;

  const KonserScreen({
    super.key,
    required this.user,
    required this.onBukaSidebar,
  });

  @override
  State<KonserScreen> createState() => _KonserScreenState();
}

class _KonserScreenState extends State<KonserScreen> {

  //!State
  bool _sedangLoading = true;
  String _genreAktif  = 'Semua';
  String _kataCari    = '';

  //!Controller Search Bar
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    //! Simulasi Loading Data Server
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _sedangLoading = false);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  //! Hasil Konser Ynag Di Filter
  List<KonserModel> get _konserTerfilter {
    return DummyData.daftarKonser.where((k) {
      final cocokGenre = _genreAktif == 'Semua' || k.genre == _genreAktif;
      final cocokCari  = _kataCari.isEmpty ||
          k.judul.toLowerCase().contains(_kataCari.toLowerCase()) ||
          k.lokasi.toLowerCase().contains(_kataCari.toLowerCase());
      return cocokGenre && cocokCari;
    }).toList();
  }

  //! Hapus Konser
  void _hapusKonser(KonserModel konser) {
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
          '"${konser.judul}" akan dihapus permanen.',
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
              Navigator.pop(ctx);
              setState(() {
                DummyData.daftarKonser.removeWhere(
                  (k) => k.id == konser.id,
                );
              });
              _tampilSnackbar(
                'Konser berhasil dihapus',
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
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _sedangLoading
                  ? _buildSkeleton()
                  : _buildDaftarKonser(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  //TODO: Top Bar
  Widget _buildTopbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          //!Button Open Side Bar
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
            'Manage Konser',
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Badge ADMIN
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

  //TODO: Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
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

  //TODO: Filter Genre
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
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: aktif
                    ? AppColors.primary
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: aktif
                      ? AppColors.primary
                      : AppColors.divider,
                ),
              ),
              child: Text(
                genres[i],
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

  //TODO: Animation Skeleton Loading
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
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  //TODO: Daftar Konser
  Widget _buildDaftarKonser() {
    final konserList = _konserTerfilter;

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
      itemCount: konserList.length,
      itemBuilder: (_, i) => _buildKonserCard(konserList[i]),
    );
  }

  //TODO: Card Konser
  Widget _buildKonserCard(KonserModel konser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar konser
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Image.network(
                  konser.gambarUrl.isEmpty
                      ? 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600'
                      : konser.gambarUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 130,
                    color: AppColors.surfaceLight,
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
                // Overlay gelap
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.card.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badge genre
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      konser.genre,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // 3 tombol aksi (inspect, edit, hapus)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _tombolAksi(
                        ikon: Icons.remove_red_eye_outlined,
                        warna: AppColors.success,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InspectKonserScreen(
                              konser: konser,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _tombolAksi(
                        ikon: Icons.edit_outlined,
                        warna: AppColors.primary,
                        onTap: () async {
                          final diperbarui = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FormKonserScreen(
                                konser: konser,
                              ),
                            ),
                          );
                          if (diperbarui == true) {
                            setState(() {});
                            _tampilSnackbar(
                              'Konser berhasil diperbarui',
                              AppColors.success,
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
          // Info konser
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
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        konser.lokasi,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${konser.tanggal.day}/${konser.tanggal.month}/${konser.tanggal.year}',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        konser.formatHarga,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
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

  //! Button Icon, Warna, Tap
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
          color: AppColors.background.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(ikon, color: warna, size: 15),
      ),
    );
  }

  //TODO: Tab Tambah Konser
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final ditambah = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const FormKonserScreen(),
          ),
        );
        if (ditambah == true) {
          setState(() {});
          _tampilSnackbar(
            'Konser berhasil ditambahkan',
            AppColors.success,
            Icons.check_circle_outline,
          );
        }
      },
      backgroundColor: AppColors.primary,
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