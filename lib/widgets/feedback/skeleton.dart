import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/app_theme.dart';

/// Kotak abu berkilau sebagai pengganti konten yang belum termuat.
///
/// Kenapa skeleton, bukan animasi Lottie: skeleton menempati ruang yang
/// **sama** dengan konten aslinya, sehingga tata letak tidak melompat saat
/// data tiba. Animasi Lottie butuh ruang sendiri dan mendorong konten turun —
/// untuk pemuatan yang hanya setengah detik, lompatan itu lebih terasa
/// mengganggu daripada animasinya.
///
/// `shimmer` sudah terpasang sejak awal dan dipakai di panel admin, jadi tidak
/// ada paket baru.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Pembungkus shimmer untuk sekelompok skeleton.
///
/// Satu `Shimmer.fromColors` membungkus semuanya supaya kilaunya bergerak
/// serempak. Kalau setiap kotak punya shimmer sendiri, hasilnya terlihat
/// berkedip acak.
class SkeletonGroup extends StatelessWidget {
  final Widget child;

  const SkeletonGroup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.card,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Skeleton untuk daftar kategori tiket di halaman detail konser.
///
/// Bentuknya meniru kartu tiket sungguhan: satu blok judul, dua baris
/// keterangan, dan satu tombol di kanan. Tujuannya bukan meniru detail, tapi
/// memesan ruang yang kira-kira sama supaya tidak ada lompatan tata letak.
class SkeletonTicketList extends StatelessWidget {
  final int jumlah;

  const SkeletonTicketList({super.key, this.jumlah = 3});

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: jumlah,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.rLg,
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 16),
                    SizedBox(height: 10),
                    SkeletonBox(width: 80, height: 11),
                    SizedBox(height: 8),
                    SkeletonBox(width: 150, height: 11),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(width: 70, height: 11),
                  SizedBox(height: 10),
                  SkeletonBox(width: 88, height: 34, radius: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton untuk daftar konser berbentuk kartu besar (gambar di atas).
class SkeletonConcertList extends StatelessWidget {
  final int jumlah;

  const SkeletonConcertList({super.key, this.jumlah = 3});

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: Column(
        children: List.generate(
          jumlah,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.rLg,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 140, radius: 20),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 180, height: 16),
                      SizedBox(height: 10),
                      SkeletonBox(width: 120, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
