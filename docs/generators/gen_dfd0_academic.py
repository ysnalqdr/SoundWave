"""Generator DFD Level 0 Soundwave: Presisi Akademik Monokrom.
Mendekomposisi sistem menjadi:
- 4 Entitas Eksternal: USER, ADMIN, PAYMENT GATEWAY, FIREBASE PLATFORM.
- 5 Proses DeMarco: 1.0 (Akun), 2.0 (Event), 3.0 (Pemesanan/Bayar), 4.0 (E-Tiket), 5.0 (Laporan & Notifikasi).
- 5 Data Store: D1 users, D2 events, D3 orders, D4 tickets, D5 promos.
- Garis ortogonal rapi, label teks di atas garis dengan mask penutup tipis (nol strikethrough).
"""
import math
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_dfd0_diagram():
    W, H = 2400, 1800
    c = Canvas(W, H, s=2)

    # 1. HEADER KIRI ATAS
    c.rect(60, 45, 500, 75, lw=1.6)
    c.text(80, 68, "DATA FLOW DIAGRAM (DFD LEVEL 0)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 93, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font styles
    f_ent_title = c.f(SANS_B, 15)
    f_ent_sub = c.f(MONO, 11)
    f_p_num = c.f(MONO_B, 18)
    f_p_title = c.f(SANS_B, 13)
    f_p_sub = c.f(MONO, 10)
    f_ds_id = c.f(MONO_B, 12)
    f_ds_name = c.f(MONO, 11)
    f_lbl = c.f(MONO, 10)
    f_foot = c.f(MONO, 10)

    # Helper: Gambar Data Store (2 Garis Paralel Terbuka di Kanan ala DeMarco/Gane-Sarson)
    def draw_datastore(x, y, w, h, ds_id, ds_name):
        # 2 garis horizontal
        c.line(x, y, x + w, y, lw=1.4)
        c.line(x, y + h, x + w, y + h, lw=1.4)
        # garis penutup kiri & pemisah ID
        c.line(x, y, x, y + h, lw=1.4)
        c.line(x + 45, y, x + 45, y + h, lw=1.2)
        # teks
        c.text(x + 22, y + h / 2, ds_id, f_ds_id, anchor="mm")
        c.text(x + 55, y + h / 2, ds_name, f_ds_name, anchor="lm")

    # Helper: Gambar Lingkaran Proses DeMarco (dengan garis pemisah nomor)
    def draw_process(cx, cy, r, p_num, p_title1, p_title2=""):
        c.d.ellipse(
            [c._p(cx - r, cy - r), c._p(cx + r, cy + r)],
            outline=BLACK,
            width=max(1, int(round(1.8 * c.S))),
            fill=WHITE
        )
        # Garis pemisah nomor proses
        chord_y = cy - r * 0.35
        dx = math.sqrt(r**2 - (chord_y - cy)**2)
        c.line(cx - dx, chord_y, cx + dx, chord_y, lw=1.2)
        c.text(cx, cy - r * 0.65, p_num, f_p_num, anchor="mm")
        if p_title2:
            c.text(cx, cy + 5, p_title1, f_p_title, anchor="mm")
            c.text(cx, cy + 30, p_title2, f_p_title, anchor="mm")
        else:
            c.text(cx, cy + 18, p_title1, f_p_title, anchor="mm")

    # ==================== 2. EMPAT ENTITAS EKSTERNAL ====================
    # USER (Kiri)
    ux, uy, uw, uh = 70, 520, 240, 500
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 235, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 265, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    # ADMIN (Kanan)
    ax, ay, aw, ah = 2090, 520, 240, 500
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 235, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 265, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    # PAYMENT GATEWAY (Atas Tengah)
    px, py, pw, ph = 960, 45, 480, 85
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 34, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 58, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    # FIREBASE PLATFORM (Bawah Tengah)
    fx, fy, fw, fh = 960, 1660, 480, 85
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 34, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 58, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # ==================== 3. LIMA PROSES UTAMA ====================
    # P1.0: Manajemen Akun & Sesi (Kiri Atas)
    p1_cx, p1_cy, p1_r = 600, 360, 95
    draw_process(p1_cx, p1_cy, p1_r, "1.0", "Manajemen Akun", "& Autentikasi")

    # P2.0: Manajemen Event & Katalog (Kanan Atas)
    p2_cx, p2_cy, p2_r = 1800, 360, 95
    draw_process(p2_cx, p2_cy, p2_r, "2.0", "Manajemen Event", "& Katalog Tiket")

    # P3.0: Pemesanan & Pembayaran (Tengah Sentral)
    p3_cx, p3_cy, p3_r = 1200, 780, 115
    draw_process(p3_cx, p3_cy, p3_r, "3.0", "Pemesanan, Hold", "Kuota & Bayar")

    # P4.0: E-Tiket & Validasi Gate (Kiri Bawah)
    p4_cx, p4_cy, p4_r = 600, 1260, 95
    draw_process(p4_cx, p4_cy, p4_r, "4.0", "Penerbitan Tiket", "& Validasi Gate")

    # P5.0: Pelaporan & Notifikasi (Kanan Bawah)
    p5_cx, p5_cy, p5_r = 1800, 1260, 95
    draw_process(p5_cx, p5_cy, p5_r, "5.0", "Pelaporan & Notif", "Sistem (FCM)")

    # ==================== 4. LIMA DATA STORE ====================
    # D1: users (di antara P1.0 dan P3.0)
    draw_datastore(780, 480, 200, 40, "D1", "users")

    # D2: events (di antara P2.0 dan P3.0)
    draw_datastore(1420, 480, 200, 40, "D2", "events")

    # D3: orders (di bawah P3.0)
    draw_datastore(1100, 1020, 200, 40, "D3", "orders")

    # D4: tickets (di antara P4.0 dan P3.0/P5.0)
    draw_datastore(780, 1090, 200, 40, "D4", "tickets")

    # D5: promos (di antara P3.0 dan P2.0)
    draw_datastore(1420, 1090, 200, 40, "D5", "promos")

    # ==================== 5. ALIRAN DATA ORTOGONAL ====================

    # Helper potong lingkaran
    def circle_pt(cx, cy, r, angle_deg):
        rad = math.radians(angle_deg)
        return cx + r * math.cos(rad), cy + r * math.sin(rad)

    # A. USER <-> P1.0 (Akun)
    # User -> P1.0
    c.line(ux + uw, 340, p1_cx - p1_r, 340, lw=1.3)
    c.head(p1_cx - p1_r, 340, "right", size=6.5)
    c.mask_text((ux + uw + p1_cx - p1_r) / 2, 330, "Data Registrasi & Login", f_lbl, pad=3)

    # P1.0 -> User
    c.line(p1_cx - p1_r, 380, ux + uw, 380, lw=1.3)
    c.head(ux + uw, 380, "left", size=6.5)
    c.mask_text((ux + uw + p1_cx - p1_r) / 2, 370, "Info Profil & Sesi Token", f_lbl, pad=3)

    # B. P1.0 <-> D1: users
    c.line(p1_cx + p1_r * 0.7, p1_cy + p1_r * 0.7, 780, 500, lw=1.3)
    c.head(780, 500, "right", size=6.5)
    c.mask_text(710, 465, "Simpan / Baca Profil", f_lbl, pad=3)

    # C. P1.0 <-> FIREBASE (Auth)
    c.line(p1_cx, p1_cy + p1_r, p1_cx, 1690, lw=1.3)
    c.line(p1_cx, 1690, fx, 1690, lw=1.3)
    c.head(fx, 1690, "right", size=6.5)
    c.mask_text(p1_cx - 85, 1000, "Kredensial Auth UID", f_lbl, pad=3)

    # D. ADMIN <-> P1.0 (Login Admin)
    # Admin -> P1.0 via jalur atas
    c.line(ax + aw / 2, uy, ax + aw / 2, 220, lw=1.3)
    c.line(ax + aw / 2, 220, p1_cx, 220, lw=1.3)
    c.line(p1_cx, 220, p1_cx, p1_cy - p1_r, lw=1.3)
    c.head(p1_cx, p1_cy - p1_r, "down", size=6.5)
    c.mask_text(1300, 210, "Kredensial Login Administrator", f_lbl, pad=3)

    # E. ADMIN <-> P2.0 (Event & Tiket)
    # Admin -> P2.0
    c.line(ax, 340, p2_cx + p2_r, 340, lw=1.3)
    c.head(p2_cx + p2_r, 340, "left", size=6.5)
    c.mask_text((ax + p2_cx + p2_r) / 2, 330, "Setup Konser & Alokasi Kuota", f_lbl, pad=3)

    # P2.0 -> Admin
    c.line(p2_cx + p2_r, 380, ax, 380, lw=1.3)
    c.head(ax, 380, "right", size=6.5)
    c.mask_text((ax + p2_cx + p2_r) / 2, 370, "Status Publikasi Event", f_lbl, pad=3)

    # F. P2.0 <-> D2: events
    c.line(p2_cx - p2_r * 0.7, p2_cy + p2_r * 0.7, 1620, 500, lw=1.3)
    c.head(1620, 500, "left", size=6.5)
    c.mask_text(1690, 465, "Update Jadwal & Kuota", f_lbl, pad=3)

    # G. P2.0 -> USER (Katalog Konser)
    c.line(p2_cx, p2_cy - p2_r, p2_cx, 260, lw=1.3)
    c.line(p2_cx, 260, 400, 260, lw=1.3)
    c.line(400, 260, 400, 560, lw=1.3)
    c.line(400, 560, ux + uw, 560, lw=1.3)
    c.head(ux + uw, 560, "left", size=6.5)
    c.mask_text(1050, 250, "Katalog Konser Musik & Info Tiket", f_lbl, pad=3)

    # H. USER <-> P3.0 (Pemesanan & Bayar)
    # User -> P3.0
    c.line(ux + uw, 740, p3_cx - p3_r, 740, lw=1.3)
    c.head(p3_cx - p3_r, 740, "right", size=6.5)
    c.mask_text((ux + uw + p3_cx - p3_r) / 2, 728, "Data Pesan Tiket & Kupon Promo", f_lbl, pad=3)

    # P3.0 -> User
    c.line(p3_cx - p3_r, 820, ux + uw, 820, lw=1.3)
    c.head(ux + uw, 820, "left", size=6.5)
    c.mask_text((ux + uw + p3_cx - p3_r) / 2, 808, "Invoice & Hold Kuota 5 Menit", f_lbl, pad=3)

    # I. P3.0 <-> MIDTRANS (Payment Gateway)
    # P3.0 -> Midtrans
    c.line(1120, p3_cy - p3_r, 1120, py + ph, lw=1.3)
    c.head(1120, py + ph, "up", size=6.5)
    c.mask_text(1030, 450, "Parameter Tagihan", f_lbl, pad=3)

    # Midtrans -> P3.0
    c.line(1280, py + ph, 1280, p3_cy - p3_r, lw=1.3)
    c.head(1280, p3_cy - p3_r, "down", size=6.5)
    c.mask_text(1380, 435, "Snap Token, VA, QRIS", f_lbl, pad=3)
    c.mask_text(1380, 460, "Webhook Settlement SHA-512", f_lbl, pad=3)

    # J. P3.0 <-> DATA STORES (D2, D3, D5)
    # P3.0 <-> D2: events (Cek & Hold Kuota)
    c.line(p3_cx + p3_r * 0.8, p3_cy - p3_r * 0.5, 1520, 520, lw=1.3)
    c.head(1520, 520, "up", size=6.5)
    c.mask_text(1420, 600, "Atomic Hold Kuota", f_lbl, pad=3)

    # P3.0 <-> D5: promos (Cek Promo)
    c.line(p3_cx + p3_r * 0.7, p3_cy + p3_r * 0.7, 1520, 1090, lw=1.3)
    c.head(1520, 1090, "down", size=6.5)
    c.mask_text(1440, 960, "Validasi Kode Promo", f_lbl, pad=3)

    # P3.0 -> D3: orders (Simpan Order Sukses)
    c.line(p3_cx, p3_cy + p3_r, p3_cx, 1020, lw=1.3)
    c.head(p3_cx, 1020, "down", size=6.5)
    c.mask_text(p3_cx - 75, 960, "Simpan Transaksi", f_lbl, pad=3)

    # K. P3.0 -> D4: tickets (Terbitkan Tiket Lunas)
    c.line(p3_cx - p3_r * 0.7, p3_cy + p3_r * 0.7, 880, 1090, lw=1.3)
    c.head(880, 1090, "down", size=6.5)
    c.mask_text(940, 960, "Generate E-Tiket", f_lbl, pad=3)

    # L. D4: tickets -> P4.0 (Ambil Tiket)
    c.line(780, 1110, p4_cx + p4_r * 0.7, p4_cy - p4_r * 0.7, lw=1.3)
    c.head(p4_cx + p4_r * 0.7, p4_cy - p4_r * 0.7, "down", size=6.5)
    c.mask_text(710, 1170, "Data Tiket Lunas", f_lbl, pad=3)

    # M. P4.0 <-> USER (Kirim E-Tiket)
    c.line(p4_cx - p4_r, 1240, ux + uw, 1240, lw=1.3)
    c.line(ux + uw, 1240, ux + uw, uy + uh - 40, lw=1.3)
    c.head(ux + uw, uy + uh - 40, "up", size=6.5)
    c.mask_text((p4_cx - p4_r + ux + uw) / 2, 1228, "E-Tiket QR Ed25519", f_lbl, pad=3)

    # N. ADMIN <-> P4.0 (Offline Gate Scan)
    # Admin -> P4.0 (jalur bawah)
    c.line(ax, 880, 1680, 880, lw=1.3)
    c.line(1680, 880, 1680, 1420, lw=1.3)
    c.line(1680, 1420, p4_cx + p4_r, 1420, lw=1.3)
    c.line(p4_cx + p4_r, 1420, p4_cx + p4_r, p4_cy + p4_r * 0.4, lw=1.3)
    c.head(p4_cx + p4_r, p4_cy + p4_r * 0.4, "up", size=6.5)
    c.mask_text(1150, 1408, "Data Scan Tiket Gate (Offline Scan)", f_lbl, pad=3)

    # P4.0 -> Admin (Hasil Validasi)
    c.line(p4_cx + p4_r, p4_cy - p4_r * 0.2, 1650, p4_cy - p4_r * 0.2, lw=1.3)
    c.line(1650, p4_cy - p4_r * 0.2, 1650, 920, lw=1.3)
    c.line(1650, 920, ax, 920, lw=1.3)
    c.head(ax, 920, "right", size=6.5)
    c.mask_text(1150, p4_cy - p4_r * 0.2 - 12, "Status Validasi Gate (Valid/Invalid)", f_lbl, pad=3)

    # O. P5.0 (Pelaporan & Notifikasi FCM)
    # D3: orders -> P5.0
    c.line(1300, 1040, p5_cx - p5_r * 0.8, p5_cy - p5_r * 0.4, lw=1.3)
    c.head(p5_cx - p5_r * 0.8, p5_cy - p5_r * 0.4, "down", size=6.5)
    c.mask_text(1520, 1170, "Rekap Penjualan", f_lbl, pad=3)

    # D4: tickets -> P5.0
    c.line(980, 1110, p5_cx - p5_r, p5_cy + p5_r * 0.2, lw=1.3)
    c.head(p5_cx - p5_r, p5_cy + p5_r * 0.2, "right", size=6.5)
    c.mask_text(1380, 1260, "Data Kehadiran Venue", f_lbl, pad=3)

    # P5.0 -> ADMIN (Laporan)
    c.line(p5_cx + p5_r, 1260, ax + aw / 2, 1260, lw=1.3)
    c.line(ax + aw / 2, 1260, ax + aw / 2, uy + uh, lw=1.3)
    c.head(ax + aw / 2, uy + uh, "up", size=6.5)
    c.mask_text((p5_cx + p5_r + ax + aw / 2) / 2, 1248, "Laporan Omset & Kehadiran", f_lbl, pad=3)

    # P5.0 -> FIREBASE (Push Notification FCM)
    c.line(p5_cx, p5_cy + p5_r, p5_cx, 1700, lw=1.3)
    c.line(p5_cx, 1700, fx + fw, 1700, lw=1.3)
    c.head(fx + fw, 1700, "left", size=6.5)
    c.mask_text(p5_cx + 85, 1500, "Payload FCM Push Notif", f_lbl, pad=3)

    # ==================== FOOTER ====================
    fy_line = 1750
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 0 (DFD 0) — Sistem Informasi SoundWave.", f_foot)
    c.text(60, fy_line + 30, "Mendekomposisi proses sistem menjadi 5 proses logis utama dan 5 data store sinkron dengan arsitektur produksi.", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Yourdon & Coad / DeMarco Akademik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_level_0_soundwave_akademik.png"
    c.save(out_path)
    print("OK DFD 0 rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_dfd0_diagram()
