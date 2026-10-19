import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';

/// Dua tombol dialog yang selalu sejajar kiri-kanan, lebarnya dibagi rata.
///
/// Jangan mengembalikan tombol dialog ke `AlertDialog.actions`: `actions`
/// memakai `OverflowBar`, yang menumpuk tombol ke atas-bawah begitu layar
/// sempit. Itu penyebab tombol Batal muncul di atas tombol Keluar. Di sini
/// `Row` + `Expanded` menjaga keduanya tetap sejajar.
class TombolDialogSejajar extends StatelessWidget {
  const TombolDialogSejajar({
    super.key,
    required this.onBatal,
    required this.onKonfirmasi,
    this.labelBatal = 'Batal',
    this.labelKonfirmasi = 'Keluar',
    this.warnaKonfirmasi,
  });

  final VoidCallback onBatal;
  final VoidCallback onKonfirmasi;
  final String labelBatal;
  final String labelKonfirmasi;

  /// Warna latar tombol aksi. Default merah (aksi berisiko seperti keluar).
  final Color? warnaKonfirmasi;

  @override
  Widget build(BuildContext context) {
    // Warna latar dan warna teks dipisah agar kontras (teks gelap di tombol
    // berwarna terang) — bukan teks bawaan yang bisa tenggelam.
    final Color warna = warnaKonfirmasi ?? AppColors.error;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBatal,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              labelBatal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onKonfirmasi,
            style: ElevatedButton.styleFrom(
              backgroundColor: warna,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              labelKonfirmasi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
