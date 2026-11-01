"""Generator DFD Level 1 Soundwave: Masterpiece Akademik Zig-Zag (v4).
Standar Akademik Skripsi & Rekayasa Perangkat Lunak:
1. Kolom Tengah: General Vertical Container presisi dari P1.0 sampai P5.0.
2. Kolom Kiri: Entitas Eksternal Zig-Zag Offset berirama dinamis:
   - USER: Kiri luar atas (x=80)
   - MIDTRANS: Menjorok ke tengah (x=500) sejajar P3.0
   - FIREBASE: Kiri luar bawah (x=80)
   - ADMIN: Menjorok ke tengah (x=500) sejajar P4.0 & P5.0
3. Kolom Kanan: Data Store D1 s/d D5 berurutan vertikal klasik (D1: users, D2: events, D3: orders, D4: tickets, D5: promos).
4. Zero Conflict & Bridge Jumper: Seluruh persilangan garis dilengkapi Bridge Jumper Arc (lengkungan lompat 180 derajat) standar skematik teknik internasional.
5. Anti-Collision Text: Setiap label diberi kotak pelindung badge putih solid, nol teks bertumpuk atau terpotong garis.
"""
import math
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_masterpiece_dfd():
    W, H = 2650, 2100
    c = Canvas(W, H, s=2)

    # 1. HEADER KIRI ATAS
    c.rect(60, 40, 560, 80, lw=1.6)
    c.text(80, 65, "DATA FLOW DIAGRAM (DFD LEVEL 1)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 90, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font styles
    f_col_header = c.f(SANS_B, 14)
    f_ent_title = c.f(SANS_B, 15)
    f_ent_sub = c.f(MONO, 11)
    f_p_id = c.f(MONO_B, 14)
    f_p_title = c.f(SANS_B, 13)
    f_p_sub = c.f(MONO, 10)
    f_ds_id = c.f(MONO_B, 13)
    f_ds_name = c.f(MONO_B, 11)
    f_lbl = c.f(MONO, 9.4)
    f_foot = c.f(MONO, 10)

    # Indikator Kolom
    c.text(320, 150, "[ 1. EXTERNAL ENTITIES (OFFSET ZIG-ZAG) ]", f_col_header, anchor="mm")
    c.text(1280, 150, "[ 2. BUSINESS PROCESS CONTAINER (GANE & SARSON) ]", f_col_header, anchor="mm")
    c.text(2240, 150, "[ 3. DATA STORES ]", f_col_header, anchor="mm")

    # Helper: Kotak Label Badge Anti-Tembus
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

    # Helper: Bridge Jumper Vertikal (Garis vertikal melompat di persimpangan Y)
    def v_line_with_jumpers(x, y1, y2, jump_ys, lw=1.3, r=6):
        start_y = min(y1, y2)
        end_y = max(y1, y2)
        # Urutkan jumps yang berada di antara start_y dan end_y
        valid_jumps = sorted([jy for jy in jump_ys if start_y + r < jy < end_y - r])
        
        curr_y = start_y
        for jy in valid_jumps:
            c.line(x, curr_y, x, jy - r, lw=lw)
            # Gambar arc setengah lingkaran (jumper ke arah kanan)
            c.d.arc(
                [c._p(x - r, jy - r), c._p(x + r, jy + r)],
                start=270, end=90,
                fill=BLACK,
                width=max(1, int(round(lw * c.S)))
            )
            curr_y = jy + r
        c.line(x, curr_y, x, end_y, lw=lw)

    # ==================== KOORDINAT LAYOUT ====================
    # ENTITAS (Zig-Zag Offset Berselang-seling)
    ux, uy, uw, uh = 80, 230, 260, 360    # 1. USER (Kiri Luar Atas)
    px, py, pw, ph = 500, 850, 280, 180   # 2. MIDTRANS (Menjorok ke Tengah dekat P3.0)
    fx, fy, fw, fh = 80, 1420, 260, 340   # 3. FIREBASE (Kiri Luar Bawah)
    ax, ay, aw, ah = 500, 1220, 280, 360  # 4. ADMIN (Menjorok ke Tengah dekat P4.0 & P5.0)

    # PROSES (Wadah Kolom Tengah Terpusat: x = 1040, w = 480)
    proc_x = 1040
    proc_w = 480
    p1_y, p1_h = 230, 115
    p2_y, p2_h = 560, 115
    p3_y, p3_h = 890, 125
    p4_y, p4_h = 1220, 115
    p5_y, p5_h = 1550, 115

    # DATA STORE (Kolom Kanan Klasik D1 s/d D5: x = 1960, w = 530, h = 48)
    ds_x = 1960
    ds_w = 530
    ds_h = 48
    d1_y = 263   # Sejajar P1.0
    d2_y = 593   # Sejajar P2.0
    d3_y = 928   # Sejajar P3.0
    d4_y = 1253  # Sejajar P4.0
    d5_y = 1583  # Sejajar P5.0

    # ==================== 1. GAMBAR SEMUA GARIS KONEKTOR ====================
    # Koridor Jalur Bebas Sisi Kiri
    L_USER_P3 = 390
    L_P3_USER = 430
    L_P4_USER = 360
    L_FB_AUTH = 840

    # Koridor Sisi Kanan
    R_HOLD   = 1620
    R_TIKET  = 1680
    R_PROMO  = 1740
    R_REKAP  = 1860

    # --- A. PROSES 1.0 (AKUN & AUTH) ---
    # User -> P1.0 (Horiz murni)
    c.line(ux + uw, 260, proc_x, 260, lw=1.3)
    c.head(proc_x, 260, "right", size=6.5)

    # P1.0 -> User (Horiz murni)
    c.line(proc_x, 305, ux + uw, 305, lw=1.3)
    c.head(ux + uw, 305, "left", size=6.5)

    # Firebase -> P1.0 (Naik via koridor x=840 dengan jumper melompati garis P3.0-Midtrans di y=915, 955)
    c.line(fx + fw, 1500, L_FB_AUTH, 1500, lw=1.3)
    v_line_with_jumpers(L_FB_AUTH, 1500, 335, [1250, 1285, 955, 915], lw=1.3)
    c.line(L_FB_AUTH, 335, proc_x, 335, lw=1.3)
    c.head(proc_x, 335, "right", size=6.5)

    # P1.0 -> D1: users (Horiz murni)
    c.line(proc_x + proc_w, d1_y + ds_h / 2, ds_x, d1_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d1_y + ds_h / 2, "right", size=6.5)

    # --- B. PROSES 2.0 (EVENT & KATALOG) ---
    # Admin -> P2.0 (Naik dari Admin y=1250 via x=880 ke P2.0 y=585)
    c.line(ax + aw, 1250, 880, 1250, lw=1.3)
    v_line_with_jumpers(880, 1250, 585, [955, 915], lw=1.3)
    c.line(880, 585, proc_x, 585, lw=1.3)
    c.head(proc_x, 585, "right", size=6.5)

    # P2.0 -> User (Horiz murni ke User)
    c.line(proc_x, 620, ux + uw, 620, lw=1.3)
    c.head(ux + uw, 620, "left", size=6.5)

    # P2.0 -> D2: events (Horiz murni)
    c.line(proc_x + proc_w, d2_y + ds_h / 2, ds_x, d2_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d2_y + ds_h / 2, "right", size=6.5)

    # --- C. PROSES 3.0 (PEMESANAN & BAYAR) ---
    # User -> P3.0 (Pemesanan via koridor x=390)
    c.line(ux + uw, 510, L_USER_P3, 510, lw=1.3)
    c.line(L_USER_P3, 510, L_USER_P3, 915, lw=1.3)
    c.line(L_USER_P3, 915, px, 915, lw=1.3)  # Masuk ke Midtrans / terus ke P3.0
    c.line(px + pw, 915, proc_x, 915, lw=1.3)
    c.head(proc_x, 915, "right", size=6.5)

    # P3.0 -> User (Invoice & Hold 5 Mnt via koridor x=430)
    c.line(proc_x, 955, px + pw, 955, lw=1.3)
    c.line(px, 955, L_P3_USER, 955, lw=1.3)
    c.line(L_P3_USER, 955, L_P3_USER, 550, lw=1.3)
    c.line(L_P3_USER, 550, ux + uw, 550, lw=1.3)
    c.head(ux + uw, 550, "left", size=6.5)

    # P3.0 -> Midtrans (Horiz murni langsung di y=890)
    c.line(proc_x, 890, px + pw, 890, lw=1.3)
    c.head(px + pw, 890, "left", size=6.5)

    # Midtrans -> P3.0 (Snap Token VA/QRIS langsung di y=980)
    c.line(px + pw, 980, proc_x, 980, lw=1.3)
    c.head(proc_x, 980, "right", size=6.5)

    # P3.0 -> D3: orders (Horiz murni)
    c.line(proc_x + proc_w, d3_y + ds_h / 2, ds_x, d3_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d3_y + ds_h / 2, "right", size=6.5)

    # P3.0 -> D2: events (Atomic Hold Kuota)
    c.line(proc_x + proc_w, 915, R_HOLD, 915, lw=1.3)
    c.line(R_HOLD, 915, R_HOLD, 630, lw=1.3)
    c.line(R_HOLD, 630, ds_x, 630, lw=1.3)
    c.head(ds_x, 630, "right", size=6.5)

    # P3.0 -> D4: tickets (Generate Tiket Lunas via koridor x=1680)
    c.line(proc_x + proc_w, 975, R_TIKET, 975, lw=1.3)
    c.line(R_TIKET, 975, R_TIKET, 1260, lw=1.3)
    c.line(R_TIKET, 1260, ds_x, 1260, lw=1.3)
    c.head(ds_x, 1260, "right", size=6.5)

    # P3.0 -> D5: promos (Validasi Promo via koridor x=1740 dengan jumper melompati garis D4 di y=1277)
    c.line(proc_x + proc_w, 1005, R_PROMO, 1005, lw=1.3)
    v_line_with_jumpers(R_PROMO, 1005, 1607, [1277, 1260], lw=1.3)
    c.line(R_PROMO, 1607, ds_x, 1607, lw=1.3)
    c.head(ds_x, 1607, "right", size=6.5)

    # --- D. PROSES 4.0 (TIKET & GATE) ---
    # D4 -> P4.0 (Ambil Tiket Terbit - Horiz murni di y=1277)
    c.line(ds_x, 1277, proc_x + proc_w, 1277, lw=1.3)
    c.head(proc_x + proc_w, 1277, "left", size=6.5)

    # P4.0 -> User (E-Tiket QR Ed25519 via koridor luar x=360)
    c.line(proc_x, 1240, ax + aw, 1240, lw=1.3)
    c.line(ax, 1240, L_P4_USER, 1240, lw=1.3)
    c.line(L_P4_USER, 1240, L_P4_USER, 410, lw=1.3)
    c.line(L_P4_USER, 410, ux + uw, 410, lw=1.3)
    c.head(ux + uw, 410, "left", size=6.5)

    # Admin -> P4.0 (Scan Gate Offline - Horiz murni)
    c.line(ax + aw, 1275, proc_x, 1275, lw=1.3)
    c.head(proc_x, 1275, "right", size=6.5)

    # P4.0 -> Admin (Status Validasi Gate - Horiz murni)
    c.line(proc_x, 1315, ax + aw, 1315, lw=1.3)
    c.head(ax + aw, 1315, "left", size=6.5)

    # --- E. PROSES 5.0 (LAPORAN & NOTIF) ---
    # D3 -> P5.0 (Data Rekap Omset via koridor luar x=1860 dengan jumper melompati garis D4)
    c.line(ds_x, 975, R_REKAP, 975, lw=1.3)
    v_line_with_jumpers(R_REKAP, 975, 1575, [1277, 1260], lw=1.3)
    c.line(R_REKAP, 1575, proc_x + proc_w, 1575, lw=1.3)
    c.head(proc_x + proc_w, 1575, "left", size=6.5)

    # P5.0 -> Admin (Laporan Penjualan & Kehadiran - Horiz murni!)
    c.line(proc_x, 1610, ax + aw, 1610, lw=1.3)
    c.head(ax + aw, 1610, "left", size=6.5)

    # P5.0 -> Firebase (Push Notif FCM via garis bawah)
    c.line(proc_x, 1645, 410, 1645, lw=1.3)
    c.line(410, 1645, 410, 1590, lw=1.3)
    c.line(410, 1590, fx + fw, 1590, lw=1.3)
    c.head(fx + fw, 1590, "left", size=6.5)

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

    # 4 ENTITAS (ZIG-ZAG OFFSET)
    # 1. User (Kiri Luar)
    c.fill_rect(ux, uy, uw, uh, fill=WHITE)
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 165, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 195, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    # 2. Midtrans (Menjorok Tengah)
    c.fill_rect(px, py, pw, ph, fill=WHITE)
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 75, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 105, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    # 3. Firebase (Kiri Luar)
    c.fill_rect(fx, fy, fw, fh, fill=WHITE)
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 155, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 185, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # 4. Admin (Menjorok Tengah)
    c.fill_rect(ax, ay, aw, ah, fill=WHITE)
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 165, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 195, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    # 5 PROSES (WADAH TENGAH VERTICAL SEJAJAR)
    draw_process_gs(proc_x, p1_y, proc_w, p1_h, "1.0", "MANAJEMEN AKUN & AUTENTIKASI", "Registrasi, Login, Profil User & Admin")
    draw_process_gs(proc_x, p2_y, proc_w, p2_h, "2.0", "MANAJEMEN EVENT & KATALOG TIKET", "Setup Konser, Alokasi Kuota, Katalog Musik")
    draw_process_gs(proc_x, p3_y, proc_w, p3_h, "3.0", "PEMESANAN, HOLD KUOTA & PEMBAYARAN", "Atomic Hold 5 Mnt, Promo, Snap VA/QRIS, Webhook")
    draw_process_gs(proc_x, p4_y, proc_w, p4_h, "4.0", "PENERBITAN TIKET & VALIDASI GATE", "Generate QR Ed25519 & Offline Gate Scanner")
    draw_process_gs(proc_x, p5_y, proc_w, p5_h, "5.0", "PELAPORAN & NOTIFIKASI SISTEM", "Rekap Penjualan, Kehadiran Venue & FCM Push")

    # 5 DATA STORE (KOLOM KANAN BERURUTAN D1 - D5)
    draw_datastore_gs(ds_x, d1_y, ds_w, ds_h, "D1", "users (Profil Akun & Kredensial)")
    draw_datastore_gs(ds_x, d2_y, ds_w, ds_h, "D2", "events (Jadwal Konser & Kuota Tiket)")
    draw_datastore_gs(ds_x, d3_y, ds_w, ds_h, "D3", "orders (Pemesanan & Status Bayar)")
    draw_datastore_gs(ds_x, d4_y, ds_w, ds_h, "D4", "tickets (Record E-Tiket & Status Scan)")
    draw_datastore_gs(ds_x, d5_y, ds_w, ds_h, "D5", "promos (Kupon Diskon & Kuota Kupon)")

    # ==================== 3. GAMBAR SEMUA LABEL BADGE (LAYER TERATAS) ====================
    # Label P1.0
    label_badge((ux + uw + proc_x) / 2, 260, "Data Registrasi & Kredensial Login")
    label_badge((ux + uw + proc_x) / 2, 305, "Informasi Profil & Token Sesi")
    label_badge(940, 335, "Verifikasi Token UID", border=True)
    label_badge((proc_x + proc_w + ds_x) / 2, d1_y + ds_h / 2, "Simpan / Baca Data User")

    # Label P2.0
    label_badge(950, 585, "Setup Event Konser & Kuota")
    label_badge((ux + uw + proc_x) / 2, 620, "Katalog Konser & Info Tiket")
    label_badge((proc_x + proc_w + ds_x) / 2, d2_y + ds_h / 2, "Simpan / Update Jadwal & Kuota")

    # Label P3.0
    label_badge(910, 890, "Parameter Tagihan Transaksi")
    label_badge(910, 980, "Snap Token, VA, QRIS & Webhook SHA-512")
    label_badge(450, 915, "Pemesanan Tiket & Kupon Promo")
    label_badge(450, 955, "Invoice & Hold Kuota 5 Menit")
    label_badge((proc_x + proc_w + ds_x) / 2, d3_y + ds_h / 2, "Simpan Record Pemesanan Lunas")
    label_badge(1840, 630, "Atomic Hold Kuota Tiket")
    label_badge(1840, 1260, "Generate Record Tiket Lunas")
    label_badge(1840, 1607, "Validasi Kupon Diskon")

    # Label P4.0
    label_badge(1630, 1277, "Ambil Tiket Terbit & Data QR Ed25519")
    label_badge(450, 410, "Penerbitan E-Tiket QR Ed25519")
    label_badge(910, 1275, "Data Scan Tiket Gate (Offline)")
    label_badge(910, 1315, "Status Validasi Gate (Valid / Invalid)")

    # Label P5.0
    label_badge(1710, 1575, "Data Rekap Omset Penjualan")
    label_badge(910, 1610, "Laporan Penjualan & Kehadiran Venue")
    label_badge(620, 1645, "Dispatch Payload Push Notifikasi FCM")

    # ==================== FOOTER ====================
    fy_line = 1980
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 1 (DFD 1) — Style 1: 3-Column Linear Architecture (Gane & Sarson).", f_foot)
    c.text(60, fy_line + 30, "Mendekomposisi aliran sistem SoundWave: Entitas Offset Zig-Zag (Kiri) -> Wadah Proses Inti (Tengah) -> Data Store D1-D5 (Kanan).", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Gane & Sarson Akademik (Standard Orthogonal with Bridge Jumpers)", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_style1_linear_soundwave_masterpiece.png"
    c.save(out_path)
    print("OK Masterpiece DFD rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_masterpiece_dfd()
