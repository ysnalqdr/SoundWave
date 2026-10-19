// Penjaga sumber: tombol Bayar Sekarang pada pesanan yang sudah ada
// Metode pembayaran sudah dipilih saat pesanan dibuat, jadi user tidak
// boleh dipaksa memilihnya lagi. Yang dikunci di sini:
//   1. wizard mode lanjut mulai di langkah 2 (Bayar), bukan langkah 1;
//   2. stepper menandai langkah metode sebagai SELESAI + nama metodenya;
//   3. back & tombol kiri bawah membawa ke Tiket Saya, bukan ke metode;
//   4. tetap ada jalan keluar "Ganti metode pembayaran";
//   5. VA/QR yang sudah ada langsung tampil (backend memakai ulang),
//      dan berganti metode membuang instrumen lama.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const String berkas = 'lib/screens/user/checkout_screen.dart';
  const String berkasServer = '../soundwave-backend/server.js';

  late String kode;
  setUpAll(() => kode = File(berkas).readAsStringSync());

  test('mode lanjut mulai di langkah Bayar', () {
    final int metode = kode.indexOf('_metodeDariLabel(lanjut.metodePembayaran)');
    final int lompat = kode.indexOf('if (_selectedMethod != null) _currentStep = 1;');
    expect(metode, greaterThanOrEqualTo(0));
    expect(lompat, greaterThan(metode),
        reason: 'lompatan harus SETELAH metode dipulihkan dari pesanan');
    expect(lompat - metode, lessThan(400),
        reason: 'masih di dalam blok mode lanjut pada initState');
  });

  test('stepper menandai langkah metode selesai dengan nama metode', () {
    expect(
        kode.contains(
            "_lanjut && _selectedMethod != null ? _methodLabel : 'Metode'"),
        isTrue,
        reason: 'kalau balik ke "Metode", user merasa ada langkah yang terlewat');
  });

  test('back & tombol kiri bawah membawa ke Tiket Saya', () {
    expect(kode.contains('if (_lanjut && _currentStep <= 1) {'), isTrue);
    expect(kode.contains('_lanjut ? _keTiketSaya : () => _goToStep(0)'), isTrue,
        reason: 'tombol Kembali di langkah Bayar tidak boleh mundur ke metode');
    expect(kode.contains("_lanjut ? 'Ke Tiket Saya' : 'Kembali'"), isTrue);
  });

  test('tetap ada jalan keluar ganti metode', () {
    expect(kode.contains('_buildTautanGantiMetode()'), isTrue);
    expect(kode.contains("'Ganti metode pembayaran'"), isTrue,
        reason: 'tanpa ini user terjebak kalau GoPay-nya kosong');
    // Catatan peringatan hanya muncul saat user memang membuka langkah metode.
    final int idxStep1 = kode.indexOf('Widget _buildStep1Methods()');
    final int idxCatatan = kode.indexOf('Nomor VA / QR lama tidak dipakai lagi');
    expect(idxCatatan, greaterThan(idxStep1));
  });

  test('data pemesan diringkas jadi kartu, bukan 3 kolom readOnly', () {
    expect(kode.contains('_buildKartuPemesanTerkunci()'), isTrue);
    expect(kode.contains('readOnly: _lanjut'), isFalse,
        reason: 'kolom readOnly hanya ada di cabang non-lanjut, sudah dihapus');
    // Kartu & tautan hanya di cabang _lanjut, formulir di cabang else.
    final int idx = kode.indexOf('Widget _buildStep2Form(');
    final String step2 = kode.substring(idx, idx + 1200);
    expect(step2.contains('if (_lanjut) ...['), isTrue);
    expect(step2.contains('] else ...['), isTrue);
  });

  test('instrumen lama langsung ditampilkan sekali per layar', () {
    expect(kode.contains('_cobaTampilkanInstrumen(currentUserId)'), isTrue);
    final int idx = kode.indexOf('void _cobaTampilkanInstrumen(String uid)');
    expect(idx, greaterThanOrEqualTo(0));
    final String badan = kode.substring(idx, idx + 1600);

    expect(badan.contains('_autoInstrumenDicoba'), isTrue,
        reason: 'tanpa penjaga ini, setiap rebuild memanggil backend lagi');
    expect(badan.contains('!_lanjut || _currentStep != 1'), isTrue);
    expect(badan.contains('_generateVA(uid)'), isTrue);
    expect(badan.contains('_generateGoPay(uid, diam: true)'), isTrue);
    expect(badan.contains('_generateQRIS(uid)'), isTrue);
    expect(badan.contains('addPostFrameCallback'), isTrue,
        reason: 'tidak boleh setState saat build');
  });

  test('berganti metode membuang instrumen lama', () {
    final int idx = kode.indexOf('_selectedMethod = m.id;');
    final String sebelum = kode.substring(idx - 700, idx);
    expect(sebelum.contains('_vaNumber = null;'), isTrue);
    expect(sebelum.contains('_qrString = null;'), isTrue);
    expect(sebelum.contains('_gopayPhone = null;'), isTrue);
    expect(sebelum.contains('_autoInstrumenDicoba = false;'), isTrue);
  });

  test('backend memang memakai ulang instrumen (syarat auto-tampil)', () {
    final f = File(berkasServer);
    if (!f.existsSync()) return;
    final String server = f.readAsStringSync();
    expect(server.contains('orderData.vaNumber && isFutureTimestamp'),
        isTrue);
    expect(server.contains('orderData.gopayQrString && isFutureTimestamp'),
        isTrue);
    expect(server.contains('orderData.qrisQrString && isFutureTimestamp'),
        isTrue);
  });
}
