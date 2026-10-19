import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/pesanan_tiket_model.dart';
import '../../providers/app_providers.dart';
import '../../constants/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gambar_widget.dart';
import '../../widgets/hitung_mundur_teks.dart';
import '../../widgets/kotak_pending_tiket.dart';
import 'invoice_screen.dart';
import 'checkout_screen.dart';
import 'user_konser_detail_screen.dart';

class UserTiketScreen extends ConsumerStatefulWidget {
  const UserTiketScreen({super.key});

  @override
  ConsumerState<UserTiketScreen> createState() => _UserTiketScreenState();
}

class _UserTiketScreenState extends ConsumerState<UserTiketScreen> {
  String _filter = 'SEMUA'; // 'SEMUA','AKTIF','PENDING','TERPAKAI','REFUND'

  @override
  void initState() {
    super.initState();
    _sapuReservasiKedaluwarsa();
  }

  // Minta backend menyapu reservasi yang jendela bayarnya sudah lewat.
  // Hasilnya masuk sendiri lewat stream order.
  Future<void> _sapuReservasiKedaluwarsa() async {
    try {
      await ref.read(midtransServiceProvider).sweepExpired();
    } catch (_) {
      // Diamkan: penyapu backend tetap jalan tiap 30 detik.
    }
  }

  void _bukaDetailTiket(PesananTiketModel tiket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DialogDetailTiket(tiket: tiket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'TIKET SAYA',
            style: GoogleFonts.rajdhani(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Silakan Masuk Terlebih Dahulu',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kamu harus login untuk melihat koleksi tiket konser milikmu.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(userOrdersProvider(currentUserId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'TIKET SAYA',
          style: GoogleFonts.rajdhani(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Tab filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('SEMUA'),
                const SizedBox(width: 6),
                _buildFilterChip('AKTIF'),
                const SizedBox(width: 6),
                _buildFilterChip('PENDING'),
                const SizedBox(width: 6),
                _buildFilterChip('TERPAKAI'),
                const SizedBox(width: 6),
                _buildFilterChip('REFUND'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Daftar tiket
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat e-tiket', style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(userOrdersProvider(currentUserId)),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (orders) {
                final List<PesananTiketModel> filteredList;
                if (_filter == 'AKTIF') {
                  // Tiket yang sedang diproses refund tetap tampil di sini
                  // (badge REFUND DIPROSES) supaya tidak menghilang.
                  filteredList = orders
                      .where((p) => p.isAktif || p.isRefundRequired)
                      .toList();
                } else if (_filter == 'PENDING') {
                  // Pesanan yang waktunya habis tetap tampil: user melihat
                  // status EXPIRED dan bisa langsung memesan ulang.
                  filteredList = orders
                      .where((p) => p.isPending || p.isExpired)
                      .toList();
                } else if (_filter == 'TERPAKAI') {
                  filteredList = orders.where((p) => p.isTerpakai).toList();
                } else if (_filter == 'REFUND') {
                  // Termasuk yang sedang diproses dan yang sudah selesai.
                  filteredList = orders
                      .where((p) => p.isRefundRequired || p.isRefunded)
                      .toList();
                } else {
                  filteredList = orders;
                }

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum Ada E-Tiket',
                          style: GoogleFonts.rajdhani(
                            color: AppColors.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pesan tiket konser favoritmu sekarang!',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filteredList.length,
                  itemBuilder: (ctx, i) {
                    final item = filteredList[i];
                    return _buildKartuTiket(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKartuTiket(PesananTiketModel item) {
    return GestureDetector(
      onTap: () => _bukaDetailTiket(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isAktif
                ? AppColors.warnaHarga.withValues(alpha: 0.4)
                : AppColors.divider,
          ),
          boxShadow: [
            if (item.isAktif)
              BoxShadow(
                color: AppColors.warnaHarga.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          children: [
            // Bagian atas kartu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: GambarWidget(
                        url: item.gambarKonser,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wrap, bukan Row, supaya dua badge turun baris
                        // dan tidak meluber di layar sempit.
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                item.kategoriTiket.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.warnaHarga,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              _buildBadgeGanda(item,
                                  onHabis: _sapuReservasiKedaluwarsa),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.judulKonser,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rajdhani(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.lokasiKonser,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Tanggal pembelian, supaya tiket tidak tertukar.
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Dibeli ${_formatTanggalWaktu(item.tanggalBeli)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Garis putus-putus ala tiket.
            Row(
              children: [
                Container(
                  width: 12,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: List.generate(
                          (constraints.constrainWidth() / 10).floor(),
                          (i) => Expanded(
                            child: Container(
                              color: i.isEven
                                  ? AppColors.divider
                                  : Colors.transparent,
                              height: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 12,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            // Bagian bawah kartu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KODE BOOKING',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.kodeBooking,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'JUMLAH',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.jumlahTiket} Tiket',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Bottom sheet detail tiket, QR, dan aksi pembayaran.
class _DialogDetailTiket extends ConsumerWidget {
  final PesananTiketModel tiket;

  const _DialogDetailTiket({required this.tiket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Status tiket dipantau real-time. Begitu admin memindai QR di gate,
    // status berubah jadi TERPAKAI dan tampilan ini ikut berubah.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionOrders)
          .doc(tiket.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final live =
            (data != null) ? PesananTiketModel.fromMap(data, tiket.id) : tiket;
        return _buildSheet(context, ref, live);
      },
    );
  }

  // Buka wizard pembayaran untuk pesanan yang sudah ada. Tidak membuat
  // pesanan baru, jadi stok hanya dikunci sekali.
  Future<void> _lanjutkanPembayaran(
      BuildContext context, WidgetRef ref, PesananTiketModel tiket) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final idTiket = tiket.idTiket;

    void pesan(String m) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(m, style: GoogleFonts.spaceGrotesk(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (idTiket == null || idTiket.isEmpty) {
      pesan('Data tiket konser tidak lengkap. Hubungi admin.');
      return;
    }

    var dialogTerbuka = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final db = ref.read(databaseServiceProvider);
      final konser = await db.getEventById(tiket.idKonser);
      final tiketKonser = await db.getTicketById(idTiket);
      if (!context.mounted) return;

      if (dialogTerbuka) {
        nav.pop(); // tutup indikator loading
        dialogTerbuka = false;
      }
      if (konser == null || tiketKonser == null) {
        pesan('Data konser atau tiket tidak ditemukan.');
        return;
      }
      nav.pop(); // tutup sheet detail supaya tidak menutupi wizard
      await nav.push(
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            konser: konser,
            tiketDipilih: tiketKonser,
            orderLanjutan: tiket,
          ),
        ),
      );
    } catch (e) {
      if (dialogTerbuka) {
        nav.pop();
        dialogTerbuka = false;
      }
      pesan('Gagal membuka pembayaran: $e');
    }
  }

  // Hitungan waktu menyentuh nol: minta server menyapu pesanan ini supaya
  // statusnya jadi EXPIRED, lalu segarkan daftar tiket.
  Future<void> _sinkronkanKedaluwarsa(
      WidgetRef ref, PesananTiketModel tiket) async {
    try {
      await ref.read(midtransServiceProvider).sweepExpired();
    } catch (_) {
      // Diamkan: penyapu backend tetap berjalan tiap 30 detik.
    }
    ref.invalidate(userOrdersProvider(tiket.userId));
  }

  // Reservasi kedaluwarsa: user diantar kembali ke halaman konser untuk
  // memilih tiket lagi.
  Future<void> _pesanUlang(
      BuildContext context, WidgetRef ref, PesananTiketModel tiket) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final konser =
          await ref.read(databaseServiceProvider).getEventById(tiket.idKonser);
      if (konser == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Data konser tidak ditemukan. Coba lagi nanti.',
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      nav.pop(); // tutup sheet detail
      await nav.push(
        MaterialPageRoute(builder: (_) => UserKonserDetailScreen(konser: konser)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka halaman konser: $e',
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSheet(
      BuildContext context, WidgetRef ref, PesananTiketModel tiket) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gagang sheet
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              tiket.isAktif ? 'E-TIKET MASUK KONSER' : 'STATUS PESANAN',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tiket.judulKonser,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.warnaHarga,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Badge ganda dan catatan penolakan refund. Dibaca dari dokumen
            // ORDER, bukan query ke koleksi refunds: aturan Firestore menolak
            // query tanpa filter userId ("rules are not filters"), jadi versi
            // lama tidak pernah tampil walau datanya ada.
            if (tiket.refundDitolak) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadgeStatus('REFUND_REJECTED'),
                  const SizedBox(width: 8),
                  _buildBadgeStatus(tiket.status),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PENGAJUAN REFUND DITOLAK',
                            style: GoogleFonts.rajdhani(
                              color: AppColors.error,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tiket.alasanRefundDitolak.isEmpty
                                ? 'Tiketmu tetap aktif dan bisa digunakan seperti biasa.'
                                : 'Alasan: ${tiket.alasanRefundDitolak}\n\n'
                                    'Tiketmu tetap aktif dan bisa digunakan seperti biasa.',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (tiket.isAktif || tiket.isTerpakai) ...[
              // Banner bila tiket sudah dipakai di gate.
              if (tiket.isTerpakai) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TIKET BERHASIL DIGUNAKAN',
                              style: GoogleFonts.rajdhani(
                                color: AppColors.success,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Check-in sukses. Selamat menikmati konser!',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Kotak QR, diberi cap bila tiket sudah dipakai.
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: tiket.isTerpakai ? 0.3 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: (tiket.qrPayloadSignature != null &&
                                tiket.qrPayloadSignature!.isNotEmpty)
                            ? tiket.qrPayloadSignature!
                            : tiket.kodeBooking,
                        version: QrVersions.auto,
                        size: 180.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  if (tiket.isTerpakai)
                    Transform.rotate(
                      angle: -0.35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          'SUDAH DIGUNAKAN',
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tiket.isTerpakai
                    ? 'Tiket ini sudah dipindai di gate masuk.'
                    : 'Tunjukkan QR ini ke scanner gate masuk',
                style: GoogleFonts.spaceGrotesk(
                  color:
                      tiket.isTerpakai ? AppColors.error : AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ] else if (tiket.isRefundRequested) ...[
              // Pengajuan refund dari user sedang ditinjau admin.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepOrange),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        color: Colors.deepOrange, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'REFUND SEDANG DITINJAU',
                      style: GoogleFonts.rajdhani(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pengajuan refundmu sudah diterima dan sedang diperiksa admin. Tiket sementara tidak bisa digunakan. Hasilnya (disetujui / ditolak) akan muncul di halaman ini.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else if (tiket.isRefundRequired) ...[
              // Pembayaran masuk setelah reservasi kedaluwarsa.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepOrange),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.currency_exchange_rounded, color: Colors.deepOrange, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Menunggu Pengembalian Dana',
                      style: GoogleFonts.rajdhani(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pembayaran diterima setelah batas reservasi '
                      '${AppConstants.reservationHoldMinutes} menit berakhir '
                      'dan tiket telah habis. Dana Anda aman dan sedang '
                      'diproses untuk refund.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else if (tiket.isRefunded) ...[
              // Refund disetujui: tiket tidak berlaku lagi.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warnaHarga.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warnaHarga),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.task_alt_rounded,
                        color: AppColors.warnaHarga, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'REFUND DISETUJUI',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.warnaHarga,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dana kamu sedang/sudah dikembalikan oleh admin. Tiket ini tidak berlaku lagi dan tidak bisa discan di gate.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else if (tiket.isPending) ...[
              // Satu kotak, dua keadaan: masih ada waktu / waktu sudah habis.
              // Perpindahannya terjadi tepat saat hitungan menyentuh 00:00.
              KotakPendingTiket(
                tiket: tiket,
                onBayar: () => _lanjutkanPembayaran(context, ref, tiket),
                onPesanUlang: () => _pesanUlang(context, ref, tiket),
                onKedaluwarsa: () => _sinkronkanKedaluwarsa(ref, tiket),
              ),
            ] else ...[
              // Kotak status terpakai, kedaluwarsa, atau batal.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Icon(
                      tiket.isTerpakai
                          ? Icons.done_all_rounded
                          : tiket.isExpired
                              ? Icons.timer_off_outlined
                              : Icons.cancel_outlined,
                      color: tiket.isTerpakai
                          ? AppColors.textMuted
                          : AppColors.error,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tiket.isTerpakai
                          ? 'Tiket Telah Digunakan di Gate'
                          : tiket.isExpired
                              ? 'Batas Waktu Reservasi Habis (Kedaluwarsa)'
                              : 'Pesanan Dibatalkan',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Kode booking
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tiket.kodeBooking,
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tiket.kodeBooking));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode booking berhasil disalin'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rincian
            _buildBarisDetail('Kategori', tiket.kategoriTiket),
            _buildBarisDetail('Jumlah', '${tiket.jumlahTiket} Orang'),
            _buildBarisDetail('Atas Nama', tiket.namaPembeli),
            _buildBarisDetail(
                'Dibeli', _formatTanggalWaktu(tiket.tanggalBeli)),
            _buildBarisDetail('Total Bayar', tiket.formatTotalHarga),
            _buildBarisDetail('Status', tiket.status),

            const SizedBox(height: 20),
            Text(
              tiket.isTerpakai
                  ? 'Tiket ini sudah digunakan di gate masuk. Terima kasih! 🎉'
                  : tiket.isAktif
                      ? 'Tunjukkan QR Code ini kepada petugas gate saat masuk venue.'
                      : 'Pesanan ini hanya dapat dipakai di gate setelah berstatus AKTIF.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),

            // Tombol invoice dan refund
            if (tiket.isAktif || tiket.isTerpakai) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceScreen(tiket: tiket),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: Text(
                        'Invoice',
                        style: GoogleFonts.spaceGrotesk(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warnaHarga,
                        side: BorderSide(color: AppColors.warnaHarga.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  // Refund hanya untuk tiket yang masih AKTIF
                  if (tiket.isAktif) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _mintaRefund(context, ref, tiket),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: Text(
                          'Refund',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBarisDetail(String label, String value) {
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
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mintaRefund(BuildContext context, WidgetRef ref, PesananTiketModel tiket) async {
    // Refund paling lambat 3 hari sebelum konser.
    if (tiket.tanggalKonser.difference(DateTime.now()).inDays < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refund hanya bisa diajukan H-3 sebelum konser',
            style: GoogleFonts.spaceGrotesk()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? selected;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Ajukan Refund',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              )),
            content: RadioGroup<String>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih alasan refund:',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  ...['Tidak bisa hadir', 'Salah beli', 'Event dibatalkan', 'Lainnya'].map((a) =>
                    RadioListTile<String>(
                      value: a,
                      title: Text(a,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary, fontSize: 13)),
                      activeColor: AppColors.warnaHarga,
                      dense: true,
                    )),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actions: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    // Batal
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Batal',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Kirim
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selected != null ? () => Navigator.pop(ctx, selected) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warnaHarga,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: AppColors.warnaHarga.withValues(alpha: 0.35),
                          minimumSize: const Size.fromHeight(46),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Kirim',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (alasan == null || !context.mounted) return;

    final midtrans = ref.read(midtransServiceProvider);
    final result = await midtrans.requestRefund(
      orderId: tiket.id,
      userId: tiket.userId,
      alasan: alasan,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Refund diajukan! Tunggu konfirmasi admin.'
              : (result['message'] ?? 'Gagal mengajukan refund'),
          style: GoogleFonts.spaceGrotesk(),
        ),
        backgroundColor: result['success'] == true ? AppColors.warnaHarga : AppColors.error,
      ),
    );

    if (result['success'] == true) {
      Navigator.pop(context);
    }
  }
}

/// Purchase date and time in device local time: "16 Okt 2026 · 16:42".
/// No intl package, so no locale initialization is needed.
String _formatTanggalWaktu(DateTime t) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  final lokal = t.toLocal();
  final jam = lokal.hour.toString().padLeft(2, '0');
  final menit = lokal.minute.toString().padLeft(2, '0');
  return '${lokal.day.toString().padLeft(2, '0')} '
      '${bulan[lokal.month - 1]} ${lokal.year} · $jam:$menit';
}

/// One status badge. When the last refund was rejected, a red REFUND GAGAL
/// badge sits to its left.
Widget _buildBadgeGanda(PesananTiketModel item, {VoidCallback? onHabis}) {
  // Masih punya waktu bayar → satu pill dengan hitungan waktu yang berdetak,
  // supaya sisa waktunya kelihatan langsung dari daftar tiket.
  if (item.isPending && !item.isExpired && item.reservedUntil != null) {
    return _buildBadgeMenunggu(item, onHabis: onHabis);
  }
  final badgeStatus =
      _buildBadgeStatus(item.isExpired ? 'EXPIRED' : item.status);
  if (!item.refundDitolak) return badgeStatus;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildBadgeStatus('REFUND_REJECTED'),
      const SizedBox(width: 6),
      badgeStatus,
    ],
  );
}

/// "MENUNGGU · 02:47" pill whose number ticks every second.
Widget _buildBadgeMenunggu(PesananTiketModel item, {VoidCallback? onHabis}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.amber.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 11, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          'MENUNGGU',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.amber,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        HitungMundurTeks(
          sampai: item.reservedUntil,
          awalan: '· ',
          onHabis: onHabis,
          gaya: GoogleFonts.rajdhani(
            color: Colors.amber,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

Widget _buildBadgeStatus(String status) {
  Color bg;
  Color fg;
  String text;

  if (status == 'AKTIF' || status == 'PAID') {
    bg = AppColors.warnaHarga.withValues(alpha: 0.15);
    fg = AppColors.warnaHarga;
    text = 'AKTIF';
  } else if (status == 'PENDING') {
    bg = Colors.amber.withValues(alpha: 0.15);
    fg = Colors.amber;
    text = 'PENDING';
  } else if (status == 'CANCELLED') {
    bg = AppColors.error.withValues(alpha: 0.15);
    fg = AppColors.error;
    text = 'DIBATALKAN';
  } else if (status == 'EXPIRED') {
    bg = AppColors.error.withValues(alpha: 0.15);
    fg = AppColors.error;
    text = 'KEDALUWARSA';
  } else if (status == 'REFUND_REQUIRED' || status == 'REFUND_REQUESTED') {
    bg = Colors.deepOrange.withValues(alpha: 0.15);
    fg = Colors.deepOrange;
    text = 'REFUND DIPROSES';
  } else if (status == 'REFUND_REJECTED') {
    bg = AppColors.error.withValues(alpha: 0.15);
    fg = AppColors.error;
    text = 'REFUND GAGAL';
  } else if (status == 'REFUNDED') {
    bg = Colors.teal.withValues(alpha: 0.15);
    fg = Colors.teal;
    text = 'DI-REFUND';
  } else if (status == 'TERPAKAI') {
    bg = AppColors.textMuted.withValues(alpha: 0.15);
    fg = AppColors.textMuted;
    text = 'TERPAKAI';
  } else {
    bg = AppColors.textMuted.withValues(alpha: 0.15);
    fg = AppColors.textMuted;
    text = status;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        color: fg,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}
