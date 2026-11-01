part of '../checkout_screen.dart';

/// Kerangka tampilan: AppBar, indikator langkah, banner, ringkasan
/// pemesan, dan judul bagian.
///
/// Dipisahkan dari `checkout_screen.dart` agar berkas utama tidak lagi
/// menampung seluruh layar checkout. Perilaku tidak berubah: mixin ini
/// berada dalam library yang sama (`part of`) dan di-`with` oleh state,
/// sehingga tetap dapat mengakses field, method, serta `setState`.
mixin _CheckoutLayout on _CheckoutBase {
  @override
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: SwCheckout.bg,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Kembali',
        icon:
            const Icon(Icons.arrow_back_ios_new, color: SwCheckout.ink, size: 20),
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
          color: SwCheckout.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
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
        color: SwCheckout.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: SwCheckout.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: SwCheckout.sub, size: 13),
              const SizedBox(width: 6),
              Text(
                'PEMESAN',
                style: GoogleFonts.rajdhani(
                  color: SwCheckout.sub,
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
              color: SwCheckout.ink,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${o.jumlahTiket} tiket ${o.kategoriTiket} · '
            'terkunci ke ${o.kodeBooking}',
            style:
                GoogleFonts.spaceGrotesk(color: SwCheckout.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildTautanGantiMetode() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => _goToStep(0),
        style: TextButton.styleFrom(
          foregroundColor: SwCheckout.sub,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          minimumSize: const Size(0, 32),
          // JANGAN pakai MaterialTapTargetSize.shrinkWrap di sini.
          // Dengan shrinkWrap, area sentuh menyusut jadi ~22px — di bawah
          // ambang 44px dan sulit ditekan saat tangan sedang bergerak.
          // Dibiarkan default, Flutter membungkusnya jadi 48x48 tanpa
          // mengubah tampilan satu piksel pun.
        ),
        child: Text(
          'Ganti metode pembayaran',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            decoration: TextDecoration.underline,
            decorationColor: SwCheckout.sub,
          ),
        ),
      ),
    );
  }

  @override
  Widget _buildBannerLanjut() {
    final o = widget.orderLanjutan!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SwCheckout.greenSoft,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: SwCheckout.aksi.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded,
              color: SwCheckout.aksi, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MELANJUTKAN PESANAN ${o.kodeBooking}',
                  style: GoogleFonts.rajdhani(
                    color: SwCheckout.ink,
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
                    color: SwCheckout.sub,
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

  @override
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
        color: SwCheckout.bg,
        border: Border(bottom: BorderSide(color: SwCheckout.line)),
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
                    color: active ? SwCheckout.aksi : SwCheckout.surface,
                    border: current
                        ? Border.all(color: SwCheckout.aksi, width: 2)
                        : Border.all(color: SwCheckout.line),
                  ),
                  child: Center(
                    child: active
                        ? (i < _currentStep
                            ? const Icon(Icons.check,
                                color: SwCheckout.btnFg, size: 15)
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.spaceGrotesk(
                                  color: SwCheckout.btnFg,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ))
                        : Text(
                            '${i + 1}',
                            style: GoogleFonts.spaceGrotesk(
                              color: SwCheckout.sub,
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
                      color: active ? SwCheckout.ink : SwCheckout.sub,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (i < 2)
                  Container(height: 1, width: 12, color: SwCheckout.line),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget _detectedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SwCheckout.green.withValues(alpha: 0.12),
        borderRadius: AppRadius.rMd,
        border: Border.all(color: SwCheckout.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: SwCheckout.greenDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pembayaran terverifikasi. Lanjut ke konfirmasi.',
              style: GoogleFonts.spaceGrotesk(
                  color: SwCheckout.greenDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.rajdhani(
        color: SwCheckout.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}
