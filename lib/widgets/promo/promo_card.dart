import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/promo_model.dart';
import '../../utils/app_theme.dart';
import '../gambar_widget.dart';

/// ============================================================================
/// KARTU PROMO — gaya poster, tanpa tombol klaim
/// ============================================================================
///
/// Kartu ini sengaja **tidak** punya tombol "Klaim". Mengetuk kartu membuka
/// lembar ketentuan; tombol klaim ada di sana. Alasannya bukan estetika:
///
/// * Pengguna perlu tahu **syaratnya** (minimum belanja, masa berlaku, kuota,
///   tidak bisa digabung) sebelum menyimpan voucher. Tombol klaim di kartu
///   membuat orang menyimpan voucher yang ternyata tidak bisa dipakai.
/// * Satu kartu yang bisa diketuk di mana saja jauh lebih mudah ditekan
///   daripada tombol kecil 34px di dalam kartu.
///
/// ## Tema warna
///
/// Tiga tema, sesuai referensi desain: **gold** (obsidian + champagne),
/// **emerald** (hitam + emerald), **amethyst** (hitam + ungu).
///
/// Warna dipilih dari field `tema` di dokumen promo bila ada. Kalau tidak
/// ada, warnanya **bergilir menurut indeks** supaya deretan kartu terlihat
/// hidup tanpa admin harus mengisi apa pun.
///
/// Catatan penting: warna tema ini **bukan** hijau harga. Hijau di
/// `AppColors.primary` dipakai untuk satu makna — uang. Emerald di sini
/// adalah warna kartu promo, dan karena itu didefinisikan terpisah.
enum TemaPromo {
  gold,
  emerald,
  amethyst,
  silver,
  red;

  /// Warna aksen utama tema.
  Color get aksen => switch (this) {
        TemaPromo.gold => const Color(0xFFE8C87A),
        TemaPromo.emerald => const Color(0xFF34D399),
        TemaPromo.amethyst => const Color(0xFFA78BFA),
        // Hitam + silver chrome. Kontras 12,1:1 di latar #08090C.
        TemaPromo.silver => const Color(0xFFC8C8D0),
        // Luxury glossy red. Kontras 5,47:1 di latar — aman untuk teks,
        // tetapi sengaja hanya dipakai DI DALAM kartu voucher, tidak di
        // chrome aplikasi, supaya tidak tertukar dengan merah galat
        // (#FF5A5F).
        TemaPromo.red => const Color(0xFFFF3048),
      };

  /// Warna aksen kedua untuk gradien halus.
  Color get aksen2 => switch (this) {
        TemaPromo.gold => const Color(0xFFB8860B),
        TemaPromo.emerald => const Color(0xFF0E9F6E),
        TemaPromo.amethyst => const Color(0xFF7C3AED),
        TemaPromo.silver => const Color(0xFF2A2A30),
        TemaPromo.red => const Color(0xFF35090F),
      };

  /// Label bawaan tema — dipakai HANYA kalau promo tidak menentukan label
  /// sendiri (`PromoCodeModel.label` kosong).
  ///
  /// Nama-nama ini dipilih supaya terasa seperti tingkatan keanggotaan,
  /// bukan sekadar nama warna. Karena itu admin sebaiknya mengisi label
  /// sendiri: "SIGNATURE" untuk promo biasa akan menyesatkan.
  String get label => switch (this) {
        TemaPromo.gold => 'SIGNATURE',
        TemaPromo.silver => 'PLATINUM',
        TemaPromo.amethyst => 'NOCTURNE',
        TemaPromo.emerald => 'RESERVE',
        TemaPromo.red => 'BACKSTAGE',
      };

  /// Pilih tema dari dokumen promo, atau bergilir menurut indeks.
  static TemaPromo untuk(PromoCodeModel promo, int indeks) {
    final t = (promo.tema ?? '').toLowerCase().trim();
    for (final tema in TemaPromo.values) {
      if (tema.name == t) return tema;
    }
    return TemaPromo.values[indeks % TemaPromo.values.length];
  }
}

/// Kartu promo bergaya poster. Ketuk untuk membuka ketentuan.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.promo,
    required this.tema,
    required this.onKetuk,
    this.sudahDiklaim = false,
  });

  final PromoCodeModel promo;
  final TemaPromo tema;
  final VoidCallback onKetuk;
  final bool sudahDiklaim;

  String _rp(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $s';
  }

  String get _nilaiBesar {
    // Persentase tampil besar ("50%"), nominal tetap tampil sebagai rupiah.
    if (promo.tipe == 'percentage') {
      return '${promo.nilai.toStringAsFixed(0)}%';
    }
    return _rp(promo.nilai);
  }

  String get _subjudul {
    if (promo.tipe == 'percentage') {
      return 'Potongan ${promo.nilai.toStringAsFixed(0)}% '
          'untuk tiket pilihan';
    }
    return 'Potongan ${_rp(promo.nilai)} untuk tiket pilihan';
  }

  /// Label yang tampil: dari data promo bila ada, kalau tidak dari tema.
  String get labelTampil {
    final l = promo.label?.trim();
    if (l != null && l.isNotEmpty) return l;
    return tema.label;
  }

  String get _masaBerlaku {
    String tgl(DateTime d) {
      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      return '${d.day} ${bulan[d.month - 1]} ${d.year}';
    }

    return 'Berlaku sampai ${tgl(promo.berlakuAkhir)}';
  }

  @override
  Widget build(BuildContext context) {
    final aksen = tema.aksen;
    final berlaku = promo.isValid;

    return SizedBox(
      width: 268,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onKetuk,
          borderRadius: AppRadius.rLg,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.rLg,
              border: Border.all(color: aksen.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: aksen.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.rLg,
              child: Stack(
                children: [
                  // Latar: poster konser (bila ada) di bawah lapisan gelap,
                  // supaya teks tetap terbaca apa pun gambarnya.
                  Positioned.fill(
                    child: promo.gambarUrl != null && promo.gambarUrl!.isNotEmpty
                        ? GambarWidget(url: promo.gambarUrl!, fit: BoxFit.cover)
                        : const SizedBox.shrink(),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xF20A0A0E),
                            const Color(0xE60A0A0E),
                            aksen.withValues(alpha: 0.16),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Cahaya tema di sudut kanan atas.
                  Positioned(
                    top: -46,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            aksen.withValues(alpha: 0.34),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: aksen.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: aksen.withValues(alpha: 0.4)),
                              ),
                              // Label dibatasi satu baris.
                              //
                              // Label berasal dari tema, tapi kartu juga
                              // bisa memuat teks panjang dari data promo.
                              // Tanpa `maxLines`, label yang panjang
                              // membungkus ke baris kedua dan mendorong
                              // tinggi isi melewati wadah — itu sumber
                              // "BOTTOM OVERFLOWED BY 1.00 PIXELS".
                              child: Text(
                                labelTampil,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.rajdhani(
                                  color: aksen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (sudahDiklaim)
                              Icon(Icons.check_circle_rounded,
                                  size: 16,
                                  color: aksen.withValues(alpha: 0.9)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Angka besar: nilai diskon.
                        Text(
                          _nilaiBesar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rajdhani(
                            color: aksen,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _subjudul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Kode voucher, seperti di referensi.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.confirmation_number_outlined,
                                  size: 11, color: aksen),
                              const SizedBox(width: 5),
                              Text(
                                promo.kode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textPrimary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          berlaku ? _masaBerlaku : 'Sudah tidak berlaku',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: berlaku
                                ? AppColors.textMuted
                                : AppColors.textDisabled,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
