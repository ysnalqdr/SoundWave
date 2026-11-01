import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants/app_constants.dart';
import '../../models/konser_model.dart';
import '../../models/tiket_konser_model.dart';
import '../../models/pesanan_tiket_model.dart';
import '../../models/claimed_promo_model.dart';
import '../../models/promo_model.dart';
import '../../utils/rincian_harga.dart';
import '../../providers/app_providers.dart';
import '../../services/midtrans_service.dart';
import '../../widgets/gambar_widget.dart';
import '../../utils/app_theme.dart';
import '../../widgets/feedback/payment_loading_overlay.dart';
import '../../widgets/animasi/countdown_ring.dart';
import 'package:lottie/lottie.dart';

import 'checkout/checkout_palette.dart';
import 'checkout/checkout_models.dart';

part 'checkout_parts/checkout_logic.dart';
part 'checkout_parts/checkout_sheets.dart';
part 'checkout_parts/checkout_layout.dart';
part 'checkout_parts/checkout_forms.dart';
part 'checkout_parts/checkout_steps.dart';

// Palet khusus layar ini: latar putih, teks hitam, aksen hijau Soundwave.
// Terpisah dari AppColors yang bertema gelap.
class CheckoutScreen extends ConsumerStatefulWidget {
  final KonserModel konser;
  final TiketKonserModel tiketDipilih;

  /// Bila diisi -> mode "LANJUTKAN PEMBAYARAN": wizard memakai pesanan yang
  /// SUDAH ada (tidak membuat pesanan baru; stok hanya dikunci sekali).
  final PesananTiketModel? orderLanjutan;

