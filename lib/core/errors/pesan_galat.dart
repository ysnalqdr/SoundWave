import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Menerjemahkan exception menjadi kalimat yang bisa dibaca pengguna.
///
/// Kenapa ini ada: sebelumnya 30 tempat menampilkan `'$e'` langsung ke layar,
/// sehingga pengguna melihat nama paket, kode galat, dan jejak internal seperti
/// `[cloud_firestore/permission-denied]`. Itu informasi untuk programmer, bukan
/// untuk pembeli tiket.
///
/// Aturan yang dipegang di sini:
/// - **Jangan pernah** mengembalikan teks yang mengandung nama paket, kode
///   galat, atau tipe exception.
/// - **Selalu** beri tahu apa yang bisa dilakukan pengguna ("coba lagi",
///   "periksa koneksi"), bukan apa yang salah di mesin.
/// - Pesan yang sengaja ditulis manusia di lapisan bawah (`throw 'Stok tiket
///   tidak mencukupi...'`) dibiarkan lewat apa adanya — itu sudah kalimat yang
///   benar dan spesifik.
///
/// Kenapa tidak memakai `dart:io`: aplikasi ini juga di-build untuk web, dan
/// `SocketException` tidak ada di sana. Deteksi jaringan dilakukan lewat teks
/// exception, yang aman di semua platform.
class PesanGalat {
  PesanGalat._();

  /// Kalimat pengganti bila tidak ada yang lebih spesifik.
  static const String _generik = 'Terjadi kendala. Coba lagi sebentar.';

  /// Ubah [e] jadi kalimat untuk pengguna.
  ///
  /// [awalan] menyebut apa yang sedang dicoba, mis. `'Gagal menyimpan konser'`.
  /// Bila null, dipakai kalimat generik.
  static String untuk(Object e, {String? awalan}) {
    final String? pesan = _petakan(e);
    if (pesan != null) return pesan;
    if (awalan == null || awalan.trim().isEmpty) return _generik;
    return '${awalan.trim()}. Coba lagi sebentar.';
  }

  /// Null berarti "tidak ada padanan khusus, pakai awalan".
  static String? _petakan(Object e) {
    // Galat koneksi lebih dulu: ini yang paling sering terjadi di lapangan
    // (sinyal venue buruk) dan paling penting disebutkan dengan benar.
    if (_galatJaringan(e)) {
      return 'Koneksi internet bermasalah. Periksa sinyal lalu coba lagi.';
    }

    if (e is TimeoutException) {
      return 'Server terlalu lama menjawab. Coba lagi sebentar.';
    }

    if (e is FormatException) {
      return 'Jawaban server tidak dikenali. Coba lagi sebentar.';
    }

    if (e is FirebaseAuthException) return _auth(e);
    if (e is FirebaseException) return _firestore(e);

    // Cadangan berbasis teks: exception sering dibungkus lapisan lain
    // (`Exception('... [cloud_firestore/permission-denied] ...')`) sehingga
    // tipe aslinya hilang. Membaca kodenya dari teks membuat terjemahan tetap
    // bekerja pada jalur yang terbungkus — ini kasus yang paling sering
    // terjadi di lapangan.
    final String mentah = e.toString().toLowerCase();
    if (mentah.contains('permission-denied') ||
        mentah.contains('missing or insufficient permissions')) {
      return 'Kamu tidak punya akses untuk ini.';
    }
    if (mentah.contains('unavailable') || mentah.contains('deadline-exceeded')) {
      return 'Server sedang tidak bisa dihubungi. Coba lagi sebentar.';
    }
    if (mentah.contains('timeout') || mentah.contains('timed out')) {
      return 'Server terlalu lama menjawab. Coba lagi sebentar.';
    }
    if (mentah.contains('unauthenticated') ||
        mentah.contains('id token has expired')) {
      return 'Sesi kamu sudah berakhir. Masuk ulang untuk melanjutkan.';
    }
    if (mentah.contains('resource-exhausted') ||
        mentah.contains('too many requests')) {
      return 'Permintaan terlalu sering. Tunggu sebentar lalu coba lagi.';
    }
    if (mentah.contains('failed-precondition') ||
        mentah.contains('requires an index')) {
      return 'Data belum siap. Coba lagi sebentar.';
    }

    if (e is String) {
      // Lapisan bawah banyak melempar kalimat Indonesia yang sudah jadi, mis.
      // 'Stok tiket tidak mencukupi (Sisa stok: 3).' Itu justru pesan terbaik
      // yang bisa diberikan, jadi diteruskan. Yang dibuang hanya teks yang
      // jelas-jelas jejak mesin.
      final String t = e.trim();
      if (t.isEmpty) return null;
      if (t.length > 180) return null;
      final String rendah = t.toLowerCase();
      const List<String> jejakMesin = <String>[
        'exception',
        'error:',
        '[cloud_',
        '[firebase',
        'platformexception',
        'null check operator',
        'type \'',
        'nosuchmethod',
        'bad state',
      ];
      for (final String jejak in jejakMesin) {
        if (rendah.contains(jejak)) return null;
      }
      return t;
    }

    return null;
  }

  /// Deteksi kegagalan jaringan tanpa bergantung pada `dart:io`.
  static bool _galatJaringan(Object e) {
    final String t = e.toString().toLowerCase();
    return t.contains('socketexception') ||
        t.contains('clientexception') ||
        t.contains('failed host lookup') ||
        t.contains('network is unreachable') ||
        t.contains('connection refused') ||
        t.contains('connection closed') ||
        t.contains('connection reset') ||
        t.contains('handshake') ||
        t.contains('xmlhttprequest error');
  }

  static String? _firestore(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Kamu tidak punya akses untuk ini.';
      case 'unavailable':
        return 'Server sedang tidak bisa dihubungi. Coba lagi sebentar.';
      case 'deadline-exceeded':
        return 'Server terlalu lama menjawab. Coba lagi sebentar.';
      case 'not-found':
        return 'Data yang dicari sudah tidak ada.';
      case 'already-exists':
        return 'Data ini sudah ada sebelumnya.';
      case 'resource-exhausted':
        return 'Permintaan terlalu sering. Tunggu sebentar lalu coba lagi.';
      case 'unauthenticated':
        return 'Sesi kamu sudah berakhir. Masuk ulang untuk melanjutkan.';
      case 'failed-precondition':
        return 'Data belum siap. Coba lagi sebentar.';
      case 'aborted':
        return 'Data berubah saat diproses. Coba lagi sebentar.';
      case 'cancelled':
        return 'Proses dibatalkan.';
      default:
        // Kode galat tidak pernah ditampilkan ke pengguna. Kembalikan null
        // supaya pemanggil memakai awalannya sendiri ("Gagal menyimpan
        // konser. Coba lagi sebentar.").
        return null;
    }
  }

  static String _auth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email tidak dikenali.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Coba masuk saja.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Pakai minimal 6 karakter.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa sinyal lalu coba lagi.';
      case 'requires-recent-login':
        return 'Demi keamanan, masuk ulang dulu untuk melanjutkan.';
      default:
        return _generik;
    }
  }
}
