import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Penampil gambar dengan cache disk.
///
/// **Kenapa memakai `CachedNetworkImage` dan bukan `Image.network`:**
/// `Image.network` hanya menyimpan hasil unduhan di memori selama widget masih
/// hidup. Begitu pengguna menggulir melewati poster, gambarnya dibuang; saat
/// digulir balik, poster **diunduh ulang dari internet**. Di halaman Jelajah
/// yang isinya poster konser, itu berarti kuota pengguna terpakai berkali-kali
/// untuk gambar yang sama, dan poster berkedip saat muncul kembali.
///
/// `cached_network_image` menyimpan ke disk, jadi gulir bolak-balik memakai
/// berkas lokal. Paket ini **sudah ada di `pubspec.yaml` sejak lama** tapi
/// tidak pernah dipakai — jadi tidak ada dependensi baru.
class GambarWidget extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData ikonDefault;

  const GambarWidget({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.ikonDefault = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    // Tanpa sumber gambar: pakai placeholder.
    if (url.isEmpty) return _placeholder();

    // Sumber dari aset lokal.
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // Sumber dari URL — dengan cache disk.
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      // Ukuran cache disesuaikan lebar tampil supaya tidak menyimpan gambar
      // 2000px untuk thumbnail 56px.
      // `width!.isFinite` wajib ada.
      //
      // `double.infinity` adalah idiom Flutter yang sah untuk "isi lebar
      // induk". Tapi `infinity > 0` bernilai true, sehingga
      // `infinity * dpr` tetap infinity dan `.round()` melempar
      // `Unsupported operation: Infinity or NaN toInt` — persis yang
      // membuat kartu "Konser Lainnya" menampilkan kotak merah.
      memCacheWidth: width != null && width!.isFinite && width! > 0
          ? (width! * MediaQuery.devicePixelRatioOf(context)).round()
          : null,
      fadeInDuration: AppMotion.fast,
      placeholder: (_, __) => _loading(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceLight,
      child: Icon(
        ikonDefault,
        color: AppColors.textMuted,
        size: 36,
      ),
    );
  }

  Widget _loading() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceLight,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.textMuted,
          strokeWidth: 2,
        ),
      ),
    );
  }
}