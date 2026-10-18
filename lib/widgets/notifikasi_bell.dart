import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notifikasi_model.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
/// Ikon lonceng di layar Jelajah + badge jumlah notifikasi belum dibaca.
///
/// Notifikasi ditulis OTOMATIS oleh backend (`server.js` → `kirimNotifikasi`)
/// saat pembayaran berhasil/batal dan refund diajukan/disetujui/ditolak —
/// admin maupun user tidak perlu mengetik apa pun.
/// ─────────────────────────────────────────────────────────────
class NotifikasiBell extends ConsumerWidget {
  final String? userId;

  const NotifikasiBell({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = userId;
    final daftar = uid == null
        ? const <NotifikasiModel>[]
        : (ref.watch(notifikasiProvider(uid)).valueOrNull ??
            const <NotifikasiModel>[]);
    final belumDibaca = daftar.where((n) => n.belumDibaca).length;

    return GestureDetector(
      onTap: uid == null ? null : () => tampilkanNotifikasi(context, uid),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          if (belumDibaca > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
                child: Text(
                  belumDibaca > 99 ? '99+' : '$belumDibaca',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Buka bottom sheet daftar notifikasi.
Future<void> tampilkanNotifikasi(BuildContext context, String userId) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => NotifikasiSheet(userId: userId),
  );
}

/// Isi bottom sheet: daftar notifikasi + aksi "tandai semua dibaca".
class NotifikasiSheet extends ConsumerWidget {
  final String userId;

  const NotifikasiSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar =
        ref.watch(notifikasiProvider(userId)).valueOrNull ?? const <NotifikasiModel>[];
    final belumDibaca = daftar.where((n) => n.belumDibaca).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'NOTIFIKASI',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                if (belumDibaca > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '$belumDibaca baru',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                if (belumDibaca > 0)
                  TextButton(
                    onPressed: () => ref
                        .read(databaseServiceProvider)
                        .tandaiSemuaNotifikasiDibaca(userId),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Tandai semua',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (daftar.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 8),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.notifications_off_outlined,
                          size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada notifikasi',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Info pembayaran & refund akan muncul di sini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  itemCount: daftar.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      KartuNotifikasi(notif: daftar[i], userId: userId),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Satu kartu notifikasi. Bisa di-tap untuk menandai sudah dibaca —
/// TIDAK memindahkan halaman: panel notifikasi tetap terbuka.
class KartuNotifikasi extends ConsumerWidget {
  final NotifikasiModel notif;
  final String userId;

  const KartuNotifikasi({super.key, required this.notif, required this.userId});

  /// Warna + ikon sesuai jenis notifikasi.
  (Color, IconData) get gaya {
    switch (notif.type) {
      case 'payment_success':
        return (AppColors.success, Icons.check_circle_outline);
      case 'payment_cancelled':
        return (AppColors.error, Icons.cancel_outlined);
      case 'refund_approved':
        return (AppColors.success, Icons.currency_exchange_outlined);
      case 'refund_rejected':
        return (AppColors.error, Icons.block_outlined);
      case 'refund_requested':
        return (AppColors.warning, Icons.hourglass_top_outlined);
      case 'refund_required':
        return (AppColors.warning, Icons.report_gmailerrorred_outlined);
      default:
        return (AppColors.accent, Icons.notifications_none);
    }
  }

  /// Menandai notifikasi ini sudah dibaca.
  ///
  /// SENGAJA tidak memindahkan halaman: kartu notifikasi hanya informasi, dan
  /// panel tetap terbuka supaya user bisa lanjut membaca yang lain. Sebelumnya
  /// setiap tap menutup panel lalu melempar ke halaman Tiket Saya — padahal
  /// notifikasi refund tidak ada hubungannya dengan daftar tiket.
  Future<void> _tandaiDibaca(WidgetRef ref) async {
    if (!notif.belumDibaca) return;
    await ref.read(databaseServiceProvider).tandaiNotifikasiDibaca(notif.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (Color warna, IconData ikon) = gaya;
    final belumDibaca = notif.belumDibaca;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _tandaiDibaca(ref),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: belumDibaca ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: belumDibaca ? warna.withValues(alpha: 0.45) : AppColors.divider,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ikon, color: warna, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notif.waktuRelatif,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: warna.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notif.jenisLabel,
                          style: GoogleFonts.spaceGrotesk(
                            color: warna,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (belumDibaca) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Baru',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.error,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
