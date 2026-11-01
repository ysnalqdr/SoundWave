import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/promo_model.dart';
import '../../utils/app_theme.dart';
import 'promo_card.dart';

/// ============================================================================
/// LEMBAR KETENTUAN VOUCHER
/// ============================================================================
///
/// Dibuka saat kartu promo diketuk. Berisi **syarat pemakaian** dan tombol
/// klaim — satu-satunya tempat voucher bisa disimpan.
///
/// Kenapa syaratnya ditampilkan lebih dulu, bukan tombol klaim di kartu:
/// voucher yang tersimpan tapi tidak bisa dipakai (karena minimum belanja
/// belum terpenuhi, atau sudah kedaluwarsa) membuat pembeli kecewa di detik
/// terakhir checkout. Menampilkan syaratnya di depan mencegah itu.
///
/// Lembaran ini mengembalikan `true` lewat `Navigator.pop` bila klaim
/// berhasil, supaya pemanggil bisa menyegarkan daftar.
class PromoLembar extends StatefulWidget {
  const PromoLembar({
    super.key,
    required this.promo,
    required this.tema,
    required this.sudahDiklaim,
    required this.onKlaim,
  });

  final PromoCodeModel promo;
  final TemaPromo tema;
  final bool sudahDiklaim;

  /// Dipanggil saat tombol klaim ditekan. Mengembalikan pesan galat, atau
  /// null bila berhasil.
  final Future<String?> Function() onKlaim;

  /// Menampilkan lembaran ini sebagai modal bottom sheet.
  static Future<bool?> tampilkan(
    BuildContext context, {
    required PromoCodeModel promo,
    required TemaPromo tema,
    required bool sudahDiklaim,
    required Future<String?> Function() onKlaim,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PromoLembar(
        promo: promo,
        tema: tema,
        sudahDiklaim: sudahDiklaim,
        onKlaim: onKlaim,
      ),
    );
  }

  @override
  State<PromoLembar> createState() => _PromoLembarState();
}

class _PromoLembarState extends State<PromoLembar> {
  bool _memproses = false;
  bool _tersimpan = false;
  String? _galat;

  String _rp(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(?:\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $s';
  }

  String _tgl(DateTime d) {
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}';
  }

  Future<void> _klaim() async {
    setState(() {
      _memproses = true;
      _galat = null;
    });
    final galat = await widget.onKlaim();
    if (!mounted) return;
    setState(() {
      _memproses = false;
      _galat = galat;
      _tersimpan = galat == null;
    });
    if (galat == null) {
      // Beri jeda singkat supaya pengguna melihat konfirmasi, lalu tutup.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final aksen = widget.tema.aksen;
    final berlaku = promo.isValid;
    final sudah = widget.sudahDiklaim || _tersimpan;

    final syarat = <({IconData ikon, String judul, String isi})>[
      (
        ikon: Icons.shopping_bag_outlined,
        judul: 'Minimum belanja',
        isi: promo.minPembelian > 0
            ? 'Berlaku untuk transaksi mulai ${_rp(promo.minPembelian)}.'
            : 'Tidak ada minimum belanja.',
      ),
      (
        ikon: Icons.event_outlined,
        judul: 'Masa berlaku',
        isi: '${_tgl(promo.berlakuMulai)} sampai ${_tgl(promo.berlakuAkhir)}.',
      ),
      (
        ikon: Icons.people_outline,
        judul: 'Kuota',
        isi: promo.maxPakai >= 100
            ? 'Tanpa batas kuota.'
            : 'Tersisa ${(promo.maxPakai - promo.sudahDipakai).clamp(0, promo.maxPakai)} '
                'dari ${promo.maxPakai} pemakaian.',
      ),
      (
        ikon: Icons.confirmation_number_outlined,
        judul: 'Cara pakai',
        isi: 'Pilih voucher ini saat membayar, atau ketik kodenya di halaman '
            'pembayaran.',
      ),
      (
        ikon: Icons.info_outline_rounded,
        judul: 'Ketentuan lain',
        isi: 'Satu voucher per transaksi dan tidak dapat digabung dengan '
            'voucher lain. Potongan dihitung dari harga tiket sebelum pajak '
            'dan biaya layanan.',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pegangan lembaran.
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------------------------------------------------- kepala
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.rLg,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              aksen.withValues(alpha: 0.16),
                              AppColors.card,
                            ],
                          ),
                          border: Border.all(
                              color: aksen.withValues(alpha: 0.32)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: aksen.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: aksen.withValues(alpha: 0.42)),
                                  ),
                                  child: Text(
                                    widget.promo.label?.trim().isNotEmpty ?? false
                                        ? widget.promo.label!.trim()
                                        : widget.tema.label,
                                    style: GoogleFonts.rajdhani(
                                      color: aksen,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (!berlaku)
                                  Text(
                                    'Tidak berlaku',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.error,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              promo.tipe == 'percentage'
                                  ? 'Diskon ${promo.nilai.toStringAsFixed(0)}%'
                                  : 'Potongan ${_rp(promo.nilai)}',
                              style: GoogleFonts.rajdhani(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.14)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      Icons.confirmation_number_outlined,
                                      size: 13,
                                      color: aksen),
                                  const SizedBox(width: 6),
                                  Text(
                                    promo.kode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --------------------------------------------- ketentuan
                      Text(
                        'Syarat & ketentuan',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final s in syarat) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: aksen.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(s.ikon, size: 15, color: aksen),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.judul,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.isi,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (_galat != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.10),
                            borderRadius: AppRadius.rSm,
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _galat!,
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.error,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              // ---------------------------------------------------- tombol klaim
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (sudah || !berlaku || _memproses) ? null : _klaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: aksen,
                      foregroundColor: const Color(0xFF0A0A0E),
                      disabledBackgroundColor: AppColors.surfaceLight,
                      disabledForegroundColor: AppColors.textMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
                    ),
                    child: _memproses
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0A0A0E),
                            ),
                          )
                        : Text(
                            sudah
                                ? 'Sudah Tersimpan di Diskon Saya'
                                : !berlaku
                                    ? 'Voucher Tidak Berlaku'
                                    : 'Klaim Voucher',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
