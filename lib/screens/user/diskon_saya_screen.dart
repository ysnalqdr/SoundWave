import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/claimed_promo_model.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';

/// Halaman "Diskon Saya" di bagian Akun.
///
/// Menampilkan voucher yang sudah diklaim dari halaman Jelajah, sumbernya
/// `users/{uid}/claimed_promos`. Voucher berstatus tersedia bisa dipakai
/// sebagai potongan harga saat checkout.
class DiskonSayaScreen extends ConsumerStatefulWidget {
  const DiskonSayaScreen({super.key});

  @override
  ConsumerState<DiskonSayaScreen> createState() => _DiskonSayaScreenState();
}

class _DiskonSayaScreenState extends ConsumerState<DiskonSayaScreen> {
  Stream<List<ClaimedPromoModel>>? _stream;
  String? _boundUid;

  void _bind(String? uid) {
    if (uid == _boundUid) return;
    _boundUid = uid;
    _stream = uid == null
        ? null
        : ref.read(databaseServiceProvider).streamClaimedPromos(uid);
  }

  String _formatTanggal(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

  String _formatRupiah(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $s';
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    _bind(uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Diskon Saya',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: uid == null
          ? _emptyState(
              'Masuk ke akun untuk melihat vouchermu.',
              Icons.lock_outline_rounded,
            )
          : StreamBuilder<List<ClaimedPromoModel>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.warnaHarga),
                    ),
                  );
                }
                if (snap.hasError) {
                  return _emptyState(
                    'Gagal memuat voucher. Coba lagi nanti.',
                    Icons.cloud_off_rounded,
                  );
                }
                final list = snap.data ?? const <ClaimedPromoModel>[];
                if (list.isEmpty) {
                  return _emptyState(
                    'Belum ada voucher.\nKlaim promo di halaman Jelajah.',
                    Icons.local_offer_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == 0) return _header(list.length);
                    return _voucherCard(list[i - 1]);
                  },
                );
              },
            ),
    );
  }

  Widget _header(int jumlah) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VOUCHER SAYA',
          style: GoogleFonts.rajdhani(
            color: AppColors.warnaHarga,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$jumlah voucher · pilih salah satu saat pembayaran',
          style: GoogleFonts.spaceGrotesk(
              color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _voucherCard(ClaimedPromoModel c) {
    final status = c.statusLabel;
    final Color statusColor;
    final Color statusBg;
    switch (status) {
      case 'TERPAKAI':
        statusColor = AppColors.textMuted;
        statusBg = AppColors.surfaceLight;
        break;
      case 'KEDALUWARSA':
        statusColor = AppColors.error;
        statusBg = AppColors.error.withValues(alpha: 0.12);
        break;
      default:
        statusColor = Colors.black;
        statusBg = AppColors.warnaHarga;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'TERSEDIA'
              ? AppColors.warnaHarga.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status == 'TERSEDIA'
                      ? AppColors.warnaHarga
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.labelNilai,
                  style: GoogleFonts.spaceGrotesk(
                    color: status == 'TERSEDIA'
                        ? Colors.black
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.kode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.spaceGrotesk(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          if (c.deskripsi?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(
              c.deskripsi!.trim(),
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.minPembelian > 0
                      ? 'Min. belanja ${_formatRupiah(c.minPembelian)}'
                      : 'Tanpa minimum belanja',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ),
              if (c.berlakuAkhir != null)
                Text(
                  's/d ${_formatTanggal(c.berlakuAkhir!)}',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Diklaim ${_formatTanggal(c.claimedAt)}',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