  const CheckoutScreen({
    super.key,
    required this.konser,
    required this.tiketDipilih,
    this.orderLanjutan,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

/// Menampung SELURUH state layar checkout (field, getter, controller).
///
/// Method perilaku & tampilan dipisah ke mixin pada berkas `checkout_parts/`.
/// Kelas ini sengaja abstrak: hanya dipakai sebagai basis mixin.
abstract class _CheckoutBase extends ConsumerState<CheckoutScreen> {
  // ------------------------------------------------------------------
  // Deklarasi method yang diimplementasikan oleh mixin di `checkout_parts/`.
  // Diperlukan agar mixin dapat saling memanggil tanpa saling bergantung.
  // ------------------------------------------------------------------
  Widget _buildVoucherPicker();
  List<Widget> _buildVaForm(String currentUserId);
  List<Widget> _buildCardForm();
  List<Widget> _buildGoPayForm(String currentUserId);
  List<Widget> _buildQrForm(String currentUserId, String kind);
  PreferredSizeWidget _buildAppBar();
  Widget _buildKartuPemesanTerkunci();
  Widget _buildTautanGantiMetode();
  Widget _buildBannerLanjut();
  Widget _buildStepIndicator();
  Widget _detectedBanner();
  Widget _sectionTitle(String text);
  void _bindClaimedPromos(String? uid);
  String _formatRupiah(double nominal);
  void _goToStep(int step);
  void _nextFromStep1();
  void _nextFromStep2();
  Future<void> _generateVA(String currentUserId);
  Future<void> _generateGoPay(String currentUserId);
  Future<void> _generateQRIS(String currentUserId);
  void _onVaExpired();
  void _onQrExpired();
  String _formatVaCountdown(int s);
  String _formatQrCountdown(int s);
  Future<void> _bayarSekarang(String currentUserId);
  void _keTiketSaya();
  void _showSuccessScreen();
  void _toast(String msg, Color color);
  Future<void> _copyToClipboard(String text);
  void _cobaTampilkanInstrumen(String uid);
  void _showCardPayInfo(PesananTiketModel order);
  void _showWaitingInfo();
  InputDecoration _whiteInput(String label, {IconData? icon});
  Widget _buildStep1Methods();
  Widget _buildStep2Form(String currentUserId);
  Widget _buildStep3Confirm(String currentUserId);
  Widget _buildBottomBar(String currentUserId);
  Widget _buildSuccessView();

  final _formKey = GlobalKey<FormState>();

  late TiketKonserModel _tiket;
  int _jumlahTiket = 1;

  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController(text: '081234567890');

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _saveCard = false;

  bool _loading = false;
  bool _formInitialized = false;

  // Biaya layanan & pajak TIDAK lagi berupa konstanta lokal. Semuanya
  // dihitung oleh `RincianHarga` supaya layar, pesanan, dan backend memakai
  // rumus yang sama. Dulu `_biayaAdmin = 5000` hanya ada di klien, sehingga
  // backend menghitung ulang dengan angka berbeda.

  // Alur langkah
  int _currentStep = 0; // 0=metode, 1=form metode, 2=konfirmasi
  String? _selectedMethod; // 'va' | 'card' | 'gopay' | 'qris'

  // Status VA
  String _selectedBank = 'bca';
  String? _vaNumber;
  String? _vaBank;
  String? _billerCode;
  Timer? _vaTimer;
  int _vaRemaining = 24 * 60 * 60; // 24 jam dalam detik

  /// Batas waktu pembayaran dari server (`expires_at` Midtrans).
  /// Menjadi acuan cincin hitung-mundur; null berarti belum ada instrumen.
  DateTime? _vaExpiresAt;

  // Status GoPay dan QRIS
  String? _qrString;
  String? _gopayPhone; // nomor HP untuk GoPay
  Timer? _qrTimer;
  Timer? _pollTimer;
  int _qrRemaining = 5 * 60; // 5 menit dalam detik

  /// Batas waktu QR/GoPay dari server (`expires_at` Midtrans).
  DateTime? _qrExpiresAt;

  bool _methodLoading = false; // loading generate VA/QR
  bool _autoInstrumenDicoba =
      false; // mode lanjut: instrumen sudah dicoba ditampilkan

  // Pesanan
  PesananTiketModel? _savedOrder;
  bool _orderCreated = false;
  bool _paymentDetected = false; // poll / settle-dev mendeteksi lunas

  // Voucher yang sudah diklaim user
  List<ClaimedPromoModel> _claimedPromos = const [];
  ClaimedPromoModel? _selectedClaim;
  StreamSubscription<List<ClaimedPromoModel>>? _claimedSub;
  String? _claimedUid;

  // Voucher dari kode manual (belum tentu diklaim).
  final TextEditingController _kodeVoucherCtrl = TextEditingController();
  bool _memeriksaKode = false;
  String? _pesanVoucher;
  bool _voucherSah = false;

  // Animasi sukses kini ditangani aset Lottie di dalam layar sukses,
  // sehingga controller manual tidak lagi diperlukan.
  bool _showSuccess = false;


  @override
  void initState() {
    super.initState();
    _tiket = widget.tiketDipilih;

    // Mode lanjutkan pembayaran: pakai pesanan yang sudah ada.
    final lanjut = widget.orderLanjutan;
    if (lanjut != null) {
      _savedOrder = lanjut;
      _orderCreated = true; // cegah pembuatan pesanan baru
      _jumlahTiket = lanjut.jumlahTiket;
      if (lanjut.namaPembeli.isNotEmpty) _namaCtrl.text = lanjut.namaPembeli;
      if (lanjut.emailPembeli.isNotEmpty) _emailCtrl.text = lanjut.emailPembeli;
      if ((lanjut.teleponPembeli ?? '').isNotEmpty) {
        _teleponCtrl.text = lanjut.teleponPembeli!;
      }
      _selectedMethod = _metodeDariLabel(lanjut.metodePembayaran);
      // Metode sudah dipilih saat pesanan dibuat → langsung ke langkah Bayar.
      // Kalau label metode tidak dikenali, tetap mulai dari daftar metode.
      if (_selectedMethod != null) _currentStep = 1;
      _formInitialized = true; // jangan ditimpa data profil user
    }

  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _teleponCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _vaTimer?.cancel();
    _qrTimer?.cancel();
    _pollTimer?.cancel();
    _claimedSub?.cancel();
    _kodeVoucherCtrl.dispose();
    super.dispose();
  }

  /// Satu sumber kebenaran untuk semua angka uang di layar ini.
  ///
  /// `_diskon` dulu dihitung terpisah lalu dipakai di beberapa tempat;
  /// sekarang semuanya turun dari [RincianHarga] sehingga tidak mungkin
  /// layar menampilkan angka berbeda dari yang ditagih.
  /// Voucher hasil ketik manual. Disimpan terpisah dari [_selectedClaim]
  /// supaya memilih dari daftar akan menimpa yang manual, dan sebaliknya.
  ({String kode, double nilai, String tipe, double minPembelian})?
      _voucherManual;

  /// Periksa kode voucher yang diketik pengguna.
  ///
  /// Pemeriksaan dilakukan di **backend** (`/validate-promo`), bukan di
  /// klien: klien tidak boleh memutuskan sendiri apakah sebuah kode sah.
  /// Backend juga yang nanti memvalidasi ulang saat pembayaran dibuat, jadi
  /// kode yang lolos di sini tetap diperiksa lagi.
  Future<void> _pakaiKodeManual() async {
    final kode = _kodeVoucherCtrl.text.trim().toUpperCase();
    if (kode.isEmpty) {
      setState(() {
        _pesanVoucher = 'Ketik kode voucher dulu.';
        _voucherSah = false;
      });
      return;
    }

    setState(() {
      _memeriksaKode = true;
      _pesanVoucher = null;
    });

    final subtotal = _tiket.harga * _jumlahTiket;
    final hasil = await ref.read(midtransServiceProvider).validatePromo(
          kode: kode,
          idKonser: widget.konser.id,
          subtotal: subtotal,
        );

    if (!mounted) return;

    final sah = hasil['valid'] == true;

    if (!sah) {
      setState(() {
        _memeriksaKode = false;
        _voucherSah = false;
        _voucherManual = null;
        _pesanVoucher = (hasil['message'] ?? 'Kode voucher tidak berlaku.')
            .toString();
      });
      return;
    }

    // ---------------------------------------------------------------
    // Simpan voucher ke akun pengguna (auto-claim).
    //
    // Voucher yang diketik manual dulu hanya dipakai sekali di layar ini
    // lalu menguap: tidak masuk "Diskon Saya", dan — yang lebih serius —
    // tidak pernah ditandai terpakai, sehingga satu kode bisa dipakai
    // berulang tanpa batas.
    //
    // Klaim dilakukan SETELAH kode lolos validasi backend. Kalau pengguna
    // batal membayar, voucher tetap tersimpan dan bisa dipakai nanti —
    // itu memang yang diinginkan. Ini juga aman: klaim di sini hanya
    // menandai, bukan memberi hak. Gerbang sebenarnya tetap di backend
    // saat pesanan dibuat, yang memvalidasi ulang semuanya.
    // ---------------------------------------------------------------
    final promoMap = hasil['promo'];
    String? pesanKlaim;
    if (promoMap is Map) {
      // Ambil uid dari state autentikasi; layar ini tidak menerima uid
      // lewat konstruktor. Memakai `_claimedUid` yang sudah diikat lebih
      // murah, tapi bisa kosong bila stream belum sempat terpasang.
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) {
        pesanKlaim = 'Masuk ke akun dulu supaya voucher tersimpan.';
      } else {
        try {
          final promo = PromoCodeModel.fromMap(
            Map<String, dynamic>.from(promoMap),
            (promoMap['id'] ?? kode).toString(),
          );
          await ref.read(databaseServiceProvider).claimPromo(uid, promo);
          pesanKlaim = 'tersimpan';
        } catch (e) {
          final teks = e.toString().replaceFirst('Exception: ', '');
          // Sudah pernah diklaim bukan kegagalan — voucher tetap bisa dipakai.
          pesanKlaim = teks.contains('sudah ada')
              ? 'sudah-tersimpan'
              : 'Voucher sah, tapi gagal disimpan: $teks';
        }
      }
    } else {
      pesanKlaim = 'Voucher sah, tapi gagal disimpan.';
    }

    if (!mounted) return;
    setState(() {
      _memeriksaKode = false;
      _voucherSah = true;
      _selectedClaim = null; // kode manual menggantikan pilihan daftar
      _voucherManual = (
        kode: kode,
        nilai: (hasil['nilai'] as num?)?.toDouble() ?? 0,
        tipe: (hasil['tipe'] ?? 'fixed').toString(),
        minPembelian:
            (promoMap is Map ? (promoMap['minPembelian'] as num?) : null)
                    ?.toDouble() ??
                0,
      );
      final potong = (hasil['discountAmount'] as num?)?.toDouble() ?? 0;
      final hemat = _formatRupiah(potong);
      _pesanVoucher = switch (pesanKlaim) {
        'tersimpan' =>
          'Voucher $kode dipakai — hemat $hemat. Tersimpan di Diskon Saya.',
        'sudah-tersimpan' =>
          'Voucher $kode dipakai — hemat $hemat. Sudah ada di Diskon Saya.',
        _ => 'Voucher $kode dipakai — hemat $hemat. $pesanKlaim',
      };
    });
  }

  /// Voucher yang sedang dipakai — dari daftar klaim ATAU dari kode manual.
  ({String kode, double nilai, String tipe, double minPembelian})?
      get _voucherAktif {
    final c = _selectedClaim;
    if (c != null) {
      return (
        kode: c.kode,
        nilai: c.nilai,
        tipe: c.tipe,
        minPembelian: c.minPembelian,
      );
    }
    final m = _voucherManual;
    if (m != null) {
      return (
        kode: m.kode,
        nilai: m.nilai,
        tipe: m.tipe,
        minPembelian: m.minPembelian,
      );
    }
    return null;
  }

  /// Potongan voucher aktif untuk subtotal tertentu.
  ///
  /// Rumusnya sama dengan `PromoCodeModel.discountAmount`, tapi ditulis di
  /// sini karena voucher manual tidak selalu berasal dari model klaim.
  double _potonganVoucher(double subtotal) {
    final v = _voucherAktif;
    if (v == null) return 0;
    if (subtotal < v.minPembelian) return 0;
    if (v.tipe == 'percentage') {
      final raw = subtotal * (v.nilai / 100);
      return raw > subtotal ? subtotal : raw;
    }
    return v.nilai > subtotal ? subtotal : v.nilai;
  }

  RincianHarga get _rincian => RincianHarga(
        hargaSatuan: _tiket.harga,
        jumlah: _jumlahTiket,
        diskon: _potonganVoucher(_tiket.harga * _jumlahTiket),
        kodePromo: _voucherAktif?.kode,
      );

  double get _subtotal => _rincian.subtotal.toDouble();

  /// Potongan voucher terpilih. Nol bila tidak ada voucher atau minimum
  /// belanja belum terpenuhi.
  double get _diskon => _rincian.potongan.toDouble();

  double get _totalBayar => _rincian.total.toDouble();


  int get _maxTiket => _tiket.stok < 5 ? _tiket.stok : 5;

  /// Mode lanjutkan pembayaran untuk pesanan yang sudah ada.
  bool get _lanjut => widget.orderLanjutan != null;

  /// Total yang ditagih dan ditampilkan. Di mode lanjut nilainya total
  /// pesanan asli yang sudah terpotong voucher; backend menagih angka sama.
  double get _totalTagih =>
      _lanjut ? widget.orderLanjutan!.totalHarga : _totalBayar;

  /// Petakan label metode di pesanan ke kode metode wizard.


  String get _methodLabel {
    switch (_selectedMethod) {
      case 'va':
        return 'Transfer Bank';
      case 'card':
        return 'Kartu Kredit/Debit';
      case 'gopay':
        return 'GoPay';
      case 'qris':
        return 'QRIS';
      default:
        return 'Bayar';
    }
  }


  // Langkah 2: buat instrumen VA, GoPay, atau QRIS.


  // Polling status tiap 3 detik setelah QR atau VA tampil.

  // Langkah 3: bayar sekarang lewat checkoutAtomic.


  /// Keluar dari alur pembayaran dan mendarat di tab Tiket Saya.
  ///
  /// Reservasi tidak dibatalkan: pesanan tetap PENDING dan stok tetap
  /// tertahan, jadi user bisa melanjutkan dari daftar tiket.


  /// Dropdown voucher yang sudah diklaim user.

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final user = currentUserAsync.value;
    final authUser = ref.watch(authStateProvider).value;
    final currentUserId = user?.id ?? authUser?.uid ?? 'guest';
    _cobaTampilkanInstrumen(currentUserId);
    _bindClaimedPromos(authUser?.uid ?? user?.id);

    if (!_formInitialized && user != null) {
      _namaCtrl.text = user.nama;
      _emailCtrl.text = user.email;
      _formInitialized = true;
    }

    if (_showSuccess) {
      return _buildSuccessView();
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: SwCheckout.bg,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              if (_lanjut) _buildBannerLanjut(),
              _buildStepIndicator(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildStep1Methods(),
                      _buildStep2Form(currentUserId),
                      _buildStep3Confirm(currentUserId),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(currentUserId),
            ],
          ),
        ),
        // Overlay menutup seluruh layar selama pembayaran diproses. Selama
        // ini pengguna tidak bisa menekan tombol kembali, ganti metode, atau
        // kirim ulang — tiga hal yang bisa membuat tagihan ganda.
        PaymentLoadingOverlay(visible: _loading),
      ],
    );
  }

  // AppBar

  // Tampilan mode lanjut: bagian yang tidak perlu diulang user.

  /// Kartu pemesan ringkas. Data pemesan terkunci ke pesanan, jadi tiga
  /// kolom formulir readOnly tidak ada gunanya.

  /// Jalan keluar kalau metode terpilih ternyata tidak bisa dipakai, misalnya
  /// saldo GoPay kurang. Sengaja tautan kecil, bukan tombol, supaya user tidak
  /// dirayu berganti-ganti metode.

  /// Mode lanjut: tampilkan VA atau QR yang sudah ada tanpa menekan Generate.
  /// Backend memakai ulang instrumen yang belum kedaluwarsa, jadi tidak ada
  /// tagihan ganda. Dicoba sekali per layar; tombol manual tetap tersedia.

  // Banner mode lanjutkan pembayaran.

  // Indikator langkah.

  // Langkah 1: pilih metode pembayaran.


  // Langkah 2: formulir sesuai metode.

  // Formulir transfer bank.

  // Formulir kartu kredit atau debit.

  // Formulir GoPay: nomor HP, tanpa QR.


  // Langkah 3: konfirmasi dan bayar.


  // Bilah bawah.


  // Tampilan sukses.

}

class _CheckoutScreenState extends _CheckoutBase
    with
        _CheckoutLogic,
        _CheckoutSheets,
        _CheckoutLayout,
        _CheckoutForms,
        _CheckoutSteps {}
