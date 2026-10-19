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
import '../../providers/app_providers.dart';
import '../../services/midtrans_service.dart';
import '../../widgets/gambar_widget.dart';

// Palet khusus layar ini: latar putih, teks hitam, aksen hijau Soundwave.
// Terpisah dari AppColors yang bertema gelap.
class _SwWhite {
  static const Color bg = Color(0xFF0A0A0F);
  static const Color ink = Color(0xFFFFFFFF);
  static const Color sub = Color(0xFF9E9E9E);
  static const Color muted = Color(0xFF6B6B6B);
  static const Color green = Color(0xFF00E676);
  static const Color greenDark = Color(0xFF00B24F);
  static const Color btnBg = Color(0xFF00E676); // CTA background
  static const Color btnFg = Color(0xFF06130B); // teks gelap di atas CTA
  static const Color surface = Color(0xFF1C1C26); // permukaan naik
  static const Color navy = Color(0xFF1A2332);
  static const Color line = Color(0xFF333333);
  static const Color chip = Color(0xFF16161F);
  static const Color redBright = Color(
      0xFFF50000); // teks tombol Simulasi -> merah terang (#F50000, dari 0xFFFF50000)
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
}

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

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with SingleTickerProviderStateMixin {
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

  final double _biayaAdmin = 5000;

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

  // Status GoPay dan QRIS
  String? _qrString;
  String? _gopayPhone; // nomor HP untuk GoPay
  Timer? _qrTimer;
  Timer? _pollTimer;
  int _qrRemaining = 5 * 60; // 5 menit dalam detik

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

  // Animasi sukses
  bool _showSuccess = false;
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  static const List<_PaymentMethod> _methods = [
    _PaymentMethod(
        'va', 'Transfer Bank', Icons.account_balance, 'BCA, BNI, Mandiri'),
    _PaymentMethod(
        'card', 'Kartu Kredit/Debit', Icons.credit_card, 'Visa, Mastercard'),
    _PaymentMethod('gopay', 'GoPay', Icons.wallet, 'Bayar dengan GoPay'),
    _PaymentMethod('qris', 'QRIS', Icons.qr_code, 'Scan untuk bayar'),
  ];

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

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
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
    _checkController.dispose();
    super.dispose();
  }

  double get _subtotal => _tiket.harga * _jumlahTiket;

  /// Potongan voucher terpilih. Nol bila tidak ada voucher atau minimum
  /// belanja belum terpenuhi.
  double get _diskon => _selectedClaim?.discountAmount(_subtotal) ?? 0;

  double get _totalBayar {
    final t = _subtotal + _biayaAdmin - _diskon;
    return t < 0 ? 0 : t;
  }

  void _bindClaimedPromos(String? uid) {
    if (uid == null || uid.isEmpty || uid == _claimedUid) return;
    _claimedUid = uid;
    _claimedSub?.cancel();
    _claimedSub = ref
        .read(databaseServiceProvider)
        .streamClaimedPromos(uid)
        .listen((list) {
      if (!mounted) return;
      setState(() {
        _claimedPromos = list.where((c) => c.isUsable).toList();
        // Buang pilihan yang sudah tidak valid lagi.
        if (_selectedClaim != null &&
            !_claimedPromos.any((c) => c.promoId == _selectedClaim!.promoId)) {
          _selectedClaim = null;
        }
      });
    }, onError: (_) {});
  }

  Future<void> _markVoucherUsed() async {
    final uid = _claimedUid;
    final claim = _selectedClaim;
    if (uid == null || claim == null) return;
    try {
      await ref
          .read(databaseServiceProvider)
          .markClaimedPromoUsed(uid, claim.promoId, orderId: _savedOrder?.id);
    } catch (_) {
      // Tidak fatal: pembayaran sudah sukses.
    }
    _selectedClaim = null;
  }

  int get _maxTiket => _tiket.stok < 5 ? _tiket.stok : 5;

  /// Mode lanjutkan pembayaran untuk pesanan yang sudah ada.
  bool get _lanjut => widget.orderLanjutan != null;

  /// Total yang ditagih dan ditampilkan. Di mode lanjut nilainya total
  /// pesanan asli yang sudah terpotong voucher; backend menagih angka sama.
  double get _totalTagih =>
      _lanjut ? widget.orderLanjutan!.totalHarga : _totalBayar;

  /// Petakan label metode di pesanan ke kode metode wizard.
  static String? _metodeDariLabel(String? label) {
    final l = (label ?? '').toLowerCase();
    if (l.contains('gopay')) return 'gopay';
    if (l.contains('qris')) return 'qris';
    if (l.contains('kartu')) return 'card';
    if (l.contains('virtual account') ||
        l.contains('transfer') ||
        l.contains('bank')) {
      return 'va';
    }
    return null;
  }

  String _formatRupiah(double nominal) {
    final formatted = nominal.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $formatted';
  }

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

  String _metodeForOrder() {
    switch (_selectedMethod) {
      case 'va':
        return 'Transfer Bank (${(_vaBank ?? _selectedBank).toUpperCase()})';
      case 'card':
        return 'Kartu Kredit/Debit';
      case 'gopay':
        return 'GoPay';
      case 'qris':
        return 'QRIS';
      default:
        return 'QRIS';
    }
  }

  void _goToStep(int step) => setState(() => _currentStep = step);

  void _nextFromStep1() {
    if (_selectedMethod == null) {
      _toast('Pilih metode pembayaran terlebih dahulu', _SwWhite.error);
      return;
    }
    _goToStep(1);
  }

  void _nextFromStep2() {
    if (!_formKey.currentState!.validate()) return;
    // VA, GoPay, dan QRIS harus dibuat dulu sebelum user bisa membayar.
    if (_selectedMethod == 'va' && (_vaNumber == null || _vaNumber!.isEmpty)) {
      _toast('Generate Virtual Account terlebih dahulu', _SwWhite.warning);
      return;
    }
    if (_selectedMethod == 'qris' &&
        (_qrString == null || _qrString!.isEmpty)) {
      _toast('Tampilkan QR code terlebih dahulu', _SwWhite.warning);
      return;
    }
    if (_selectedMethod == 'gopay' && _gopayPhone == null) {
      _toast('Konfirmasi nomor GoPay terlebih dahulu', _SwWhite.warning);
      return;
    }
    _goToStep(2);
  }

  Future<PesananTiketModel?> _ensureOrderCreated(String currentUserId) async {
    if (_orderCreated && _savedOrder != null) return _savedOrder;
    if (!_formKey.currentState!.validate()) return null;

    final db = ref.read(databaseServiceProvider);
    final pesananBaru = PesananTiketModel(
      id: '',
      kodeBooking: '',
      idKonser: widget.konser.id,
      judulKonser: widget.konser.judul,
      gambarKonser: widget.konser.gambarUrl,
      kategoriTiket: _tiket.kategori,
      idTiket: _tiket.id,
      jumlahTiket: _jumlahTiket,
      totalHarga: _totalBayar,
      tanggalBeli: DateTime.now(),
      tanggalKonser: widget.konser.tanggal,
      lokasiKonser: widget.konser.lokasi,
      namaPembeli: _namaCtrl.text.trim(),
      emailPembeli: _emailCtrl.text.trim(),
      teleponPembeli: _teleponCtrl.text.trim(),
      metodePembayaran: _metodeForOrder(),
      userId: currentUserId,
      status: AppConstants.orderStatusPending,
    );

    try {
      final saved = await db.createPendingOrder(pesananBaru);
      setState(() {
        _savedOrder = saved;
        _orderCreated = true;
      });
      return saved;
    } catch (e) {
      _toast(MidtransService.pesanRamah(e, 'Gagal membuat pesanan'),
          _SwWhite.error);
      return null;
    }
  }

  // Langkah 2: buat instrumen VA, GoPay, atau QRIS.
  Future<void> _generateVA(String currentUserId) async {
    final order = await _ensureOrderCreated(currentUserId);
    if (order == null) return;

    setState(() => _methodLoading = true);
    try {
      final midtrans = ref.read(midtransServiceProvider);
      // Retry: 3 percobaan (backend idempoten → aman diulang, cegah error 406)
      Map<String, dynamic> res = {};
      for (int attempt = 0; attempt < 3; attempt++) {
        res = await midtrans.createVA(
          orderId: order.id,
          bank: _selectedBank,
        );
        if (res['success'] == true && res['va_number'] != null) break;
        if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
      }
      if (!mounted) return;
      if (res['success'] == true && res['va_number'] != null) {
        setState(() {
          _vaNumber = res['va_number'] as String?;
          _vaBank = res['bank'] as String?;
          _billerCode = res['biller_code'] as String?;
          _vaRemaining = 24 * 60 * 60;
        });
        _startVaTimer();
        _startPolling(order.id);
      } else {
        _toast(
            res['message'] ?? 'Gagal membuat Virtual Account', _SwWhite.error);
      }
    } catch (e) {
      _toast(MidtransService.pesanRamah(e, 'Gagal membuat Virtual Account'),
          _SwWhite.error);
    } finally {
      if (mounted) setState(() => _methodLoading = false);
    }
  }

  Future<void> _generateGoPay(String currentUserId, {bool diam = false}) async {
    final order = await _ensureOrderCreated(currentUserId);
    if (order == null) return;

    setState(() => _methodLoading = true);
    try {
      final midtrans = ref.read(midtransServiceProvider);
      Map<String, dynamic> res = {};
      for (int attempt = 0; attempt < 3; attempt++) {
        res = await midtrans.createGoPay(orderId: order.id);
        if (res['success'] == true) break;
        if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
      }
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _gopayPhone = _teleponCtrl.text.trim();
          _qrRemaining = 5 * 60;
        });
        _startQrTimer();
        _startPolling(order.id);
        if (!diam) {
          _toast(
              'Pembayaran GoPay dibuat. Cek aplikasi GoPay di nomor $_gopayPhone',
              _SwWhite.green);
        }
      } else {
        _toast(res['message'] ?? 'Gagal membuat pembayaran GoPay. Coba lagi.',
            _SwWhite.error);
      }
    } catch (e) {
      _toast(MidtransService.pesanRamah(e, 'Gagal membuat pembayaran GoPay'),
          _SwWhite.error);
    } finally {
      if (mounted) setState(() => _methodLoading = false);
    }
  }

  Future<void> _generateQRIS(String currentUserId) async {
    final order = await _ensureOrderCreated(currentUserId);
    if (order == null) return;

    setState(() => _methodLoading = true);
    try {
      final midtrans = ref.read(midtransServiceProvider);
      Map<String, dynamic> res = {};
      for (int attempt = 0; attempt < 3; attempt++) {
        res = await midtrans.createQRIS(orderId: order.id);
        if (res['success'] == true) break;
        if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
      }
      if (!mounted) return;
      if (res['success'] == true && res['qr_string'] != null) {
        setState(() {
          _qrString = res['qr_string'] as String?;
          _qrRemaining = 5 * 60;
        });
        _startQrTimer();
        _startPolling(order.id);
      } else {
        _toast(res['message'] ?? 'Gagal membuat QR QRIS', _SwWhite.error);
      }
    } catch (e) {
      _toast(MidtransService.pesanRamah(e, 'Gagal membuat QR QRIS'),
          _SwWhite.error);
    } finally {
      if (mounted) setState(() => _methodLoading = false);
    }
  }

  void _startVaTimer() {
    _vaTimer?.cancel();
    _vaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _vaTimer?.cancel();
        return;
      }
      setState(() {
        if (_vaRemaining > 0) {
          _vaRemaining--;
        } else {
          _vaTimer?.cancel();
        }
      });
    });
  }

  void _startQrTimer() {
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _qrTimer?.cancel();
        return;
      }
      setState(() {
        if (_qrRemaining > 0) {
          _qrRemaining--;
        } else {
          _qrTimer?.cancel();
          _pollTimer?.cancel();
        }
      });
    });
  }

  String _formatVaCountdown(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _formatQrCountdown(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // Polling status tiap 3 detik setelah QR atau VA tampil.
  void _startPolling(String orderId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      final midtrans = ref.read(midtransServiceProvider);
      final res = await midtrans.pollPayment(orderId: orderId);
      if (!mounted) return;
      if (res['is_paid'] == true) {
        _pollTimer?.cancel();
        _vaTimer?.cancel();
        _qrTimer?.cancel();
        setState(() => _paymentDetected = true);
        _toast('Pembayaran terverifikasi ✓', _SwWhite.greenDark);
      }
    });
  }

  // Langkah 3: bayar sekarang lewat checkoutAtomic.
  Future<void> _bayarSekarang(String currentUserId) async {
    // Kalau pelunasan sudah terdeteksi lewat polling, langsung sukses.
    if (_paymentDetected) {
      _showSuccessScreen();
      return;
    }

    // Metode kartu belum membuat order di langkah 2, jadi order dibuat di sini.
    final order = await _ensureOrderCreated(currentUserId);
    if (order == null) return;

    setState(() => _loading = true);
    try {
      final midtrans = ref.read(midtransServiceProvider);
      final result = await midtrans.checkoutAtomic(
        orderId: order.id,
        ticketId: _tiket.id,
        jumlahTiket: _jumlahTiket,
        revisionCounter: _tiket.revisionCounter,
        metodePembayaran: _metodeForOrder(),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      // 409: stok atau revisi tiket berubah.
      if (result['conflict'] == true) {
        _toast(
          result['message'] ?? 'Stok berubah, silakan refresh',
          _SwWhite.warning,
        );
        return;
      }

      if (result['success'] == true) {
      // Kartu memakai Snap token; VA dan QR sudah dibayar lewat Core API.
        if (_selectedMethod == 'card') {
          // Polling untuk mendeteksi pelunasan.
          _startPolling(order.id);
          _showCardPayInfo(order);
        } else {
          // Instrumen sudah dibuat dan stok sudah direservasi: tunggu bayar.
          _showWaitingInfo();
        }
        return;
      }

      final msg = (result['message'] ?? '').toString();
      if (msg.toLowerCase().contains('stok') ||
          msg.toLowerCase().contains('cukup') ||
          msg.toLowerCase().contains('insufficient')) {
        _toast('Stok tidak mencukupi', _SwWhite.error);
        return;
      }

      _toast(result['message'] ?? 'Gagal memproses pembayaran', _SwWhite.error);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(MidtransService.pesanRamah(e, 'Gagal memproses pembayaran'),
          _SwWhite.error);
    }
  }

  void _showCardPayInfo(PesananTiketModel order) {
    final midtrans = ref.read(midtransServiceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _SwWhite.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _SwWhite.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selesaikan Pembayaran',
              style: GoogleFonts.rajdhani(
                color: _SwWhite.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan telah dibuat. Stok tiket berhasil direservasi.',
              style: GoogleFonts.spaceGrotesk(
                color: _SwWhite.sub,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            if (order.kodeBooking.isNotEmpty)
              _sheetRow('Kode Booking', order.kodeBooking),
            const SizedBox(height: 8),
            _sheetRow('Total', _formatRupiah(_totalTagih)),
            const SizedBox(height: 8),
            _sheetRow('Status', 'RESERVED'),
            const SizedBox(height: 24),
            if (!AppConstants.midtransIsProduction) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final res = await midtrans.settleOrderDev(order.id);
                    nav.pop();
                    if (res['success'] == true) {
                      _pollTimer?.cancel();
                      _showSuccessScreen();
                    } else {
                      _toast(
                          res['message'] ?? 'Gagal simulasi', _SwWhite.error);
                    }
                  },
                  icon: const Icon(Icons.developer_mode, size: 18),
                  label: Text(
                    'bayar',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _SwWhite.redBright,
                    side: const BorderSide(color: _SwWhite.navy),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _keTiketSaya,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _SwWhite.btnBg,
                  foregroundColor: _SwWhite.btnFg,
                  minimumSize: const Size.fromHeight(50),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Ke Tiket Saya',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Keluar dari alur pembayaran dan mendarat di tab Tiket Saya.
  ///
  /// Reservasi tidak dibatalkan: pesanan tetap PENDING dan stok tetap
  /// tertahan, jadi user bisa melanjutkan dari daftar tiket.
  void _keTiketSaya() {
    final tab = ref.read(permintaanTabUserProvider.notifier);
    Navigator.of(context).popUntil((r) => r.isFirst);
    tab.state = 1; // 0 Jelajah · 1 Tiket Saya · 2 Wishlist · 3 Akun
  }

  void _showWaitingInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _SwWhite.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0x1400E676),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: _SwWhite.greenDark, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'MENUNGGU PEMBAYARAN',
              style: GoogleFonts.rajdhani(
                color: _SwWhite.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stok tiket berhasil direservasi. Selesaikan pembayaran ${_methodLabel.toLowerCase()} Anda. Status akan terverifikasi otomatis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: _SwWhite.sub,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            if (!AppConstants.midtransIsProduction && _savedOrder != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final res = await ref
                        .read(midtransServiceProvider)
                        .settleOrderDev(_savedOrder!.id);
                    nav.pop();
                    if (res['success'] == true) {
                      _pollTimer?.cancel();
                      _vaTimer?.cancel();
                      _qrTimer?.cancel();
                      _showSuccessScreen();
                    } else {
                      _toast(
                          res['message'] ?? 'Gagal simulasi', _SwWhite.error);
                    }
                  },
                  icon: const Icon(Icons.developer_mode, size: 18),
                  label: Text(
                    'bayar',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _SwWhite.redBright,
                    side: const BorderSide(color: _SwWhite.navy),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _keTiketSaya,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _SwWhite.btnBg,
                  foregroundColor: _SwWhite.btnFg,
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Ke Tiket Saya',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessScreen() {
    _pollTimer?.cancel();
    _vaTimer?.cancel();
    _qrTimer?.cancel();
    unawaited(_markVoucherUsed());
    setState(() => _showSuccess = true);
    _checkController.forward(from: 0);
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _toast('Disalin: $text', _SwWhite.greenDark);
  }

  Widget _sheetRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 13)),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                color: _SwWhite.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  InputDecoration _whiteInput(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.spaceGrotesk(color: _SwWhite.muted, fontSize: 14),
      floatingLabelStyle:
          GoogleFonts.spaceGrotesk(color: _SwWhite.ink, fontSize: 14),
      filled: true,
      fillColor: _SwWhite.chip,
      prefixIcon:
          icon != null ? Icon(icon, color: _SwWhite.sub, size: 20) : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _SwWhite.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _SwWhite.ink, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _SwWhite.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _SwWhite.error, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Dropdown voucher yang sudah diklaim user.
  Widget _buildVoucherPicker() {
    if (_claimedPromos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _SwWhite.chip,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _SwWhite.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined,
                size: 18, color: _SwWhite.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Belum ada voucher. Klaim promo di halaman Jelajah, lalu lihat di Akun → Diskon Saya.',
                style: GoogleFonts.spaceGrotesk(
                    color: _SwWhite.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _SwWhite.chip,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _diskon > 0 ? _SwWhite.green : _SwWhite.line,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedClaim?.promoId ?? '',
              isExpanded: true,
              dropdownColor: _SwWhite.surface,
              icon: const Icon(Icons.expand_more, color: _SwWhite.sub),
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.ink, fontSize: 13),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(
                    'Tanpa diskon',
                    style: GoogleFonts.spaceGrotesk(
                        color: _SwWhite.sub, fontSize: 13),
                  ),
                ),
                ..._claimedPromos.map((v) {
                  final memenuhi = _subtotal >= v.minPembelian;
                  return DropdownMenuItem<String>(
                    value: v.promoId,
                    child: Text(
                      '${v.kode} · ${v.labelNilai}'
                      '${memenuhi ? '' : ' (min ${_formatRupiah(v.minPembelian)})'}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: memenuhi ? _SwWhite.ink : _SwWhite.muted,
                        fontSize: 13,
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  if (val == null || val.isEmpty) {
                    _selectedClaim = null;
                  } else {
                    _selectedClaim =
                        _claimedPromos.firstWhere((v) => v.promoId == val);
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedClaim != null && _diskon <= 0)
          Text(
            'Subtotal belum mencapai minimum ${_formatRupiah(_selectedClaim!.minPembelian)} untuk voucher ini.',
            style:
                GoogleFonts.spaceGrotesk(color: _SwWhite.warning, fontSize: 11),
          )
        else if (_diskon > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hemat ${_formatRupiah(_diskon)}',
                style: GoogleFonts.spaceGrotesk(
                    color: _SwWhite.greenDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'Total: ${_formatRupiah(_totalTagih)}',
                style: GoogleFonts.spaceGrotesk(
                    color: _SwWhite.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          )
        else
          Text(
            'Pilih voucher untuk memotong total pembayaran.',
            style:
                GoogleFonts.spaceGrotesk(color: _SwWhite.muted, fontSize: 11),
          ),
      ],
    );
  }

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

    return Scaffold(
      backgroundColor: _SwWhite.bg,
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
    );
  }

  // AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _SwWhite.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_new, color: _SwWhite.ink, size: 20),
        onPressed: () {
          if (_showSuccess) {
            Navigator.of(context).pop();
            return;
          }
          // Mode lanjut: mundur dari Bayar membawa user ke Tiket Saya,
          // bukan kembali ke daftar metode.
          if (_lanjut && _currentStep <= 1) {
            _keTiketSaya();
            return;
          }
          if (_currentStep > 0) {
            _goToStep(_currentStep - 1);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        _showSuccess
            ? 'Pembayaran Berhasil'
            : (_lanjut && _currentStep == 0)
                ? 'Bayar Pesanan'
                : ['Checkout', _methodLabel, 'Konfirmasi'][_currentStep],
        style: GoogleFonts.rajdhani(
          color: _SwWhite.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Tampilan mode lanjut: bagian yang tidak perlu diulang user.

  /// Kartu pemesan ringkas. Data pemesan terkunci ke pesanan, jadi tiga
  /// kolom formulir readOnly tidak ada gunanya.
  Widget _buildKartuPemesanTerkunci() {
    final o = widget.orderLanjutan!;
    final hp = (o.teleponPembeli ?? '').trim();
    final rincian = [
      if (o.namaPembeli.trim().isNotEmpty) o.namaPembeli.trim(),
      if (o.emailPembeli.trim().isNotEmpty) o.emailPembeli.trim(),
      if (hp.isNotEmpty) hp,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SwWhite.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _SwWhite.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: _SwWhite.sub, size: 13),
              const SizedBox(width: 6),
              Text(
                'PEMESAN',
                style: GoogleFonts.rajdhani(
                  color: _SwWhite.sub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rincian.isEmpty ? 'Data pemesan mengikuti pesanan' : rincian,
            style: GoogleFonts.spaceGrotesk(
              color: _SwWhite.ink,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${o.jumlahTiket} tiket ${o.kategoriTiket} · '
            'terkunci ke ${o.kodeBooking}',
            style:
                GoogleFonts.spaceGrotesk(color: _SwWhite.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Jalan keluar kalau metode terpilih ternyata tidak bisa dipakai, misalnya
  /// saldo GoPay kurang. Sengaja tautan kecil, bukan tombol, supaya user tidak
  /// dirayu berganti-ganti metode.
  Widget _buildTautanGantiMetode() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => _goToStep(0),
        style: TextButton.styleFrom(
          foregroundColor: _SwWhite.sub,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Ganti metode pembayaran',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            decoration: TextDecoration.underline,
            decorationColor: _SwWhite.sub,
          ),
        ),
      ),
    );
  }

  /// Mode lanjut: tampilkan VA atau QR yang sudah ada tanpa menekan Generate.
  /// Backend memakai ulang instrumen yang belum kedaluwarsa, jadi tidak ada
  /// tagihan ganda. Dicoba sekali per layar; tombol manual tetap tersedia.
  void _cobaTampilkanInstrumen(String uid) {
    if (_autoInstrumenDicoba || !_lanjut || _currentStep != 1) return;
    if (uid.isEmpty || uid == 'guest') return;

    switch (_selectedMethod) {
      case 'va':
        if (_vaNumber != null) return;
        break;
      case 'gopay':
        if (_gopayPhone != null) return;
        break;
      case 'qris':
        if (_qrString != null) return;
        break;
      default:
        _autoInstrumenDicoba = true; // kartu: tidak ada instrumen tersimpan
        return;
    }

    _autoInstrumenDicoba = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (_selectedMethod) {
        case 'va':
          _generateVA(uid);
          break;
        case 'gopay':
          _generateGoPay(uid, diam: true);
          break;
        case 'qris':
          _generateQRIS(uid);
          break;
      }
    });
  }

  // Banner mode lanjutkan pembayaran.
  Widget _buildBannerLanjut() {
    final o = widget.orderLanjutan!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1400E676),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _SwWhite.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: _SwWhite.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MELANJUTKAN PESANAN ${o.kodeBooking}',
                  style: GoogleFonts.rajdhani(
                    color: _SwWhite.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${o.jumlahTiket} tiket ${o.kategoriTiket} · '
                  'total ${_formatRupiah(_totalTagih)}',
                  style: GoogleFonts.spaceGrotesk(
                    color: _SwWhite.sub,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Indikator langkah.
  Widget _buildStepIndicator() {
    // Mode lanjut: langkah metode sudah selesai, jadi labelnya diganti nama
    // metode supaya user melihat centang dan pilihannya.
    final labels = [
      _lanjut && _selectedMethod != null ? _methodLabel : 'Metode',
      'Bayar',
      'Konfirmasi',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: const BoxDecoration(
        color: _SwWhite.bg,
        border: Border(bottom: BorderSide(color: _SwWhite.line)),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _currentStep;
          final current = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? _SwWhite.green : _SwWhite.surface,
                    border: current
                        ? Border.all(color: _SwWhite.green, width: 2)
                        : Border.all(color: _SwWhite.line),
                  ),
                  child: Center(
                    child: active
                        ? (i < _currentStep
                            ? const Icon(Icons.check,
                                color: _SwWhite.btnFg, size: 15)
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.spaceGrotesk(
                                  color: _SwWhite.btnFg,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ))
                        : Text(
                            '${i + 1}',
                            style: GoogleFonts.spaceGrotesk(
                              color: _SwWhite.sub,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labels[i],
                    style: GoogleFonts.spaceGrotesk(
                      color: active ? _SwWhite.ink : _SwWhite.sub,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (i < 2)
                  Container(height: 1, width: 12, color: _SwWhite.line),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Langkah 1: pilih metode pembayaran.
  Widget _buildStep1Methods() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Metode Pembayaran',
            style: GoogleFonts.rajdhani(
              color: _SwWhite.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih cara pembayaran yang paling nyaman untuk kamu.',
            style: GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (_lanjut) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x14FFB300),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66FFB300)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.swap_horiz_rounded,
                      color: Color(0xFFFFB300), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Metode baru akan membuat instrumen pembayaran baru. '
                      'Nomor VA / QR lama tidak dipakai lagi untuk pesanan ini.',
                      style: GoogleFonts.spaceGrotesk(
                          color: _SwWhite.sub, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildConcertSummary(),
          const SizedBox(height: 20),
          ..._methods.map((m) => _buildMethodCard(m)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMethodCard(_PaymentMethod m) {
    final selected = _selectedMethod == m.id;
    // Jangan pakai Colors.transparent di satu sisi border selama ada
    // borderRadius: Flutter menghitung transparan sebagai warna yang terlihat,
    // lalu melempar "A borderRadius can only be given on borders with uniform
    // colors" saat paint. Kartu tampak kosong karena isinya tidak pernah
    // digambar. Semua sisi wajib satu warna; lebar boleh berbeda.
    final Color borderColor =
        selected ? _SwWhite.green.withValues(alpha: 0.4) : _SwWhite.line;
    return GestureDetector(
      onTap: () => setState(() {
        if (_selectedMethod != m.id) {
          // Metode berganti: instrumen lama tidak dipakai lagi.
          _vaNumber = null;
          _vaBank = null;
          _billerCode = null;
          _qrString = null;
          _gopayPhone = null;
          _autoInstrumenDicoba = false;
        }
        _selectedMethod = m.id;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _SwWhite.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? _SwWhite.green.withValues(alpha: 0.15)
                    : _SwWhite.chip,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? _SwWhite.green : _SwWhite.line,
                ),
              ),
              child: Icon(m.icon,
                  color: selected ? _SwWhite.green : _SwWhite.sub, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: _SwWhite.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      color: _SwWhite.sub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _SwWhite.green : Colors.transparent,
                border: Border.all(
                  color: selected ? _SwWhite.green : _SwWhite.muted,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: _SwWhite.btnFg)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcertSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SwWhite.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child:
                  GambarWidget(url: widget.konser.gambarUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.konser.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                    color: _SwWhite.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tiket.kategori,
                  style: GoogleFonts.spaceGrotesk(
                    color: _SwWhite.sub,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.konser.tanggal.day}/${widget.konser.tanggal.month}/${widget.konser.tanggal.year} · ${widget.konser.lokasi}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: _SwWhite.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Langkah 2: formulir sesuai metode.
  Widget _buildStep2Form(String currentUserId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data pemesan.
          // Mode lanjut: data pemesan terkunci di pesanan, jadi tiga kolom
          // formulir readOnly hanya memanjangkan layar.
          if (_lanjut) ...[
            _buildKartuPemesanTerkunci(),
            const SizedBox(height: 6),
            _buildTautanGantiMetode(),
          ] else ...[
            _sectionTitle('Informasi Pemesan'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaCtrl,
              decoration:
                  _whiteInput('Nama Lengkap', icon: Icons.person_outline),
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.ink, fontSize: 14),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _whiteInput('Email Konfirmasi E-Tiket',
                  icon: Icons.email_outlined),
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.ink, fontSize: 14),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Email tidak valid' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _teleponCtrl,
              keyboardType: TextInputType.phone,
              decoration: _whiteInput('Nomor WhatsApp / HP',
                  icon: Icons.phone_outlined),
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.ink, fontSize: 14),
              validator: (v) => v == null || v.trim().length < 8
                  ? 'Nomor HP tidak valid'
                  : null,
            ),
          ],

          // Jumlah tiket.
          // Mode lanjut: jumlah tiket dan voucher terkunci ke pesanan asli.
          if (_lanjut) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Jumlah Tiket'),
                Text(
                  '$_jumlahTiket tiket',
                  style: GoogleFonts.rajdhani(
                    color: _SwWhite.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Jumlah tiket & data pemesan mengikuti pesanan '
              '${widget.orderLanjutan!.kodeBooking} yang sudah dibuat.',
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.muted, fontSize: 11),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Jumlah Tiket'),
                Container(
                  decoration: BoxDecoration(
                    color: _SwWhite.chip,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _SwWhite.line),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _jumlahTiket > 1
                            ? () => setState(() => _jumlahTiket--)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        color: _SwWhite.ink,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_jumlahTiket',
                          style: GoogleFonts.spaceGrotesk(
                            color: _SwWhite.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _jumlahTiket < _maxTiket
                            ? () => setState(() => _jumlahTiket++)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        color: _SwWhite.ink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Maks. $_maxTiket tiket · Sisa stok: ${_tiket.stok}',
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.muted, fontSize: 11),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Diskon / Voucher'),
            const SizedBox(height: 10),
            _buildVoucherPicker(),
          ],

          const SizedBox(height: 24),
          const Divider(color: _SwWhite.line, height: 1),
          const SizedBox(height: 20),

          if (_selectedMethod == 'va') ..._buildVaForm(currentUserId),
          if (_selectedMethod == 'card') ..._buildCardForm(),
          if (_selectedMethod == 'gopay') ..._buildGoPayForm(currentUserId),
          if (_selectedMethod == 'qris') ..._buildQrForm(currentUserId, 'qris'),
        ],
      ),
    );
  }

  // Formulir transfer bank.
  List<Widget> _buildVaForm(String currentUserId) {
    const banks = [
      ('bca', 'BCA'),
      ('bni', 'BNI'),
      ('mandiri', 'Mandiri'),
    ];
    return [
      _sectionTitle('Pilih Bank'),
      const SizedBox(height: 12),
      Row(
        children: banks.map((b) {
          final selected = _selectedBank == b.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedBank = b.$1;
                // Ganti bank berarti VA lama tidak dipakai lagi.
                _vaNumber = null;
                _vaTimer?.cancel();
              }),
              child: Container(
                margin: EdgeInsets.only(right: b.$1 != 'mandiri' ? 10 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? _SwWhite.green.withValues(alpha: 0.08)
                      : _SwWhite.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? _SwWhite.green : _SwWhite.line,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? _SwWhite.green : _SwWhite.muted,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.$2,
                      style: GoogleFonts.spaceGrotesk(
                        color: selected ? _SwWhite.ink : _SwWhite.sub,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      if (_vaNumber == null)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _methodLoading ? null : () => _generateVA(currentUserId),
            icon: _methodLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _SwWhite.btnFg),
                  )
                : const Icon(Icons.account_balance, size: 20),
            label: Text(
              _methodLoading ? 'Membuat VA...' : 'Generate VA',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _SwWhite.green,
              foregroundColor: _SwWhite.btnFg,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )
      else ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _SwWhite.chip,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _SwWhite.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nomor Virtual Account',
                    style: GoogleFonts.spaceGrotesk(
                      color: _SwWhite.sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _SwWhite.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (_vaBank ?? _selectedBank).toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        color: _SwWhite.greenDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                _vaNumber!,
                style: GoogleFonts.rajdhani(
                  color: _SwWhite.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              if (_billerCode != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Kode Biller: $_billerCode',
                  style: GoogleFonts.spaceGrotesk(
                    color: _SwWhite.muted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: _SwWhite.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Bayar dalam ${_formatVaCountdown(_vaRemaining)}',
                    style: GoogleFonts.spaceGrotesk(
                      color: _SwWhite.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _copyToClipboard(_vaNumber!),
                icon: const Icon(Icons.copy, size: 16),
                label: Text(
                  'Salin Nomor VA',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _SwWhite.ink,
                  side: const BorderSide(color: _SwWhite.ink),
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _SwWhite.chip,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: _SwWhite.sub),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transfer ke nomor VA di atas via ATM / m-banking. Status terverifikasi otomatis.',
                  style: GoogleFonts.spaceGrotesk(
                      color: _SwWhite.sub, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        if (_paymentDetected) ...[
          const SizedBox(height: 12),
          _detectedBanner(),
        ],
      ],
    ];
  }

  // Formulir kartu kredit atau debit.
  List<Widget> _buildCardForm() {
    return [
      _sectionTitle('Data Kartu'),
      const SizedBox(height: 12),
      TextFormField(
        controller: _cardNumberCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [_CardNumberFormatter()],
        decoration: _whiteInput('Nomor Kartu', icon: Icons.credit_card),
        style: GoogleFonts.spaceGrotesk(color: _SwWhite.ink, fontSize: 14),
        validator: (v) {
          final digits = (v ?? '').replaceAll(' ', '');
          return digits.length < 16 ? 'Nomor kartu tidak lengkap' : null;
        },
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _expiryCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [_ExpiryFormatter()],
              decoration: _whiteInput('MM/YY'),
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.ink, fontSize: 14),
              validator: (v) {
                final digits = (v ?? '').replaceAll('/', '');
                return digits.length < 4 ? 'MM/YY' : null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _cvvCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: _whiteInput('CVV'),
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.ink, fontSize: 14),
              validator: (v) => (v ?? '').length < 3 ? 'CVV' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _saveCard,
              onChanged: (v) => setState(() => _saveCard = v ?? false),
              activeColor: _SwWhite.green,
              checkColor: _SwWhite.ink,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: _SwWhite.line),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Simpan kartu untuk pembelian berikutnya',
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          const Icon(Icons.lock_outline, size: 14, color: _SwWhite.greenDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Pembayaran diamankan dengan enkripsi 256-bit SSL',
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 11),
            ),
          ),
        ],
      ),
      if (_paymentDetected) ...[
        const SizedBox(height: 12),
        _detectedBanner(),
      ],
    ];
  }

  // Formulir GoPay: nomor HP, tanpa QR.
  List<Widget> _buildGoPayForm(String currentUserId) {
    return [
      _sectionTitle('Pembayaran GoPay'),
      const SizedBox(height: 6),
      Text(
        'Pembayaran akan diproses melalui GoPay. Pastikan nomor HP kamu terhubung dengan akun GoPay.',
        style: GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 13),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _SwWhite.chip,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _SwWhite.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_android_rounded,
                color: _SwWhite.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor GoPay',
                    style: GoogleFonts.spaceGrotesk(
                        color: _SwWhite.muted, fontSize: 11),
                  ),
                  Text(
                    _teleponCtrl.text,
                    style: GoogleFonts.spaceGrotesk(
                        color: _SwWhite.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (_gopayPhone == null)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                _methodLoading ? null : () => _generateGoPay(currentUserId),
            icon: _methodLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _SwWhite.btnFg))
                : const Icon(Icons.wallet, size: 20),
            label: Text(
              _methodLoading ? 'Memproses...' : 'Bayar dengan GoPay',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _SwWhite.green,
              foregroundColor: _SwWhite.btnFg,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        )
      else ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: _SwWhite.warning),
            const SizedBox(width: 6),
            Text(
              'Bayar dalam ${_formatQrCountdown(_qrRemaining)}',
              style: GoogleFonts.spaceGrotesk(
                  color: _SwWhite.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _SwWhite.chip,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _SwWhite.green),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: _SwWhite.green, size: 48),
              const SizedBox(height: 12),
              Text(
                'Menunggu Pembayaran',
                style: GoogleFonts.rajdhani(
                    color: _SwWhite.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Buka aplikasi GoPay di nomor $_gopayPhone untuk menyelesaikan pembayaran.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildQrForm(String currentUserId, String kind) {
    final isGoPay = kind == 'gopay';
    final label = isGoPay ? 'GoPay' : 'QRIS';
    return [
      _sectionTitle('Scan QR $label'),
      const SizedBox(height: 6),
      Text(
        isGoPay
            ? 'Scan QR dengan aplikasi GoPay'
            : 'Scan dengan e-wallet atau m-banking',
        style: GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 13),
      ),
      const SizedBox(height: 16),
      if (_qrString == null)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _methodLoading
                ? null
                : () => isGoPay
                    ? _generateGoPay(currentUserId)
                    : _generateQRIS(currentUserId),
            icon: _methodLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _SwWhite.btnFg),
                  )
                : Icon(isGoPay ? Icons.wallet : Icons.qr_code, size: 20),
            label: Text(
              _methodLoading ? 'Membuat QR...' : 'Tampilkan QR $label',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _SwWhite.green,
              foregroundColor: _SwWhite.btnFg,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )
      else ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: _SwWhite.warning),
            const SizedBox(width: 6),
            Text(
              'Bayar dalam ${_formatQrCountdown(_qrRemaining)}',
              style: GoogleFonts.spaceGrotesk(
                color: _SwWhite.warning,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _SwWhite.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _SwWhite.line),
          ),
          child: QrImageView(
            data: _qrString!,
            version: QrVersions.auto,
            size: 220,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: _SwWhite.ink,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _SwWhite.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isGoPay
              ? 'Scan QR dengan aplikasi GoPay'
              : 'Scan dengan e-wallet atau m-banking',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (_paymentDetected) _detectedBanner(),
      ],
    ];
  }

  Widget _detectedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _SwWhite.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _SwWhite.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: _SwWhite.greenDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pembayaran terverifikasi. Lanjut ke konfirmasi.',
              style: GoogleFonts.spaceGrotesk(
                  color: _SwWhite.greenDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Langkah 3: konfirmasi dan bayar.
  Widget _buildStep3Confirm(String currentUserId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfirmasi Pesanan',
            style: GoogleFonts.rajdhani(
              color: _SwWhite.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Periksa detail pesanan sebelum membayar.',
            style: GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 13),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _SwWhite.chip,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: GambarWidget(
                            url: widget.konser.gambarUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.konser.judul,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.rajdhani(
                              color: _SwWhite.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${widget.konser.tanggal.day}/${widget.konser.tanggal.month}/${widget.konser.tanggal.year}',
                            style: GoogleFonts.spaceGrotesk(
                                color: _SwWhite.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: _SwWhite.line, height: 1),
                const SizedBox(height: 14),
                _confirmRow('Konser', widget.konser.judul),
                _confirmRow('Kategori Tiket', _tiket.kategori),
                _confirmRow('Jumlah', '$_jumlahTiket tiket'),
                _confirmRow('Metode', _methodLabel),
                if (_savedOrder != null && _savedOrder!.kodeBooking.isNotEmpty)
                  _confirmRow('Kode Booking', _savedOrder!.kodeBooking),
                const SizedBox(height: 14),
                const Divider(color: _SwWhite.line, height: 1),
                const SizedBox(height: 14),
                _confirmRow(
                    'Subtotal ($_jumlahTiket tiket)', _formatRupiah(_subtotal)),
                const SizedBox(height: 8),
                _confirmRow('Biaya Admin', _formatRupiah(_biayaAdmin)),
                if (_diskon > 0) ...[
                  const SizedBox(height: 8),
                  _confirmRow(
                    'Diskon (${_selectedClaim?.kode ?? ''})',
                    '- ${_formatRupiah(_diskon)}',
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.rajdhani(
                        color: _SwWhite.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _formatRupiah(_totalTagih),
                      style: GoogleFonts.spaceGrotesk(
                        color: _SwWhite.greenDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_paymentDetected)
            _detectedBanner()
          else ...[
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 14, color: _SwWhite.sub),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dengan menekan BAYAR SEKARANG, kamu menyetujui Syarat & Ketentuan Soundwave.',
                    style: GoogleFonts.spaceGrotesk(
                        color: _SwWhite.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Stok tiket akan direservasi secara atomik via /checkout-atomic.',
              style:
                  GoogleFonts.spaceGrotesk(color: _SwWhite.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                  color: _SwWhite.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Bilah bawah.
  Widget _buildBottomBar(String currentUserId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: _SwWhite.bg,
        border: Border(top: BorderSide(color: _SwWhite.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: GoogleFonts.spaceGrotesk(
                      color: _SwWhite.sub, fontSize: 12),
                ),
                Text(
                  _formatRupiah(_totalTagih),
                  style: GoogleFonts.rajdhani(
                    color: _SwWhite.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBottomButton(currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(String currentUserId) {
    if (_currentStep == 0) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedMethod == null ? null : _nextFromStep1,
          style: ElevatedButton.styleFrom(
            backgroundColor: _SwWhite.btnBg,
            foregroundColor: _SwWhite.btnFg,
            disabledBackgroundColor: _SwWhite.chip,
            disabledForegroundColor: _SwWhite.muted,
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Lanjut',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (_currentStep == 1) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _lanjut ? _keTiketSaya : () => _goToStep(0),
              style: OutlinedButton.styleFrom(
                foregroundColor: _SwWhite.ink,
                side: const BorderSide(color: _SwWhite.line),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _lanjut ? 'Ke Tiket Saya' : 'Kembali',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextFromStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: _SwWhite.btnBg,
                foregroundColor: _SwWhite.btnFg,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Lanjut ke Konfirmasi',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : () => _bayarSekarang(currentUserId),
        style: ElevatedButton.styleFrom(
          backgroundColor: _SwWhite.btnBg,
          foregroundColor: _SwWhite.btnFg,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: _SwWhite.btnFg),
              )
            : Text(
                _paymentDetected ? 'Lihat E-Tiket' : 'BAYAR SEKARANG',
                style: GoogleFonts.rajdhani(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  // Tampilan sukses.
  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: _SwWhite.bg,
      appBar: AppBar(
        backgroundColor: _SwWhite.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Pembayaran Berhasil',
          style: GoogleFonts.rajdhani(
            color: _SwWhite.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: _SwWhite.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: _SwWhite.green,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Transaksi Berhasil!',
                style: GoogleFonts.rajdhani(
                  color: _SwWhite.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _savedOrder != null
                    ? 'E-Tiket kamu sudah aktif. Kode booking: ${_savedOrder!.kodeBooking}'
                    : 'E-Tiket kamu sudah aktif dan siap digunakan.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.spaceGrotesk(color: _SwWhite.sub, fontSize: 14),
              ),
              const Spacer(),
              if (_savedOrder != null && _savedOrder!.kodeBooking.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _SwWhite.chip,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _SwWhite.line),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'KODE BOOKING',
                        style: GoogleFonts.spaceGrotesk(
                          color: _SwWhite.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _savedOrder!.kodeBooking,
                        style: GoogleFonts.rajdhani(
                          color: _SwWhite.greenDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _keTiketSaya,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _SwWhite.btnBg,
                    foregroundColor: _SwWhite.btnFg,
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Lihat Tiket Saya',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: Text(
                    'Kembali ke Beranda',
                    style: GoogleFonts.spaceGrotesk(
                        color: _SwWhite.sub,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.rajdhani(
        color: _SwWhite.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _PaymentMethod {
  final String id;
  final String title;
  final IconData icon;
  final String subtitle;
  const _PaymentMethod(this.id, this.title, this.icon, this.subtitle);
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) digits = digits.substring(0, 16);
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      var end = i + 4;
      if (end > digits.length) end = digits.length;
      groups.add(digits.substring(i, end));
    }
    final formatted = groups.join(' ');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    String text;
    if (digits.length <= 2) {
      text = digits;
    } else {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
