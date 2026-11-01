"""Generator Diagram Konteks Soundwave: Presisi & Terstruktur (Gaya Klasik Akademik DFD).
Mengikuti referensi Sistem Perpustakaan:
- Lingkaran Proses 0 di tengah.
- 4 Entitas di 4 penjuru (User di kiri, Admin di kanan, Midtrans di atas, Firebase di bawah).
- Jalur garis siku 90 derajat rapi teratur, tidak bersilangan.
- Label teks ditaruh bersih di atas garis horizontal / di samping garis vertikal.
- Standar teknik anti-slop (1-bit monochrome, tajam, presisi).
"""
import os
import sys
from pathlib import Path

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_academic_context_diagram():
    # Dimensi kanvas proporsional, luas & leluasa agar semua garis dan teks bernapas lega
    W, H = 2200, 1600
    c = Canvas(W, H, s=2)

    # 1. Judul & Header (Kotak Sudut Kiri Atas seperti contoh referensi)
    c.rect(60, 50, 480, 75, lw=1.6)
    c.text(80, 75, "CONTEXT DIAGRAM (DFD LEVEL 0)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 100, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font definisi
    f_entity_title = c.f(SANS_B, 16)
    f_entity_sub = c.f(MONO, 11)
    f_lbl = c.f(MONO, 10.5)
    f_lbl_b = c.f(MONO_B, 10.5)
    f_sys_num = c.f(MONO_B, 22)
    f_sys_title = c.f(SANS_B, 18)
    f_sys_sub = c.f(MONO, 11)

    # 2. PUSAT: LINGKARAN PROSES 0.0 SISTEM
    cx, cy = 1100, 800
    r_sys = 150
    # Gambar lingkaran proses
    c.d.ellipse(
        [c._p(cx - r_sys, cy - r_sys), c._p(cx + r_sys, cy + r_sys)],
        outline=BLACK,
        width=max(1, int(round(2.0 * c.S))),
        fill=WHITE
    )
    # Garis pembagi nomor proses
    c.line(cx - 110, cy - 35, cx + 110, cy - 35, lw=1.4)
    c.text(cx, cy - 65, "0.0", f_sys_num, anchor="mm")
    c.text(cx, cy - 5, "SISTEM INFORMASI", f_sys_title, anchor="mm")
    c.text(cx, cy + 25, "SOUNDWAVE", f_sys_title, anchor="mm")
    c.text(cx, cy + 65, "[ Core Engine ]", f_sys_sub, anchor="mm")

    # 3. EMPAT ENTITAS (Kiri, Kanan, Atas, Bawah)
    # ENTITAS KIRI: USER
    ux, uy, uw, uh = 80, 680, 240, 240
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 105, "USER", f_entity_title, anchor="mm")
    c.text(ux + uw / 2, uy + 135, "(Pembeli / Penonton)", f_entity_sub, anchor="mm")

    # ENTITAS KANAN: ADMIN
    ax, ay, aw, ah = 1880, 680, 240, 240
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 105, "ADMIN", f_entity_title, anchor="mm")
    c.text(ax + aw / 2, ay + 135, "(Promotor & Petugas)", f_entity_sub, anchor="mm")

    # ENTITAS ATAS: PAYMENT GATEWAY (MIDTRANS)
    px, py, pw, ph = 950, 70, 300, 110
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 45, "PAYMENT GATEWAY", f_entity_title, anchor="mm")
    c.text(px + pw / 2, py + 72, "(Midtrans Sandbox)", f_entity_sub, anchor="mm")

    # ENTITAS BAWAH: FIREBASE PLATFORM
    fx, fy, fw, fh = 950, 1420, 300, 110
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 45, "FIREBASE PLATFORM", f_entity_title, anchor="mm")
    c.text(fx + fw / 2, fy + 72, "(Auth & FCM Service)", f_entity_sub, anchor="mm")

    # Helper garis siku ortogonal berpanah dengan label di atas garis horizontal
    def ortho_arrow_h_first(x1, y1, x2, y2, label="", label_pos="start", direction="forward"):
        """
        Garis siku 90 derajat: horizontal dari x1 ke x2, lalu vertikal ke y2 (atau sebaliknya).
        direction: 'forward' (panah di x2, y2) atau 'backward' (panah di x1, y1)
        """
        # Segmen horizontal: (x1, y1) -> (x2, y1)
        # Segmen vertikal  : (x2, y1) -> (x2, y2)
        c.line(x1, y1, x2, y1, lw=1.3)
        c.line(x2, y1, x2, y2, lw=1.3)
        if direction == "forward":
            # Panah di ujung (x2, y2)
            c.head(x2, y2, "down" if y2 > y1 else "up", size=7.0)
        else:
            # Panah di awal (x1, y1)
            c.head(x1, y1, "left" if x1 < x2 else "right", size=7.0)

        # Label di atas segmen horizontal
        if label:
            lx = (x1 + x2) / 2
            c.text(lx, y1 - 6, label, f_lbl, anchor="ma")

    # ==================== A. ALIRAN SISI KIRI (USER <-> SISTEM) ====================
    # 1. Dari USER ke SISTEM (Masuk - Jalur Atas)
    # Tiga garis siku masuk ke bagian kiri atas lingkaran sistem:
    user_inputs = [
        ("Data Registrasi & Login Akun", 400, 480),
        ("Pencarian & Filter Konser", 445, 525),
        ("Data Pemesanan Tiket & Kode Promo", 490, 570),
        ("Konfirmasi Pembayaran (VA / QRIS)", 535, 615),
    ]

    for lbl, y_start, x_corner in user_inputs:
        # Garis horizontal keluar dari User (x=320, y=y_start) -> ke kanan sampai x_corner -> belok ke bawah/sistem
        # Karena lingkaran di cx=1100, cy=800, titik sentuh lingkaran dihitung rapi
        c.line(320, y_start, x_corner, y_start, lw=1.3)
        # Hitung titik potong lingkaran di x_corner: y_hit = cy - sqrt(r^2 - (x_corner-cx)^2)
        import math
        dx = x_corner - cx
        if abs(dx) < r_sys:
            y_hit = cy - math.sqrt(r_sys**2 - dx**2)
        else:
            y_hit = cy - 40
        c.line(x_corner, y_start, x_corner, y_hit, lw=1.3)
        c.head(x_corner, y_hit, "down", size=7.0)
        c.text((320 + x_corner) / 2, y_start - 6, lbl, f_lbl, anchor="ma")

    # Hubungkan titik keluar User vertikal jika y_start di atas batas kotak User (uy=680)
    # Seperti di diagram perpustakaan: sebuah bus bar vertikal dari kotak User ke atas
    c.line(320, 400, 320, uy + 40, lw=1.3)

    # 2. Dari SISTEM ke USER (Keluar - Jalur Bawah)
    # Garis-garis keluar dari bawah lingkaran sistem ke User:
    user_outputs = [
        ("Info Akun, Profil & Sesi Login", 1070, 520),
        ("Katalog Konser & Informasi Kuota", 1115, 565),
        ("Tagihan Pembayaran & Hold Kuota 5 Mnt", 1160, 610),
        ("E-Tiket Digital (QR Code Ed25519)", 1205, 655),
        ("Notifikasi Status Tiket & Transaksi", 1250, 700),
    ]

    for lbl, y_end, x_corner in user_outputs:
        import math
        dx = x_corner - cx
        if abs(dx) < r_sys:
            y_hit = cy + math.sqrt(r_sys**2 - dx**2)
        else:
            y_hit = cy + 40
        # Garis keluar dari lingkaran sistem ke bawah sampai y_end
        c.line(x_corner, y_hit, x_corner, y_end, lw=1.3)
        # Lalu belok kiri sampai ke x=320
        c.line(x_corner, y_end, 320, y_end, lw=1.3)
        c.head(320, y_end, "left", size=7.0)
        c.text((320 + x_corner) / 2, y_end - 6, lbl, f_lbl, anchor="ma")

    # Bus bar vertikal bawah masuk ke User
    c.line(320, uy + uh - 40, 320, 1250, lw=1.3)

    # ==================== B. ALIRAN SISI KANAN (ADMIN <-> SISTEM) ====================
    # 1. Dari ADMIN ke SISTEM (Masuk - Jalur Atas Kanan)
    admin_inputs = [
        ("Data Login Admin & Pengelola", 400, 1720),
        ("Data Event Konser, Artis & Jadwal", 445, 1675),
        ("Setup Kategori Tiket, Tarif & Kuota", 490, 1630),
        ("Penerbitan Kode Promo & Batas Pakai", 535, 1585),
        ("Data Pindaian QR Tiket di Gate Venue", 580, 1540),
    ]

    for lbl, y_start, x_corner in admin_inputs:
        c.line(ax, y_start, x_corner, y_start, lw=1.3)
        import math
        dx = x_corner - cx
        if abs(dx) < r_sys:
            y_hit = cy - math.sqrt(r_sys**2 - dx**2)
        else:
            y_hit = cy - 40
        c.line(x_corner, y_start, x_corner, y_hit, lw=1.3)
        c.head(x_corner, y_hit, "down", size=7.0)
        c.text((ax + x_corner) / 2, y_start - 6, lbl, f_lbl, anchor="ma")

    # Bus bar vertikal admin atas
    c.line(ax, 400, ax, ay + 40, lw=1.3)

    # 2. Dari SISTEM ke ADMIN (Keluar - Jalur Bawah Kanan)
    admin_outputs = [
        ("Hasil Validasi Gate (Valid / Terpakai)", 1070, 1680),
        ("Laporan Penjualan Tiket & Total Omset", 1115, 1635),
        ("Laporan Realtime Kehadiran Penonton Venue", 1160, 1590),
        ("Daftar Pengajuan Refund & Audit Log", 1205, 1545),
    ]

    for lbl, y_end, x_corner in admin_outputs:
        import math
        dx = x_corner - cx
        if abs(dx) < r_sys:
            y_hit = cy + math.sqrt(r_sys**2 - dx**2)
        else:
            y_hit = cy + 40
        c.line(x_corner, y_hit, x_corner, y_end, lw=1.3)
        c.line(x_corner, y_end, ax, y_end, lw=1.3)
        c.head(ax, y_end, "right", size=7.0)
        c.text((ax + x_corner) / 2, y_end - 6, lbl, f_lbl, anchor="ma")

    # Bus bar vertikal admin bawah
    c.line(ax, ay + ah - 40, ax, 1205, lw=1.3)

    # ==================== C. ALIRAN SISI ATAS (MIDTRANS <-> SISTEM) ====================
    # Jalur vertikal langsung antara kotak Midtrans (y=180) dan bagian atas lingkaran sistem (cy - r_sys = 650)
    # Ada 3 jalur vertikal:
    # 1. Request Transaksi (Sistem -> Midtrans)
    x_m1 = 1010
    c.line(x_m1, cy - r_sys, x_m1, py + ph, lw=1.3)
    c.head(x_m1, py + ph, "up", size=7.0)
    c.text(x_m1 - 8, (py + ph + cy - r_sys) / 2 - 40, "Data Tagihan & Request Transaksi", f_lbl, anchor="ra")

    # 2. Token Snap, VA & QRIS (Midtrans -> Sistem)
    x_m2 = 1100
    c.line(x_m2, py + ph, x_m2, cy - r_sys, lw=1.3)
    c.head(x_m2, cy - r_sys, "down", size=7.0)
    c.text(x_m2 + 8, (py + ph + cy - r_sys) / 2 - 20, "Token Snap, Nomor VA & QRIS Dinamis", f_lbl, anchor="la")

    # 3. Webhook Status Bayar / Settlement (Midtrans -> Sistem)
    x_m3 = 1190
    c.line(x_m3, py + ph, x_m3, cy - r_sys, lw=1.3)
    c.head(x_m3, cy - r_sys, "down", size=7.0)
    c.text(x_m3 + 8, (py + ph + cy - r_sys) / 2 + 30, "Webhook Status Pembayaran (Settlement SHA-512)", f_lbl, anchor="la")

    # ==================== D. ALIRAN SISI BAWAH (FIREBASE <-> SISTEM) ====================
    # Jalur vertikal langsung antara bawah lingkaran (cy + r_sys = 950) dan kotak Firebase (fy = 1420)
    # 1. Request Autentikasi & Verifikasi Token (Sistem -> Firebase)
    x_f1 = 1010
    c.line(x_f1, cy + r_sys, x_f1, fy, lw=1.3)
    c.head(x_f1, fy, "down", size=7.0)
    c.text(x_f1 - 8, (cy + r_sys + fy) / 2 - 30, "Permintaan Verifikasi Autentikasi User", f_lbl, anchor="ra")

    # 2. Token Kredensial & Status UID (Firebase -> Sistem)
    x_f2 = 1080
    c.line(x_f2, fy, x_f2, cy + r_sys, lw=1.3)
    c.head(x_f2, cy + r_sys, "up", size=7.0)
    c.text(x_f2 + 8, (cy + r_sys + fy) / 2 - 30, "Token Kredensial, UID & Email Verified", f_lbl, anchor="la")

    # 3. Payload Notifikasi FCM & Token Perangkat (Sistem -> Firebase)
    x_f3 = 1170
    c.line(x_f3, cy + r_sys, x_f3, fy, lw=1.3)
    c.head(x_f3, fy, "down", size=7.0)
    c.text(x_f3 + 8, (cy + r_sys + fy) / 2 + 30, "Payload Push FCM & Device Token", f_lbl, anchor="la")

    # Simpan file
    out_path = Path(__file__).resolve().parents[1] / "diagram_konteks_soundwave_akademik.png"
    c.save(out_path)
    print("OK", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_academic_context_diagram()
