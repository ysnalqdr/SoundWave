import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_theme.dart';

/// ============================================================================
/// NAVBAR KACA MENGAMBANG
/// ============================================================================
///
/// Menggantikan `BottomNavigationBar` yang menempel dan **lebih gelap dari
/// kartu di atasnya** (`surface` #0E0E13, L\* 4,11 vs `card` #17171F, L\* 8,07)
/// — sehingga navbar terbaca seperti lubang, bukan permukaan yang melayang.
///
/// Gaya baru: pil kaca mengambang dengan pil putih di tab aktif.
///
/// ## Kenapa opasitas 0,90 dan bukan 0,80 seperti referensi
///
/// Navbar ini melayang di atas konten yang bisa berupa poster konser terang.
/// Pada 0,85 latar efektif di atas poster putih jatuh ke `#4B4B52` dan teks
/// pasif hanya **4,21:1** — gagal WCAG AA. Pada 0,90 menjadi **5,01:1**.
///
/// Blur tetap terlihat pada 0,90 karena `BackdropFilter` bekerja dari 10%
/// yang tersisa.
///
/// ## Label dipertahankan
///
/// Referensi hanya memakai ikon. Empat ikon abstrak tanpa label memaksa
/// pengguna baru menebak. Label Indonesia dipertahankan.
class NavbarKaca extends StatelessWidget {
  const NavbarKaca({
    super.key,
    required this.indeks,
    required this.onPilih,
    required this.item,
  });

  final int indeks;
  final ValueChanged<int> onPilih;
  final List<NavbarKacaItem> item;

  static const double tinggi = 66;
  static const double jarakBawah = 20;
  static const double jarakSamping = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: jarakSamping,
        right: jarakSamping,
        bottom: jarakBawah,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tinggi / 2),
        child: BackdropFilter(
          // Blur + saturasi: 10% warna di belakang tetap bocor, jadi kaca
          // terasa hidup tanpa mengorbankan kontras teks.
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: tinggi,
            decoration: BoxDecoration(
              color: AppColors.navKaca,
              borderRadius: BorderRadius.circular(tinggi / 2),
              border: Border.all(color: AppColors.navKacaBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 34,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final lebarItem = c.maxWidth / item.length;
                return Stack(
                  children: [
                    // Pil penanda tab aktif, bergeser halus saat ganti tab.
                    AnimatedPositioned(
                      duration: AppMotion.base,
                      curve: AppMotion.out,
                      left: lebarItem * indeks,
                      top: 0,
                      bottom: 0,
                      width: lebarItem,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navPilAktif,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x59000000),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isiItem(item[indeks], aktif: true),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < item.length; i++)
                          Expanded(
                            child: Semantics(
                              selected: i == indeks,
                              button: true,
                              label: item[i].label,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onPilih(i),
                                child: SizedBox(
                                  height: tinggi,
                                  child: Center(
                                    child: i == indeks
                                        // Ruang kosong: pil aktif sudah
                                        // digambar di lapisan bawah, dan
                                        // ketukan ditangani GestureDetector.
                                        ? Opacity(
                                            opacity: 0,
                                            child: _isiItem(item[i],
                                                aktif: true),
                                          )
                                        : _isiItem(item[i], aktif: false),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _isiItem(NavbarKacaItem it, {required bool aktif}) {
    final warna =
        aktif ? AppColors.navPilAktifFg : AppColors.navTeksPasif;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(it.ikon, size: 19, color: warna),
        const SizedBox(height: 1),
        Text(
          it.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            color: warna,
            fontSize: 8.5,
            fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class NavbarKacaItem {
  const NavbarKacaItem({
    required this.ikon,
    required this.label,
  });

  final IconData ikon;
  final String label;
}
