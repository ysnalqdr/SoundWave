import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../providers/app_providers.dart';
import '../user/user_main_screen.dart';
import 'dashboard_admin_screen.dart';
import 'konser_screen.dart';
import 'tiket_screen.dart';
import 'profil_screen.dart';
import 'gate_scanner_screen.dart';
import 'laporan_penjualan_screen.dart';
import 'user_management_screen.dart';
import 'kelola_promo_screen.dart';
import 'laporan_revenue_screen.dart';
import 'kelola_refund_screen.dart';
import '../../widgets/tombol_dialog_sejajar.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDestination {
  final String label;
  final IconData icon;
  final Widget Function(UserModel user, VoidCallback openSidebar) screenBuilder;
  final bool superAdminOnly;
  final String group;

  const _AdminDestination({
    required this.label,
    required this.icon,
    required this.screenBuilder,
    this.superAdminOnly = false,
    required this.group,
  });
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _halamanAktif = 0;
  bool _sidebarCollapsed = false; // Desktop sidebar collapse state
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late UserModel _currentUser;

  // Tidak lagi `static` supaya tiap tujuan bisa memanggil `_pindahKeLabel`
  // (dipakai kartu "Perlu tindakan" di Dashboard untuk lompat ke menu lain).
  late final List<_AdminDestination> _allDestinations = [
    _AdminDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      group: 'OPERASIONAL',
      screenBuilder: (user, openSidebar) => DashboardAdminScreen(
        user: user,
        onBukaSidebar: openSidebar,
        onBukaMenu: _pindahKeLabel,
      ),
    ),
    _AdminDestination(
      label: 'Konser',
      icon: Icons.music_note_rounded,
      group: 'OPERASIONAL',
      screenBuilder: (user, openSidebar) => KonserScreen(user: user, onBukaSidebar: openSidebar),
    ),
    _AdminDestination(
      label: 'Tiket',
      icon: Icons.confirmation_number_outlined,
      group: 'OPERASIONAL',
      screenBuilder: (user, openSidebar) => TiketScreen(user: user, onBukaSidebar: openSidebar),
    ),
    _AdminDestination(
      label: 'Validasi Gate (Scan)',
      icon: Icons.qr_code_scanner_rounded,
      group: 'OPERASIONAL',
      screenBuilder: (user, openSidebar) => GateScannerScreen(user: user, onBukaSidebar: openSidebar),
    ),
    _AdminDestination(
      label: 'Laporan Penjualan',
      icon: Icons.analytics_outlined,
      group: 'OPERASIONAL',
      screenBuilder: (user, openSidebar) => LaporanPenjualanScreen(user: user, onBukaSidebar: openSidebar),
    ),
    _AdminDestination(
      label: 'Revenue Dashboard',
      icon: Icons.bar_chart_rounded,
      group: 'OPERASIONAL',
      screenBuilder: (user, openSidebar) => LaporanRevenueScreen(user: user, onBukaSidebar: openSidebar),
    ),
    _AdminDestination(
      label: 'Kelola Promo',
      icon: Icons.local_offer_rounded,
      group: 'OPERASIONAL',
      screenBuilder: (user, openSidebar) => KelolaPromoScreen(user: user, onBukaSidebar: openSidebar),
    ),
    _AdminDestination(
      label: 'Kelola Refund',
      icon: Icons.undo_rounded,
      group: 'OPERASIONAL',
      screenBuilder: (user, openSidebar) => KelolaRefundScreen(user: user, onBukaSidebar: openSidebar),
    ),
    _AdminDestination(
      label: 'Kelola User',
      icon: Icons.people_outline_rounded,
      group: 'MANAJEMEN SISTEM',
      superAdminOnly: true,
      screenBuilder: (user, openSidebar) => UserManagementScreen(currentUser: user, onBukaSidebar: openSidebar),
    ),
    _AdminDestination(
      label: 'Profil & Pengaturan',
      icon: Icons.account_circle_outlined,
      group: 'AKUN',
      screenBuilder: (user, openSidebar) => ProfilScreen(user: user, onBukaSidebar: openSidebar),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  List<_AdminDestination> _getDestinations(bool isSuperAdmin) {
    if (isSuperAdmin) {
      return _allDestinations;
    }
    return _allDestinations.where((d) => !d.superAdminOnly).toList();
  }

  /// Pindah halaman lewat label menu (dipakai Dashboard & jalan pintas).
  /// Dicari berdasarkan label, bukan index, supaya tetap benar ketika daftar
  /// menu menyusut untuk admin non-super.
  void _pindahKeLabel(String label) {
    final daftar = _getDestinations(_currentUser.isSuperAdmin);
    final index = daftar.indexWhere((d) => d.label == label);
    if (index < 0) return;
    setState(() => _halamanAktif = index);
  }

  void _bukaSidebar() {
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    if (isDesktop) {
      // Di desktop, sidebar diciutkan, bukan membuka drawer.
      setState(() => _sidebarCollapsed = !_sidebarCollapsed);
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  void _tutupSidebar(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _gantiHalaman(int index, bool isDesktop) {
    setState(() => _halamanAktif = index);
    if (!isDesktop) {
      _tutupSidebar(context);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Yakin ingin keluar dari dashboard SoundWave?',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TombolDialogSejajar(
              onBatal: () => Navigator.pop(ctx),
              onKonfirmasi: () async {
                Navigator.pop(ctx);
                try {
                  await AuthService().logout();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                } catch (e) {
                  debugPrint('[AdminDashboard] Logout error: $e');
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
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tap notifikasi push -> mendarat di Konser (index 1), BUKAN Dashboard:
    // notifikasi selalu bercerita tentang pesanan/konser, jadi operator
    // dibawa langsung ke daftar konser tempat aksi berikutnya dilakukan.
    ref.listen<int>(permintaanMenuUtamaProvider, (_, __) {
      if (mounted) setState(() => _halamanAktif = 1);
    });

    // Pantau perubahan profil user secara real-time.
    ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider, (prev, next) {
      if (next.hasValue) {
        final updatedUser = next.value;
        if (updatedUser == null || !updatedUser.isAdmin) {
          // Hak admin dicabut.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akses administrator Anda telah dicabut.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pushReplacementNamed(context, '/user');
          }
        } else {
          setState(() {
            _currentUser = updatedUser;
          });
        }
      }
    });

    final isSuperAdmin = _currentUser.isSuperAdmin;
    final destinations = _getDestinations(isSuperAdmin);

    // Cegah index out of bounds saat role turun dan menu menyusut.
    if (_halamanAktif >= destinations.length) {
      _halamanAktif = 0;
    }

    final isDesktop = MediaQuery.of(context).size.width >= 960;
    final activeDestination = destinations[_halamanAktif];
    final activeScreen = activeDestination.screenBuilder(_currentUser, _bukaSidebar);

    if (isDesktop) {
      final sidebarWidth = _sidebarCollapsed ? 72.0 : 260.0;

      // Tata letak desktop: sidebar tetap bisa diciutkan.
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: sidebarWidth,
              child: _buildSidebarContent(
                destinations: destinations,
                isDesktop: true,
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.divider),
            Expanded(child: activeScreen),
          ],
        ),
      );
    }

    // Tata letak ponsel: drawer adaptif.
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        width: 270,
        child: _buildSidebarContent(
          destinations: destinations,
          isDesktop: false,
        ),
      ),
      body: activeScreen,
    );
  }

  Widget _buildSidebarContent({
    required List<_AdminDestination> destinations,
    required bool isDesktop,
  }) {
    final isSuperAdmin = _currentUser.isSuperAdmin;
    final collapsed = isDesktop && _sidebarCollapsed;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: collapsed
                ? EdgeInsets.fromLTRB(8, isDesktop ? 32 : 54, 8, 16)
                : EdgeInsets.fromLTRB(20, isDesktop ? 32 : 54, 20, 20),
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              crossAxisAlignment: collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                if (collapsed) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isSuperAdmin
                          ? const LinearGradient(colors: [Colors.amber, Colors.deepOrange])
                          : AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _currentUser.initials,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: isSuperAdmin
                              ? const LinearGradient(colors: [Colors.amber, Colors.deepOrange])
                              : AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isSuperAdmin ? AppColors.warning : AppColors.primary).withValues(alpha: 0.3),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentUser.initials,
                            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUser.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _currentUser.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSuperAdmin
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.warnaHarga.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSuperAdmin
                            ? AppColors.warning.withValues(alpha: 0.4)
                            : AppColors.warnaHarga.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSuperAdmin ? Icons.stars_rounded : Icons.shield_outlined,
                          color: isSuperAdmin ? AppColors.warning : AppColors.warnaHarga,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN OPERASIONAL',
                          style: GoogleFonts.spaceGrotesk(
                            color: isSuperAdmin ? AppColors.warning : AppColors.warnaHarga,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuSection('OPERASIONAL', destinations.where((d) => d.group == 'OPERASIONAL').toList(), destinations, isDesktop, collapsed),
                if (destinations.any((d) => d.group == 'MANAJEMEN SISTEM'))
                  _buildMenuSection('MANAJEMEN SISTEM', destinations.where((d) => d.group == 'MANAJEMEN SISTEM').toList(), destinations, isDesktop, collapsed),
                
                if (!collapsed) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(color: AppColors.divider),
                  ),

                  // Mode penonton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      'MODE APLIKASI',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: InkWell(
                      onTap: () {
                        if (!isDesktop) _tutupSidebar(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserMainScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.headphones_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mode Penonton (User)',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.open_in_new, color: AppColors.primary, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Divider(color: AppColors.divider),
                  ),
                  Tooltip(
                    message: 'Mode Penonton (User)',
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserMainScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.headphones_rounded, color: AppColors.primary, size: 18),
                      ),
                    ),
                  ),
                ],

                if (!collapsed) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Divider(color: AppColors.divider),
                  ),

                  _buildMenuSection('AKUN', destinations.where((d) => d.group == 'AKUN').toList(), destinations, isDesktop, collapsed),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Divider(color: AppColors.divider),
                  ),
                  _buildMenuSection('AKUN', destinations.where((d) => d.group == 'AKUN').toList(), destinations, isDesktop, collapsed),
                ],
              ],
            ),
          ),

          if (collapsed)
            Tooltip(
              message: 'Keluar',
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Keluar',
                        style: GoogleFonts.spaceGrotesk(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isDesktop)
            InkWell(
              onTap: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Icon(
                  _sidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),

          if (!isDesktop)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                AppConstants.appVersionLabelSecure,
                style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    String title,
    List<_AdminDestination> sectionDestinations,
    List<_AdminDestination> allActiveDestinations,
    bool isDesktop,
    bool collapsed,
  ) {
    if (sectionDestinations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ...sectionDestinations.map((dest) {
          final globalIndex = allActiveDestinations.indexOf(dest);
          final isAktif = _halamanAktif == globalIndex;

          if (collapsed) {
            return Tooltip(
              message: dest.label,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: InkWell(
                  onTap: () => _gantiHalaman(globalIndex, isDesktop),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isAktif ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isAktif
                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Icon(
                      dest.icon,
                      color: isAktif ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: InkWell(
              onTap: () => _gantiHalaman(globalIndex, isDesktop),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: isAktif ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isAktif
                      ? const Border(left: BorderSide(color: AppColors.primary, width: 3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      dest.icon,
                      color: isAktif ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dest.label,
                        style: GoogleFonts.spaceGrotesk(
                          color: isAktif ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isAktif ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (dest.superAdminOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SUPER',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.warning,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}