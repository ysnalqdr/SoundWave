import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../constants/app_constants.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  final UserModel currentUser;
  final VoidCallback? onBukaSidebar;

  const UserManagementScreen({
    super.key,
    required this.currentUser,
    this.onBukaSidebar,
  });

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedRoleFilter = 'all';
  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!widget.currentUser.isSuperAdmin) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Akses ditolak: Hanya Super Admin yang berhak mengelola pengguna.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _db.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat daftar pengguna: $e';
        });
      }
    }
  }

  Future<void> _changeRole(UserModel targetUser, String newRole) async {
    if (!widget.currentUser.isSuperAdmin) {
      _showSnackbar('Akses ditolak: Hanya Super Admin yang dapat mengubah role.', isError: true);
      return;
    }
    if (targetUser.id == widget.currentUser.id) {
      _showSnackbar('Tidak dapat mengubah role akun sendiri.', isError: true);
      return;
    }
    if (_isProcessing) return;

    final actionLabel = newRole == AppConstants.roleAdmin ? 'Promosikan ke Admin' : 'Turunkan ke Member';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$actionLabel?',
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
              'Anda akan mengubah role akun berikut:',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(targetUser.nama, style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text(targetUser.email, style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Role saat ini: ', style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 12)),
                      _roleBadge(targetUser.role),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Role baru: $newRole',
              style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == AppConstants.roleAdmin ? AppColors.warnaHarga : AppColors.primary,
            ),
            child: Text(actionLabel, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _db.updateUserRole(targetUser.id, newRole);
      if (mounted) {
        _showSnackbar('Role ${targetUser.nama} berhasil diubah ke $newRole');
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Gagal mengubah role: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteUser(UserModel targetUser) async {
    if (!widget.currentUser.isSuperAdmin) {
      _showSnackbar('Akses ditolak: Hanya Super Admin yang dapat menghapus profil pengguna.', isError: true);
      return;
    }
    if (targetUser.id == widget.currentUser.id) {
      _showSnackbar('Tidak dapat menghapus akun sendiri.', isError: true);
      return;
    }
    if (targetUser.isSuperAdmin) {
      _showSnackbar('Tidak dapat menghapus akun sesama Super Admin.', isError: true);
      return;
    }
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 8),
            Text(
              'Hapus Profil Pengguna?',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yakin ingin menghapus dokumen profil ${targetUser.nama} (${targetUser.email}) dari database Cloud Firestore?',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Semantik Spark:',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tindakan ini menghapus profil dari Cloud Firestore. Di lingkungan Firebase Spark (Free), kredensial login Firebase Authentication harus dihapus terpisah melalui Firebase Console oleh Administrator untuk mencabut akses akun secara permanen.',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Hapus Profil Firestore', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _db.deleteUser(targetUser.id);
      if (mounted) {
        _showSnackbar('Profil ${targetUser.nama} berhasil dihapus dari Firestore');
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Gagal menghapus profil pengguna: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(date);
  }

  Widget _roleBadge(String role) {
    switch (role) {
      case AppConstants.roleSuperAdmin:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.warning, size: 12),
              const SizedBox(width: 4),
              Text(
                'SUPER ADMIN',
                style: GoogleFonts.spaceGrotesk(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      case AppConstants.roleAdmin:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warnaHarga.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.warnaHarga.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.warnaHarga, size: 12),
              const SizedBox(width: 4),
              Text(
                'ADMIN',
                style: GoogleFonts.spaceGrotesk(color: AppColors.warnaHarga, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            'MEMBER',
            style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Selain super admin melihat tampilan akses ditolak.
    if (!widget.currentUser.isSuperAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: widget.onBukaSidebar != null
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                  onPressed: widget.onBukaSidebar,
                )
              : null,
          title: Text(
            'Kelola User',
            style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_rounded, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Akses Ditolak',
                  style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modul Kelola User hanya diperuntukkan bagi Super Admin.\nAdmin operasional tidak memiliki wewenang mengelola role atau akun pengguna.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalUsers = _users.length;
    final totalSuperAdmins = _users.where((u) => u.isSuperAdmin).length;
    final totalAdmins = _users.where((u) => u.role == AppConstants.roleAdmin).length;
    final totalMembers = _users.where((u) => u.role == AppConstants.roleUser).length;

    final filteredUsers = _users.where((u) {
      final query = _searchCtrl.text.trim().toLowerCase();
      final matchSearch = query.isEmpty ||
          u.nama.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
      final matchRole = _selectedRoleFilter == 'all' || u.role == _selectedRoleFilter;
      return matchSearch && matchRole;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: widget.onBukaSidebar != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                onPressed: widget.onBukaSidebar,
                tooltip: 'Buka Menu',
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelola User',
              style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              'Manajemen hak akses & akun pengguna SoundWave',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _isLoading || _isProcessing ? null : _loadUsers,
            tooltip: 'Segarkan data',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadUsers,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('Coba Lagi', style: GoogleFonts.spaceGrotesk()),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatsStrip(
                        totalUsers: totalUsers,
                        superAdmins: totalSuperAdmins,
                        admins: totalAdmins,
                        members: totalMembers,
                      ),
                      const SizedBox(height: 16),

                      _buildSearchAndFilter(),
                      const SizedBox(height: 16),

                      if (filteredUsers.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredUsers.map((user) => _buildUserCard(user)),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsStrip({
    required int totalUsers,
    required int superAdmins,
    required int admins,
    required int members,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final items = [
          _statItem('Total Pengguna', '$totalUsers', Icons.people_outline_rounded, AppColors.textPrimary),
          _statItem('Super Admin', '$superAdmins', Icons.stars_rounded, AppColors.warning),
          _statItem('Admin', '$admins', Icons.shield_outlined, AppColors.warnaHarga),
          _statItem('Member', '$members', Icons.person_outline_rounded, AppColors.primary),
        ];

        if (isNarrow) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: items,
          );
        }

        return Row(
          children: items.map((item) => Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: item,
          ))).toList(),
        );
      },
    );
  }

  Widget _statItem(String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
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
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceLight,
              hintText: 'Cari nama atau email pengguna...',
              hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoleFilter,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.textMuted),
                      style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Semua Role')),
                        DropdownMenuItem(value: AppConstants.roleSuperAdmin, child: Text('Super Admin')),
                        DropdownMenuItem(value: AppConstants.roleAdmin, child: Text('Admin Operasional')),
                        DropdownMenuItem(value: AppConstants.roleUser, child: Text('Member (User)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoleFilter = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filter Role',
                style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.person_search_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Tidak ada pengguna ditemukan',
            style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ubah kata kunci pencarian atau filter role',
            style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isSelf = user.id == widget.currentUser.id;
    final isSuperAdmin = user.isSuperAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelf ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar dengan inisial sebagai cadangan.
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isSuperAdmin
                    ? const LinearGradient(colors: [Colors.amber, Colors.deepOrange])
                    : AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.initials,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info user
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.nama.isNotEmpty ? user.nama : 'Tanpa Nama',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'AKUN ANDA',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _roleBadge(user.role),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Bergabung ${_formatDate(user.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu aksi, hanya untuk super admin dan bukan pada dirinya sendiri.
            if (isSelf)
              const Tooltip(
                message: 'Akun Anda sendiri terproteksi',
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 20),
                ),
              )
            else if (isSuperAdmin)
              const Tooltip(
                message: 'Akun sesama Super Admin terproteksi',
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.verified_user_rounded, color: AppColors.warning, size: 20),
                ),
              )
            else if (widget.currentUser.isSuperAdmin)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'promote_to_admin') {
                    _changeRole(user, AppConstants.roleAdmin);
                  } else if (value == 'demote_to_user') {
                    _changeRole(user, AppConstants.roleUser);
                  } else if (value == 'delete_user') {
                    _deleteUser(user);
                  }
                },
                itemBuilder: (ctx) => [
                  if (user.role == AppConstants.roleUser)
                    PopupMenuItem(
                      value: 'promote_to_admin',
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.warnaHarga, size: 18),
                          const SizedBox(width: 8),
                          Text('Jadikan Admin', style: GoogleFonts.spaceGrotesk(color: AppColors.warnaHarga)),
                        ],
                      ),
                    )
                  else if (user.role == AppConstants.roleAdmin)
                    PopupMenuItem(
                      value: 'demote_to_user',
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Turunkan ke Member', style: GoogleFonts.spaceGrotesk(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete_user',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Text('Hapus Profil Firestore', style: GoogleFonts.spaceGrotesk(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
