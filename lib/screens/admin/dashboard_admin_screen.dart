import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/konser_model.dart';
import '../../models/pesanan_tiket_model.dart';
import '../../models/tiket_konser_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/ringkasan_admin.dart';

/// Halaman pertama yang dilihat operator setelah login.
///
/// Menjawab tiga pertanyaan sekaligus: berapa yang masuk, apa yang perlu
/// ditangani sekarang, dan konser terdekat sudah terjual berapa. Semua angka
/// dihitung dari provider yang sudah streaming, tanpa query Firestore baru.
class DashboardAdminScreen extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onBukaSidebar;
  final void Function(String labelMenu) onBukaMenu;

  const DashboardAdminScreen({
    super.key,
    required this.user,
    required this.onBukaSidebar,
    required this.onBukaMenu,
  });

  static const List<String> _namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final tiketAsync = ref.watch(allTicketsProvider);
    final pesananAsync = ref.watch(allOrdersProvider);

    final daftarKonser = eventsAsync.valueOrNull ?? const <KonserModel>[];
    final daftarTiket = tiketAsync.valueOrNull ?? const <TiketKonserModel>[];
    final daftarPesanan =
        pesananAsync.valueOrNull ?? const <PesananTiketModel>[];

    final ringkasan = hitungRingkasan(
      pesanan: daftarPesanan,
      tiket: daftarTiket,
    );

    final memuat = eventsAsync.isLoading ||
        tiketAsync.isLoading ||
        pesananAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopbar(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceLight,
                onRefresh: () async {
                  ref.invalidate(eventsProvider);
                  ref.invalidate(allTicketsProvider);
                  ref.invalidate(allOrdersProvider);
                  await Future<void>.delayed(
                    const Duration(milliseconds: 600),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: [
                    _buildSapaan(),
                    const SizedBox(height: 18),
                    _buildKpi(ringkasan, memuat),
                    const SizedBox(height: 22),
                    _bagian('PENJUALAN 7 HARI TERAKHIR'),
                    const SizedBox(height: 10),
                    _buildGrafik(ringkasan, memuat),
                    const SizedBox(height: 22),
                    _bagian('PERLU TINDAKAN'),
                    const SizedBox(height: 10),
                    _buildPerluTindakan(ringkasan, memuat),
                    const SizedBox(height: 22),
                    _bagian('KONSER TERDEKAT'),
                    const SizedBox(height: 10),
                    _buildKonserTerdekat(daftarKonser, daftarTiket),
                    const SizedBox(height: 22),
                    _bagian('JALAN PINTAS'),
                    const SizedBox(height: 10),
                    _buildJalanPintas(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Topbar

  Widget _buildTopbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBukaSidebar,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Expanded (bukan Spacer) supaya judul yang menyusut lebih dulu
          // ketika layar sempit — badge ADMIN tidak boleh terpotong.
          Expanded(
            child: Text(
              'Dashboard',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'ADMIN',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSapaan() {
    final kini = DateTime.now();
    final namaDepan = user.nama.trim().isEmpty
        ? 'Admin'
        : user.nama.trim().split(' ').first;
    final jam = kini.hour;
    final salam = jam < 11
        ? 'Selamat pagi'
        : jam < 15
            ? 'Selamat siang'
            : jam < 19
                ? 'Selamat sore'
                : 'Selamat malam';
    final tanggal =
        '${_namaHari[kini.weekday - 1]}, ${kini.day} ${_namaBulan[kini.month - 1]} ${kini.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$salam, $namaDepan',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tanggal,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // KPI

  Widget _buildKpi(RingkasanAdmin r, bool memuat) {
    final kartu = [
      _KartuKpi(
        label: 'Pendapatan',
        nilai: memuat ? '—' : _rupiah(r.pendapatan),
        catatan: memuat ? null : '${r.tiketTerjual} tiket lunas',
        ikon: Icons.account_balance_wallet_outlined,
        aksen: AppColors.success,
      ),
      _KartuKpi(
        label: 'Tiket terjual',
        nilai: memuat ? '—' : '${r.tiketTerjual}',
        catatan: memuat ? null : '${r.totalPesanan} total pesanan',
        ikon: Icons.confirmation_number_outlined,
        aksen: AppColors.primary,
      ),
      _KartuKpi(
        label: 'Menunggu bayar',
        nilai: memuat ? '—' : '${r.menungguBayar}',
        catatan: memuat
            ? null
            : r.hampirKedaluwarsa > 0
                ? '${r.hampirKedaluwarsa} hampir kedaluwarsa'
                : 'tidak ada yang mendesak',
        ikon: Icons.schedule_rounded,
        aksen: AppColors.warning,
      ),
      _KartuKpi(
        label: 'Refund ditinjau',
        nilai: memuat ? '—' : '${r.refundPerluTinjauan}',
        catatan: memuat ? null : 'stok kritis: ${r.stokKritis}',
        ikon: Icons.undo_rounded,
        aksen: AppColors.error,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: kartu,
    );
  }

  // Grafik

  Widget _buildGrafik(RingkasanAdmin r, bool memuat) {
    final maxNilai = r.penjualanHarian.fold<double>(
      0,
      (p, e) => e > p ? e : p,
    );
    final maxY = (maxNilai * 1.25).ceilToDouble().clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  memuat ? 'memuat…' : _rupiah(r.rataHarian),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'rata-rata / hari',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          _ringkasNominal(value),
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i < 0 || i >= r.hari.length) {
                          return const SizedBox();
                        }
                        final label =
                            _namaHari[r.hari[i].weekday - 1].substring(0, 3);
                        final iniHariIni = i == r.hari.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: GoogleFonts.spaceGrotesk(
                              color: iniHariIni
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: iniHariIni
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(r.penjualanHarian.length, (i) {
                  final iniHariIni = i == r.penjualanHarian.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: r.penjualanHarian[i],
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                        color: iniHariIni
                            ? AppColors.success
                            : AppColors.success.withValues(alpha: 0.35),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Perlu tindakan

  Widget _buildPerluTindakan(RingkasanAdmin r, bool memuat) {
    if (memuat) {
      return _kartuKosong('Memuat data…');
    }
    if (r.tenang) {
      return _kartuKosong('Tidak ada yang perlu ditangani. Semua beres.');
    }

    final baris = <Widget>[];

    if (r.refundPerluTinjauan > 0) {
      baris.add(_barisTindakan(
        ikon: Icons.undo_rounded,
        warna: AppColors.error,
        judul: '${r.refundPerluTinjauan} refund menunggu keputusan',
        sub: 'Tinjau pengajuan dari penonton',
        tujuan: 'Kelola Refund',
      ));
    }
    if (r.hampirKedaluwarsa > 0) {
      baris.add(_barisTindakan(
        ikon: Icons.timer_outlined,
        warna: AppColors.warning,
        judul: '${r.hampirKedaluwarsa} pesanan hampir kedaluwarsa',
        sub: 'Sisa waktu bayar kurang dari 10 menit',
        tujuan: 'Laporan Penjualan',
      ));
    }
    if (r.stokKritis > 0) {
      baris.add(_barisTindakan(
        ikon: Icons.inventory_2_outlined,
        warna: AppColors.warning,
        judul: '${r.stokKritis} kategori tiket stok kritis',
        sub: 'Sisa kuota 10 atau kurang',
        tujuan: 'Tiket',
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < baris.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
            baris[i],
          ],
        ],
      ),
    );
  }

  Widget _barisTindakan({
    required IconData ikon,
    required Color warna,
    required String judul,
    required String sub,
    required String tujuan,
  }) {
    return InkWell(
      onTap: () => onBukaMenu(tujuan),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(ikon, color: warna, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Konser terdekat

  Widget _buildKonserTerdekat(
    List<KonserModel> daftarKonser,
    List<TiketKonserModel> daftarTiket,
  ) {
    final kini = DateTime.now();
    final akanDatang = daftarKonser
        .where((k) => k.tanggal.isAfter(kini))
        .toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    if (akanDatang.isEmpty) {
      return _kartuKosong('Belum ada konser mendatang.');
    }

    final tampil = akanDatang.take(3).toList();

    return Column(
      children: [
        for (final k in tampil) ...[
          _kartuKonser(k, daftarTiket),
          if (k != tampil.last) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _kartuKonser(KonserModel konser, List<TiketKonserModel> daftarTiket) {
    final tiketKonser =
        daftarTiket.where((t) => t.idKonser == konser.id).toList();
    final kuota = tiketKonser.fold<int>(0, (p, t) => p + t.stok + t.terjual);
    final terjual = tiketKonser.fold<int>(0, (p, t) => p + t.terjual);
    final persen = kuota == 0 ? 0.0 : (terjual / kuota).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  konser.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(persen * 100).round()}%',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${konser.lokasi} · ${konser.tanggal.day}/${konser.tanggal.month}/${konser.tanggal.year}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: persen,
              minHeight: 5,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kuota == 0
                ? 'Kuota belum diisi'
                : '$terjual terjual dari $kuota tiket',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Jalan pintas

  Widget _buildJalanPintas() {
    return Row(
      children: [
        Expanded(
          child: _tombolPintas(
            Icons.qr_code_scanner_rounded,
            'Scan Gate',
            'Validasi Gate (Scan)',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tombolPintas(
            Icons.add_rounded,
            'Konser',
            'Konser',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tombolPintas(
            Icons.analytics_outlined,
            'Laporan',
            'Laporan Penjualan',
          ),
        ),
      ],
    );
  }

  Widget _tombolPintas(IconData ikon, String label, String tujuan) {
    return InkWell(
      onTap: () => onBukaMenu(tujuan),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(ikon, color: AppColors.textPrimary, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper judul bagian.

  Widget _bagian(String judul) {
    return Text(
      judul,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _kartuKosong(String teks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        teks,
        style: GoogleFonts.spaceGrotesk(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  String _rupiah(double nominal) {
    final angka = nominal.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < angka.length; i++) {
      if (i > 0 && (angka.length - i) % 3 == 0) buf.write('.');
      buf.write(angka[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  String _ringkasNominal(double nominal) {
    if (nominal >= 1000000) {
      final juta = nominal / 1000000;
      return '${juta.toStringAsFixed(juta >= 10 ? 0 : 1)}jt';
    }
    if (nominal >= 1000) return '${(nominal / 1000).round()}rb';
    return nominal.toStringAsFixed(0);
  }
}

class _KartuKpi extends StatelessWidget {
  final String label;
  final String nilai;
  final String? catatan;
  final IconData ikon;
  final Color aksen;

  const _KartuKpi({
    required this.label,
    required this.nilai,
    required this.ikon,
    required this.aksen,
    this.catatan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Icon(ikon, color: aksen, size: 15),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nilai,
              maxLines: 1,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (catatan != null) ...[
            const SizedBox(height: 2),
            Text(
              catatan!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted,
                fontSize: 9.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
