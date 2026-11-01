"""
Buat ulang ikon APK SoundWave: lima batang waveform putih di atas #08080C.

Kenapa skrip, bukan aset jadi:
  * Ikon adaptive Android butuh `foreground` dengan **safe zone**: logo harus
    muat di lingkaran 66% tengah kanvas, karena peluncur memotongnya menjadi
    lingkaran/squircle/teardrop. Ikon sebelumnya memenuhi seluruh kanvas,
    sehingga batang terluar terpotong di sebagian bentuk.
  * Butuh 5 kepadatan (mdpi..xxxhdpi) dengan ukuran berbeda; menghitung
    manual rawan salah.

Jalankan: python tools/buat_ikon.py
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

# ---------------------------------------------------------------- warna
LATAR = (0x08, 0x08, 0x0C, 255)  # #08080C, sama dengan AppColors.background
PUTIH = (0xF4, 0xF4, 0xF6, 255)  # #F4F4F6, sama dengan AppColors.aksi

# Tinggi relatif kelima batang (0..1). Simetris: pendek–sedang–tinggi–sedang–pendek.
TINGGI_BATANG = [0.42, 0.68, 1.00, 0.68, 0.42]

# Kepadatan peluncur Android -> ukuran ikon legacy (px).
KEPADATAN = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(AKAR, "android", "app", "src", "main", "res")


def gambar_batang(
    kanvas: int,
    tinggi_maks: float,
    lebar_batang: float,
    jarak: float,
    warna=PUTIH,
) -> Image.Image:
    """Gambar lima batang di tengah kanvas transparan berukuran `kanvas`."""
    img = Image.new("RGBA", (kanvas, kanvas), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    total_lebar = 5 * lebar_batang + 4 * jarak
    x0 = (kanvas - total_lebar) / 2
    tengah_y = kanvas / 2

    for i, rasio in enumerate(TINGGI_BATANG):
        h = tinggi_maks * rasio
        x = x0 + i * (lebar_batang + jarak)
        y0 = tengah_y - h / 2
        y1 = tengah_y + h / 2
        d.rounded_rectangle(
            [x, y0, x + lebar_batang, y1],
            radius=lebar_batang / 2,
            fill=warna,
        )
    return img


def buat_legacy(ukuran: int) -> Image.Image:
    """Ikon legacy: latar penuh + batang, tanpa safe zone."""
    latar = Image.new("RGBA", (ukuran, ukuran), LATAR)
    # Batang mengisi ~62% tinggi kanvas, menyisakan napas di atas/bawah.
    batang = gambar_batang(
        ukuran,
        tinggi_maks=ukuran * 0.62,
        lebar_batang=max(2.0, ukuran * 0.075),
        jarak=max(1.0, ukuran * 0.055),
    )
    latar.alpha_composite(batang)
    return latar


def buat_foreground(ukuran: int) -> Image.Image:
    """
    Lapisan foreground adaptive icon.

    Android memotong lapisan ini menjadi bentuk peluncur, jadi isinya harus
    berada di dalam lingkaran 66% tengah (safe zone). `ukuran` di sini adalah
    108dp * skala kepadatan; 66% dari itu adalah area aman.
    """
    aman = ukuran * 0.66
    img = Image.new("RGBA", (ukuran, ukuran), (0, 0, 0, 0))
    batang = gambar_batang(
        int(aman),
        tinggi_maks=aman * 0.58,
        lebar_batang=max(2.0, aman * 0.075),
        jarak=max(1.0, aman * 0.055),
    )
    ofs = (ukuran - batang.width) // 2
    img.alpha_composite(batang, (ofs, ofs))
    return img


def main() -> None:
    for nama, ukuran in KEPADATAN.items():
        folder = os.path.join(RES, f"mipmap-{nama}")
        os.makedirs(folder, exist_ok=True)

        legacy = buat_legacy(ukuran)
        legacy.save(os.path.join(folder, "ic_launcher.png"))

        # Foreground adaptive = 108dp * skala (ukuran legacy * 2.25).
        fg_ukuran = int(round(ukuran * 2.25))
        fg = buat_foreground(fg_ukuran)
        fg.save(os.path.join(folder, "ic_launcher_foreground.png"))

        print(f"{nama:8} legacy {ukuran:3}px  foreground {fg_ukuran:3}px")

    # Simpan satu salinan besar untuk dipakai splash native.
    splash = buat_foreground(432)
    os.makedirs(os.path.join(RES, "drawable"), exist_ok=True)
    splash.save(os.path.join(RES, "drawable", "splash_logo.png"))
    print("splash_logo.png 432px -> drawable/")


if __name__ == "__main__":
    main()
