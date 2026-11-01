"""Generator DFD Level 1 Soundwave: Style 1 Linear Akademik Sempurna (v3).
Perbaikan Fundamental:
1. Badge text anti-tembus: Memakai bbox nyata teks dengan latar belakang putih solid ber-padding penuh.
2. Penempatan label teks secara strategis di segmen horizontal dekat entitas atau proses (bukan di persimpangan bus).
3. Bus routing rapi & terisolasi dengan jarak antar lajur yang konsisten (50px).
4. Sesuai 100% dengan referensi Style 1 (3 Kolom Linear: Entitas -> Proses Gane & Sarson -> Data Store).
"""
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_style1_v3():
    W, H = 2500, 2050
    c = Canvas(W, H, s=2)

    # 1. HEADER KIRI ATAS
    c.rect(60, 40, 560, 80, lw=1.6)
    c.text(80, 65, "DATA FLOW DIAGRAM (DFD LEVEL 1)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 90, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Fonts
    f_col_header = c.f(SANS_B, 14)
    f_ent_title = c.f(SANS_B, 15)
    f_ent_sub = c.f(MONO, 11)
    f_p_id = c.f(MONO_B, 14)
    f_p_title = c.f(SANS_B, 13)
    f_p_sub = c.f(MONO, 10)
    f_ds_id = c.f(MONO_B, 13)
    f_ds_name = c.f(MONO_B, 11)
    f_lbl = c.f(MONO, 9.5)
    f_foot = c.f(MONO, 10)

    # Header Kolom
    c.text(205, 150, "[ 1. EXTERNAL ENTITIES ]", f_col_header, anchor="mm")
    c.text(1175, 150, "[ 2. BUSINESS PROCESSES (GANE & SARSON) ]", f_col_header, anchor="mm")
    c.text(2160, 150, "[ 3. DATA STORES ]", f_col_header, anchor="mm")

    # Helper: Kotak Label Badge Anti-Tembus (Latar putih solid + border sangat tipis)
    def label_badge(cx, cy, text, font=f_lbl, pad_x=6, pad_y=4, border=True):
        fnt = font
        bbox = c.d.textbbox((cx * c.S, cy * c.S), text, font=fnt, anchor="mm")
        x0 = bbox[0] - pad_x * c.S
        y0 = bbox[1] - pad_y * c.S
        x1 = bbox[2] + pad_x * c.S
        y1 = bbox[3] + pad_y * c.S
        outline_col = BLACK if border else None
        c.d.rectangle([x0, y0, x1, y1], fill=WHITE, outline=outline_col, width=int(1 * c.S) if border else 0)
        c.d.text((cx * c.S, cy * c.S), text, font=fnt, fill=BLACK, anchor="mm")

    # ==================== KOORDINAT LAYOUT ====================
    # ENTITAS (Kiri: x=60, w=270)
    ux, uy, uw, uh = 60, 230, 270, 360  # User
    ax, ay, aw, ah = 60, 670, 270, 360  # Admin
    px, py, pw, ph = 60, 1110, 270, 340 # Midtrans
    fx, fy, fw, fh = 60, 1530, 270, 340 # Firebase

    # PROSES (Tengah: x=920, w=510)
    proc_x = 920
    proc_w = 510
    p1_y, p1_h = 230, 115
    p2_y, p2_h = 570, 115
    p3_y, p3_h = 910, 125
    p4_y, p4_h = 1260, 115
    p5_y, p5_h = 1600, 115

    # DATA STORE (Kanan: x=1900, w=530, h=48)
    ds_x = 1900
    ds_w = 530
    ds_h = 48
    d1_y = 263
    d2_y = 603
    d3_y = 948
    d4_y = 1293
    d5_y = 1633

    # ==================== 1. GAMBAR SEMUA GARIS KONEKTOR ====================
    # Bus Lanes Kiri (X coords terisolasi)
    L_FB_UID  = 370
    L_KATALOG = 420
    L_ETIKET  = 470
    L_ORDER   = 520
    L_TAGIHAN = 570
    L_MID_REQ = 620
    L_MID_RES = 670
    L_ADM_EVT = 720
    L_ADM_SCN = 770
    L_ADM_VAL = 820
    L_ADM_LAP = 870

    # Bus Lanes Kanan (X coords terisolasi)
    R_HOLD   = 1500
    R_TIKET  = 1580
    R_PROMO  = 1660
    R_REKAP  = 1740

    # --- P1.0 KONEKTOR ---
    # User -> P1.0
    c.line(ux + uw, 260, proc_x, 260, lw=1.3)
    c.head(proc_x, 260, "right", size=6.5)

    # P1.0 -> User
    c.line(proc_x, 310, ux + uw, 310, lw=1.3)
    c.head(ux + uw, 310, "left", size=6.5)

    # Firebase -> P1.0
    c.line(fx + fw, 1590, L_FB_UID, 1590, lw=1.3)
    c.line(L_FB_UID, 1590, L_FB_UID, 335, lw=1.3)
    c.line(L_FB_UID, 335, proc_x, 335, lw=1.3)
    c.head(proc_x, 335, "right", size=6.5)

    # P1.0 -> D1: users
    c.line(proc_x + proc_w, d1_y + ds_h / 2, ds_x, d1_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d1_y + ds_h / 2, "right", size=6.5)

    # --- P2.0 KONEKTOR ---
    # Admin -> P2.0
    c.line(ax + aw, 710, L_ADM_EVT, 710, lw=1.3)
    c.line(L_ADM_EVT, 710, L_ADM_EVT, 600, lw=1.3)
    c.line(L_ADM_EVT, 600, proc_x, 600, lw=1.3)
    c.head(proc_x, 600, "right", size=6.5)

    # P2.0 -> User (Katalog)
    c.line(proc_x, 640, L_KATALOG, 640, lw=1.3)
    c.line(L_KATALOG, 640, L_KATALOG, 470, lw=1.3)
    c.line(L_KATALOG, 470, ux + uw, 470, lw=1.3)
    c.head(ux + uw, 470, "left", size=6.5)

    # P2.0 -> D2: events
    c.line(proc_x + proc_w, d2_y + ds_h / 2, ds_x, d2_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d2_y + ds_h / 2, "right", size=6.5)

    # --- P3.0 KONEKTOR ---
    # User -> P3.0 (Order)
    c.line(ux + uw, 520, L_ORDER, 520, lw=1.3)
    c.line(L_ORDER, 520, L_ORDER, 940, lw=1.3)
    c.line(L_ORDER, 940, proc_x, 940, lw=1.3)
    c.head(proc_x, 940, "right", size=6.5)

    # P3.0 -> User (Tagihan & Hold)
    c.line(proc_x, 975, L_TAGIHAN, 975, lw=1.3)
    c.line(L_TAGIHAN, 975, L_TAGIHAN, 565, lw=1.3)
    c.line(L_TAGIHAN, 565, ux + uw, 565, lw=1.3)
    c.head(ux + uw, 565, "left", size=6.5)

    # P3.0 -> Midtrans
    c.line(proc_x, 1005, L_MID_REQ, 1005, lw=1.3)
    c.line(L_MID_REQ, 1005, L_MID_REQ, 1210, lw=1.3)
    c.line(L_MID_REQ, 1210, px + pw, 1210, lw=1.3)
    c.head(px + pw, 1210, "left", size=6.5)

    # Midtrans -> P3.0
    c.line(px + pw, 1270, L_MID_RES, 1270, lw=1.3)
    c.line(L_MID_RES, 1270, L_MID_RES, 1025, lw=1.3)
    c.line(L_MID_RES, 1025, proc_x, 1025, lw=1.3)
    c.head(proc_x, 1025, "right", size=6.5)

    # P3.0 -> D3: orders
    c.line(proc_x + proc_w, d3_y + ds_h / 2, ds_x, d3_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d3_y + ds_h / 2, "right", size=6.5)

    # P3.0 -> D2: events (Hold Kuota)
    c.line(proc_x + proc_w, 935, R_HOLD, 935, lw=1.3)
    c.line(R_HOLD, 935, R_HOLD, 640, lw=1.3)
    c.line(R_HOLD, 640, ds_x, 640, lw=1.3)
    c.head(ds_x, 640, "right", size=6.5)

    # P3.0 -> D4: tickets (Generate Tiket Lunas)
    c.line(proc_x + proc_w, 995, R_TIKET, 995, lw=1.3)
    c.line(R_TIKET, 995, R_TIKET, 1285, lw=1.3)
    c.line(R_TIKET, 1285, ds_x, 1285, lw=1.3)
    c.head(ds_x, 1285, "right", size=6.5)

    # P3.0 -> D5: promos (Validasi Promo)
    c.line(proc_x + proc_w, 1015, R_PROMO, 1015, lw=1.3)
    c.line(R_PROMO, 1015, R_PROMO, 1625, lw=1.3)
    c.line(R_PROMO, 1625, ds_x, 1625, lw=1.3)
    c.head(ds_x, 1625, "right", size=6.5)

    # --- P4.0 KONEKTOR ---
    # D4 -> P4.0 (Ambil Tiket)
    c.line(ds_x, d4_y + ds_h / 2, proc_x + proc_w, d4_y + ds_h / 2, lw=1.3)
    c.head(proc_x + proc_w, d4_y + ds_h / 2, "left", size=6.5)

    # P4.0 -> User (E-Tiket)
    c.line(proc_x, 1290, L_ETIKET, 1290, lw=1.3)
    c.line(L_ETIKET, 1290, L_ETIKET, 410, lw=1.3)
    c.line(L_ETIKET, 410, ux + uw, 410, lw=1.3)
    c.head(ux + uw, 410, "left", size=6.5)

    # Admin -> P4.0 (Scan Gate Offline)
    c.line(ax + aw, 830, L_ADM_SCN, 830, lw=1.3)
    c.line(L_ADM_SCN, 830, L_ADM_SCN, 1325, lw=1.3)
    c.line(L_ADM_SCN, 1325, proc_x, 1325, lw=1.3)
    c.head(proc_x, 1325, "right", size=6.5)

    # P4.0 -> Admin (Status Validasi Gate)
    c.line(proc_x, 1355, L_ADM_VAL, 1355, lw=1.3)
    c.line(L_ADM_VAL, 1355, L_ADM_VAL, 890, lw=1.3)
    c.line(L_ADM_VAL, 890, ax + aw, 890, lw=1.3)
    c.head(ax + aw, 890, "left", size=6.5)

    # --- P5.0 KONEKTOR ---
    # D3 -> P5.0 (Rekap Omset)
    c.line(ds_x, 1005, R_REKAP, 1005, lw=1.3)
    c.line(R_REKAP, 1005, R_REKAP, 1630, lw=1.3)
    c.line(R_REKAP, 1630, proc_x + proc_w, 1630, lw=1.3)
    c.head(proc_x + proc_w, 1630, "left", size=6.5)

    # P5.0 -> Admin (Laporan)
    c.line(proc_x, 1630, L_ADM_LAP, 1630, lw=1.3)
    c.line(L_ADM_LAP, 1630, L_ADM_LAP, 950, lw=1.3)
    c.line(L_ADM_LAP, 950, ax + aw, 950, lw=1.3)
    c.head(ax + aw, 950, "left", size=6.5)

    # P5.0 -> Firebase (Push FCM)
    c.line(proc_x, 1680, fx + fw, 1680, lw=1.3)
    c.head(fx + fw, 1680, "left", size=6.5)

    # ==================== 2. GAMBAR SHAPES DI ATAS GARIS ====================
    def draw_process_gs(x, y, w, h, pid, title, desc=""):
        c.d.rounded_rectangle(
            [c._p(x, y), c._p(x + w, y + h)],
            radius=int(14 * c.S),
            outline=BLACK,
            width=max(1, int(round(1.8 * c.S))),
            fill=WHITE
        )
        sekat_y = y + 36
        c.line(x, sekat_y, x + w, sekat_y, lw=1.4)
        c.text(x + w / 2, y + 18, f"PROSES {pid}", f_p_id, anchor="mm")
        if desc:
            c.text(x + w / 2, y + 62, title, f_p_title, anchor="mm")
            c.text(x + w / 2, y + 88, desc, f_p_sub, anchor="mm")
        else:
            c.text(x + w / 2, y + 75, title, f_p_title, anchor="mm")

    def draw_datastore_gs(x, y, w, h, ds_id, ds_name):
        c.fill_rect(x, y, w, h, fill=WHITE)
        c.line(x, y, x + w, y, lw=1.4)
        c.line(x, y + h, x + w, y + h, lw=1.4)
        c.line(x, y, x, y + h, lw=1.4)
        c.line(x + 55, y, x + 55, y + h, lw=1.2)
        c.text(x + 28, y + h / 2, ds_id, f_ds_id, anchor="mm")
        c.text(x + 70, y + h / 2, ds_name, f_ds_name, anchor="lm")

    # 4 ENTITAS
    c.fill_rect(ux, uy, uw, uh, fill=WHITE)
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 165, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 195, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    c.fill_rect(ax, ay, aw, ah, fill=WHITE)
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 165, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 195, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    c.fill_rect(px, py, pw, ph, fill=WHITE)
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 155, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 185, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    c.fill_rect(fx, fy, fw, fh, fill=WHITE)
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 155, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 185, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # 5 PROSES
    draw_process_gs(proc_x, p1_y, proc_w, p1_h, "1.0", "MANAJEMEN AKUN & AUTENTIKASI", "Registrasi, Login, Profil User & Admin")
    draw_process_gs(proc_x, p2_y, proc_w, p2_h, "2.0", "MANAJEMEN EVENT & KATALOG TIKET", "Setup Konser, Alokasi Kuota, Katalog Musik")
    draw_process_gs(proc_x, p3_y, proc_w, p3_h, "3.0", "PEMESANAN, HOLD KUOTA & PEMBAYARAN", "Atomic Hold 5 Mnt, Promo, Snap VA/QRIS, Webhook")
    draw_process_gs(proc_x, p4_y, proc_w, p4_h, "4.0", "PENERBITAN TIKET & VALIDASI GATE", "Generate QR Ed25519 & Offline Gate Scanner")
    draw_process_gs(proc_x, p5_y, proc_w, p5_h, "5.0", "PELAPORAN & NOTIFIKASI SISTEM", "Rekap Penjualan, Kehadiran Venue & FCM Push")

    # 5 DATA STORE
    draw_datastore_gs(ds_x, d1_y, ds_w, ds_h, "D1", "users (Profil Akun & Kredensial)")
    draw_datastore_gs(ds_x, d2_y, ds_w, ds_h, "D2", "events (Jadwal Konser & Kuota Tiket)")
    draw_datastore_gs(ds_x, d3_y, ds_w, ds_h, "D3", "orders (Pemesanan & Status Bayar)")
    draw_datastore_gs(ds_x, d4_y, ds_w, ds_h, "D4", "tickets (Record E-Tiket & Status Scan)")
    draw_datastore_gs(ds_x, d5_y, ds_w, ds_h, "D5", "promos (Kupon Diskon & Kuota Kupon)")

    # ==================== 3. GAMBAR SEMUA LABEL BADGE (LAYER TERATAS) ====================
    # Label P1.0
    label_badge((ux + uw + proc_x) / 2, 260, "Data Registrasi & Kredensial Login")
    label_badge((ux + uw + proc_x) / 2, 310, "Informasi Profil & Token Sesi")
    label_badge(L_FB_UID, 1000, "Verifikasi Token UID", border=True)
    label_badge((proc_x + proc_w + ds_x) / 2, d1_y + ds_h / 2, "Simpan / Baca Data User")

    # Label P2.0
    label_badge(L_ADM_EVT + 75, 600, "Setup Event Konser & Kuota")
    label_badge(L_KATALOG, 540, "Katalog Konser & Info Tiket")
    label_badge((proc_x + proc_w + ds_x) / 2, d2_y + ds_h / 2, "Simpan / Update Jadwal & Kuota")

    # Label P3.0
    label_badge(L_ORDER, 750, "Pemesanan Tiket & Kupon Promo")
    label_badge(L_TAGIHAN, 770, "Invoice & Hold Kuota 5 Menit")
    label_badge(L_MID_REQ, 1110, "Parameter Tagihan Transaksi")
    label_badge(L_MID_RES, 1150, "Snap Token, VA, QRIS & Webhook SHA-512")
    label_badge((proc_x + proc_w + ds_x) / 2, d3_y + ds_h / 2, "Simpan Record Pemesanan & Status Lunas")
    label_badge(R_HOLD, 790, "Atomic Hold Kuota Tiket")
    label_badge(R_TIKET, 1140, "Generate Record Tiket Lunas")
    label_badge(R_PROMO, 1320, "Cek & Validasi Kupon Promo")

    # Label P4.0
    label_badge((proc_x + proc_w + ds_x) / 2, d4_y + ds_h / 2, "Ambil Tiket Terbit & Data QR Ed25519")
    label_badge(L_ETIKET, 850, "Penerbitan E-Tiket QR Ed25519")
    label_badge(L_ADM_SCN, 1080, "Data Scan Tiket Gate (Offline)")
    label_badge(L_ADM_VAL, 1120, "Status Validasi Gate (Valid / Invalid)")

    # Label P5.0
    label_badge(R_REKAP, 1320, "Data Rekap Omset Penjualan")
    label_badge(L_ADM_LAP, 1290, "Laporan Penjualan & Kehadiran")
    label_badge((proc_x + fx + fw) / 2, 1680, "Dispatch Payload Push Notifikasi FCM")

    # ==================== FOOTER ====================
    fy_line = 1980
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 1 (DFD 1) — Style 1: 3-Column Linear Architecture (Gane & Sarson).", f_foot)
    c.text(60, fy_line + 30, "Mendekomposisi aliran sistem SoundWave secara teratur: Entitas Eksternal (Kiri) -> Proses Inti (Tengah) -> Data Store (Kanan).", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Gane & Sarson Linear Akademik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_style1_linear_soundwave_sempurna.png"
    c.save(out_path)
    print("OK Style 1 v3 rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_style1_v3()
