import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';

class LaporanPenjualanScreen extends ConsumerWidget {
  final UserModel user;
  final VoidCallback? onBukaSidebar;

  const LaporanPenjualanScreen({
    super.key,
    required this.user,
    this.onBukaSidebar,
  });

  String _formatRupiah(double nominal) {
    final formatted = nominal
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    final ticketsAsync = ref.watch(allTicketsProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'LAPORAN & ANALITIK PENJUALAN',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        leading: onBukaSidebar != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: onBukaSidebar,
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ordersAsync.when(
              data: (orders) {
                double totalPendapatan = 0;
                int totalTerjual = 0;

                for (var o in orders) {
                  if (o.isAktif || o.isTerpakai) {
                    totalPendapatan += o.totalHarga;
                    totalTerjual += o.jumlahTiket;
                  }
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'TOTAL PENDAPATAN',
                            _formatRupiah(totalPendapatan),
                            Icons.monetization_on_outlined,
                            AppColors.warnaHarga,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'TIKET TERJUAL',
                            '$totalTerjual Lembar',
                            Icons.confirmation_number_outlined,
                            Colors.lightBlueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ticketsAsync.when(
                            data: (tickets) {
                              int totalSisa = 0;
                              for (var t in tickets) {
                                totalSisa += t.stok;
                              }
                              return _buildMetricCard(
                                'SISA KUOTA TIKET',
                                '$totalSisa Lembar',
                                Icons.inventory_2_outlined,
                                AppColors.warning,
                              );
                            },
                            loading: () => _buildMetricCard(
                              'SISA KUOTA TIKET',
                              '...',
                              Icons.inventory_2_outlined,
                              AppColors.warning,
                            ),
                            error: (_, __) => _buildMetricCard(
                              'SISA KUOTA TIKET',
                              '0 Lembar',
                              Icons.inventory_2_outlined,
                              AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Gagal memuat analitik: $e',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'RINGKASAN TIKET PER KONSER',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            eventsAsync.when(
              data: (daftarKonser) {
                if (daftarKonser.isEmpty) {
                  return Text(
                    'Belum ada konser terdaftar di Firestore',
                    style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted),
                  );
                }

                return ticketsAsync.when(
                  data: (allTickets) {
                    return Column(
                      children: daftarKonser.map((k) {
                        final tiketKonser =
                            allTickets.where((t) => t.idKonser == k.id).toList();
                        int sisa = 0;
                        for (var t in tiketKonser) {
                          sisa += t.stok;
                        }

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      k.judul,
                                      style: GoogleFonts.rajdhani(
                                        color: AppColors.textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'Sisa: $sisa Kuota',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.warnaHarga,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tiketKonser.length} Kategori Tiket Aktif',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Gagal: $e',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.error)),
            ),
            const SizedBox(height: 24),

            Text(
              'RIWAYAT TRANSAKSI TERAKHIR',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ordersAsync.when(
              data: (daftarPesanan) {
                if (daftarPesanan.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Belum ada transaksi di Firestore',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                return Column(
                  children: daftarPesanan.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.kodeBooking,
                                  style: GoogleFonts.rajdhani(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.namaPembeli} • ${p.judulKonser}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                p.formatTotalHarga,
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.warnaHarga,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                p.status,
                                style: GoogleFonts.spaceGrotesk(
                                  color: p.isAktif
                                      ? AppColors.success
                                      : (p.isTerpakai
                                          ? AppColors.textMuted
                                          : AppColors.warning),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Gagal memuat pesanan: $e',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color warna,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: warna, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
