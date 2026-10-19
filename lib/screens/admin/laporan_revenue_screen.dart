import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pesanan_tiket_model.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';

/// Dashboard analitik pendapatan.
///
/// Semua angka diagregasi di client dari data yang sudah streaming: orders
/// untuk revenue, events untuk funnel. Grafik memakai fl_chart.
class LaporanRevenueScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback? onBukaSidebar;
  const LaporanRevenueScreen({super.key, required this.user, this.onBukaSidebar});

  @override
  ConsumerState<LaporanRevenueScreen> createState() =>
      _LaporanRevenueScreenState();
}

class _LaporanRevenueScreenState extends ConsumerState<LaporanRevenueScreen> {
  bool _loading = true;
  String? _error;

  double _revToday = 0;
  double _revWeek = 0;
  double _revMonth = 0;

  final List<FlSpot> _dailySpots = [];
  final List<String> _dailyLabels = [];

  final List<MapEntry<String, double>> _topKonser = [];
  final List<MapEntry<String, int>> _metodeEntries = [];

  int _totalViews = 0;
  int _totalCheckout = 0;
  int _totalPaid = 0;

  static const _palette = <Color>[
    AppColors.warnaHarga,
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFFB347),
    Color(0xFFEF5350),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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

  /// Format ringkas untuk sumbu chart (mis. 1,2jt / 450rb).
  String _formatRingkas(double nominal) {
    if (nominal >= 1000000) {
      return '${(nominal / 1000000).toStringAsFixed(1)}jt';
    } else if (nominal >= 1000) {
      return '${(nominal / 1000).toStringAsFixed(0)}rb';
    }
    return nominal.toStringAsFixed(0);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _loadData() async {
    try {
      final fs = FirebaseFirestore.instance;
      final ordersSnap = await fs.collection('orders').get();
      final eventsSnap = await fs.collection('events').get();

      final allOrders = ordersSnap.docs
          .map((d) => PesananTiketModel.fromMap(d.data(), d.id))
          .toList();
      final aktifOrders =
          allOrders.where((o) => o.status == 'AKTIF').toList();

      final now = DateTime.now();
      double revToday = 0, revWeek = 0, revMonth = 0;
      for (final o in aktifOrders) {
        final t = o.tanggalBeli;
        if (_sameDay(t, now)) revToday += o.totalHarga;
        if (t.isAfter(now.subtract(const Duration(days: 7)))) {
          revWeek += o.totalHarga;
        }
        if (t.year == now.year && t.month == now.month) {
          revMonth += o.totalHarga;
        }
      }

      // Tujuh hari terakhir.
      final spots = <FlSpot>[];
      final labels = <String>[];
      for (int i = 6; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        double rev = 0;
        for (final o in aktifOrders) {
          if (_sameDay(o.tanggalBeli, day)) rev += o.totalHarga;
        }
        spots.add(FlSpot((6 - i).toDouble(), rev));
        labels.add(day.day.toString().padLeft(2, '0'));
      }

      // Lima konser dengan pendapatan terbesar.
      final konserRev = <String, double>{};
      for (final o in aktifOrders) {
        konserRev[o.judulKonser] =
            (konserRev[o.judulKonser] ?? 0) + o.totalHarga;
      }
      final sortedKonser = konserRev.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5 = sortedKonser.take(5).toList();

      // Distribusi metode pembayaran.
      final metodeCount = <String, int>{};
      for (final o in aktifOrders) {
        final m = (o.metodePembayaran ?? 'Lainnya').isNotEmpty
            ? o.metodePembayaran!
            : 'Lainnya';
        metodeCount[m] = (metodeCount[m] ?? 0) + 1;
      }
      final sortedMetode = metodeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Funnel: dilihat, checkout, lunas.
      int totalViews = 0;
      for (final d in eventsSnap.docs) {
        totalViews += (d.data()['views'] as num?)?.toInt() ?? 0;
      }

      if (mounted) {
        setState(() {
          _revToday = revToday;
          _revWeek = revWeek;
          _revMonth = revMonth;
          _dailySpots
            ..clear()
            ..addAll(spots);
          _dailyLabels
            ..clear()
            ..addAll(labels);
          _topKonser
            ..clear()
            ..addAll(top5);
          _metodeEntries
            ..clear()
            ..addAll(sortedMetode);
          _totalViews = totalViews;
          _totalCheckout = allOrders.length;
          _totalPaid = aktifOrders.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
          ),
        ],
        title: Text(
          'LAPORAN REVENUE',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Text('Gagal memuat data: $_error',
                      style:
                          GoogleFonts.spaceGrotesk(color: AppColors.error)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('PENJUALAN 7 HARI TERAKHIR'),
                      const SizedBox(height: 12),
                      _buildLineChartCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('TOP 5 KONSER BY REVENUE'),
                      const SizedBox(height: 12),
                      _buildBarChartCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('DISTRIBUSI METODE PEMBAYARAN'),
                      const SizedBox(height: 12),
                      _buildPieChartCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('FUNNEL KONVERSI'),
                      const SizedBox(height: 12),
                      _buildFunnelCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('HARI INI', _formatRupiah(_revToday),
              Icons.today_outlined, _palette[0]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard('MINGGU INI', _formatRupiah(_revWeek),
              Icons.date_range_outlined, _palette[1]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard('BULAN INI', _formatRupiah(_revMonth),
              Icons.calendar_month_outlined, _palette[2]),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color warna) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: warna, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({required Widget child, double height = 220}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: SizedBox(height: height, child: child),
    );
  }

  Widget _buildLineChartCard() {
    final maxRev = _dailySpots.fold<double>(
        0, (prev, e) => e.y > prev ? e.y : prev);
    final chartMaxY = (maxRev * 1.2).ceilToDouble().clamp(1.0, double.infinity).toDouble();

    return _chartCard(
      height: 240,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= _dailyLabels.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _dailyLabels[i],
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value % 1 != 0) return const SizedBox();
                  return Text(
                    _formatRingkas(value),
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textMuted, fontSize: 9),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0.0,
          maxX: 6.0,
          minY: 0.0,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: _dailySpots,
              isCurved: true,
              isStrokeCapRound: true,
              barWidth: 3,
              color: _palette[0],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: _palette[0].withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard() {
    if (_topKonser.isEmpty) {
      return _chartCard(
        child: Center(
          child: Text('Belum ada transaksi AKTIF',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted)),
        ),
      );
    }

    final maxRev = _topKonser
        .map((e) => e.value)
        .fold<double>(0, (p, e) => e > p ? e : p);
    final chartMaxY = (maxRev * 1.15).ceilToDouble().clamp(1.0, double.infinity).toDouble();

    return _chartCard(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value % 1 != 0) return const SizedBox();
                  return Text(
                    _formatRingkas(value),
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textMuted, fontSize: 9),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= _topKonser.length) {
                    return const SizedBox();
                  }
                  final label = _topKonser[i].key;
                  final short = label.length > 8
                      ? '${label.substring(0, 7)}…'
                      : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      short,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(_topKonser.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _topKonser[i].value,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                  color: _palette[i % _palette.length],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPieChartCard() {
    if (_metodeEntries.isEmpty) {
      return _chartCard(
        child: Center(
          child: Text('Belum ada data metode pembayaran',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted)),
        ),
      );
    }

    final total = _metodeEntries.fold<int>(0, (p, e) => p + e.value);

    return _chartCard(
      height: 260,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 38,
                sections: List.generate(_metodeEntries.length, (i) {
                  final e = _metodeEntries[i];
                  final pct = total == 0 ? 0.0 : (e.value / total * 100);
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    color: _palette[i % _palette.length],
                    title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
                    titleStyle: GoogleFonts.spaceGrotesk(
                      color: AppColors.warnaTombolTeks,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    radius: 46,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _metodeEntries.take(6).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ),
                      Text(
                        '${e.value}',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelCard() {
    final double checkoutRate =
        _totalViews == 0 ? 0 : (_totalCheckout / _totalViews * 100);
    final double paidRate =
        _totalCheckout == 0 ? 0 : (_totalPaid / _totalCheckout * 100);
    final double overallRate =
        _totalViews == 0 ? 0 : (_totalPaid / _totalViews * 100);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _funnelStep('Views Konser', '$_totalViews', _palette[1], 1.0),
          _funnelConnector('Konversi → Checkout ${checkoutRate.toStringAsFixed(1)}%'),
          _funnelStep('Checkout (Orders)', '$_totalCheckout', _palette[2],
              _totalViews == 0 ? 0 : _totalCheckout / _totalViews),
          _funnelConnector('Konversi → Paid ${paidRate.toStringAsFixed(1)}%'),
          _funnelStep('Paid (AKTIF)', '$_totalPaid', _palette[0],
              _totalViews == 0 ? 0 : _totalPaid / _totalViews),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('KONVERSI KESELURUHAN',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Text(
                '${overallRate.toStringAsFixed(2)}%',
                style: GoogleFonts.rajdhani(
                  color: _palette[0],
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _funnelStep(
      String label, String value, Color warna, double fraction) {
    final widthFraction = (fraction.clamp(0.15, 1.0)) * 100;
    return Row(
      children: [
        Container(
          width: 6 + widthFraction * 1.6,
          height: 40,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.warnaTombolTeks,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _funnelConnector(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        '↓  $text',
        style: GoogleFonts.spaceGrotesk(
            color: AppColors.textMuted, fontSize: 10),
      ),
    );
  }
}
