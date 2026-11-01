import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/media/venue_model_library.dart';
import '../../models/event_media_model.dart';
import '../../utils/app_theme.dart';
import 'venue_viewer.dart';

/// Pemilih model panggung 3D untuk form konser.
///
/// Hanya **pustaka**, tanpa unggah dan tanpa URL. Alasannya: model 3D yang
/// baik berukuran megabyte, dan memuatnya dari sembarang URL membuat aplikasi
/// bergantung pada server pihak lain yang bisa mati kapan saja. Untuk sekarang
/// admin memilih dari model yang sudah dioptimasi dan diuji; daftar ini akan
/// bertambah seiring waktu.
class VenueModelPickerField extends StatefulWidget {
  final EventMedia media;
  final ValueChanged<EventMedia> onChanged;

  const VenueModelPickerField({
    super.key,
    required this.media,
    required this.onChanged,
  });

  @override
  State<VenueModelPickerField> createState() => _VenueModelPickerFieldState();
}

class _VenueModelPickerFieldState extends State<VenueModelPickerField> {
  String? _refTerpilih;

  @override
  void initState() {
    super.initState();
    final ref = widget.media.venueModelRef;
    _refTerpilih = VenueModelLibrary.byRef(ref)?.ref;
  }

  void _pilih(String? ref) {
    setState(() => _refTerpilih = ref);
    // Hanya bagian venue yang diubah; audio dan video tetap utuh.
    widget.onChanged(widget.media.withVenue(venueModelRef: ref));
  }

  @override
  Widget build(BuildContext context) {
    final terpilih = VenueModelLibrary.byRef(_refTerpilih);

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
              const Icon(Icons.view_in_ar_rounded,
                  size: 16, color: AppColors.aksi),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Panggung 3D',
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

          ...VenueModelLibrary.models.map((m) {
            final dipilih = _refTerpilih == m.ref;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                borderRadius: AppRadius.rSm,
                onTap: () => _pilih(dipilih ? null : m.ref),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        dipilih
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 16,
                        color: dipilih ? AppColors.aksi : AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.nama,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: dipilih
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.keterangan,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                height: 1.4,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.ukuranMb.toStringAsFixed(1)} MB · ${m.kredit}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                color: AppColors.textMuted.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (terpilih != null) ...[
            const SizedBox(height: AppSpacing.xs),
            VenueViewer(
              model: terpilih,
              nama: terpilih.nama,
              kredit: terpilih.kredit,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ketuk model sekali lagi untuk melepas pilihan.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
