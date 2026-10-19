import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/konser_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gambar_widget.dart';

/// Shares a concert to WhatsApp, Instagram, or the clipboard.
/// Takes the concert and an optional user ID for referrals.
class ShareKonserScreen extends StatelessWidget {
  final KonserModel konser;
  final String? userId;

  const ShareKonserScreen({
    super.key,
    required this.konser,
    this.userId,
  });

  String get _deepLink {
    final ref = userId != null && userId!.isNotEmpty ? '?ref=$userId' : '';
    return 'soundwave://concert/${konser.id}$ref';
  }

  String _formatTanggal(DateTime t) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${t.day.toString().padLeft(2, '0')} ${bulan[t.month - 1]} ${t.year}';
  }

  String get _shareText {
    return '🎵 ${konser.judul} di Soundwave! '
        '📅 ${_formatTanggal(konser.tanggal)} '
        '📍 ${konser.lokasi} '
        '💰 Mulai dari ${konser.formatHarga}. '
        'Download Soundwave sekarang!\n$_deepLink';
  }

  Future<void> _share(BuildContext context) async {
    await Share.share(
      _shareText,
      subject: '${konser.judul} di Soundwave',
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _deepLink));
    messenger.showSnackBar(
      SnackBar(
        content: Text('Link disalin: $_deepLink',
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'BAGIKAN KONSER',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPosterCard(),
            const SizedBox(height: 20),
            _buildShareButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              width: double.infinity,
              height: 240,
              child: GambarWidget(
                url: konser.gambarUrl,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  konser.judul,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _infoRow(
                    Icons.calendar_today_rounded, _formatTanggal(konser.tanggal)),
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_rounded, konser.lokasi),
                const SizedBox(height: 8),
                _infoRow(
                    Icons.confirmation_number_rounded, konser.formatHarga),
                if (konser.penyelenggara != null &&
                    konser.penyelenggara!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.mic_rounded, konser.penyelenggara!),
                ],
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 14),
                Text(
                  'DEEP LINK',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _deepLink,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.warnaHarga,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildShareButtons(BuildContext context) {
    return Column(
      children: [
        _shareButton(
          context: context,
          icon: Icons.chat_rounded,
          label: 'Bagikan ke WhatsApp',
          color: const Color(0xFF25D366),
          onTap: () => _share(context),
        ),
        const SizedBox(height: 12),
        _shareButton(
          context: context,
          icon: Icons.camera_alt_rounded,
          label: 'Bagikan ke Instagram',
          color: const Color(0xFFE1306C),
          onTap: () => _share(context),
        ),
        const SizedBox(height: 12),
        _shareButton(
          context: context,
          icon: Icons.link_rounded,
          label: 'Salin Link',
          color: AppColors.warnaHarga,
          outlined: true,
          onTap: () => _copyLink(context),
        ),
      ],
    );
  }

  Widget _shareButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? AppColors.surfaceLight : color,
          foregroundColor: outlined ? AppColors.textPrimary : Colors.black,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: outlined
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color, width: 1.2),
                )
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
