import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/pesanan_tiket_model.dart';
import '../../utils/app_theme.dart';

/// Invoice or receipt for a ticket purchase, built from [tiket].
///
/// The invoice number follows INV-SW-{year}-{kodeBooking}.
class InvoiceScreen extends StatelessWidget {
  final PesananTiketModel tiket;

  const InvoiceScreen({super.key, required this.tiket});

  String get _invoiceNumber =>
      'INV-SW-${tiket.tanggalBeli.year}-${tiket.kodeBooking}';

  String _formatRupiah(double nominal) {
    final formatted = nominal
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  String _formatTanggal(DateTime t) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${t.day.toString().padLeft(2, '0')} ${bulan[t.month - 1]} ${t.year}';
  }

  // Tax-inclusive: DPP = total / 1.11, PPN = total - DPP.
  double get _dpp => tiket.totalHarga / 1.11;
  double get _ppn => tiket.totalHarga - _dpp;
  double get _hargaSatuan =>
      tiket.jumlahTiket == 0 ? 0 : tiket.totalHarga / tiket.jumlahTiket;

  String _buildInvoiceText() {
    final lines = <String>[
      '═══════════════════════════════════',
      '            SOUNDWAVE',
      '            INVOICE',
      '═══════════════════════════════════',
      'No. Invoice  : $_invoiceNumber',
      'Kode Booking : ${tiket.kodeBooking}',
      'Tanggal      : ${_formatTanggal(tiket.tanggalBeli)}',
      '───────────────────────────────────',
      'Pembeli:',
      '  Nama    : ${tiket.namaPembeli}',
      '  Email   : ${tiket.emailPembeli}',
      if (tiket.teleponPembeli != null) '  Telepon : ${tiket.teleponPembeli}',
      '───────────────────────────────────',
      'Item:',
      '  ${tiket.judulKonser}',
      '  Kategori : ${tiket.kategoriTiket}',
      '  Jumlah   : ${tiket.jumlahTiket} lembar',
      '  Harga    : ${_formatRupiah(_hargaSatuan)} x ${tiket.jumlahTiket}',
      '───────────────────────────────────',
      'Subtotal (DPP) : ${_formatRupiah(_dpp)}',
      'PPN 11%        : ${_formatRupiah(_ppn)}',
      'TOTAL          : ${_formatRupiah(tiket.totalHarga)}',
      '───────────────────────────────────',
      'Metode Bayar   : ${tiket.metodePembayaran ?? '-'}',
      'Status         : ${tiket.status}',
      '═══════════════════════════════════',
      'Terima kasih telah berbelanja di Soundwave!',
    ];
    return lines.join('\n');
  }

  Future<void> _share(BuildContext context) async {
    await Share.share(
      _buildInvoiceText(),
      subject: 'Invoice $_invoiceNumber - Soundwave',
    );
  }

  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$_invoiceNumber.txt');
      await file.writeAsString(_buildInvoiceText());
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice $_invoiceNumber - Soundwave',
      );
    } catch (e) {
      // Fallback: salin teks ke clipboard jika simpan berkas gagal.
      await Clipboard.setData(ClipboardData(text: _buildInvoiceText()));
      messenger.showSnackBar(
        SnackBar(
          content: Text('Invoice disalin ke clipboard',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Hindari unused warning.
      navigator.canPop();
    }
  }

  Color get _statusColor {
    if (tiket.isAktif) return AppColors.success;
    if (tiket.isPending) return AppColors.warning;
    if (tiket.isCancelled || tiket.isExpired) return AppColors.error;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'INVOICE',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInvoiceCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _download(context),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('Download',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warnaTombolBg,
                      foregroundColor: AppColors.warnaTombolTeks,
                      minimumSize: const Size.fromHeight(50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text('Share',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size.fromHeight(50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                  bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOUNDWAVE',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _invoiceNumber,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.warnaHarga,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('INFORMASI PEMBELI'),
                const SizedBox(height: 8),
                _infoRow('Nama', tiket.namaPembeli),
                _infoRow('Email', tiket.emailPembeli),
                if (tiket.teleponPembeli != null)
                  _infoRow('Telepon', tiket.teleponPembeli!),
                const SizedBox(height: 16),
                _sectionTitle('DETAIL PESANAN'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _tableHeader(),
                      const Divider(
                          color: AppColors.divider, height: 16),
                      _tableRow(
                        tiket.judulKonser,
                        tiket.kategoriTiket,
                        '${tiket.jumlahTiket}x',
                        _formatRupiah(_hargaSatuan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle('RINCIAN PEMBAYARAN'),
                const SizedBox(height: 8),
                _amountRow('Subtotal (DPP)', _formatRupiah(_dpp)),
                _amountRow('PPN 11%', _formatRupiah(_ppn)),
                const Divider(
                    color: AppColors.divider, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        )),
                    Text(_formatRupiah(tiket.totalHarga),
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.warnaHarga,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                _statusBadge(),
                const SizedBox(height: 10),
                _infoRow(
                    'Metode Bayar', tiket.metodePembayaran ?? '-'),
                _infoRow('Tanggal Beli', _formatTanggal(tiket.tanggalBeli)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return const Row(
      children: [
        Expanded(
            flex: 4, child: _TableHeaderCell('ITEM')),
        Expanded(
            flex: 2, child: _TableHeaderCell('JUMLAH')),
        Expanded(
            flex: 3, child: _TableHeaderCell('HARGA', alignRight: true)),
      ],
    );
  }

  Widget _tableRow(
      String item, String kategori, String jumlah, String harga) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(kategori,
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(jumlah,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary, fontSize: 12)),
        ),
        Expanded(
          flex: 3,
          child: Text(harga,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _amountRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary, fontSize: 12)),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Status',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary, fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tiket.status,
            style: GoogleFonts.spaceGrotesk(
              color: _statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final bool alignRight;
  const _TableHeaderCell(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}
