"""Generator DFD Level 0/1 Soundwave: Style 1 (3 Kolom Linear Terstruktur).
Mengadopsi format referensi WhatsApp image:
- Kolom Kiri: 4 Entitas Eksternal (User, Admin, Payment Gateway, Firebase Platform).
- Kolom Tengah: 5 Proses Bisnis Gane & Sarson (Rounded Rect bersekat nomor ID).
- Kolom Kanan: 5 Data Store Gane & Sarson (Open-ended rect bersekat D1..D5).
- Alur ortogonal 100% murni, nol persilangan, label teks di atas garis dengan mask putih tipis.
"""
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_style1_diagram():
    W, H = 2500, 2050
    c = Canvas(W, H, s=2)

    # 1. HEADER KIRI ATAS
    c.rect(60, 45, 540, 80, lw=1.6)
    c.text(80, 70, "DATA FLOW DIAGRAM (3-COLUMN LINEAR)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 95, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font styles
    f_col_header = c.f(SANS_B, 15)
    f_ent_title = c.f(SANS_B, 15)
    f_ent_sub = c.f(MONO, 11)
    f_p_id = c.f(MONO_B, 14)
    f_p_title = c.f(SANS_B, 13)
    f_p_sub = c.f(MONO, 10)
    f_ds_id = c.f(MONO_B, 13)
    f_ds_name = c.f(MONO_B, 12)
    f_lbl = c.f(MONO, 10)
    f_foot = c.f(MONO, 10)

    # Indikator Kolom di bagian atas
    c.mask_text(210, 160, "[ 1. EXTERNAL ENTITIES ]", f_col_header, pad=3)
    c.mask_text(1150, 160, "[ 2. BUSINESS PROCESSES (GANE & SARSON) ]", f_col_header, pad=3)
    c.mask_text(2120, 160, "[ 3. DATA STORES ]", f_col_header, pad=3)

    # Garis pemisah kolom halus (dashed atau batas imajiner)
    c.line(480, 185, 480, 1950, lw=0.8)
    c.line(1780, 185, 1780, 1950, lw=0.8)

    # Helper: Gambar Proses Gane & Sarson (Rounded Rect bersekat)
    def draw_process_gs(x, y, w, h, pid, title, desc=""):
        # Kotak rounded
        c.d.rounded_rectangle(
            [c._p(x, y), c._p(x + w, y + h)],
            radius=int(14 * c.S),
            outline=BLACK,
            width=max(1, int(round(1.8 * c.S))),
            fill=WHITE
        )
        # Sekat horizontal nomor proses
        sekat_y = y + 36
        c.line(x, sekat_y, x + w, sekat_y, lw=1.4)
        c.text(x + w / 2, y + 18, f"PROSES {pid}", f_p_id, anchor="mm")
        if desc:
            c.text(x + w / 2, y + 62, title, f_p_title, anchor="mm")
            c.text(x + w / 2, y + 88, desc, f_p_sub, anchor="mm")
        else:
            c.text(x + w / 2, y + 75, title, f_p_title, anchor="mm")

    # Helper: Gambar Data Store Gane & Sarson (Open-ended rect)
    def draw_datastore_gs(x, y, w, h, ds_id, ds_name):
        c.line(x, y, x + w, y, lw=1.4)
        c.line(x, y + h, x + w, y + h, lw=1.4)
        c.line(x, y, x, y + h, lw=1.4)
        c.line(x + 55, y, x + 55, y + h, lw=1.2)
        c.text(x + 28, y + h / 2, ds_id, f_ds_id, anchor="mm")
        c.text(x + 70, y + h / 2, ds_name, f_ds_name, anchor="lm")

    # ==================== 1. KOLOM KIRI: 4 ENTITAS ====================
    # USER (Kiri Atas)
    ux, uy, uw, uh = 70, 240, 280, 360
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 165, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 195, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    # ADMIN (Kiri Tengah Atas)
    ax, ay, aw, ah = 70, 680, 280, 360
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 165, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 195, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    # PAYMENT GATEWAY (Kiri Tengah Bawah)
    px, py, pw, ph = 70, 1120, 280, 340
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 155, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 185, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    # FIREBASE PLATFORM (Kiri Bawah)
    fx, fy, fw, fh = 70, 1540, 280, 340
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 155, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 185, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # ==================== 2. KOLOM TENGAH: 5 PROSES ====================
    px_mid = 900
    pw_mid = 500

    # 1.0 Akun & Autentikasi
    p1_y, p1_h = 240, 115
    draw_process_gs(px_mid, p1_y, pw_mid, p1_h, "1.0", "MANAJEMEN AKUN & AUTENTIKASI", "Registrasi, Login, Profil User & Admin")

    # 2.0 Manajemen Event & Katalog
    p2_y, p2_h = 580, 115
    draw_process_gs(px_mid, p2_y, pw_mid, p2_h, "2.0", "MANAJEMEN EVENT & KATALOG TIKET", "Setup Konser, Alokasi Kuota, Katalog Musik")

    # 3.0 Pemesanan, Hold Kuota & Pembayaran
    p3_y, p3_h = 920, 125
    draw_process_gs(px_mid, p3_y, pw_mid, p3_h, "3.0", "PEMESANAN, HOLD KUOTA & PEMBAYARAN", "Atomic Hold 5 Mnt, Promo, Snap VA/QRIS, Webhook")

    # 4.0 Penerbitan Tiket & Validasi Gate
    p4_y, p4_h = 1270, 115
    draw_process_gs(px_mid, p4_y, pw_mid, p4_h, "4.0", "PENERBITAN TIKET & VALIDASI GATE", "Generate QR Ed25519 & Offline Gate Scanner")

    # 5.0 Pelaporan & Notifikasi Sistem
    p5_y, p5_h = 1610, 115
    draw_process_gs(px_mid, p5_y, pw_mid, p5_h, "5.0", "PELAPORAN & NOTIFIKASI SISTEM", "Rekap Penjualan, Kehadiran Venue & FCM Push")

    # ==================== 3. KOLOM KANAN: 5 DATA STORE ====================
    ds_x = 1920
    ds_w = 480
    ds_h = 50

    draw_datastore_gs(ds_x, 272, ds_w, ds_h, "D1", "users (Profil Akun & Kredensial)")
    draw_datastore_gs(ds_x, 612, ds_w, ds_h, "D2", "events (Jadwal Konser & Kuota Tiket)")
    draw_datastore_gs(ds_x, 957, ds_w, ds_h, "D3", "orders (Pemesanan & Status Bayar)")
    draw_datastore_gs(ds_x, 1302, ds_w, ds_h, "D4", "tickets (Record E-Tiket & Status Scan)")
    draw_datastore_gs(ds_x, 1642, ds_w, ds_h, "D5", "promos (Kupon Diskon & Kuota Kupon)")

    # ==================== 4. ALIRAN DATA ORTOGONAL (100% SIKU) ====================

    # --------- A. PROSES 1.0 (AKUN) ---------
    # User -> P1.0
    c.line(ux + uw, 270, px_mid, 270, lw=1.3)
    c.head(px_mid, 270, "right", size=6.5)
    c.mask_text((ux + uw + px_mid) / 2, 258, "Data Registrasi & Login", f_lbl, pad=3)

    # P1.0 -> User
    c.line(px_mid, 320, ux + uw, 320, lw=1.3)
    c.head(ux + uw, 320, "left", size=6.5)
    c.mask_text((ux + uw + px_mid) / 2, 308, "Informasi Profil & Sesi Token", f_lbl, pad=3)

    # P1.0 <-> D1 (users)
    c.line(px_mid + pw_mid, 297, ds_x, 297, lw=1.3)
    c.head(ds_x, 297, "right", size=6.5)
    c.mask_text((px_mid + pw_mid + ds_x) / 2, 285, "Simpan / Baca Data User", f_lbl, pad=3)

    # P1.0 <-> Firebase (Auth Token via koridor kiri)
    c.line(fx + uw, 1600, 560, 1600, lw=1.3)
    c.line(560, 1600, 560, 345, lw=1.3)
    c.line(560, 345, px_mid, 345, lw=1.3)
    c.head(px_mid, 345, "right", size=6.5)
    c.mask_text(560, 850, "Verifikasi Token Kredensial UID", f_lbl, pad=3)

    # --------- B. PROSES 2.0 (EVENT & KATALOG) ---------
    # Admin -> P2.0
    c.line(ax + aw, 720, 680, 720, lw=1.3)
    c.line(680, 720, 680, 610, lw=1.3)
    c.line(680, 610, px_mid, 610, lw=1.3)
    c.head(px_mid, 610, "right", size=6.5)
    c.mask_text(740, 598, "Setup Event Konser & Kuota", f_lbl, pad=3)

    # P2.0 -> User (Katalog Konser)
    c.line(px_mid, 650, 620, 650, lw=1.3)
    c.line(620, 650, 620, 480, lw=1.3)
    c.line(620, 480, ux + uw, 480, lw=1.3)
    c.head(ux + uw, 480, "left", size=6.5)
    c.mask_text(620, 530, "Katalog Konser Musik & Info Tiket", f_lbl, pad=3)

    # P2.0 <-> D2 (events)
    c.line(px_mid + pw_mid, 637, ds_x, 637, lw=1.3)
    c.head(ds_x, 637, "right", size=6.5)
    c.mask_text((px_mid + pw_mid + ds_x) / 2, 625, "Simpan / Update Jadwal & Kuota", f_lbl, pad=3)

    # --------- C. PROSES 3.0 (ORDER & BAYAR) ---------
    # User -> P3.0
    c.line(ux + uw, 530, 720, 530, lw=1.3)
    c.line(720, 530, 720, 950, lw=1.3)
    c.line(720, 950, px_mid, 950, lw=1.3)
    c.head(px_mid, 950, "right", size=6.5)
    c.mask_text(720, 750, "Pemesanan Tiket & Kode Promo", f_lbl, pad=3)

    # P3.0 -> User
    c.line(px_mid, 990, 780, 990, lw=1.3)
    c.line(780, 990, 780, 570, lw=1.3)
    c.line(780, 570, ux + uw, 570, lw=1.3)
    c.head(ux + uw, 570, "left", size=6.5)
    c.mask_text(780, 800, "Tagihan & Hold Kuota 5 Menit", f_lbl, pad=3)

    # P3.0 <-> Payment Gateway (Midtrans)
    # P3.0 -> Midtrans
    c.line(px_mid, 1030, 640, 1030, lw=1.3)
    c.line(640, 1030, 640, 1220, lw=1.3)
    c.line(640, 1220, px + pw, 1220, lw=1.3)
    c.head(px + pw, 1220, "left", size=6.5)
    c.mask_text(640, 1140, "Parameter Tagihan Transaksi", f_lbl, pad=3)

    # Midtrans -> P3.0
    c.line(px + pw, 1280, 700, 1280, lw=1.3)
    c.line(700, 1280, 700, 1040, lw=1.3)
    c.line(700, 1040, px_mid, 1040, lw=1.3)
    c.head(px_mid, 1040, "right", size=6.5)
    c.mask_text(700, 1190, "Snap Token, VA, QRIS & Webhook SHA-512", f_lbl, pad=3)

    # P3.0 -> D3 (orders)
    c.line(px_mid + pw_mid, 982, ds_x, 982, lw=1.3)
    c.head(ds_x, 982, "right", size=6.5)
    c.mask_text((px_mid + pw_mid + ds_x) / 2, 970, "Simpan Record Pemesanan & Status Lunas", f_lbl, pad=3)

    # P3.0 <-> D2 (Hold Kuota via Manhattan koridor kanan)
    c.line(px_mid + pw_mid, 940, 1600, 940, lw=1.3)
    c.line(1600, 940, 1600, 650, lw=1.3)
    c.line(1600, 650, ds_x, 650, lw=1.3)
    c.head(ds_x, 650, "right", size=6.5)
    c.mask_text(1600, 780, "Atomic Hold Kuota Tiket", f_lbl, pad=3)

    # P3.0 <-> D5 (Validasi Promo via Manhattan koridor kanan)
    c.line(px_mid + pw_mid, 1020, 1650, 1020, lw=1.3)
    c.line(1650, 1020, 1650, 1667, lw=1.3)
    c.line(1650, 1667, ds_x, 1667, lw=1.3)
    c.head(ds_x, 1667, "right", size=6.5)
    c.mask_text(1650, 1340, "Cek & Validasi Kupon Promo", f_lbl, pad=3)

    # P3.0 -> D4 (Generate Record Tiket Lunas)
    c.line(px_mid + pw_mid, 1000, 1720, 1000, lw=1.3)
    c.line(1720, 1000, 1720, 1327, lw=1.3)
    c.line(1720, 1327, ds_x, 1327, lw=1.3)
    c.head(ds_x, 1327, "right", size=6.5)
    c.mask_text(1720, 1160, "Generate Record Tiket Lunas", f_lbl, pad=3)

    # --------- D. PROSES 4.0 (E-TIKET & GATE) ---------
    # D4 -> P4.0 (Ambil Tiket)
    c.line(ds_x, 1315, px_mid + pw_mid, 1315, lw=1.3)
    c.head(px_mid + pw_mid, 1315, "left", size=6.5)
    c.mask_text((px_mid + pw_mid + ds_x) / 2, 1303, "Ambil Tiket Terbit & Data QR Ed25519", f_lbl, pad=3)

    # P4.0 -> User (E-Tiket QR Ed25519)
    c.line(px_mid, 1310, 840, 1310, lw=1.3)
    c.line(840, 1310, 840, 420, lw=1.3)
    c.line(840, 420, ux + uw, 420, lw=1.3)
    c.head(ux + uw, 420, "left", size=6.5)
    c.mask_text(840, 880, "Penerbitan E-Tiket QR Ed25519", f_lbl, pad=3)

    # Admin -> P4.0 (Scan Gate Offline)
    c.line(ax + aw, 840, 760, 840, lw=1.3)
    c.line(760, 840, 760, 1340, lw=1.3)
    c.line(760, 1340, px_mid, 1340, lw=1.3)
    c.head(px_mid, 1340, "right", size=6.5)
    c.mask_text(760, 1090, "Data Pindaian Tiket Gate (Offline)", f_lbl, pad=3)

    # P4.0 -> Admin (Status Validasi Gate)
    c.line(px_mid, 1370, 800, 1370, lw=1.3)
    c.line(800, 1370, 800, 920, lw=1.3)
    c.line(800, 920, ax + aw, 920, lw=1.3)
    c.head(ax + aw, 920, "left", size=6.5)
    c.mask_text(800, 1140, "Status Validasi Gate (Valid / Invalid)", f_lbl, pad=3)

    # --------- E. PROSES 5.0 (LAPORAN & NOTIF) ---------
    # D3 -> P5.0 (Data Omset)
    c.line(ds_x, 995, 1550, 995, lw=1.3)
    c.line(1550, 995, 1550, 1640, lw=1.3)
    c.line(1550, 1640, px_mid + pw_mid, 1640, lw=1.3)
    c.head(px_mid + pw_mid, 1640, "left", size=6.5)
    c.mask_text(1550, 1420, "Data Omset & Transaksi Lunas", f_lbl, pad=3)

    # P5.0 -> Admin (Laporan Penjualan & Kehadiran)
    c.line(px_mid, 1640, 860, 1640, lw=1.3)
    c.line(860, 1640, 860, 980, lw=1.3)
    c.line(860, 980, ax + aw, 980, lw=1.3)
    c.head(ax + aw, 980, "left", size=6.5)
    c.mask_text(860, 1310, "Laporan Penjualan & Kehadiran Venue", f_lbl, pad=3)

    # P5.0 -> Firebase (Push Notification FCM)
    c.line(px_mid, 1690, fx + fw, 1690, lw=1.3)
    c.head(fx + fw, 1690, "left", size=6.5)
    c.mask_text((px_mid + fx + fw) / 2, 1678, "Dispatch Payload Push Notifikasi FCM", f_lbl, pad=3)

    # ==================== FOOTER ====================
    fy_line = 1980
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 1 (DFD 1) — Style 1: 3-Column Linear Architecture (Gane & Sarson).", f_foot)
    c.text(60, fy_line + 30, "Mendekomposisi aliran sistem SoundWave secara teratur: Entitas Eksternal (Kiri) -> Proses Inti (Tengah) -> Data Store (Kanan).", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Gane & Sarson / DeMarco Linear", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_style1_linear_soundwave.png"
    c.save(out_path)
    print("OK Style 1 DFD rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_style1_diagram()
