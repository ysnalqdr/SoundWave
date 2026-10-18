import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../auth/login_screen.dart';
import '../../widgets/gambar_widget.dart';
import '../../widgets/tombol_dialog_sejajar.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onBukaSidebar;

  const ProfilScreen({
    super.key,
    required this.user,
    required this.onBukaSidebar,
  });

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  bool _sedangEdit = false;
  bool _sedangSimpan = false;

  late final TextEditingController _namaCtrl;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.user.nama);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpanProfil() async {
    setState(() => _sedangSimpan = true);
    try {
      await ref.read(authServiceProvider).updateProfile(
        uid: widget.user.id,
        nama: _namaCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _sedangSimpan = false;
        _sedangEdit = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Profil berhasil disimpan',
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangSimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Keluar?',
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
              'Yakin ingin keluar dari aplikasi?',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TombolDialogSejajar(
              onBatal: () => Navigator.pop(ctx),
              onKonfirmasi: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(authServiceProvider).logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                } catch (e) {
                  debugPrint('[ProfilScreen] Logout error: $e');
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
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final admin = currentUserAsync.value ?? widget.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: widget.onBukaSidebar,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _sedangSimpan
                    ? null
                    : () {
                        if (_sedangEdit) {
                          _simpanProfil();
                        } else {
                          setState(() => _sedangEdit = true);
                        }
                      },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _sedangEdit
                        ? AppColors.error.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _sedangEdit ? AppColors.error : AppColors.divider,
                    ),
                  ),
                  child: _sedangSimpan
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _sedangEdit ? 'Simpan' : 'Edit',
                          style: GoogleFonts.spaceGrotesk(
                            color: _sedangEdit ? AppColors.error : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    _buildProfileAvatar(admin, 75),
                    const SizedBox(height: 10),
                    Text(
                      admin.nama,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      admin.email,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: admin.isSuperAdmin
                            ? AppColors.warning
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        admin.isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account Info
                _labelSeksi('Informasi Akun'),
                const SizedBox(height: 10),
                _sedangEdit ? _buildFormEdit() : _buildInfoCard(admin),

                const SizedBox(height: 24),

                // Settings
                _labelSeksi('Pengaturan'),
                const SizedBox(height: 10),
                _buildPengaturanCard(admin),

                const SizedBox(height: 24),

                // Logout
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Keluar',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: Text(
                    AppConstants.appVersionLabel,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted,
                      fontSize: 12,
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

  Widget _buildProfileAvatar(UserModel user, double size) {
    if (user.fotoUrl != null && user.fotoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 2),
        ),
        child: ClipOval(
          child: GambarWidget(
            url: user.fotoUrl!,
            width: size,
            height: size,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 2),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(UserModel admin) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _barisInfo(Icons.person_outline_rounded, 'Nama', admin.nama),
          _barisInfo(Icons.email_outlined, 'Email', admin.email),
          _barisInfo(
            Icons.shield_outlined,
            'Role',
            admin.isSuperAdmin ? 'SUPER ADMIN' : 'ADMIN',
            warnaValue: AppColors.primary,
          ),
          if (admin.createdAt != null)
            _barisInfo(
              Icons.calendar_today_outlined,
              'Bergabung',
              _formatDate(admin.createdAt!),
              isLast: true,
            )
          else
            _barisInfo(
              Icons.calendar_today_outlined,
              'Bergabung',
              '-',
              isLast: true,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _barisInfo(
    IconData ikon,
    String label,
    String nilai, {
    Color? warnaValue,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
      ),
      child: Row(
        children: [
          Icon(ikon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              nilai,
              style: GoogleFonts.spaceGrotesk(
                color: warnaValue ?? AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormEdit() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _fieldEdit(
            'Nama Lengkap',
            _namaCtrl,
            Icons.person_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _fieldEdit(
    String label,
    TextEditingController ctrl,
    IconData ikon, {
    TextInputType tipe = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: tipe,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPengaturanCard(UserModel admin) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _itemPengaturan(
            Icons.lock_outline_rounded,
            'Ubah Password',
            () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Fitur ubah password segera hadir',
                  style: GoogleFonts.spaceGrotesk(),
                ),
                backgroundColor: AppColors.surface,
                behavior: SnackBarBehavior.floating,
              ),
            ),
          ),
          _itemPengaturan(
            Icons.dns_outlined,
            'Status Lingkungan & Sistem',
            () => _showEnvironmentDialog(),
          ),
          if (admin.isSuperAdmin)
            _itemPengaturan(
              Icons.admin_panel_settings_outlined,
              'Kebijakan Hak Akses Super Admin',
              () => _showSuperAdminPolicyDialog(),
            ),
          _itemPengaturan(
            Icons.info_outline_rounded,
            'Tentang Aplikasi',
            () => showAboutDialog(
              context: context,
              applicationName: 'SoundWave',
              applicationVersion: 'V${AppConstants.appVersion} (Secure)',
              applicationLegalese: '© 2026 SoundWave - Hak Cipta Dilindungi',
            ),
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showEnvironmentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Status Lingkungan & Sistem',
          style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _envItem('Payment Gateway', 'Midtrans Sandbox', Icons.payment_rounded, AppColors.success),
            const SizedBox(height: 10),
            _envItem('Database & Auth', 'Firebase Spark (Free Plan)', Icons.cloud_done_rounded, AppColors.warnaHarga),
            const SizedBox(height: 10),
            _envItem('Gate Scanner Offline', 'Ed25519 Cryptographic Proof', Icons.security_rounded, AppColors.primary),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _envItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 11)),
                Text(value, style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuperAdminPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Text(
              'Kebijakan Super Admin',
              style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aturan Keamanan Sistem SoundWave:',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              '1. Pengubahan role dan promosi admin hanya dapat dijalankan oleh akun ber-role "super_admin".\n\n'
              '2. Super Admin tidak dapat mencabut hak akun miliknya sendiri atau menghapus sesama Super Admin.\n\n'
              '3. Admin Operasional memiliki akses penuh terhadap Konser, Tiket, Scan Gate, dan Laporan, namun tidak dapat melihat atau mengakses Kelola User.',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Mengerti', style: GoogleFonts.spaceGrotesk(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _itemPengaturan(
    IconData ikon,
    String label,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
        ),
        child: Row(
          children: [
            Icon(ikon, color: AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelSeksi(String teks) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          teks,
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
