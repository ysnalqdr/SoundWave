import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/utils/app_theme.dart';

/// Penjaga aset Lottie gate dan penyambungannya ke layar.
///
/// Aset ini gampang rusak tanpa ketahuan: file bisa diganti versi lain yang
/// durasinya berubah, ekspresi After Effects bisa masuk lagi (tidak didukung
/// lottie-dart, jadi animasinya jadi datar), atau pengawasnya lupa disambungkan
/// sehingga animasi tidak pernah muncul sama sekali. Ketiganya tidak akan
/// terlihat sampai diuji di HP, jadi dikunci di sini.
void main() {
  const path = 'assets/lottie/scan_success.json';

  late Map<String, dynamic> animasi;
  late String teksMentah;

  setUpAll(() {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: 'aset Lottie gate harus ada di $path');
    teksMentah = file.readAsStringSync();
    animasi = jsonDecode(teksMentah) as Map<String, dynamic>;
  });

  group('scan_success.json — struktur', () {
    test('JSON valid dan punya field wajib Lottie', () {
      for (final k in ['v', 'fr', 'ip', 'op', 'w', 'h', 'layers']) {
        expect(animasi.containsKey(k), isTrue, reason: 'kunci "$k" tidak ada');
      }
      expect(animasi['layers'] as List, isNotEmpty);
    });

    test('kanvas persegi', () {
      expect(animasi['w'], animasi['h']);
    });

    test('durasi tetap 2,3 detik — tidak boleh diubah', () {
      final fr = (animasi['fr'] as num).toDouble();
      final durasi = ((animasi['op'] as num) - (animasi['ip'] as num)) / fr;
      // Nilai ini disepakati bersama pemilik produk: durasi aset dipertahankan
      // apa adanya. Kalau angka ini gagal, berarti file tertimpa versi lain.
      expect(durasi, closeTo(2.3, 0.01),
          reason: 'durasi aktual: ${durasi.toStringAsFixed(2)} detik');
    });

    test('30 fps', () {
      expect(animasi['fr'], 30);
    });
  });

  group('scan_success.json — bebas ekspresi After Effects', () {
    // lottie-dart hanya menulis peringatan "Lottie doesn't support expressions."
    // lalu mengabaikannya. Ekspresi yang tertinggal membuat file berat tanpa
    // memberi efek apa pun, dan menipu: orang mengira bounce-nya jalan.
    test('tidak ada satu pun ekspresi tersisa', () {
      expect(teksMentah.contains(r'$bm_rt'), isFalse,
          reason: 'ekspresi After Effects tidak didukung lottie-dart');
      expect(teksMentah.contains('effect('), isFalse);
    });

    test('tidak ada layer effect (Glo2 dan sejenisnya)', () {
      bool adaEfek(dynamic n) {
        if (n is Map) {
          if (n.containsKey('ef')) return true;
          return n.values.any(adaEfek);
        }
        if (n is List) return n.any(adaEfek);
        return false;
      }

      expect(adaEfek(animasi), isFalse,
          reason: 'efek glow tidak didukung dan hanya menambah berat');
    });
  });

  group('scan_success.json — warna', () {
    /// Mengumpulkan semua warna `fill` di seluruh layer.
    Set<int> fillColors(dynamic node) {
      final out = <int>{};
      void walk(dynamic n) {
        if (n is Map) {
          if (n['ty'] == 'fl' && n['c'] is Map) {
            final k = (n['c'] as Map)['k'];
            if (k is List && k.length >= 3) {
              out.add(Color.fromARGB(
                255,
                ((k[0] as num) * 255).round(),
                ((k[1] as num) * 255).round(),
                ((k[2] as num) * 255).round(),
              ).toARGB32());
            }
          }
          for (final v in n.values) {
            walk(v);
          }
        } else if (n is List) {
          for (final v in n) {
            walk(v);
          }
        }
      }

      walk(node);
      return out;
    }

    test('warna kembali ke default asli', () {
      // DIUBAH lagi Okt 2026 atas permintaan pemilik produk: aset
      // dikembalikan ke warna aslinya. Warna tetap ADA (bukan monokrom)
      // karena gate scanner adalah pengecualian — hijau/merah di sana
      // adalah kode keselamatan petugas.
      final warna = fillColors(animasi);
      expect(warna, isNotEmpty, reason: 'aset harus punya warna');

      // Hijau asli (#00CD1D) harus kembali, dan warna tema tidak dipakai.
      const hijauAsli = Color(0xFF00CD1D);
      expect(warna.contains(hijauAsli.toARGB32()), isTrue,
          reason: 'hijau asli harus kembali');
      expect(warna.contains(AppColors.primary.toARGB32()), isFalse,
          reason: 'warna tema tidak lagi dipakai di aset ini');
    });

    test('tidak di-tint oleh komponen pemakainya', () {
      final komponen =
          File('lib/widgets/gate/scan_success_overlay.dart').readAsStringSync();
      expect(komponen.contains('ColorFilter'), isFalse,
          reason: 'aset berwarna; tint akan meratakan seluruh gambar');
      expect(komponen.contains('BlendMode'), isFalse);
    });
  });

  group('scan_success.json — ukuran', () {
    test('di bawah 600 KB', () {
      final kb = File(path).lengthSync() / 1024;
      expect(kb, lessThan(600), reason: 'aktual: ${kb.toStringAsFixed(0)} KB');
    });
  });

  group('pendaftaran aset', () {
    test('terdaftar di LottieAssets', () {
      final daftar =
          File('lib/core/media/lottie_assets.dart').readAsStringSync();
      expect(daftar.contains('assets/lottie/scan_success.json'), isTrue);
      expect(daftar.contains('scanSuccess'), isTrue);
    });

    test('folder assets/lottie terdaftar di pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('assets/lottie/'), isTrue);
    });
  });

  group('penyambungan ke layar', () {
    test('pengawas gate dipasang di menu utama user', () {
      final main =
          File('lib/screens/user/user_main_screen.dart').readAsStringSync();
      expect(main.contains('GateResultWatcher'), isTrue,
          reason: 'tanpa ini animasi tidak pernah muncul');
    });

    test('pengawas hanya memicu untuk perubahan baru, bukan tiket lama', () {
      final watcher =
          File('lib/widgets/gate/gate_result_watcher.dart').readAsStringSync();
      expect(watcher.contains('_sudahDilihat'), isTrue,
          reason: 'tanpa penyemaian awal, membuka app memicu animasi tiket lama');
      expect(watcher.contains('isTerpakai'), isTrue);
    });

    test('animasi dimainkan sekali, tidak berulang', () {
      final overlay =
          File('lib/widgets/gate/scan_success_overlay.dart').readAsStringSync();
      expect(overlay.contains('repeat: false'), isTrue,
          reason: 'perayaan yang mengulang terus terasa seperti iklan');
    });

    test('layar animasi tidak bisa ditutup sebelum selesai', () {
      final overlay =
          File('lib/widgets/gate/scan_success_overlay.dart').readAsStringSync();
      expect(overlay.contains('AbsorbPointer'), isTrue,
          reason: 'kalau bisa di-swipe, hasilnya terlewat lalu user tanya petugas');
    });

    test('tombol back Android ditahan selama animasi', () {
      final overlay =
          File('lib/widgets/gate/scan_success_overlay.dart').readAsStringSync();
      expect(overlay.contains('PopScope'), isTrue);
      expect(overlay.contains('canPop: false'), isTrue,
          reason: 'back menutup overlay lebih awal dan pengawas tidak pernah '
              'menerima sinyal selesai');
    });

    test('pengawas punya batas waktu agar tidak macet selamanya', () {
      final watcher =
          File('lib/widgets/gate/gate_result_watcher.dart').readAsStringSync();
      expect(watcher.contains('TimeoutException'), isTrue,
          reason: 'tanpa batas waktu, satu overlay yang gagal melapor '
              'mematikan animasi untuk semua tiket berikutnya');
    });

    test('durasi diambil dari aset, bukan ditebak', () {
      final overlay =
          File('lib/widgets/gate/scan_success_overlay.dart').readAsStringSync();
      expect(overlay.contains('komposisi.duration'), isTrue);
      expect(overlay.contains('onLoaded'), isTrue);
    });

    test('ada cadangan bila aset gagal dimuat', () {
      final overlay =
          File('lib/widgets/gate/scan_success_overlay.dart').readAsStringSync();
      expect(overlay.contains('errorBuilder'), isTrue,
          reason: 'layar tidak boleh kosong total saat animasi rusak');
    });

    test('setelah animasi, user diantar ke tab Tiket', () {
      final main =
          File('lib/screens/user/user_main_screen.dart').readAsStringSync();
      expect(main.contains('onSelesai'), isTrue);
      expect(main.contains('_pindahKeTab(1)'), isTrue);
    });
  });
}
