import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/hitung_mundur.dart';

/// Teks hitungan waktu yang berdetak tiap detik ("02:47").
///
/// Widget sendiri supaya yang di-rebuild tiap detik hanya teks ini, bukan
/// seluruh layar atau seluruh daftar tiket.
class HitungMundurTeks extends StatefulWidget {
  /// Batas waktu dari server (`reservedUntil`).
  final DateTime? sampai;

  /// Gaya teks; kalau null memakai gaya bawaan tema.
  final TextStyle? gaya;

  /// Teks di depan angka, mis. "Sisa waktu ".
  final String awalan;

  /// Teks saat waktunya sudah habis.
  final String teksHabis;

  /// Sumber waktu. Bisa diganti di test supaya hasilnya deterministik.
  final DateTime Function()? jam;

  /// Dipanggil sekali tepat saat hitungan menyentuh nol, supaya induknya
  /// langsung berpindah ke keadaan waktu habis.
  final VoidCallback? onHabis;

  const HitungMundurTeks({
    super.key,
    required this.sampai,
    this.gaya,
    this.awalan = '',
    this.teksHabis = '00:00',
    this.jam,
    this.onHabis,
  });

  @override
  State<HitungMundurTeks> createState() => _HitungMundurTeksState();
}

class _HitungMundurTeksState extends State<HitungMundurTeks> {
  Timer? _detak;
  Duration _sisa = Duration.zero;
  bool _sudahLaporHabis = false;

  DateTime _sekarang() => widget.jam?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _sisa = sisaReservasi(widget.sampai, sekarang: _sekarang());
    _mulaiDetak();
  }

  @override
  void didUpdateWidget(covariant HitungMundurTeks lama) {
    super.didUpdateWidget(lama);
    if (lama.sampai != widget.sampai) {
      _sisa = sisaReservasi(widget.sampai, sekarang: _sekarang());
      _mulaiDetak();
    }
  }

  void _mulaiDetak() {
    _detak?.cancel();
    _detak = null;
    if (_sisa == Duration.zero) return;

    _detak = Timer.periodic(const Duration(seconds: 1), (_) {
      final sisa = sisaReservasi(widget.sampai, sekarang: _sekarang());
      if (!mounted) return;
      setState(() => _sisa = sisa);
      if (sisa == Duration.zero) {
        _detak?.cancel();
        _detak = null;
        // Beri tahu induk TEPAT saat menyentuh nol (sekali saja).
        if (!_sudahLaporHabis) {
          _sudahLaporHabis = true;
          widget.onHabis?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _detak?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habis = _sisa == Duration.zero;
    return Text(
      habis ? widget.teksHabis : '${widget.awalan}${formatHitungMundur(_sisa)}',
      style: widget.gaya,
    );
  }
}
