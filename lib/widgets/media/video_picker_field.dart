import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/media/duration_format.dart';
import '../../core/media/media_resolver.dart';
import '../../models/event_media_model.dart';
import '../../utils/app_theme.dart';

/// Pemilih trailer video YouTube untuk form konser.
///
/// Kenapa menempelkan tautan, bukan mengunggah berkas: video di-host di
/// YouTube, jadi aplikasi hanya menyimpan **ID** dan dua angka detik. Tidak ada
/// bandwidth server sendiri, tidak ada kuota penyimpanan, dan pemutaran tetap
/// memakai pemutar YouTube yang sudah dikenal pengguna.
///
/// Tiga nilai yang disimpan:
/// - `videoYoutubeId` — 11 karakter, hasil ekstraksi dari tautan apa pun
/// - `videoStartSec` — detik mulai potongan
/// - `videoDurationSec` — panjang potongan
///
/// Durasi dibatasi 10–90 detik. Di bawah 10 detik potongan terasa terpotong
/// sebelum sempat dinikmati; di atas 90 detik ini bukan lagi trailer.
class VideoPickerField extends StatefulWidget {
  /// Nilai awal (saat mengedit konser yang sudah punya video).
  final EventMedia media;

  /// Dipanggil setiap kali pilihan berubah.
  final ValueChanged<EventMedia> onChanged;

  const VideoPickerField({
    super.key,
    required this.media,
    required this.onChanged,
  });

  @override
  State<VideoPickerField> createState() => _VideoPickerFieldState();
}

class _VideoPickerFieldState extends State<VideoPickerField> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _mulaiCtrl;
  late final TextEditingController _durasiCtrl;

  String? _idTerdeteksi;
  String? _galatUrl;
  String? _galatMulai;
  String? _galatDurasi;

  static const int _durasiMin = 10;
  static const int _durasiMaks = 90;

  @override
  void initState() {
    super.initState();
    final id = widget.media.videoYoutubeId;
    _idTerdeteksi = id;
    // Tautan kanonis lebih mudah dikenali admin daripada ID telanjang.
    _urlCtrl = TextEditingController(
      text: id == null ? '' : 'https://youtu.be/$id',
    );
    _mulaiCtrl = TextEditingController(
      text: DurationFormat.clock(widget.media.videoStartSec),
    );
    _durasiCtrl = TextEditingController(
      text: '${widget.media.videoDurationSec}',
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _mulaiCtrl.dispose();
    _durasiCtrl.dispose();
    super.dispose();
  }

  void _terapkan() {
    final teksUrl = _urlCtrl.text.trim();

    // --- tautan ---
    String? id;
    String? galatUrl;
    if (teksUrl.isNotEmpty) {
      id = MediaResolver.extractYoutubeId(teksUrl);
      if (id == null) {
        galatUrl = 'Tautan YouTube tidak dikenali. Contoh: '
            'https://youtu.be/dQw4w9WgXcQ';
      }
    }

    // --- detik mulai ---
    final mulai = DurationFormat.parseClock(_mulaiCtrl.text);
    String? galatMulai;
    if (_mulaiCtrl.text.trim().isNotEmpty && mulai == null) {
      galatMulai = 'Format salah. Contoh: 0:30 atau 30';
    }

    // --- durasi ---
    final durasi = int.tryParse(_durasiCtrl.text.trim());
    String? galatDurasi;
    if (durasi == null) {
      galatDurasi = 'Isi angka detik, mis. 30';
    } else if (durasi < _durasiMin || durasi > _durasiMaks) {
      galatDurasi = 'Antara $_durasiMin dan $_durasiMaks detik';
    }

    setState(() {
      _galatUrl = galatUrl;
      _galatMulai = galatMulai;
      _galatDurasi = galatDurasi;
      _idTerdeteksi = id;
    });

    if (galatUrl != null || galatMulai != null || galatDurasi != null) {
      // Jangan simpan nilai setengah jadi — lebih baik data lama dipertahankan
      // daripada tersimpan trailer yang tidak bisa diputar.
      return;
    }

    if (id == null) {
      // Video dilepas. Audio dan model 3D yang sudah diisi tetap dipertahankan.
      widget.onChanged(widget.media.withVideo());
      return;
    }

    widget.onChanged(
      widget.media.withVideo(
        videoYoutubeId: id,
        videoStartSec: mulai ?? 0,
        videoDurationSec: durasi ?? 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = _idTerdeteksi;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_display_rounded,
                  size: 16, color: AppColors.aksi),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Trailer video',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Opsional',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // --- tautan ---
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              hintText: 'https://youtu.be/xxxxxxxxxxx',
              prefixIcon: const Icon(Icons.link_rounded),
              errorText: _galatUrl,
              suffixIcon: id == null
                  ? null
                  : const Icon(Icons.check_circle_rounded,
                      color: AppColors.aksi, size: 20),
            ),
            onChanged: (_) => _terapkan(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tempel tautan YouTube biasa, tautan pendek, atau Shorts. '
            'ID video diambil otomatis.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // --- mulai & durasi ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _mulaiCtrl,
                  decoration: InputDecoration(
                    labelText: 'Mulai dari',
                    hintText: '0:30',
                    errorText: _galatMulai,
                  ),
                  onChanged: (_) => _terapkan(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _durasiCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Durasi (detik)',
                    hintText: '30',
                    errorText: _galatDurasi,
                  ),
                  onChanged: (_) => _terapkan(),
                ),
              ),
            ],
          ),

          // --- pratinjau ---
          if (id != null && _galatUrl == null) ...[
            const SizedBox(height: AppSpacing.md),
            _PratinjauVideo(
              videoId: id,
              mulaiDetik: DurationFormat.parseClock(_mulaiCtrl.text) ?? 0,
              durasiDetik: int.tryParse(_durasiCtrl.text.trim()) ?? 30,
            ),
          ],
        ],
      ),
    );
  }
}

/// Thumbnail asli YouTube dengan penanda rentang potongan.
///
/// Thumbnail diambil dari `img.youtube.com`, bukan dibingkai ulang secara
/// manual — memakai gambar asli berarti admin melihat video yang benar, bukan
/// kotak dekoratif. Bila gambar gagal dimuat (video privat, jaringan putus),
/// tampil placeholder netral, bukan kotak rusak.
class _PratinjauVideo extends StatelessWidget {
  final String videoId;
  final int mulaiDetik;
  final int durasiDetik;

  const _PratinjauVideo({
    required this.videoId,
    required this.mulaiDetik,
    required this.durasiDetik,
  });

  @override
  Widget build(BuildContext context) {
    // `hqdefault` hampir selalu tersedia; `maxresdefault` sering kosong pada
    // video lama, jadi jangan dijadikan sumber utama.
    final thumbUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.rSm,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  thumbUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: Icon(Icons.movie_outlined,
                          size: 32, color: AppColors.textMuted),
                    ),
                  ),
                ),
                // Lapisan gelap supaya tombol play dan label tetap terbaca
                // di atas thumbnail yang terang.
                Container(color: Colors.black.withValues(alpha: 0.28)),
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      size: 44, color: Colors.white),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: AppRadius.rXs,
                    ),
                    child: Text(
                      DurationFormat.rentang(mulaiDetik, durasiDetik),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Potongan ${durasiDetik}s mulai detik $mulaiDetik. '
          'Video penuh tidak diputar di aplikasi.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
