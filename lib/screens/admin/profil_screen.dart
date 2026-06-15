import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../data/dummy_data.dart';
import '../auth/login_screen.dart';
import '../../widgets/gambar_widget.dart';

//!Logic
class AnggotaKelompok {
  final String nama;
  final String nim;
  final String fotoUrl;
  final String peran; //TODO: MANUAL

  const AnggotaKelompok({
    required this.nama,
    required this.nim,
    this.fotoUrl = '',
    this.peran = 'Anggota',
  });
}

//TODO: LIST ANGGOTA
const List<AnggotaKelompok> daftarAnggota = [
  AnggotaKelompok(
    nama: 'Ahmad Fariz Aqil',
    nim: '17240242',
    fotoUrl: 'assets/images/anggota/anggota.jpg',
  ),
  AnggotaKelompok(
    nama: 'Laudya Kesya Maria',
    nim: '17240415',
    fotoUrl: '',
    peran: 'Ketua',
  ),
  AnggotaKelompok(
    nama: 'Muhammad Dzakiy Sev Faiq',
    nim: '17240203',
    fotoUrl: '',
  ),
  AnggotaKelompok(
    nama: 'Muhammad Yasin Al Qadri',
    nim: '17240123',
    fotoUrl: '',
  ),
  AnggotaKelompok(
    nama: 'Putra Rizky Permana',
    nim: '17240623',
    fotoUrl: '',
  ),
  AnggotaKelompok(
    nama: 'Yukie Wirapratama Agusti',
    nim: '17240008',
    fotoUrl: '',
  ),
];

class ProfilScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onBukaSidebar;

  const ProfilScreen({
    super.key,
    required this.user,
    required this.onBukaSidebar,
  });

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _sedangEdit = false;

  late final TextEditingController _namaCtrl;
  late final TextEditingController _nimCtrl;
  late final TextEditingController _kelompokCtrl;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.user.nama);
    _nimCtrl = TextEditingController(text: widget.user.nim);
    _kelompokCtrl = TextEditingController(text: widget.user.namaKelompok);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nimCtrl.dispose();
    _kelompokCtrl.dispose();
    super.dispose();
  }

  void _simpanProfil() {
    DummyData.adminUser = widget.user.copyWith(
      nama: _namaCtrl.text.trim(),
      nim: _nimCtrl.text.trim(),
      namaKelompok: _kelompokCtrl.text.trim(),
    );
    setState(() => _sedangEdit = false);
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
        content: Text(
          'Yakin ingin keluar dari aplikasi?',
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.spaceGrotesk(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = DummyData.adminUser ?? widget.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
//TODO: Header (Versi Terupdate - Kontras & Clean)
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
                  color:
                      Colors.white, // Dipaksa putih murni agar selalu terlihat
                  size: 20,
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
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
                    // Latar belakang tombol menggunakan abu-abu surface agar kontras
                    color: _sedangEdit
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _sedangEdit ? AppColors.error : AppColors.divider,
                    ),
                  ),
                  child: Text(
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
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      admin.nama,
                      style: GoogleFonts.rajdhani(
                        color: Colors
                            .white, // Nama diatur putih murni agar tidak tenggelam
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      admin.email,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors
                            .textSecondary, // Menggunakan abu-abu sedang agar terbaca rapi
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),

                    //! BADGE ADMIN: Diubah menjadi kotak putih dengan teks hitam murni (Sangat Menonjol!)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ADMIN',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors
                              .black, // Teks hitam pekat di atas background putih
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

          //TODO: BODY
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                //TODO: INFO ACCOUNT
                _labelSeksi('Informasi Akun'),
                const SizedBox(height: 10),
                _sedangEdit ? _buildFormEdit() : _buildInfoCard(),

                const SizedBox(height: 24),

                //TODO: SETTINGS
                _labelSeksi('Pengaturan'),
                const SizedBox(height: 10),
                _buildPengaturanCard(),

                const SizedBox(height: 24),

                //TODO: ANGGOTA KELOMPOK
                _buildAnggotaKelompok(),

                const SizedBox(height: 24),

                //TODO: LOGOUIT
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.25),
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
                    'SoundWave v1.0.0',
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

  //TODO: INFO CARD DESIGN KELOMPOK
  Widget _buildInfoCard() {
    final admin = DummyData.adminUser ?? widget.user;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _barisInfo(
            Icons.person_outline_rounded,
            'Nama',
            admin.nama,
          ),
          _barisInfo(
            Icons.email_outlined,
            'Email',
            admin.email,
          ),
          _barisInfo(
            Icons.shield_outlined,
            'Role',
            'ADMIN',
            warnaValue: AppColors.primary,
            isLast: true,
          ),
        ],
      ),
    );
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
          Text(
            nilai,
            style: GoogleFonts.spaceGrotesk(
              color: warnaValue ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  //TODO: FORM EDIT DESIGN
  Widget _buildFormEdit() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
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

  //TODO: SETTINGS DESIGN
  Widget _buildPengaturanCard() {
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
            Icons.info_outline_rounded,
            'Tentang Aplikasi',
            () => showAboutDialog(
              context: context,
              applicationName: 'SoundWave',
              applicationVersion: 'v1.0.0',
              applicationLegalese: '© 2025 SoundWave',
            ),
            isLast: true,
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

  //TODO: ANGGOTA KELOMPOK DESIGN
  Widget _buildAnggotaKelompok() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelSeksi('Anggota Kelompok'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              //TODO: HEADER KELOMPOK
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kelompok Konser',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${daftarAnggota.length} Anggota',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              //!ListAnggota
              ...daftarAnggota.asMap().entries.map((entry) {
                final i = entry.key;
                final anggota = entry.value;
                final isLast = i == daftarAnggota.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(
                              color: AppColors.divider,
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      //! No Urut
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      //! Forto Anggota
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: anggota.fotoUrl.isNotEmpty
                              ? GambarWidget(
                                  url: anggota.fotoUrl,
                                  width: 48,
                                  height: 48,
                                  ikonDefault: Icons.person_rounded,
                                )
                              : _inisialAvatar(anggota.nama),
                        ),
                      ),

                      const SizedBox(width: 12),

                      //! Nama Nim
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anggota.nama,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              anggota.nim,
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      //!BadgeAnggota — ubah peran jadi 'Ketua' di daftarAnggota
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (anggota.peran == 'Ketua'
                                  ? AppColors.primary
                                  : AppColors.success)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (anggota.peran == 'Ketua'
                                    ? AppColors.primary
                                    : AppColors.success)
                                .withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          anggota.peran,
                          style: GoogleFonts.spaceGrotesk(
                            color: anggota.peran == 'Ketua'
                                ? AppColors.primary
                                : AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  //! Avatar Inisial
  Widget _inisialAvatar(String nama) {
    final parts = nama.trim().split(' ');
    final inisial = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : nama.substring(0, 2).toUpperCase();

    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          inisial,
          style: GoogleFonts.rajdhani(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _labelSeksi(String teks) {
    return Text(
      teks.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
