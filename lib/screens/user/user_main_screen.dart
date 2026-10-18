import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/user_model.dart';
import '../../widgets/gambar_widget.dart';
import '../admin/admin_dashboard.dart';
import '../auth/login_screen.dart';
import 'user_explore_screen.dart';
import 'user_tiket_screen.dart';
import 'user_favorit_screen.dart';
import 'diskon_saya_screen.dart';
import '../../widgets/tombol_dialog_sejajar.dart';

class UserMainScreen extends ConsumerStatefulWidget {
  const UserMainScreen({super.key});

  @override
  ConsumerState<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends ConsumerState<UserMainScreen> {
  int _currentIndex = 0;

  void _pindahKeTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Tap notifikasi push -> mendarat di menu utama: tab Jelajah (index 0).
    ref.listen<int>(permintaanMenuUtamaProvider, (_, __) {
      if (mounted) _pindahKeTab(0);
    });

    // Layar lain (mis. checkout) boleh meminta tab tertentu — dipakai tombol
    // "Ke Tiket Saya" supaya user tidak tertinggal di langkah pembayaran.
    ref.listen<int>(permintaanTabUserProvider, (_, tab) {
      if (mounted && tab >= 0 && tab < 4) _pindahKeTab(tab);
    });

    final screens = [
      const UserExploreScreen(),
      const UserTiketScreen(),
      UserFavoritScreen(onMulaiJelajah: () => _pindahKeTab(0)),
      _buildAkunScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _pindahKeTab,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.rajdhani(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
          unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Jelajah',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number),
              label: 'Tiket Saya',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAkunScreen() {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final userAsync = ref.watch(currentUserStreamProvider);
    final UserModel? user = userAsync.valueOrNull;
    final bool isAuthenticated = authUser != null;
    final bool hasProfileError = isAuthenticated && userAsync.hasError;
    final bool isProfileMissing =
        isAuthenticated && !userAsync.isLoading && !userAsync.hasError && user == null;

    final String displayName = user != null && user.nama.isNotEmpty
        ? user.nama
        : (authUser?.displayName?.isNotEmpty == true
            ? authUser!.displayName!
            : (isAuthenticated ? 'Pengguna SoundWave' : 'Pengguna SoundWave'));

    final String displayEmail = user != null && user.email.isNotEmpty
        ? user.email
        : (authUser?.email ?? 'Belum masuk');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile Hero Header
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF0D0D14),
                    AppColors.background,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    children: [
                      // Profile Photo
                      _buildProfilePhoto(user, authUser: authUser),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        displayName,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        displayEmail,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Role Badge
                      if (user != null)
                        _buildRoleBadge(user)
                      else if (isAuthenticated)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isProfileMissing ? 'MEMBER (PERLU SINKRONISASI)' : 'MEMBER',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      // Member Since
                      if (user != null && user.createdAt != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppColors.textMuted.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Member sejak ${_formatDate(user.createdAt!)}',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textMuted.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Diagnostic Banners for Profile States (Semantics Isolation)
          if (hasProfileError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Koneksi Firestore gagal memuat profil. Identitas akun tetap aktif.',
                          style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
                        onPressed: () => ref.invalidate(currentUserStreamProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isProfileMissing)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_problem_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dokumen profil belum sinkron di database.',
                          style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref.read(authServiceProvider).ensureProfile(authUser);
                          ref.invalidate(currentUserStreamProvider);
                        },
                        child: Text('Sinkronkan', style: GoogleFonts.spaceGrotesk(color: AppColors.warning, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Stats Cards (real data only)
          if (user != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildStatsRow(user),
              ),
            ),

          // Menu Sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account Section
                _sectionLabel('Akun'),
                const SizedBox(height: 8),
                _buildMenuCard([
                  if (user != null)
                    _menuItem(
                      Icons.edit_outlined,
                      'Edit Profil',
                      'Ubah nama dan foto profil',
                      onTap: () => _showEditProfileSheet(user),
                    ),
                  if (user != null && user.isAdmin)
                    _menuItem(
                      Icons.admin_panel_settings_outlined,
                      'Panel Admin',
                      'Kelola konser, tiket & scanner',
                      iconColor: AppColors.warning,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminDashboard(user: user),
                          ),
                        );
                      },
                    ),
                ]),

                const SizedBox(height: 20),

                // Activity Section
                _sectionLabel('Aktivitas'),
                const SizedBox(height: 8),
                _buildMenuCard([
                  _menuItem(
                    Icons.confirmation_number_outlined,
                    'E-Tiket Saya',
                    'Lihat semua tiket aktif',
                    onTap: () => _pindahKeTab(1),
                  ),
                  _menuItem(
                    Icons.favorite_outline,
                    'Konser Favorit',
                    'Daftar konser yang disimpan',
                    onTap: () => _pindahKeTab(2),
                  ),
                  _menuItem(
                    Icons.local_offer_outlined,
                    'Diskon Saya',
                    'Voucher promo yang sudah diklaim',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiskonSayaScreen(),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Settings Section
                _sectionLabel('Pengaturan'),
                const SizedBox(height: 8),
                _buildMenuCard([
                  _menuItem(
                    Icons.info_outline_rounded,
                    'Tentang SoundWave',
                    'Versi, lisensi, informasi',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'SoundWave',
                      applicationVersion: 'V${AppConstants.appVersion}',
                      applicationLegalese: '© 2026 SoundWave',
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Session Section (Strict Authentication Isolation)
                if (isAuthenticated)
                  GestureDetector(
                    onTap: _confirmLogout,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Keluar dari Akun',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.error,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Masuk atau Daftar',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                Center(
                  child: Text(
                    AppConstants.appVersionLabel,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- Profile Photo ---
  Widget _buildProfilePhoto(UserModel? user, {User? authUser}) {
    const double size = 88;
    final photoUrl = (user != null && user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
        ? user.fotoUrl
        : authUser?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: GambarWidget(
            url: photoUrl,
            width: size,
            height: size,
          ),
        ),
      );
    }

    String initials = '?';
    if (user != null) {
      initials = user.initials;
    } else if (authUser?.displayName != null && authUser!.displayName!.trim().isNotEmpty) {
      final parts = authUser.displayName!.trim().split(' ');
      initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : authUser.displayName![0].toUpperCase();
    } else if (authUser?.email != null && authUser!.email!.isNotEmpty) {
      initials = authUser.email![0].toUpperCase();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A3E), Color(0xFF1A1A2E)],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 2.5,
        ),
      ),
      child: Center(
        child: (user != null || authUser != null)
            ? Text(
                initials,
                style: GoogleFonts.rajdhani(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const Icon(
                Icons.person_outline,
                color: AppColors.textMuted,
                size: 36,
              ),
      ),
    );
  }

  // --- Role Badge ---
  Widget _buildRoleBadge(UserModel user) {
    final isSuperAdmin = user.isSuperAdmin;
    final isAdmin = user.isAdmin;

    Color badgeColor;
    String label;

    if (isSuperAdmin) {
      badgeColor = AppColors.warning;
      label = 'SUPER ADMIN';
    } else if (isAdmin) {
      badgeColor = AppColors.success;
      label = 'ADMIN';
    } else {
      badgeColor = AppColors.primary.withValues(alpha: 0.15);
      label = 'MEMBER';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? badgeColor.withValues(alpha: 0.15) : badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: isAdmin
            ? Border.all(color: badgeColor.withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: isAdmin ? badgeColor : AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // --- Stats Row (real data from providers) ---
  Widget _buildStatsRow(UserModel user) {
    final ordersAsync = ref.watch(userOrdersProvider(user.id));
    final favAsync = ref.watch(favoriteIdsProvider(user.id));

    final orders = ordersAsync.valueOrNull ?? [];
    final favCount = favAsync.valueOrNull?.length ?? 0;
    final activeTickets = orders.where((o) => o.status == 'AKTIF').length;
    final attended = orders.where((o) => o.status == 'TERPAKAI').length;

    return Row(
      children: [
        _statCard('Tiket Aktif', activeTickets.toString(), Icons.confirmation_number_outlined),
        const SizedBox(width: 10),
        _statCard('Dihadiri', attended.toString(), Icons.event_available_outlined),
        const SizedBox(width: 10),
        _statCard('Favorit', favCount.toString(), Icons.favorite_outline),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Section Label ---
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.rajdhani(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // --- Menu Card ---
  Widget _buildMenuCard(List<Widget> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle, {
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return _MenuItemWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      onTap: onTap,
    );
  }

  // --- Edit Profile Bottom Sheet ---
  void _showEditProfileSheet(UserModel user) {
    final nameCtrl = TextEditingController(text: user.nama);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        bool saving = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Profil',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Avatar (read-only — custom upload deferred)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: ClipOval(
                            child: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                                ? GambarWidget(url: user.fotoUrl!, width: 80, height: 80)
                                : Center(
                                    child: Text(
                                      user.initials,
                                      style: GoogleFonts.rajdhani(
                                        color: AppColors.primary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                              ? 'Foto profil terhubung (Google/akun)'
                              : 'Inisial profil (foto kustom dinonaktifkan)',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nama Lengkap',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: Icon(Icons.person_outline,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              try {
                                await ref.read(authServiceProvider).updateProfile(
                                  uid: user.id,
                                  nama: nameCtrl.text.trim(),
                                  fotoUrl: user.fotoUrl,
                                );
                                ref.invalidate(currentUserStreamProvider);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Profil berhasil diperbarui',
                                          style: GoogleFonts.spaceGrotesk()),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal memperbarui profil: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warnaTombolBg,
                        foregroundColor: AppColors.warnaTombolTeks,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Simpan',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w600,
                              )),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Keluar Akun?',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yakin ingin keluar dari akun SoundWave kamu?',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TombolDialogSejajar(
              onBatal: () => Navigator.pop(ctx, false),
              onKonfirmasi: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authServiceProvider).logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        debugPrint('[UserMainScreen] Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal keluar akun: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

class _MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _MenuItemWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textMuted).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: iconColor ?? AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
