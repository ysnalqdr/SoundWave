import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/media/audio_library.dart';
import '../../core/media/duration_format.dart';
import '../../models/event_media_model.dart';
import '../../utils/app_theme.dart';
import 'audio_preview_player.dart';

/// Pemilih audio untuk form konser di panel admin.
///
/// Dua jalur, karena keduanya punya batas berbeda:
///
/// 1. **Pilih dari pustaka** — track yang dibundel di APK. Cepat, langsung
///    bisa diputar, tapi menambah track baru menuntut build ulang.
/// 2. **Tempel URL** — lagu apa pun yang bisa diakses lewat https. Tidak perlu
///    build ulang, tapi berkasnya harus sudah diunggah ke suatu tempat.
///
/// Kenapa tidak ada tombol "unggah berkas": Firebase Storage menuntut paket
/// Blaze. Selama proyek memakai Spark, unggah dari aplikasi tidak mungkin.
/// Kolom URL adalah jalan pintas yang jujur untuk keterbatasan itu.
class AudioPickerField extends StatefulWidget {
  /// Nilai awal (saat mengedit konser yang sudah punya audio).
  final EventMedia media;

  /// Dipanggil setiap kali pilihan berubah.
  final ValueChanged<EventMedia> onChanged;

  const AudioPickerField({
    super.key,
    required this.media,
    required this.onChanged,
  });

  @override
  State<AudioPickerField> createState() => _AudioPickerFieldState();
}

