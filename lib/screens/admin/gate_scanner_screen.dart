import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/pesanan_tiket_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';

class GateScannerScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback? onBukaSidebar;

  const GateScannerScreen({
    super.key,
    required this.user,
    this.onBukaSidebar,
  });

  @override
  ConsumerState<GateScannerScreen> createState() => _GateScannerScreenState();
}

class _GateScannerScreenState extends ConsumerState<GateScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  final _kodeCtrl = TextEditingController();
  late final TabController _tabController;

  Map<String, dynamic>? _hasilValidasi;
  bool _validating = false;
  bool _isTorchOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  DateTime? _lastScanTime;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _kodeCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_validating) return;

    final now = DateTime.now();
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) continue;

      // Abaikan kode yang sama dalam 2,5 detik.
      if (_lastScannedCode == code &&
          _lastScanTime != null &&
          now.difference(_lastScanTime!).inMilliseconds < 2500) {
        continue;
      }

      _lastScannedCode = code;
      _lastScanTime = now;

      // Getar saat kode terdeteksi.
      HapticFeedback.selectionClick();
      _prosesValidasi(code);
      break;
    }
  }

  Future<void> _prosesValidasi(String kode) async {
    final clean = kode.trim();
    if (clean.isEmpty) return;

    setState(() {
      _validating = true;
      _hasilValidasi = null;
    });

    try {
      final db = ref.read(databaseServiceProvider);
      final hasil = await db.validateGateTicket(clean);

      if (!mounted) return;

      final isSuccess = hasil['ok'] == true;
      final pesan = (hasil['message'] ?? '') as String;
      final tiket = hasil['order'] as PesananTiketModel?;

      if (isSuccess) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }

      final isOffline = hasil['isOffline'] == true;

      setState(() {
        _validating = false;
        _hasilValidasi = {
          'sukses': isSuccess,
          'pesan': pesan,
          'tiket': tiket,
          'kode': clean,
          'waktu': DateTime.now(),
          'isOffline': isOffline,
        };
      });

      // Tampilkan hasil pindai seketika.
      _showResultBottomSheet();
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _validating = false;
        _hasilValidasi = {
          'sukses': false,
          'pesan': 'Error validasi: $e',
          'tiket': null,
          'kode': clean,
          'waktu': DateTime.now(),
          'isOffline': false,
        };
      });
      _showResultBottomSheet();
    }
  }

  void _showResultBottomSheet() {
    if (_hasilValidasi == null) return;
    final isSuccess = _hasilValidasi!['sukses'] as bool;
    final pesan = _hasilValidasi!['pesan'] as String;
    final tiket = _hasilValidasi!['tiket'] as PesananTiketModel?;
    final kode = _hasilValidasi!['kode'] as String;
    final isOffline = _hasilValidasi!['isOffline'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final color = isSuccess ? AppColors.success : AppColors.error;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isOffline)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MODE OFFLINE: Tanda tangan kriptografis valid & belum discan pada gate ini.',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: color,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSuccess ? 'AKSES DIIZINKAN (PASS)' : 'AKSES DITOLAK (DENIED)',
                          style: GoogleFonts.rajdhani(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          pesan,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider, height: 28),
              if (tiket != null) ...[
                _buildInfoRow('Kode Booking', tiket.kodeBooking),
                _buildInfoRow('Konser', tiket.judulKonser),
                _buildInfoRow('Kategori', tiket.kategoriTiket),
                _buildInfoRow('Pemegang', '${tiket.namaPembeli} (${tiket.jumlahTiket} Orang)'),
                _buildInfoRow('Status Saat Ini', tiket.status),
              ] else ...[
                _buildInfoRow('Kode Dipindai', kode),
                _buildInfoRow('Hasil', 'Tiket tidak ditemukan di database'),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'LANJUTKAN SCAN BERIKUTNYA',
                    style: GoogleFonts.rajdhani(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'VALIDASI GATE (LIVE SCANNER)',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        leading: widget.onBukaSidebar != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: widget.onBukaSidebar,
              )
            : null,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt_outlined), text: 'Kamera Scanner'),
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Input & List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCameraView(),
          _buildManualAndListView(),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        Positioned.fill(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: AppColors.error, size: 54),
                      const SizedBox(height: 16),
                      Text(
                        'Kamera tidak aktif atau izin ditolak',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan izin kamera telah diberikan di pengaturan perangkat.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Positioned.fill(
          child: CustomPaint(
            painter: _ScannerOverlayPainter(),
          ),
        ),

        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Arahkan QR tiket ke kotak bidik',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isTorchOn ? AppColors.warnaHarga : Colors.white,
                      ),
                      onPressed: () async {
                        await _scannerController.toggleTorch();
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      },
                      tooltip: 'Toggle Flash',
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                      onPressed: () async {
                        await _scannerController.switchCamera();
                        setState(() {
                          _cameraFacing = _cameraFacing == CameraFacing.back
                              ? CameraFacing.front
                              : CameraFacing.back;
                        });
                      },
                      tooltip: 'Ganti Kamera',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (_validating)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Memverifikasi Tiket...',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildManualAndListView() {
    final ordersAsync = ref.watch(allOrdersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INPUT MANUAL KODE BOOKING',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gunakan jika kamera bermasalah atau layar ponsel pembeli rusak/pecah.',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _kodeCtrl,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: SW-2026-8812',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _validating
                          ? null
                          : () => _prosesValidasi(_kodeCtrl.text),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(90, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _validating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Validasi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'DAFTAR TIKET TERKINI (FIRESTORE)',
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ordersAsync.when(
            data: (listPesanan) {
              if (listPesanan.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Belum ada tiket pesanan di database.',
                      style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                    ),
                  ),
                );
              }

              return Column(
                children: listPesanan.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: p.isAktif
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            p.isAktif
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            color: p.isAktif ? AppColors.success : AppColors.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.kodeBooking,
                                style: GoogleFonts.rajdhani(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '${p.namaPembeli} • ${p.judulKonser} (${p.kategoriTiket})',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Status: ${p.status}',
                                style: GoogleFonts.spaceGrotesk(
                                  color: p.isAktif
                                      ? AppColors.success
                                      : p.isTerpakai
                                          ? AppColors.textMuted
                                          : AppColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _kodeCtrl.text = p.kodeBooking;
                            _prosesValidasi(p.kodeBooking);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.textPrimary,
                            minimumSize: const Size(60, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: Text(
                            'Scan',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text(
              'Gagal memuat pesanan: $e',
              style: GoogleFonts.spaceGrotesk(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the viewport cutout and the corner targeting brackets.
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanAreaSize = 260.0;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2.2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));

    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, backgroundPaint);

    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 28.0;

    canvas.drawLine(Offset(scanRect.left, scanRect.top + cornerLength), Offset(scanRect.left, scanRect.top), cornerPaint);
    canvas.drawLine(Offset(scanRect.left, scanRect.top), Offset(scanRect.left + cornerLength, scanRect.top), cornerPaint);

    canvas.drawLine(Offset(scanRect.right - cornerLength, scanRect.top), Offset(scanRect.right, scanRect.top), cornerPaint);
    canvas.drawLine(Offset(scanRect.right, scanRect.top), Offset(scanRect.right, scanRect.top + cornerLength), cornerPaint);

    canvas.drawLine(Offset(scanRect.left, scanRect.bottom - cornerLength), Offset(scanRect.left, scanRect.bottom), cornerPaint);
    canvas.drawLine(Offset(scanRect.left, scanRect.bottom), Offset(scanRect.left + cornerLength, scanRect.bottom), cornerPaint);

    canvas.drawLine(Offset(scanRect.right - cornerLength, scanRect.bottom), Offset(scanRect.right, scanRect.bottom), cornerPaint);
    canvas.drawLine(Offset(scanRect.right, scanRect.bottom), Offset(scanRect.right, scanRect.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
