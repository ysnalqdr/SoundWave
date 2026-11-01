part of '../checkout_screen.dart';

/// Bottom sheet & helper kecil (baris ringkasan, input bergaya putih).
///
/// Dipisahkan dari `checkout_screen.dart` agar berkas utama tidak lagi
/// menampung seluruh layar checkout. Perilaku tidak berubah: mixin ini
/// berada dalam library yang sama (`part of`) dan di-`with` oleh state,
/// sehingga tetap dapat mengakses field, method, serta `setState`.
mixin _CheckoutSheets on _CheckoutBase {
  @override
  void _showCardPayInfo(PesananTiketModel order) {
    final midtrans = ref.read(midtransServiceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SwCheckout.bg,
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
                  color: SwCheckout.line,
                  borderRadius: AppRadius.rXs,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selesaikan Pembayaran',
              style: GoogleFonts.rajdhani(
                color: SwCheckout.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan telah dibuat. Stok tiket berhasil direservasi.',
              style: GoogleFonts.spaceGrotesk(
                color: SwCheckout.sub,
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
                          res['message'] ?? 'Gagal simulasi', SwCheckout.error);
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
                    foregroundColor: SwCheckout.redBright,
                    side: const BorderSide(color: SwCheckout.navy),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rMd,
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
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.rMd,
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

  @override
  void _showWaitingInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SwCheckout.bg,
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
                color: SwCheckout.greenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: SwCheckout.greenDark, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Menunggu pembayaran',
              style: GoogleFonts.rajdhani(
                color: SwCheckout.ink,
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
                color: SwCheckout.sub,
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
                          res['message'] ?? 'Gagal simulasi', SwCheckout.error);
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
                    foregroundColor: SwCheckout.redBright,
                    side: const BorderSide(color: SwCheckout.navy),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rMd,
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
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.rMd,
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

  @override
  Widget _sheetRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(color: SwCheckout.sub, fontSize: 13)),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                color: SwCheckout.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  InputDecoration _whiteInput(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.spaceGrotesk(color: SwCheckout.muted, fontSize: 14),
      floatingLabelStyle:
          GoogleFonts.spaceGrotesk(color: SwCheckout.ink, fontSize: 14),
      filled: true,
      fillColor: SwCheckout.chip,
      prefixIcon:
          icon != null ? Icon(icon, color: SwCheckout.sub, size: 20) : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: const BorderSide(color: SwCheckout.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: const BorderSide(color: SwCheckout.ink, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: const BorderSide(color: SwCheckout.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: const BorderSide(color: SwCheckout.error, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
