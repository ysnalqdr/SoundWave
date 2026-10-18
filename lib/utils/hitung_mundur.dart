import '../constants/app_constants.dart';

/// Sisa waktu pembayaran sebuah pesanan.
///
/// `reservedUntil` berasal dari SERVER (bukan jam HP), jadi hitungannya tidak
/// bisa diperpanjang dengan memundurkan jam perangkat. Nilai yang sudah lewat
/// dikembalikan sebagai nol — bukan negatif — supaya semua pemakaian aman.
Duration sisaReservasi(DateTime? reservedUntil, {DateTime? sekarang}) {
  if (reservedUntil == null) return Duration.zero;
  final sisa = reservedUntil.difference(sekarang ?? DateTime.now());
  return sisa.isNegative ? Duration.zero : sisa;
}

/// Satu-satunya format hitungan waktu pembayaran di aplikasi: "02:47".
String formatHitungMundur(Duration sisa) {
  final d = sisa.isNegative ? Duration.zero : sisa;
  final menit = d.inMinutes.toString().padLeft(2, '0');
  final detik = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$menit:$detik';
}

/// Masih ada waktu untuk membayar pesanan ini?
bool masihAdaWaktuBayar(DateTime? reservedUntil, {DateTime? sekarang}) =>
    sisaReservasi(reservedUntil, sekarang: sekarang) > Duration.zero;

/// Kalimat penjelas jendela pembayaran — dipakai di kotak pending supaya
/// aturannya sama di semua tempat dan tidak ada angka yang ditulis manual.
String kalimatJendelaBayar() =>
    'Selesaikan pembayaran dalam ${AppConstants.reservationHoldMinutes} menit. '
    'Kalau waktunya habis, stok tiket otomatis dilepas dan pesanan menjadi kedaluwarsa.';
