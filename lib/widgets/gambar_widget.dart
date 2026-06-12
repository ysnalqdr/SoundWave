import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

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
    //! Kosong → Lari Ke Placeholder
    if (url.isEmpty) return _placeholder();

    //! Kalo Dari Assets Lokal
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    //! Kalo Dari Url
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _loading();
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceLight,
      child: Icon(
        ikonDefault,
        color: AppColors.primary,
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
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}