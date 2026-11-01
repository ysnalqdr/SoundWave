part of '../checkout_screen.dart';

/// Formulir per metode: voucher, Virtual Account, kartu, GoPay, QRIS.
///
/// Dipisahkan dari `checkout_screen.dart` agar berkas utama tidak lagi
/// menampung seluruh layar checkout. Perilaku tidak berubah: mixin ini
/// berada dalam library yang sama (`part of`) dan di-`with` oleh state,
/// sehingga tetap dapat mengakses field, method, serta `setState`.
mixin _CheckoutForms on _CheckoutBase {
  @override
  Widget _buildVoucherPicker() {
    if (_claimedPromos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SwCheckout.chip,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: SwCheckout.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined,
                size: 18, color: SwCheckout.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Belum ada voucher. Klaim promo di halaman Jelajah, lalu lihat di Akun → Diskon Saya.',
                style: GoogleFonts.spaceGrotesk(
                    color: SwCheckout.muted, fontSize: 12),
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
            color: SwCheckout.chip,
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: _diskon > 0 ? SwCheckout.green : SwCheckout.line,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedClaim?.promoId ?? '',
              isExpanded: true,
              dropdownColor: SwCheckout.surface,
              icon: const Icon(Icons.expand_more, color: SwCheckout.sub),
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.ink, fontSize: 13),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(
                    'Tanpa diskon',
                    style: GoogleFonts.spaceGrotesk(
                        color: SwCheckout.sub, fontSize: 13),
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
                        color: memenuhi ? SwCheckout.ink : SwCheckout.muted,
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
                GoogleFonts.spaceGrotesk(color: SwCheckout.warning, fontSize: 11),
          )
        else if (_diskon > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hemat ${_formatRupiah(_diskon)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                    color: SwCheckout.greenDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'Total: ${_formatRupiah(_totalTagih)}',
                style: GoogleFonts.spaceGrotesk(
                    color: SwCheckout.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          )
        else
          Text(
            'Pilih voucher untuk memotong total pembayaran.',
            style:
                GoogleFonts.spaceGrotesk(color: SwCheckout.muted, fontSize: 11),
          ),

        // ------------------------------------------------------ kode manual
        //
        // Voucher yang belum diklaim tetap bisa dipakai dengan mengetik
        // kodenya. Backend memvalidasi ulang kodenya saat pembayaran dibuat,
        // jadi mengetik kode yang tidak sah tidak menghasilkan potongan.
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextField(
                  controller: _kodeVoucherCtrl,
                  textCapitalization: TextCapitalization.characters,
                  maxLines: 1,
                  style: GoogleFonts.spaceGrotesk(
                    color: SwCheckout.ink,
                    fontSize: 13,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Punya kode voucher? Ketik di sini',
                    hintStyle: GoogleFonts.spaceGrotesk(
                        color: SwCheckout.muted, fontSize: 12),
                    prefixIcon: const Icon(Icons.key_rounded,
                        size: 17, color: SwCheckout.muted),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: SwCheckout.chip,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.rMd,
                      borderSide: const BorderSide(color: SwCheckout.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.rMd,
                      borderSide: const BorderSide(color: SwCheckout.ink),
                    ),
                  ),
                  onSubmitted: (_) => _pakaiKodeManual(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: _memeriksaKode ? null : _pakaiKodeManual,
                style: OutlinedButton.styleFrom(
                  foregroundColor: SwCheckout.ink,
                  side: const BorderSide(color: SwCheckout.line),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
                ),
                child: _memeriksaKode
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Pakai',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        if (_pesanVoucher != null) ...[
          const SizedBox(height: 7),
          Text(
            _pesanVoucher!,
            style: GoogleFonts.spaceGrotesk(
              color: _voucherSah ? SwCheckout.greenDark : SwCheckout.warning,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  @override
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
                      ? SwCheckout.aksi.withValues(alpha: 0.08)
                      : SwCheckout.bg,
                  borderRadius: AppRadius.rMd,
                  border: Border.all(
                    color: selected ? SwCheckout.aksi : SwCheckout.line,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? SwCheckout.aksi : SwCheckout.muted,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.$2,
                      style: GoogleFonts.spaceGrotesk(
                        color: selected ? SwCheckout.ink : SwCheckout.sub,
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
                        strokeWidth: 2, color: SwCheckout.btnFg),
                  )
                : const Icon(Icons.account_balance, size: 20),
            label: Text(
              _methodLoading ? 'Membuat VA...' : 'Generate VA',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.rMd,
              ),
            ),
          ),
        )
      else ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SwCheckout.chip,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: SwCheckout.line),
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
                      color: SwCheckout.sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: SwCheckout.aksi.withValues(alpha: 0.10),
                      borderRadius: AppRadius.rXs,
                    ),
                    child: Text(
                      (_vaBank ?? _selectedBank).toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        color: SwCheckout.greenDark,
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
                  color: SwCheckout.ink,
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
                    color: SwCheckout.muted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _vaExpiresAt == null
                      ? const Icon(Icons.access_time,
                          size: 14, color: SwCheckout.warning)
                      : CountdownRing(
                          expiresAt: _vaExpiresAt!,
                          total: const Duration(hours: 24),
                          size: 30,
                          strokeWidth: 3,
                          showLabel: false,
                          trackColor: SwCheckout.line,
                          onExpired: _onVaExpired,
                        ),
                  const SizedBox(width: 8),
                  Text(
                    'Bayar dalam ${_formatVaCountdown(_vaRemaining)}',
                    style: GoogleFonts.spaceGrotesk(
                      color: SwCheckout.warning,
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
                  foregroundColor: SwCheckout.ink,
                  side: const BorderSide(color: SwCheckout.ink),
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.rSm,
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
            color: SwCheckout.chip,
            borderRadius: AppRadius.rSm,
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: SwCheckout.sub),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transfer ke nomor VA di atas via ATM / m-banking. Status terverifikasi otomatis.',
                  style: GoogleFonts.spaceGrotesk(
                      color: SwCheckout.sub, fontSize: 11),
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

  @override
  List<Widget> _buildCardForm() {
    return [
      _sectionTitle('Data Kartu'),
      const SizedBox(height: 12),
      TextFormField(
        controller: _cardNumberCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [CardNumberFormatter()],
        decoration: _whiteInput('Nomor Kartu', icon: Icons.credit_card),
        style: GoogleFonts.spaceGrotesk(color: SwCheckout.ink, fontSize: 14),
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
              inputFormatters: [ExpiryFormatter()],
              decoration: _whiteInput('MM/YY'),
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.ink, fontSize: 14),
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
                  GoogleFonts.spaceGrotesk(color: SwCheckout.ink, fontSize: 14),
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
              activeColor: SwCheckout.aksi,
              checkColor: SwCheckout.ink,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.rXs),
              side: const BorderSide(color: SwCheckout.line),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Simpan kartu untuk pembelian berikutnya',
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          const Icon(Icons.lock_outline, size: 14, color: SwCheckout.greenDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Pembayaran diproses oleh Midtrans, penyedia pembayaran berlisensi.',
              style:
                  GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 11),
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

  @override
  List<Widget> _buildGoPayForm(String currentUserId) {
    return [
      _sectionTitle('Pembayaran GoPay'),
      const SizedBox(height: 6),
      Text(
        'Pembayaran akan diproses melalui GoPay. Pastikan nomor HP kamu terhubung dengan akun GoPay.',
        style: GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 13),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SwCheckout.chip,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: SwCheckout.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_android_rounded,
                color: SwCheckout.aksi, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor GoPay',
                    style: GoogleFonts.spaceGrotesk(
                        color: SwCheckout.muted, fontSize: 11),
                  ),
                  Text(
                    _teleponCtrl.text,
                    style: GoogleFonts.spaceGrotesk(
                        color: SwCheckout.ink,
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
                        strokeWidth: 2, color: SwCheckout.btnFg))
                : const Icon(Icons.wallet, size: 20),
            label: Text(
              _methodLoading ? 'Memproses...' : 'Bayar dengan GoPay',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.rMd),
            ),
          ),
        )
      else ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _qrExpiresAt == null
                ? const Icon(Icons.timer_outlined,
                    size: 16, color: SwCheckout.warning)
                : CountdownRing(
                    expiresAt: _qrExpiresAt!,
                    total: const Duration(minutes: 5),
                    size: 32,
                    strokeWidth: 3,
                    showLabel: false,
                    trackColor: SwCheckout.line,
                    onExpired: _onQrExpired,
                  ),
            const SizedBox(width: 8),
            Text(
              'Bayar dalam ${_formatQrCountdown(_qrRemaining)}',
              style: GoogleFonts.spaceGrotesk(
                  color: SwCheckout.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SwCheckout.chip,
            borderRadius: AppRadius.rLg,
            border: Border.all(color: SwCheckout.green),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: SwCheckout.green, size: 48),
              const SizedBox(height: 12),
              Text(
                'Menunggu Pembayaran',
                style: GoogleFonts.rajdhani(
                    color: SwCheckout.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Buka aplikasi GoPay di nomor $_gopayPhone untuk menyelesaikan pembayaran.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  @override
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
        style: GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 13),
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
                        strokeWidth: 2, color: SwCheckout.btnFg),
                  )
                : Icon(isGoPay ? Icons.wallet : Icons.qr_code, size: 20),
            label: Text(
              _methodLoading ? 'Membuat QR...' : 'Tampilkan QR $label',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.rMd,
              ),
            ),
          ),
        )
      else ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _qrExpiresAt == null
                ? const Icon(Icons.timer_outlined,
                    size: 16, color: SwCheckout.warning)
                : CountdownRing(
                    expiresAt: _qrExpiresAt!,
                    total: const Duration(minutes: 5),
                    size: 32,
                    strokeWidth: 3,
                    showLabel: false,
                    trackColor: SwCheckout.line,
                    onExpired: _onQrExpired,
                  ),
            const SizedBox(width: 8),
            Text(
              'Bayar dalam ${_formatQrCountdown(_qrRemaining)}',
              style: GoogleFonts.spaceGrotesk(
                color: SwCheckout.warning,
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
            color: SwCheckout.bg,
            borderRadius: AppRadius.rLg,
            border: Border.all(color: SwCheckout.line),
          ),
          child: QrImageView(
            data: _qrString!,
            version: QrVersions.auto,
            size: 220,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: SwCheckout.ink,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: SwCheckout.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isGoPay
              ? 'Scan QR dengan aplikasi GoPay'
              : 'Scan dengan e-wallet atau m-banking',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (_paymentDetected) _detectedBanner(),
      ],
    ];
  }
}
