import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../models/refund_model.dart';
import '../../services/midtrans_service.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';

/// Admin screen untuk mengelola permintaan refund.
/// Stream dari koleksi Firestore `refunds` (orderBy tanggalRequest desc).
/// Approve/Reject memanggil endpoint backend (`/admin/refund/approve` &
/// `/admin/refund/reject`). Backend adalah SATU-SATUNYA sumber kebenaran:
/// ia mengubah `refunds.status`, `orders.status`, dan stok tiket sekaligus.
/// Pengembalian uang dilakukan MANUAL oleh admin (tidak lewat Midtrans).
class KelolaRefundScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback? onBukaSidebar;
  const KelolaRefundScreen({super.key, required this.user, this.onBukaSidebar});

  @override
  ConsumerState<KelolaRefundScreen> createState() =>
      _KelolaRefundScreenState();
}

class _KelolaRefundScreenState extends ConsumerState<KelolaRefundScreen> {
  String _filter = 'SEMUA'; // SEMUA | PENDING | APPROVED | REJECTED
  final _alasanCtrl = TextEditingController();
  bool _processing = false;

  static const _filters = ['SEMUA', 'PENDING', 'APPROVED', 'REJECTED'];

  @override
  void dispose() {
    _alasanCtrl.dispose();
    super.dispose();
  }

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
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Approve refund lewat BACKEND (satu-satunya sumber kebenaran).
  ///
  /// Backend yang mengubah `refunds.status = APPROVED`,
  /// `orders.status = REFUNDED`, dan memulihkan stok tiket (bila tiket belum
  /// pernah discan). Pengembalian uang dilakukan MANUAL oleh admin
  /// (tidak lewat Midtrans).
  Future<void> _approveRefund(RefundModel refund) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final baseUrl = await MidtransService.getBackendUrl();
      final res = await http
          .post(
            Uri.parse('$baseUrl/admin/refund/approve'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'refundId': refund.id,
              'orderId': refund.orderId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = res.body.isNotEmpty
          ? (jsonDecode(res.body) as Map<String, dynamic>)
          : <String, dynamic>{};
      if (res.statusCode != 200 || body['success'] != true) {
        throw Exception(
            body['message'] ?? 'Backend menolak (HTTP ${res.statusCode})');
      }

      final stokNote =
          body['stokDipulihkan'] == true ? ' · stok tiket dikembalikan' : '';
      _toast('Refund disetujui$stokNote — dana dikembalikan manual',
          AppColors.success);
    } catch (e) {
      _toast(
        'Gagal menyetujui refund: ${e.toString().replaceFirst('Exception: ', '')}',
        AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Reject refund: tampilkan dialog input alasan, lalu panggil endpoint
  /// backend refund dan update Firestore dengan status REJECTED.
  Future<void> _rejectRefund(RefundModel refund) async {
    if (_processing) return;
    _alasanCtrl.clear();

    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Tolak Refund',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refund ${refund.kodeBooking}',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _alasanCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan...',
                hintStyle:
                    GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Batal',
                style:
                    GoogleFonts.spaceGrotesk(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, _alasanCtrl.text.trim()),
            child: Text('Tolak Refund',
                style: GoogleFonts.spaceGrotesk(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (alasan == null || alasan.isEmpty) {
      _toast('Alasan penolakan wajib diisi', AppColors.warning);
      return;
    }

    setState(() => _processing = true);
    try {
      final baseUrl = await MidtransService.getBackendUrl();
      final res = await http
          .post(
            Uri.parse('$baseUrl/admin/refund/reject'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'refundId': refund.id,
              'alasanReject': alasan,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final body = res.body.isNotEmpty
          ? (jsonDecode(res.body) as Map<String, dynamic>)
          : <String, dynamic>{};
      if (res.statusCode != 200 || body['success'] != true) {
        throw Exception(
            body['message'] ?? 'Backend menolak (HTTP ${res.statusCode})');
      }

      _toast('Refund ditolak — tiket kembali aktif & bisa discan',
          AppColors.warning);
    } catch (e) {
      _toast(
        'Gagal menolak refund: ${e.toString().replaceFirst('Exception: ', '')}',
        AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(widget.onBukaSidebar != null ? Icons.menu_rounded : Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (widget.onBukaSidebar != null) {
              widget.onBukaSidebar!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'KELOLA REFUND',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildRefundList()),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final active = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.warnaTombolBg
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: active
                            ? AppColors.warnaTombolBg
                            : AppColors.divider),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.spaceGrotesk(
                      color: active
                          ? AppColors.warnaTombolTeks
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRefundList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('refunds')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Gagal memuat refund: ${snapshot.error}',
                style: GoogleFonts.spaceGrotesk(color: AppColors.error)),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        var refunds = docs
            .map((d) => RefundModel.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList();
        // Sort client-side (terbaru di atas). Aman meski backend memakai
        // nama field tanggal yang berbeda (createdAt vs tanggalRequest) —
        // menghindari orderBy yang mengeksklusi dokumen tanpa field tsb.
        refunds.sort((a, b) => b.tanggalRequest.compareTo(a.tanggalRequest));
        if (_filter != 'SEMUA') {
          refunds = refunds.where((r) => r.status == _filter).toList();
        }
        if (refunds.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada permintaan refund',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: refunds.length,
          itemBuilder: (context, i) => _buildRefundCard(refunds[i]),
        );
      },
    );
  }

  Widget _buildRefundCard(RefundModel refund) {
    final statusColor = refund.isPending
        ? AppColors.warning
        : (refund.isApproved
            ? AppColors.success
            : AppColors.error);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  refund.kodeBooking,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  refund.status,
                  style: GoogleFonts.spaceGrotesk(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            refund.judulKonser,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _detailRow('Pembeli', refund.namaPembeli),
          _detailRow('Jumlah Tiket', '${refund.jumlahTiket} lembar'),
          _detailRow('Total', _formatRupiah(refund.totalHarga)),
          _detailRow('Diajukan', _formatTanggal(refund.tanggalRequest)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Alasan: ${refund.alasan}',
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          if (refund.isRejected && refund.alasanReject != null) ...[
            const SizedBox(height: 6),
            Text(
              'Alasan tolak: ${refund.alasanReject}',
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.error, fontSize: 12),
            ),
          ],
          if (refund.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _processing ? null : () => _approveRefund(refund),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('Approve',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.warnaTombolTeks,
                      minimumSize: const Size.fromHeight(44),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _processing ? null : () => _rejectRefund(refund),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text('Reject',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.warnaTombolTeks,
                      minimumSize: const Size.fromHeight(44),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textMuted, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
