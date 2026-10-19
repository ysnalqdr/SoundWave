// Penjaga sumber: tombol Bayar Sekarang untuk tiket PENDING
// Mengunci tiga hal yang pernah salah di halaman tiket:
//   1. tiket berstatus PENDING tidak punya tombol apa pun untuk
//      menyelesaikan pembayaran (tombol lama hanya muncul kalau pesanan
//      punya snapRedirectUrl — pesanan via VA/QRIS/GoPay tidak punya);
//   2. tombol itu harus masuk ke wizard 3 langkah untuk pesanan yang SAMA
//      (mode "lanjutkan"), bukan membuat pesanan baru;
//   3. jumlah tagihan tidak boleh dihitung ulang dari harga tiket, karena
//      pesanan yang sudah terpotong voucher akan ditagih harga penuh
//      (harga tiket VVIP Rp 3.000.000 vs total pesanan Rp 5.000).
// Test ini membaca sumber dan gagal kalau salah satunya balik lagi.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const String berkasLayar = 'lib/screens/user/user_tiket_screen.dart';
  const String berkasCheckout = 'lib/screens/user/checkout_screen.dart';
  const String berkasMidtrans = 'lib/services/midtrans_service.dart';
  // Backend berada di folder SEBELAH proyek Flutter (bukan di dalamnya).
  const String berkasServer = '../soundwave-backend/server.js';

  late String layar;
  late String kotak;
  late String checkout;
  late String midtrans;
  late String server;

  setUpAll(() {
    layar = File(berkasLayar).readAsStringSync();
    kotak = File('lib/widgets/kotak_pending_tiket.dart').readAsStringSync();
    checkout = File(berkasCheckout).readAsStringSync();
    midtrans = File(berkasMidtrans).readAsStringSync();
    server = File(berkasServer).existsSync()
        ? File(berkasServer).readAsStringSync()
        : '';
  });

  test('tiket PENDING punya tombol "Bayar Sekarang" tanpa syarat '
      'snapRedirectUrl', () {
    expect(kotak.contains("'Bayar Sekarang'"), isTrue,
        reason: 'CTA utama di kotak Menunggu Pembayaran');
    expect(layar.contains('] else if (tiket.isPending) ...['), isTrue,
        reason: 'cabang pending tidak boleh lagi menuntut "&& !tiket.isExpired" '
            '(jendela reservasi 15 menit hampir selalu sudah lewat)');
    expect(layar.contains('tiket.isPending && !tiket.isExpired'), isFalse,
        reason: 'kalau syarat ini balik, tombol bayar hilang lagi untuk '
            'pesanan yang jendela reservasinya sudah lewat');
    expect(layar.contains('_lanjutkanPembayaran(context, ref, tiket)'), isTrue,
        reason: 'tombol harus memanggil pembuka wizard pembayaran');
  });

  test('tombol membuka wizard 3 langkah untuk pesanan yang SUDAH ada', () {
    final int idx = layar.indexOf('Future<void> _lanjutkanPembayaran(');
    expect(idx, greaterThanOrEqualTo(0));
    final String badan = layar.substring(idx, idx + 4000);

    expect(badan.contains('db.getEventById(tiket.idKonser)'), isTrue,
        reason: 'wizard butuh KonserModel');
    expect(badan.contains('db.getTicketById(idTiket)'), isTrue,
        reason: 'wizard butuh TiketKonserModel');
    expect(badan.contains('orderLanjutan: tiket'), isTrue,
        reason: 'wizard harus menerima pesanan yang sudah ada supaya '
            'tidak membuat pesanan baru');
    expect(badan.contains('CheckoutScreen('), isTrue);
  });

  test('checkout mode lanjut: tidak membuat pesanan baru, stok dikunci sekali',
      () {
    expect(checkout.contains('final PesananTiketModel? orderLanjutan;'), isTrue);
    expect(checkout.contains('_savedOrder = lanjut;'), isTrue);
    expect(checkout.contains('_orderCreated = true; // cegah pembuatan pesanan baru'),
        isTrue,
        reason: 'kalau flag ini tidak diset, _ensureOrderCreated akan membuat '
            'pesanan kedua dan stok terkunci dua kali');
    expect(checkout.contains('if (_orderCreated && _savedOrder != null) return _savedOrder;'),
        isTrue,
        reason: 'pintu keluar _ensureOrderCreated — inti anti-pesanan-ganda');
  });

  test('checkout mode lanjut: jumlah tiket & voucher terkunci ke pesanan', () {
    final int idx = checkout.indexOf('Widget _buildStep2Form(');
    expect(idx, greaterThanOrEqualTo(0));
    final String step2 = checkout.substring(idx, idx + 6000);

    final int cabangLanjut = step2.indexOf('if (_lanjut) ...[');
    final int cabangNormal = step2.indexOf('] else ...[', cabangLanjut);
    final int voucher = step2.indexOf('_buildVoucherPicker()');

    expect(cabangLanjut, greaterThanOrEqualTo(0));
    expect(cabangNormal, greaterThan(cabangLanjut));
    expect(voucher, greaterThan(cabangNormal),
        reason: 'voucher hanya boleh muncul di cabang checkout normal — '
            'di mode lanjut total pesanan sudah final (bisa sudah ada potongan)');
  });

  test('checkout: total yang ditampilkan di mode lanjut = total pesanan', () {
    expect(
        checkout.contains(
            '_lanjut ? widget.orderLanjutan!.totalHarga : _totalBayar;'),
        isTrue,
        reason: 'halaman konfirmasi/sheet pembayaran harus menampilkan angka '
            'yang sama dengan halaman tiket');
    expect(checkout.contains('_formatRupiah(_totalBayar)'), isFalse,
        reason: 'semua tampilan total harus lewat _totalTagih');
    expect(checkout.contains('totalHarga: _totalBayar,'), isTrue,
        reason: 'pembuatan pesanan BARU tetap memakai _totalBayar');
  });

  test('checkout mode lanjut: data pemesan terkunci (kartu ringkas)', () {
    final int idx = checkout.indexOf('Widget _buildStep2Form(');
    final String step2 = checkout.substring(idx, idx + 4000);
    // Data pemesan tidak lagi ditampilkan sebagai 3 kolom readOnly, tapi
    // sebagai satu kartu "PEMESAN" yang jelas-jelas terkunci ke pesanan.
    expect(step2.contains('_buildKartuPemesanTerkunci()'), isTrue,
        reason: 'nama/email/HP mengikuti pesanan dan tidak boleh bisa diubah');
    expect(step2.contains('readOnly: _lanjut'), isFalse,
        reason: 'kolom readOnly sudah diganti kartu ringkas');
    expect(checkout.contains('terkunci ke \${o.kodeBooking}'), isTrue,
        reason: 'user harus tahu data ini milik pesanan yang mana');
  });

  test('backend /checkout-atomic menagih total pesanan, bukan harga tiket × qty',
      () {
    final int awal = server.indexOf("app.post('/checkout-atomic'");
    final int akhir = server.indexOf("app.post('/create-va'");
    expect(awal, greaterThanOrEqualTo(0));
    expect(akhir, greaterThan(awal));
    final String atomic = server.substring(awal, akhir);

    expect(atomic.contains('const grossAmount = Math.round(Number(orderData.totalHarga))'),
        isTrue,
        reason: 'sumber angka harus sama dengan /create-va & loadOrderForCharge');
    expect(atomic.contains('gross_amount: (Number(ticketData.harga) * jumlahTiket) + 5000'),
        isFalse,
        reason: 'menghitung ulang dari harga tiket = menagih harga penuh pada '
            'pesanan yang sudah terpotong voucher');
    expect(atomic.contains('gross_amount: grossAmount'), isTrue);
    expect(atomic.contains('item_details: itemDetails'), isTrue,
        reason: 'item_details wajib berjumlah tepat = gross_amount (validasi Snap)');
    expect(atomic.contains('hargaSatuan * qty === sisaTiket'), isTrue);
    expect(atomic.contains('metodePembayaran: metodeBayar'), isTrue,
        reason: 'metode yang benar-benar dipakai user harus tersimpan di pesanan');
  }, skip: !File(berkasServer).existsSync()
      ? 'soundwave-backend/server.js tidak ada di sebelah proyek'
      : false);

  test('app mengirim metode pembayaran ke /checkout-atomic', () {
    expect(midtrans.contains('String? metodePembayaran,'), isTrue);
    expect(midtrans.contains("'metodePembayaran': metodePembayaran,"), isTrue);
    expect(checkout.contains('metodePembayaran: _metodeForOrder(),'), isTrue);
  });

  test('hanya SATU tombol aksi di kotak pending — tanpa tombol Snap', () {
    expect(kotak.contains('Buka Halaman Pembayaran Midtrans'), isFalse,
        reason: 'dua tombol untuk satu urusan (bayar) membingungkan user');
    expect(kotak.contains('url_launcher'), isFalse,
        reason: 'kalau import ini balik, berarti tombol Snap dihidupkan lagi');
    expect(kotak.contains('OutlinedButton'), isFalse,
        reason: 'tombol Snap satu-satunya OutlinedButton di kotak ini');
    expect(kotak.contains('launchUrl'), isFalse,
        reason: 'kotak pending tidak boleh lagi melempar user ke browser');
    expect("'Bayar Sekarang'".allMatches(kotak).length, 1,
        reason: 'satu CTA utama saja');
  });
}
