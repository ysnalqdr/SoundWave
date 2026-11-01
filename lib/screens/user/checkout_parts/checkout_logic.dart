part of '../checkout_screen.dart';

/// Logika checkout: transisi langkah, instrumen pembayaran, timer,
/// polling status, dan aksi pengguna.
///
/// Dipisahkan dari `checkout_screen.dart` agar berkas utama tidak lagi
/// menampung seluruh layar checkout. Perilaku tidak berubah: mixin ini
/// berada dalam library yang sama (`part of`) dan di-`with` oleh state,
/// sehingga tetap dapat mengakses field, method, serta `setState`.
String? _metodeDariLabel(String? label) {
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

mixin _CheckoutLogic on _CheckoutBase {
  @override
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

  @override
  Future<void> _markVoucherUsed() async {
    final uid = _claimedUid;
    if (uid == null) return;

    // Voucher bisa datang dari dua tempat: daftar klaim, atau kode yang
    // diketik manual (yang otomatis tersimpan saat lolos validasi).
    //
    // Dulu hanya `_selectedClaim` yang ditandai. Akibatnya voucher manual
    // yang sudah tersimpan di "Diskon Saya" tetap berstatus TERSEDIA
    // selamanya — pengguna melihatnya seolah masih bisa dipakai padahal
    // sudah terpakai, dan satu kode bisa dipakai berulang.
    final promoId = _selectedClaim?.promoId ?? _voucherManual?.kode;
    if (promoId == null) return;

    try {
      await ref
          .read(databaseServiceProvider)
          .markClaimedPromoUsed(uid, promoId, orderId: _savedOrder?.id);
    } catch (_) {
      // Tidak fatal: pembayaran sudah sukses.
    }
    _selectedClaim = null;
    _voucherManual = null;
  }

  @override
  String _formatRupiah(double nominal) {
    final formatted = nominal.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  @override
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

  @override
  void _goToStep(int step) => setState(() => _currentStep = step);

  @override
  void _nextFromStep1() {
    if (_selectedMethod == null) {
      _toast('Pilih metode pembayaran terlebih dahulu', SwCheckout.error);
      return;
    }
    _goToStep(1);
  }

  @override
  void _nextFromStep2() {
    if (!_formKey.currentState!.validate()) return;
    // VA, GoPay, dan QRIS harus dibuat dulu sebelum user bisa membayar.
    if (_selectedMethod == 'va' && (_vaNumber == null || _vaNumber!.isEmpty)) {
      _toast('Generate Virtual Account terlebih dahulu', SwCheckout.warning);
      return;
    }
    if (_selectedMethod == 'qris' &&
        (_qrString == null || _qrString!.isEmpty)) {
      _toast('Tampilkan QR code terlebih dahulu', SwCheckout.warning);
      return;
    }
    if (_selectedMethod == 'gopay' && _gopayPhone == null) {
      _toast('Konfirmasi nomor GoPay terlebih dahulu', SwCheckout.warning);
      return;
    }
    _goToStep(2);
  }

  @override
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
      // Rincian harga ikut dikirim supaya backend bisa memverifikasi bahwa
      // potongan voucher memang sah, dan supaya struk bisa menampilkan
      // komponennya. Angkanya berasal dari `RincianHarga` — rumus yang sama
      // dengan yang dipakai backend.
      subtotal: _rincian.subtotal.toDouble(),
      // `_voucherAktif` mencakup voucher dari daftar klaim DAN kode yang
      // diketik manual. Dulu baris ini hanya membaca `_selectedClaim`,
      // sehingga kode manual menghasilkan potongan di layar tetapi backend
      // menagih penuh — pembeli melihat satu angka, ditagih angka lain.
      kodePromo: _voucherAktif?.kode,
      diskon: _rincian.potongan.toDouble(),
      pajak: _rincian.pajak.toDouble(),
      biayaLayananPersen: _rincian.layananPersen.toDouble(),
      biayaLayananTetap: _rincian.layananTetap.toDouble(),
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
          SwCheckout.error);
      return null;
    }
  }

  @override
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
          // Acuan waktu WAJIB dari server; jam perangkat tidak dipercaya.
          _vaExpiresAt = _parseExpiresAt(res['expires_at']) ??
              DateTime.now().add(const Duration(hours: 24));
          _vaRemaining = _secondsUntil(_vaExpiresAt, 24 * 60 * 60);
        });
        _startVaTimer();
        _startPolling(order.id);
      } else {
        _toast(
            res['message'] ?? 'Gagal membuat Virtual Account', SwCheckout.error);
      }
    } catch (e) {
      _toast(MidtransService.pesanRamah(e, 'Gagal membuat Virtual Account'),
          SwCheckout.error);
    } finally {
      if (mounted) setState(() => _methodLoading = false);
    }
  }

  @override
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
          // Acuan waktu WAJIB dari server (`expires_at` Midtrans), bukan
          // hasil hitung lokal — jam perangkat tidak dapat dipercaya.
          _qrExpiresAt = _parseExpiresAt(res['expires_at']) ??
              DateTime.now().add(const Duration(minutes: 5));
          _qrRemaining = _secondsUntil(_qrExpiresAt, 5 * 60);
        });
        _startQrTimer();
        _startPolling(order.id);
        if (!diam) {
          _toast(
              'Pembayaran GoPay dibuat. Cek aplikasi GoPay di nomor $_gopayPhone',
              SwCheckout.green);
        }
      } else {
        _toast(res['message'] ?? 'Gagal membuat pembayaran GoPay. Coba lagi.',
            SwCheckout.error);
      }
    } catch (e) {
      _toast(MidtransService.pesanRamah(e, 'Gagal membuat pembayaran GoPay'),
          SwCheckout.error);
    } finally {
      if (mounted) setState(() => _methodLoading = false);
    }
  }

  @override
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
          // Acuan waktu WAJIB dari server.
          _qrExpiresAt = _parseExpiresAt(res['expires_at']) ??
              DateTime.now().add(const Duration(minutes: 5));
          _qrRemaining = _secondsUntil(_qrExpiresAt, 5 * 60);
        });
        _startQrTimer();
        _startPolling(order.id);
      } else {
        _toast(res['message'] ?? 'Gagal membuat QR QRIS', SwCheckout.error);
      }
    } catch (e) {
      _toast(MidtransService.pesanRamah(e, 'Gagal membuat QR QRIS'),
          SwCheckout.error);
    } finally {
      if (mounted) setState(() => _methodLoading = false);
    }
  }


  /// Membaca `expires_at` dari respons backend. Midtrans mengirim ISO-8601,
  /// tetapi sebagian jalur mengirim epoch milidetik; keduanya ditangani.
  /// Mengembalikan null bila nilai tidak dapat diparse, sehingga pemanggil
  /// dapat jatuh ke perkiraan durasi bawaan.
  @override
  DateTime? _parseExpiresAt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim())?.toLocal();
    }
    return null;
  }

  /// Sisa detik menuju sebuah batas waktu, dijepit ke >= 0.
  @override
  int _secondsUntil(DateTime? expiresAt, int fallbackSeconds) {
    if (expiresAt == null) return fallbackSeconds;
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }


  /// Dipanggil cincin saat batas waktu VA tercapai.
  ///
  /// Timer dihentikan, polling dihentikan (tidak ada gunanya memantau order
  /// yang instrumennya sudah mati), dan status layar disegarkan agar teks
  /// hitung-mundur menampilkan nol. Sweep stok tetap dilakukan backend lewat
  /// `sweep-expired`, jadi klien tidak perlu memanggilnya di sini.
  @override
  void _onVaExpired() {
    if (!mounted) return;
    _vaTimer?.cancel();
    _pollTimer?.cancel();
    setState(() {
      _vaRemaining = 0;
      _vaExpiresAt = null;
    });
    _toast('Batas waktu pembayaran habis. Silakan buat ulang.', SwCheckout.error);
  }

  /// Dipanggil cincin saat batas waktu QR/GoPay tercapai.
  @override
  void _onQrExpired() {
    if (!mounted) return;
    _qrTimer?.cancel();
    _pollTimer?.cancel();
    setState(() {
      _qrRemaining = 0;
      _qrExpiresAt = null;
    });
    _toast('QR sudah kedaluwarsa. Silakan buat ulang.', SwCheckout.error);
  }

  @override
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

  @override
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

  @override
  String _formatVaCountdown(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  String _formatQrCountdown(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
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
        _toast('Pembayaran terverifikasi ✓', SwCheckout.greenDark);
      }
    });
  }

  @override
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
          SwCheckout.warning,
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
        _toast('Stok tidak mencukupi', SwCheckout.error);
        return;
      }

      _toast(result['message'] ?? 'Gagal memproses pembayaran', SwCheckout.error);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(MidtransService.pesanRamah(e, 'Gagal memproses pembayaran'),
          SwCheckout.error);
    }
  }

  @override
  void _keTiketSaya() {
    final tab = ref.read(permintaanTabUserProvider.notifier);
    Navigator.of(context).popUntil((r) => r.isFirst);
    tab.state = 1; // 0 Jelajah · 1 Tiket Saya · 2 Wishlist · 3 Akun
  }

  @override
  void _showSuccessScreen() {
    _pollTimer?.cancel();
    _vaTimer?.cancel();
    _qrTimer?.cancel();
    unawaited(_markVoucherUsed());
    setState(() => _showSuccess = true);
  }

  @override
  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _toast('Disalin: $text', SwCheckout.greenDark);
  }

  @override
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
}