class _AudioPickerFieldState extends State<AudioPickerField> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _judulCtrl;
  late final TextEditingController _mulaiCtrl;
  late final TextEditingController _durasiCtrl;
  String? _refTerpilih;
  bool _pakaiUrl = false;
  String? _galatUrl;

  @override
  void initState() {
    super.initState();
    final ref = widget.media.audioRef ?? '';
    _pakaiUrl = ref.startsWith('http');
    _refTerpilih = _pakaiUrl ? null : (ref.isEmpty ? null : ref);
    _urlCtrl = TextEditingController(text: _pakaiUrl ? ref : '');
    _judulCtrl = TextEditingController(text: widget.media.audioTitle ?? '');
    _mulaiCtrl = TextEditingController(
      text: DurationFormat.clock(widget.media.audioStartSec),
    );
    _durasiCtrl = TextEditingController(
      text: '${widget.media.audioDurationSec}',
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _judulCtrl.dispose();
    _mulaiCtrl.dispose();
    _durasiCtrl.dispose();
    super.dispose();
  }

  /// Validasi ringan: harus http/https dan berakhiran ekstensi audio.
  ///
  /// Tidak ketat berlebihan — CDN sering memakai query string
  /// (`lagu.mp3?token=abc`), jadi ekstensi diperiksa sebelum tanda tanya.
  String? _validasiUrl(String raw) {
    final url = raw.trim();
    if (url.isEmpty) return null;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL harus diawali http:// atau https://';
    }
    final tanpaQuery = url.split('?').first.toLowerCase();
    const ekstensi = ['.mp3', '.m4a', '.aac', '.wav', '.ogg'];
    if (!ekstensi.any(tanpaQuery.endsWith)) {
      return 'Berkas harus berformat mp3, m4a, aac, wav, atau ogg';
    }
    return null;
  }

  void _terapkan() {
    final galat = _validasiUrl(_urlCtrl.text);
    setState(() => _galatUrl = galat);
    if (galat != null) return;

    final judul = _judulCtrl.text.trim();
    String? ref;

    if (_pakaiUrl) {
      ref = _urlCtrl.text.trim();
    } else {
      ref = _refTerpilih;
    }

    if (ref == null || ref.isEmpty) {
      // Tidak ada audio -> kosongkan bagian audio saja. Video dan model 3D
      // yang sudah diisi tidak boleh ikut terhapus.
      widget.onChanged(widget.media.withAudio());
      return;
    }

    // Durasi: pakai durasi pustaka bila track bawaan, selain itu biarkan
    // nilai lama (pemutar membaca durasi asli berkas saat dimuat).
    final track = AudioLibrary.byRef(ref);
    // Berkas bawaan punya durasi tetap dari pustaka. Berkas jaringan memakai
    // angka yang diisi admin, karena panjangnya tidak diketahui aplikasi.
    final mulai = DurationFormat.parseClock(_mulaiCtrl.text) ?? 0;
    final durasi = track?.durationSec ??
        (int.tryParse(_durasiCtrl.text.trim()) ?? widget.media.audioDurationSec);

    widget.onChanged(
      widget.media.withAudio(
        audioRef: ref,
        audioTitle: judul.isEmpty ? (track?.title ?? 'Preview lagu') : judul,
        audioDurationSec: durasi,
        audioStartSec: track != null ? 0 : mulai,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refAktif = _pakaiUrl ? _urlCtrl.text.trim() : _refTerpilih;
    final judulAktif = _judulCtrl.text.trim();
    final bisaPratinjau = (refAktif ?? '').isNotEmpty &&
        (_pakaiUrl ? _validasiUrl(refAktif!) == null : true);

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
              const Icon(Icons.music_note_rounded,
                  size: 16, color: AppColors.aksi),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Audio pratinjau',
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

          // --- pemilih sumber ---
          Row(
            children: [
              Expanded(
                child: _TabSumber(
                  label: 'Pustaka',
                  aktif: !_pakaiUrl,
                  onTap: () {
                    setState(() => _pakaiUrl = false);
                    _terapkan();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TabSumber(
                  label: 'URL',
                  aktif: _pakaiUrl,
                  onTap: () {
                    setState(() => _pakaiUrl = true);
                    _terapkan();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (!_pakaiUrl) ...[
            // --- daftar track bawaan ---
            ...AudioLibrary.tracks.map((t) {
              final dipilih = _refTerpilih == t.ref;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  borderRadius: AppRadius.rSm,
                  onTap: () {
                    setState(() {
                      _refTerpilih = dipilih ? null : t.ref;
                      if (dipilih) _judulCtrl.text = '';
                    });
                    _terapkan();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: dipilih
                          ? AppColors.aksi.withValues(alpha: 0.08)
                          : AppColors.surfaceLight,
                      borderRadius: AppRadius.rSm,
                      border: Border.all(
                        color: dipilih ? AppColors.aksi : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          dipilih
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 16,
                          color:
                              dipilih ? AppColors.aksi : AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight:
                                  dipilih ? FontWeight.w600 : FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${t.durationSec}s',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_refTerpilih != null)
              Text(
                'Ketuk sekali lagi untuk melepas pilihan.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
          ] else ...[
            // --- input URL ---
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                hintText: 'https://cdn.contoh.com/lagu.mp3',
                prefixIcon: const Icon(Icons.link_rounded),
                errorText: _galatUrl,
              ),
              onChanged: (_) {
                setState(() => _galatUrl = null);
                _terapkan();
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Berkas harus bisa diakses publik. Contoh gratis: '
              'unggah ke Cloudinary, GitHub Releases, atau Archive.org.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // --- potongan (hanya untuk berkas jaringan) ---
          //
          // Berkas bawaan sudah dipotong saat dibundel, jadi tidak perlu
          // diatur di sini. Berkas dari URL bisa berdurasi menit-menitan;
          // tanpa kolom ini admin hanya bisa memakai 20 detik pertama, yang
          // belum tentu bagian yang menarik.
          if (_pakaiUrl) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _mulaiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mulai dari',
                      hintText: '0:30',
                    ),
                    onChanged: (_) => _terapkan(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _durasiCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Durasi (detik)',
                      hintText: '20',
                    ),
                    onChanged: (_) => _terapkan(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // --- judul track ---
          TextField(
            controller: _judulCtrl,
            decoration: const InputDecoration(
              hintText: 'Judul lagu (opsional, mengikuti berkas bila kosong)',
              prefixIcon: Icon(Icons.title_rounded),
            ),
            onChanged: (_) => _terapkan(),
          ),

          // --- pratinjau ---
          if (bisaPratinjau) ...[
            const SizedBox(height: AppSpacing.md),
            AudioPreviewPlayer(
              assetPath: refAktif!,
              title: judulAktif.isEmpty
                  ? (AudioLibrary.byRef(refAktif)?.title ?? 'Preview lagu')
                  : judulAktif,
              durationSec: AudioLibrary.byRef(refAktif)?.durationSec ?? 20,
            ),
          ],
        ],
      ),
    );
  }
}

/// Tab kecil untuk memilih sumber audio.
class _TabSumber extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  const _TabSumber({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.rSm,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? AppColors.aksi.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: AppRadius.rSm,
          border: Border.all(
            color: aktif ? AppColors.aksi : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
            color: aktif ? AppColors.aksi : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
