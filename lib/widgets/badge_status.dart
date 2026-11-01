import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';

/// ============================================================================
/// BADGE STATUS SOUNDWAVE
/// ============================================================================
///
/// Satu widget untuk seluruh badge di aplikasi. Sebelumnya setiap layar
/// menyusun badge sendiri dengan warna berbeda-beda: hijau, amber, merah, teal,
/// deepOrange, abu. Hasilnya hijau dipakai untuk 7 makna sekaligus, jadi tidak
/// lagi berarti apa-apa.
///
/// ## Aturan warna
///
/// Hanya **tiga** warna yang dipakai, masing-masing satu makna:
///   * [BadgeNada.harga]   → hijau, HANYA untuk uang.
///   * [BadgeNada.peringatan] → sunset, ada yang harus segera dilakukan.
///   * [BadgeNada.berhenti]   → merah, aksi merusak / gate menolak.
///
/// Sisanya monokrom.
///
/// ## Kenapa monokrom dibedakan BENTUK, bukan tingkat abu
///
/// Selisih persepsi (L\*) antar tingkat abu di UI gelap hanya **1,95**,
/// sedangkan mata butuh minimal **4** untuk melihat dua bidang berbeda. Jadi
/// "abu gelap" vs "abu lebih gelap" tidak akan terbaca. Yang terbaca adalah
/// perbedaan **bentuk**: isi penuh, garis tepi, atau teks dicoret.
///
/// ## Tingkat
///
/// | Nada | Bentuk | Arti |
/// |---|---|---|
/// | [BadgeNada.final_] | isi putih penuh, teks gelap | keadaan final yang baik |
/// | [BadgeNada.jalan] | garis tepi terang | sedang berjalan |
/// | [BadgeNada.lewat] | garis tepi redup | sudah lewat |
/// | [BadgeNada.gagal] | tanpa isi, teks **dicoret** | batal / gagal |
/// | [BadgeNada.label] | tanpa tepi | info, bukan status |
/// | [BadgeNada.peringatan] | sunset | butuh tindakan |
/// | [BadgeNada.berhenti] | merah | berhenti |
/// | [BadgeNada.valid] | hijau | gate: boleh masuk |
///
/// Kontras semua nada diukur di atas `card` (#18181F):
/// final 17,99 · jalan 14,05 · lewat 5,76 · gagal 4,81 · peringatan 6,19 ·
/// berhenti 5,83 · valid 8,80. Semua lulus WCAG AA.
enum BadgeNada {
  /// Isi putih penuh + teks gelap. Untuk keadaan final yang menguntungkan:
  /// tiket aktif, refund disetujui, super admin.
  final_,

  /// Garis tepi terang. Sedang berjalan: menunggu bayar, refund diproses.
  jalan,

  /// Garis tepi redup. Sudah lewat: terpakai, sudah di-refund.
  lewat,

  /// Tanpa isi, teks dicoret. Batal atau gagal.
  gagal,

  /// Tanpa tepi sama sekali. Ini info, bukan keadaan — misalnya kategori kursi.
  /// Kalau diberi tepi, ia bersaing dengan badge status di sebelahnya.
  label,

  /// Sunset. Ada tindakan yang harus diambil: hitung mundur, stok menipis.
  peringatan,

  /// Merah. Berhenti: stok habis, gate menolak.
  berhenti,

  /// Hijau. Status berhasil/tersedia: tiket AKTIF, promo AKTIF, refund
  /// disetujui, stok tersedia, kode gate sah.
  valid,

  /// Abu tanpa coret. Status yang sudah **selesai** dan tidak perlu
  /// diperhatikan lagi: TERPAKAI, REFUND, KEDALUWARSA.
  ///
  /// Ketiganya sengaja memakai SATU warna, bukan tiga tingkat abu. Selisih
  /// antar tingkat abu di tema ini hanya 1,95 L*, sedangkan mata butuh ≥4
  /// untuk membedakannya — jadi tiga abu akan terlihat sama saja. Yang
  /// membedakan cukup ikonnya: silang (kedaluwarsa), centang (terpakai),
  /// panah-ulang (refund).
  selesai,
}

/// Ikon kecil di dalam badge. Dipakai supaya badge tetap terbaca oleh
/// pengguna buta warna: bentuk ikon berbeda, bukan hanya warna.
enum BadgeIkon {
  tidakAda,
  centang,
  jam,
  silang,
  panahUlang,
  peringatan,
  kursi,
  kunci,
}

class BadgeStatus extends StatelessWidget {
  const BadgeStatus(
    this.teks, {
    super.key,
    this.nada = BadgeNada.label,
    this.ikon = BadgeIkon.tidakAda,
    this.ukuran = 9.5,
  });

  /// Teks badge. Ditulis kapital di sumbernya, bukan di sini — supaya teks
  /// yang memang bukan singkatan (mis. "14:52 TERSISA") tetap terkontrol.
  final String teks;
  final BadgeNada nada;
  final BadgeIkon ikon;
  final double ukuran;

