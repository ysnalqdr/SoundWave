"""Generator DFD Level 0 Soundwave: Presisi Akademik Sempurna (v2).
Perbaikan Total:
1. 100% Manhattan Routing (hanya garis siku 90 derajat, nol garis diagonal).
2. Nol garis menembus lingkaran proses atau entitas luar.
3. Grid simetris & terstruktur: D1 & D2 sejajar, D4 & D5 sejajar, D3 di tengah.
4. Masking teks putih sempurna di semua label (nol strikethrough/potongan teks).
5. Kerapian dan estetika standar teknik akademik tinggi.
"""
import math
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_perfect_dfd0():
    W, H = 2400, 1800
    c = Canvas(W, H, s=2)

    # 1. HEADER KIRI ATAS
    c.rect(60, 45, 520, 80, lw=1.6)
    c.text(80, 70, "DATA FLOW DIAGRAM (DFD LEVEL 0)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 95, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font styles
    f_ent_title = c.f(SANS_B, 15)
    f_ent_sub = c.f(MONO, 11)
    f_p_num = c.f(MONO_B, 18)
    f_p_title = c.f(SANS_B, 13)
    f_ds_id = c.f(MONO_B, 12)
    f_ds_name = c.f(MONO, 11)
    f_lbl = c.f(MONO, 9.8)
    f_foot = c.f(MONO, 10)

    # Helper: Gambar Data Store (2 Garis Paralel Terbuka di Kanan)
    def draw_datastore(x, y, w, h, ds_id, ds_name):
        c.line(x, y, x + w, y, lw=1.4)
        c.line(x, y + h, x + w, y + h, lw=1.4)
        c.line(x, y, x, y + h, lw=1.4)
        c.line(x + 45, y, x + 45, y + h, lw=1.2)
        c.text(x + 22, y + h / 2, ds_id, f_ds_id, anchor="mm")
        c.text(x + 55, y + h / 2, ds_name, f_ds_name, anchor="lm")

    # Helper: Gambar Lingkaran Proses DeMarco
    def draw_process(cx, cy, r, p_num, p_title1, p_title2=""):
        c.d.ellipse(
            [c._p(cx - r, cy - r), c._p(cx + r, cy + r)],
            outline=BLACK,
            width=max(1, int(round(1.8 * c.S))),
            fill=WHITE
        )
        chord_y = cy - r * 0.35
        dx = math.sqrt(r**2 - (chord_y - cy)**2)
        c.line(cx - dx, chord_y, cx + dx, chord_y, lw=1.2)
        c.text(cx, cy - r * 0.65, p_num, f_p_num, anchor="mm")
        if p_title2:
            c.text(cx, cy + 6, p_title1, f_p_title, anchor="mm")
            c.text(cx, cy + 28, p_title2, f_p_title, anchor="mm")
        else:
            c.text(cx, cy + 18, p_title1, f_p_title, anchor="mm")

    # ==================== 2. EMPAT ENTITAS EKSTERNAL ====================
    # USER (Kiri)
    ux, uy, uw, uh = 70, 560, 240, 520
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 245, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 275, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    # ADMIN (Kanan)
    ax, ay, aw, ah = 2090, 560, 240, 520
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 245, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 275, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    # PAYMENT GATEWAY (Atas)
    px, py, pw, ph = 960, 50, 480, 85
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 34, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 58, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    # FIREBASE PLATFORM (Bawah)
    fx, fy, fw, fh = 960, 1660, 480, 85
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 34, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 58, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # ==================== 3. LIMA PROSES UTAMA ====================
    p1_cx, p1_cy, p1_r = 650, 360, 95
    draw_process(p1_cx, p1_cy, p1_r, "1.0", "Manajemen Akun", "& Autentikasi")

    p2_cx, p2_cy, p2_r = 1750, 360, 95
    draw_process(p2_cx, p2_cy, p2_r, "2.0", "Manajemen Event", "& Katalog Tiket")

    p3_cx, p3_cy, p3_r = 1200, 580, 115
    draw_process(p3_cx, p3_cy, p3_r, "3.0", "Pemesanan, Hold", "Kuota & Bayar")

    p4_cx, p4_cy, p4_r = 650, 1380, 95
    draw_process(p4_cx, p4_cy, p4_r, "4.0", "Penerbitan Tiket", "& Validasi Gate")

    p5_cx, p5_cy, p5_r = 1750, 1380, 95
    draw_process(p5_cx, p5_cy, p5_r, "5.0", "Pelaporan & Notif", "Sistem (FCM)")

    # ==================== 4. TUJUH DATA STORE (GRID SEJAJAR) ====================
    #
    # KOREKSI (audit Okt 2026): koleksi Firestore yang BENAR-BENAR dipakai kode
    # diperiksa ulang. Hasilnya:
    #   * "promos" ternyata DUA koleksi berbeda: `promo_codes` (katalog promo
    #     buatan admin) dan `claimed_promos` (voucher milik pembeli, subkoleksi
    #     di bawah users). Keduanya satu kotak akan menyesatkan.
    #   * `refunds` dan `gate_scans` sama sekali belum tergambar, padahal
    #     keduanya punya alur penuh: refund punya persetujuan admin, dan
    #     gate_scans adalah inti mode offline petugas.
    #
    # Baris Data Store 1 (Tengah Atas): y = 840
    draw_datastore(520, 840, 230, 42, "D1", "users")
    draw_datastore(1100, 840, 230, 42, "D3", "orders")
    draw_datastore(1680, 840, 230, 42, "D2", "events")

    # Baris Data Store 2 (Tengah Bawah): y = 1060
    draw_datastore(420, 1060, 230, 42, "D4", "tickets")
    draw_datastore(880, 1060, 250, 42, "D5", "promo_codes")
    draw_datastore(1380, 1060, 250, 42, "D6", "claimed_promos")
    draw_datastore(1810, 1060, 230, 42, "D7", "refunds")

    # Baris Data Store 3 (Bawah): y = 1180
    #
    # KOREKSI KEDUA (audit Okt 2026): pemeriksaan ulang konstanta koleksi di
    # `app_constants.dart` menemukan TIGA koleksi lain yang dipakai kode tapi
    # belum tergambar sama sekali:
    #   * `favorites`     — daftar konser favorit per pengguna
    #   * `reviews`       — ulasan & rating pembeli
    #   * `notifications` — notifikasi in-app (dibaca user, ditulis sistem)
    # Ketiganya bukan data sepele: favorit dan ulasan dibaca di layar Jelajah
    # dan detail konser, notifikasi dipakai di panel notifikasi.
    draw_datastore(420, 1180, 230, 42, "D8", "gate_scans")
    draw_datastore(880, 1180, 230, 42, "D9", "reviews")
    draw_datastore(1180, 1180, 250, 42, "D10", "notifications")
    draw_datastore(1500, 1180, 230, 42, "D11", "favorites")

    # ==================== 5. ALIRAN DATA 100% ORTOGONAL ====================

    # --- A. PROSES 1.0 (AKUN & AUTH) ---
    # 1. User -> P1.0
    c.line(ux + uw, 335, p1_cx - p1_r, 335, lw=1.3)
    c.head(p1_cx - p1_r, 335, "right", size=6.5)
    c.mask_text((ux + uw + p1_cx - p1_r) / 2, 324, "Data Registrasi & Login", f_lbl, pad=3)

    # 2. P1.0 -> User
    c.line(p1_cx - p1_r, 385, ux + uw, 385, lw=1.3)
    c.head(ux + uw, 385, "left", size=6.5)
    c.mask_text((ux + uw + p1_cx - p1_r) / 2, 374, "Info Profil & Token Sesi", f_lbl, pad=3)

    # 3. P1.0 -> D1: users (Garis vertikal murni x = 650)
    c.line(p1_cx, p1_cy + p1_r, p1_cx, 840, lw=1.3)
    c.head(p1_cx, 840, "down", size=6.5)
    c.mask_text(p1_cx - 85, 620, "Simpan / Baca Profil", f_lbl, pad=3)

    # 4. P1.0 -> Firebase (Bypass luar: kiri koridor x = 400)
    c.line(p1_cx - p1_r * 0.7, p1_cy + p1_r * 0.7, 400, p1_cy + p1_r * 0.7, lw=1.3)
    c.line(400, p1_cy + p1_r * 0.7, 400, 1690, lw=1.3)
    c.line(400, 1690, fx, 1690, lw=1.3)
    c.head(fx, 1690, "right", size=6.5)
    c.mask_text(400, 1200, "Verifikasi Token Auth UID", f_lbl, pad=3)

    # --- B. PROSES 2.0 (EVENT & KATALOG TIKET) ---
    # 1. Admin -> P2.0
    c.line(ax, 335, p2_cx + p2_r, 335, lw=1.3)
    c.head(p2_cx + p2_r, 335, "left", size=6.5)
    c.mask_text((ax + p2_cx + p2_r) / 2, 324, "Setup Event & Kuota Tiket", f_lbl, pad=3)

    # 2. P2.0 -> Admin
    c.line(p2_cx + p2_r, 385, ax, 385, lw=1.3)
    c.head(ax, 385, "right", size=6.5)
    c.mask_text((ax + p2_cx + p2_r) / 2, 374, "Status Publikasi Event", f_lbl, pad=3)

    # 3. P2.0 -> D2: events (Garis vertikal murni x = 1750)
    c.line(p2_cx, p2_cy + p2_r, p2_cx, 840, lw=1.3)
    c.head(p2_cx, 840, "down", size=6.5)
    c.mask_text(p2_cx + 85, 620, "Update Jadwal & Kuota", f_lbl, pad=3)

    # 4. P2.0 -> User (Katalog Event lewat koridor atas y = 200 bebas hambatan)
    c.line(p2_cx, p2_cy - p2_r, p2_cx, 200, lw=1.3)
    c.line(p2_cx, 200, 360, 200, lw=1.3)
    c.line(360, 200, 360, 600, lw=1.3)
    c.line(360, 600, ux + uw, 600, lw=1.3)
    c.head(ux + uw, 600, "left", size=6.5)
    c.mask_text(1100, 189, "Katalog Konser Musik & Info Tiket", f_lbl, pad=3)

    # --- C. PROSES 3.0 (PEMESANAN, HOLD KUOTA & BAYAR) ---
    # 1. P3.0 <-> Midtrans (Garis vertikal murni)
    # P3.0 -> Midtrans (x = 1120)
    c.line(1120, p3_cy - p3_r, 1120, py + ph, lw=1.3)
    c.head(1120, py + ph, "up", size=6.5)
    c.mask_text(1030, 300, "Parameter Tagihan", f_lbl, pad=3)

    # Midtrans -> P3.0 (x = 1280)
    c.line(1280, py + ph, 1280, p3_cy - p3_r, lw=1.3)
    c.head(1280, p3_cy - p3_r, "down", size=6.5)
    c.mask_text(1385, 288, "Token Snap, VA, QRIS", f_lbl, pad=3)
    c.mask_text(1385, 312, "Webhook Bayar (SHA-512)", f_lbl, pad=3)

    # 2. User <-> P3.0
    # User -> P3.0
    c.line(ux + uw, 670, p3_cx - p3_r, 670, lw=1.3)
    c.head(p3_cx - p3_r, 670, "right", size=6.5)
    c.mask_text((ux + uw + p3_cx - p3_r) / 2, 659, "Pemesanan Tiket & Kode Promo", f_lbl, pad=3)

    # P3.0 -> User
    c.line(p3_cx - p3_r, 720, ux + uw, 720, lw=1.3)
    c.head(ux + uw, 720, "left", size=6.5)
    c.mask_text((ux + uw + p3_cx - p3_r) / 2, 709, "Tagihan & Hold Kuota 5 Menit", f_lbl, pad=3)

    # 3. P3.0 -> D3: orders (Garis vertikal murni x = 1200)
    c.line(p3_cx, p3_cy + p3_r, p3_cx, 840, lw=1.3)
    c.head(p3_cx, 840, "down", size=6.5)
    c.mask_text(p3_cx - 85, 765, "Simpan Order & Bayar", f_lbl, pad=3)

    # 4. P3.0 <-> D2: events (Hold Kuota via Manhattan)
    c.line(p3_cx + p3_r * 0.8, p3_cy + p3_r * 0.5, 1600, p3_cy + p3_r * 0.5, lw=1.3)
    c.line(1600, p3_cy + p3_r * 0.5, 1600, 860, lw=1.3)
    c.line(1600, 860, 1650, 860, lw=1.3)
    c.head(1650, 860, "right", size=6.5)
    c.mask_text(1520, p3_cy + p3_r * 0.5 - 11, "Atomic Hold Kuota", f_lbl, pad=3)

    # 5. P3.0 <-> D5: promos (Cek Promo via Manhattan)
    c.line(p3_cx + p3_r * 0.6, p3_cy + p3_r * 0.8, 1450, p3_cy + p3_r * 0.8, lw=1.3)
    c.line(1450, p3_cy + p3_r * 0.8, 1450, 1060, lw=1.3)
    c.head(1450, 1060, "down", size=6.5)
    c.mask_text(1450, 960, "Validasi Kode Promo", f_lbl, pad=3)

    # 5b. P3.0 -> D6: claimed_promos (voucher dipakai saat checkout)
    # D6 ada di (1380,1060) lebar 250 -> tepi atas y=1060, tengah x=1505.
    # Rute: keluar dari kanan P3.0 di y=700, belok kanan ke x=1505, turun.
    c.line(p3_cx + p3_r * 0.4, p3_cy + p3_r * 0.9, 1300,
           p3_cy + p3_r * 0.9, lw=1.3)
    c.line(1300, p3_cy + p3_r * 0.9, 1300, 1000, lw=1.3)
    c.line(1300, 1000, 1505, 1000, lw=1.3)
    c.line(1505, 1000, 1505, 1060, lw=1.3)
    c.head(1505, 1060, "down", size=6.5)
    c.mask_text(1400, 989, "Tandai Voucher Terpakai", f_lbl, pad=3)

    # 6. P3.0 -> D4: tickets (Generate Tiket Lunas via Manhattan)
    c.line(p3_cx - p3_r * 0.6, p3_cy + p3_r * 0.8, 950, p3_cy + p3_r * 0.8, lw=1.3)
    c.line(950, p3_cy + p3_r * 0.8, 950, 1060, lw=1.3)
    c.head(950, 1060, "down", size=6.5)
    c.mask_text(950, 960, "Generate Record Tiket", f_lbl, pad=3)

    # --- D. PROSES 4.0 (E-TIKET & VALIDASI GATE) ---
    # 1. D4: tickets -> P4.0 (Ambil Tiket via Manhattan)
    c.line(850, 1080, 850, 1240, lw=1.3)
    c.line(850, 1240, p4_cx + p4_r * 0.6, 1240, lw=1.3)
    c.line(p4_cx + p4_r * 0.6, 1240, p4_cx + p4_r * 0.6, p4_cy - p4_r * 0.8, lw=1.3)
    c.head(p4_cx + p4_r * 0.6, p4_cy - p4_r * 0.8, "down", size=6.5)
    c.mask_text(770, 1229, "Ambil Tiket Lunas", f_lbl, pad=3)

    # 2. P4.0 -> User (E-Tiket QR Ed25519)
    c.line(p4_cx - p4_r, 1380, 480, 1380, lw=1.3)
    c.line(480, 1380, 480, 980, lw=1.3)
    c.line(480, 980, ux + uw, 980, lw=1.3)
    c.head(ux + uw, 980, "left", size=6.5)
    c.mask_text(480, 1180, "E-Tiket QR Ed25519", f_lbl, pad=3)

    # 2b. P4.0 <-> D7: refunds (audit trail keputusan refund)
    # D7 ada di (1810,1060). Rute: dari kanan P4.0 naik ke y=1122 lalu kanan.
    c.line(p4_cx + p4_r * 0.9, p4_cy - p4_r * 0.4, 1930,
           p4_cy - p4_r * 0.4, lw=1.3)
    c.line(1930, p4_cy - p4_r * 0.4, 1930, 1122, lw=1.3)
    c.head(1930, 1122, "up", size=6.5)
    c.mask_text(1930, 1240, "Catat Refund & Pulihkan Stok", f_lbl, pad=3)

    # 3. Admin -> P4.0 (Scan Gate Offline lewat koridor bawah y = 1530)
    c.line(ax, 880, 2020, 880, lw=1.3)
    c.line(2020, 880, 2020, 1530, lw=1.3)
    c.line(2020, 1530, p4_cx + p4_r * 0.7, 1530, lw=1.3)
    c.line(p4_cx + p4_r * 0.7, 1530, p4_cx + p4_r * 0.7, p4_cy + p4_r * 0.7, lw=1.3)
    c.head(p4_cx + p4_r * 0.7, p4_cy + p4_r * 0.7, "up", size=6.5)
    c.mask_text(1350, 1519, "Data Pindaian Tiket Gate (Offline Scan)", f_lbl, pad=3)

    # 3b. P4.0 -> D8: gate_scans (ledger scan offline petugas)
    # D8 ada di (420,1180). Rute: keluar kiri P4.0 lalu turun.
    c.line(p4_cx - p4_r * 0.9, p4_cy + p4_r * 0.3, 535,
           p4_cy + p4_r * 0.3, lw=1.3)
    c.line(535, p4_cy + p4_r * 0.3, 535, 1180, lw=1.3)
    c.head(535, 1180, "down", size=6.5)
    c.mask_text(535, 1265, "Simpan Ledger Scan", f_lbl, pad=3)

    # 4. P4.0 -> Admin (Status Validasi Gate)
    c.line(p4_cx + p4_r, 1380, 1580, 1380, lw=1.3)
    c.line(1580, 1380, 1580, 930, lw=1.3)
    c.line(1580, 930, ax, 930, lw=1.3)
    c.head(ax, 930, "right", size=6.5)
    c.mask_text(1150, 1369, "Status Validasi Gate (Valid / Invalid)", f_lbl, pad=3)

    # --- E. PROSES 5.0 (PELAPORAN & NOTIFIKASI FCM) ---
    # 1. D3: orders -> P5.0 (Rekap Transaksi)
    c.line(1250, 882, 1250, 1280, lw=1.3)
    c.line(1250, 1280, p5_cx - p5_r, 1280, lw=1.3)
    c.head(p5_cx - p5_r, 1280, "right", size=6.5)
    c.mask_text(1450, 1269, "Data Omset & Transaksi Lunas", f_lbl, pad=3)

    # 2. D4: tickets -> P5.0 (Data Kehadiran Venue)
    c.line(1050, 1080, 1050, 1340, lw=1.3)
    c.line(1050, 1340, p5_cx - p5_r * 0.9, 1340, lw=1.3)
    c.head(p5_cx - p5_r * 0.9, 1340, "right", size=6.5)
    c.mask_text(1350, 1329, "Data Kehadiran Venue", f_lbl, pad=3)

    # 3. P5.0 -> Admin (Laporan Rekap)
    c.line(p5_cx + p5_r, 1380, ax, 1380, lw=1.3)
    c.line(ax, 1380, ax, 1030, lw=1.3)
    c.head(ax, 1030, "up", size=6.5)
    c.mask_text((p5_cx + p5_r + ax) / 2, 1369, "Laporan Penjualan & Kehadiran", f_lbl, pad=3)

    # 4. P5.0 -> Firebase (Push Notification FCM)
    c.line(p5_cx, p5_cy + p5_r, p5_cx, 1690, lw=1.3)
    c.line(p5_cx, 1690, fx + fw, 1690, lw=1.3)
    c.head(fx + fw, 1690, "left", size=6.5)
    c.mask_text(p5_cx + 85, 1570, "Dispatch FCM Push Notif", f_lbl, pad=3)

    # --- F. PROSES 4.0 <-> D9: reviews (ulasan pembeli) ---
    # D9 ada di (880,1180) tinggi 42, jadi ATASNYA y=1180 dan BAWAHNYA y=1222.
    # Panah harus berhenti di sisi atas kotak, bukan menembus ke bawahnya.
    c.line(p4_cx + p4_r * 0.5, p4_cy - p4_r * 0.85, 880, p4_cy - p4_r * 0.85, lw=1.3)
    c.line(880, p4_cy - p4_r * 0.85, 880, 1180, lw=1.3)
    c.head(880, 1180, "down", size=6.5)
    c.mask_text(905, p4_cy - p4_r * 0.85 - 11, "Tulis & Baca Ulasan", f_lbl, pad=3)

    # --- G. PROSES 5.0 -> D10: notifications (notifikasi in-app) ---
    # D10 ada di (1180,1180). Rute: keluar kiri P5.0, naik ke dasar D10.
    c.line(p5_cx - p5_r * 0.5, p5_cy - p5_r * 0.85, 1180, p5_cy - p5_r * 0.85, lw=1.3)
    c.line(1180, p5_cy - p5_r * 0.85, 1180, 1180, lw=1.3)
    c.head(1180, 1180, "down", size=6.5)
    c.mask_text(1195, p5_cy - p5_r * 0.85 - 11, "Kirim Notifikasi In-App", f_lbl, pad=3)

    # --- H. PROSES 2.0 <-> D11: favorites (favorit per pengguna) ---
    # D11 ada di (1500,1180) lebar 230 → rentang x 1500..1730.
    # Koridor turun di x=1990 lalu masuk dari kanan, berhenti di sisi kanan
    # kotak (x=1730) pada ketinggian tengahnya — bukan menembus dari atas.
    c.line(p2_cx + p2_r * 0.6, p2_cy + p2_r, p2_cx + p2_r * 0.6, 900, lw=1.3)
    c.line(p2_cx + p2_r * 0.6, 900, 1990, 900, lw=1.3)
    c.line(1990, 900, 1990, 1201, lw=1.3)
    c.line(1990, 1201, 1730, 1201, lw=1.3)
    c.head(1730, 1201, "left", size=6.5)
    c.mask_text(1790, 1189, "Simpan & Baca Favorit", f_lbl, pad=3)

    # ==================== FOOTER ====================
    fy_line = 1750
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 0 (DFD 0) — Sistem Informasi SoundWave.", f_foot)
    c.text(60, fy_line + 30, "Dekomposisi sistem menjadi 5 proses bisnis terpisah dan 11 data store riil pada Firestore (gcloud: asia-southeast2).", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v5.0", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Yourdon & Coad / DeMarco Akademik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_level_0_soundwave_final.png"
    c.save(out_path)
    print("OK DFD 0 v2 rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_perfect_dfd0()
