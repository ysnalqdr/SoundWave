// ═══════════════════════════════════════════════════════════════════
// KOTAK STATUS PENDING — hitungan waktu 5 menit yang berubah sendiri
// ═══════════════════════════════════════════════════════════════════
// Satu kotak, dua keadaan, tanpa jeda:
//   masih ada waktu → "Menunggu Pembayaran" + hitungan waktu + tombol bayar
//
// Hanya SATU tombol aksi ("Bayar Sekarang"). Tombol lama "Buka Halaman
// Pembayaran Midtrans" sudah dihapus: isinya membuka snapRedirectUrl di browser
// dengan tujuan yang sama, jadi user dihadapkan dua tombol untuk satu urusan.
//   waktu habis     → "RESERVASI BERAKHIR" + tombol "Pesan Ulang"
//
// Perpindahannya terjadi TEPAT saat hitungan menyentuh 00:00 (bukan menunggu
// layar lain di-refresh), karena keadaan itu disimpan di widget ini sendiri.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import '../models/pesanan_tiket_model.dart';
import '../utils/app_theme.dart';
import '../utils/hitung_mundur.dart';
import 'hitung_mundur_teks.dart';

class KotakPendingTiket extends StatefulWidget {
  const KotakPendingTiket({
    super.key,
    required this.tiket,
    required this.onBayar,
    required this.onPesanUlang,
    this.onKedaluwarsa,
    this.jam,
  });

  final PesananTiketModel tiket;

  /// Lanjut ke wizard pembayaran (hanya tersedia selama waktu masih ada).
  final VoidCallback onBayar;

  /// Antar kembali ke halaman konser untuk memesan tiket lagi.
  final VoidCallback onPesanUlang;

  /// Dipanggil sekali saat hitungan menyentuh nol — dipakai untuk meminta
  /// server menyapu reservasi ini supaya statusnya ikut jadi EXPIRED.
  final VoidCallback? onKedaluwarsa;

  /// Sumber waktu (bisa diganti di test).
  final DateTime Function()? jam;

  @override
  State<KotakPendingTiket> createState() => _KotakPendingTiketState();
}

class _KotakPendingTiketState extends State<KotakPendingTiket> {
  late bool _habis;

  DateTime _sekarang() => widget.jam?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _habis = !masihAdaWaktuBayar(
      widget.tiket.reservedUntil,
      sekarang: _sekarang(),
    );
  }

  void _tandaiHabis() {
    if (_habis || !mounted) return;
    setState(() => _habis = true);
    widget.onKedaluwarsa?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _habis ? _kotakBerakhir() : _kotakMenunggu();
  }

  // ── Masih ada waktu ──
  Widget _kotakMenunggu() {
    final tiket = widget.tiket;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.amber, size: 40),
          const SizedBox(height: 8),
          Text(
            'Menunggu Pembayaran',
            style: GoogleFonts.rajdhani(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          // Satu-satunya sumber angka waktu di layar ini.
          HitungMundurTeks(
            sampai: tiket.reservedUntil,
            awalan: 'Sisa waktu ',
            teksHabis: '00:00',
            jam: widget.jam,
            onHabis: _tandaiHabis,
            gaya: GoogleFonts.rajdhani(
              color: Colors.amber,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kalimatJendelaBayar(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onBayar,
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: Text(
                'Bayar Sekarang',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warnaHarga,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Waktu habis ──
  Widget _kotakBerakhir() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_off_outlined,
              color: AppColors.error, size: 40),
          const SizedBox(height: 8),
          Text(
            'RESERVASI BERAKHIR',
            style: GoogleFonts.rajdhani(
              color: AppColors.error,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Waktu pembayaran ${AppConstants.reservationHoldMinutes} menit '
            'sudah habis. Stok tiket sudah dilepas otomatis, jadi pesanan ini '
            'tidak bisa dibayar lagi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onPesanUlang,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Pesan Ulang',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warnaHarga,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