  ({Color bg, Color fg, Color? border, bool coret}) get _gaya {
    switch (nada) {
      case BadgeNada.final_:
        return (
          bg: AppColors.badgeFinalBg,
          fg: AppColors.badgeFinalFg,
          border: AppColors.badgeFinalBg,
          coret: false,
        );
      case BadgeNada.jalan:
        return (
          bg: AppColors.badgeJalanBg,
          fg: AppColors.badgeJalanFg,
          border: AppColors.badgeJalanBorder,
          coret: false,
        );
      case BadgeNada.lewat:
        return (
          bg: AppColors.badgeLewatBg,
          fg: AppColors.badgeLewatFg,
          border: AppColors.badgeLewatBorder,
          coret: false,
        );
      case BadgeNada.gagal:
        return (
          bg: Colors.transparent,
          fg: AppColors.badgeGagalFg,
          border: AppColors.badgeGagalBorder,
          coret: true,
        );
      case BadgeNada.label:
        return (
          bg: AppColors.aksi.withValues(alpha: 0.035),
          fg: AppColors.textMuted,
          border: null,
          coret: false,
        );
      case BadgeNada.peringatan:
        return (
          bg: AppColors.warning.withValues(alpha: 0.12),
          fg: AppColors.warning,
          border: AppColors.warning.withValues(alpha: 0.30),
          coret: false,
        );
      case BadgeNada.berhenti:
        return (
          bg: AppColors.error.withValues(alpha: 0.10),
          fg: AppColors.error,
          border: AppColors.error.withValues(alpha: 0.28),
          coret: false,
        );
      case BadgeNada.valid:
        return (
          bg: AppColors.primary.withValues(alpha: 0.10),
          fg: AppColors.primary,
          border: AppColors.primary.withValues(alpha: 0.30),
          coret: false,
        );
      case BadgeNada.selesai:
        return (
          bg: AppColors.surfaceLight,
          fg: AppColors.textSecondary,
          border: AppColors.line,
          coret: false,
        );
    }
  }

  Widget? _gambarIkon(Color warna) {
    final s = ukuran + 0.5;
    switch (ikon) {
      case BadgeIkon.tidakAda:
        return null;
      case BadgeIkon.centang:
        return Icon(Icons.check_rounded, size: s, color: warna);
      case BadgeIkon.jam:
        return Icon(Icons.schedule_rounded, size: s, color: warna);
      case BadgeIkon.silang:
        return Icon(Icons.close_rounded, size: s, color: warna);
      case BadgeIkon.panahUlang:
        return Icon(Icons.refresh_rounded, size: s, color: warna);
      case BadgeIkon.peringatan:
        return Icon(Icons.priority_high_rounded, size: s, color: warna);
      case BadgeIkon.kursi:
        return Icon(Icons.event_seat_outlined, size: s, color: warna);
      case BadgeIkon.kunci:
        return Icon(Icons.lock_outline_rounded, size: s, color: warna);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _gaya;
    final ik = _gambarIkon(g.fg);

    return Container(
      padding: EdgeInsets.fromLTRB(
        ik == null ? 7 : 5.5,
        3.5,
        7,
        3.5,
      ),
      decoration: BoxDecoration(
        color: g.bg,
        borderRadius: BorderRadius.circular(6),
        border: g.border == null ? null : Border.all(color: g.border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ik != null) ...[
            ik,
            const SizedBox(width: 3.5),
          ],
          Text(
            teks,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
              color: g.fg,
              fontSize: ukuran,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.05,
              decoration: g.coret ? TextDecoration.lineThrough : null,
              decorationColor: g.fg,
              decorationThickness: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pemetaan status pesanan ke nada + ikon.
///
/// Dipisah dari widget supaya bisa diuji tanpa merender apa pun, dan supaya
/// penambahan status baru cukup di satu tempat.
({BadgeNada nada, BadgeIkon ikon, String teks}) nadaUntukStatusPesanan(
  String status,
) {
  switch (status) {
    case 'AKTIF':
    case 'PAID':
      return (nada: BadgeNada.valid, ikon: BadgeIkon.centang, teks: 'AKTIF');
    case 'PENDING':
    case 'RESERVED':
      return (
        nada: BadgeNada.peringatan,
        ikon: BadgeIkon.jam,
        teks: 'PENDING'
      );
    case 'TERPAKAI':
      return (nada: BadgeNada.selesai, ikon: BadgeIkon.centang, teks: 'TERPAKAI');
    case 'CANCELLED':
      return (nada: BadgeNada.gagal, ikon: BadgeIkon.silang, teks: 'DIBATALKAN');
    case 'EXPIRED':
      // Abu tanpa coret: kedaluwarsa bukan "gagal", hanya sudah lewat.
      // Dicoret membuatnya terlihat seperti kesalahan pengguna.
      return (
        nada: BadgeNada.selesai,
        ikon: BadgeIkon.silang,
        teks: 'KEDALUWARSA'
      );
    case 'REFUND_REQUIRED':
    case 'REFUND_REQUESTED':
      return (
        nada: BadgeNada.jalan,
        ikon: BadgeIkon.panahUlang,
        teks: 'REFUND DIPROSES'
      );
    case 'REFUND_REJECTED':
      return (
        nada: BadgeNada.gagal,
        ikon: BadgeIkon.silang,
        teks: 'REFUND GAGAL'
      );
    case 'REFUNDED':
      return (
        nada: BadgeNada.selesai,
        ikon: BadgeIkon.panahUlang,
        teks: 'REFUND'
      );
    default:
      return (nada: BadgeNada.label, ikon: BadgeIkon.tidakAda, teks: status);
  }
}

/// Nada untuk badge **peran**. Hierarki izin dibedakan lewat tingkat isi:
/// makin penuh, makin tinggi izinnya — jadi terbaca tanpa membaca teksnya.
BadgeNada nadaUntukPeran(String peran) {
  final p = peran.toUpperCase();
  if (p.contains('SUPER')) return BadgeNada.final_;
  if (p.contains('ADMIN')) return BadgeNada.jalan;
  return BadgeNada.lewat;
}
