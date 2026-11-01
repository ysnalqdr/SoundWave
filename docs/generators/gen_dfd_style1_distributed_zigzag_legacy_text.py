"""Generator DFD Level 1 Soundwave: Distributed Zig-Zag dengan Teks Asli Lengkap (Legacy Detailed Text).
Konfigurasi:
1. Kolom Tengah: Proses 1.0 s/d 5.0 tetap di tengah secara vertikal dengan nama asli lengkap & deskripsi:
   - 1.0 MANAJEMEN AKUN & AUTENTIKASI
   - 2.0 MANAJEMEN EVENT & KATALOG TIKET
   - 3.0 PEMESANAN, HOLD KUOTA & PEMBAYARAN
   - 4.0 PENERBITAN TIKET & VALIDASI GATE
   - 5.0 PELAPORAN & NOTIFIKASI SISTEM
2. Sisi Kiri (Entitas & Data Store):
   - USER (Pembeli / Penonton)
   - D2: events (Jadwal Konser & Kuota Tiket)
   - PAYMENT GATEWAY (Midtrans Sandbox)
   - D5: promos (Kupon Diskon & Kuota Kupon)
   - FIREBASE PLATFORM (Auth & FCM Service)
3. Sisi Kanan (Data Store & Entitas):
   - D1: users (Profil Akun & Kredensial)
   - D3: orders (Pemesanan & Status Bayar)
   - ADMIN (Promotor & Petugas)
   - D4: tickets (Record E-Tiket & Status Scan)
4. Label Alur Data: Seluruh teks detail asli dikembalikan utuh (dengan bridge jumpers & white badge protection).
"""
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_distributed_legacy_text_dfd():
    W, H = 2700, 2150
    c = Canvas(W, H, s=2)

    # 1. HEADER KIRI ATAS
    c.rect(60, 40, 560, 80, lw=1.6)
    c.text(80, 65, "DATA FLOW DIAGRAM (DFD LEVEL 1)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 90, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font styles
    f_col_header = c.f(SANS_B, 13)
    f_cont_header = c.f(SANS_B, 13)
    f_ent_title = c.f(SANS_B, 14.5)
    f_ent_sub = c.f(MONO, 11)
    f_p_id = c.f(MONO_B, 13.5)
    f_p_title = c.f(SANS_B, 12.5)
    f_p_sub = c.f(MONO, 10)
    f_ds_id = c.f(MONO_B, 13)
    f_ds_name = c.f(MONO_B, 10.5)
    f_lbl = c.f(MONO, 9.4)
    f_foot = c.f(MONO, 9.8)

    # Header Kolom Kiri & Kanan
    c.text(380, 150, "[ SISI KIRI: ENTITAS & DATA STORE ]", f_col_header, anchor="mm")
    c.text(2320, 150, "[ SISI KANAN: DATA STORE & ENTITAS ]", f_col_header, anchor="mm")

    # Helper: Kotak Label Badge Putih Solid
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

    # Helper: Bridge Jumper Vertikal
    def v_line_with_jumpers(x, y1, y2, jump_ys, lw=1.3, r=6):
        start_y = min(y1, y2)
        end_y = max(y1, y2)
        valid_jumps = sorted([jy for jy in jump_ys if start_y + r < jy < end_y - r])
        
        curr_y = start_y
        for jy in valid_jumps:
            c.line(x, curr_y, x, jy - r, lw=lw)
            c.d.arc(
                [c._p(x - r, jy - r), c._p(x + r, jy + r)],
                start=270, end=90,
                fill=BLACK,
                width=max(1, int(round(lw * c.S)))
            )
            curr_y = jy + r
        c.line(x, curr_y, x, end_y, lw=lw)

    # ==================== KOORDINAT LAYOUT ====================
    # VERTICAL CONTAINER (Kolom Tengah)
    cont_x = 1095
    cont_y = 145
    cont_w = 510
    cont_h = 1600

    # PROSES (Di Tengah-Tengah Vertical Container)
    proc_w = 450
    proc_h = 105
    proc_x = cont_x + (cont_w - proc_w) / 2 # = 1125
    p1_y = 230
    p2_y = 570
    p3_y = 910
    p4_y = 1250
    p5_y = 1590

    # SISI KIRI (Campuran Zig-Zag)
    ux, uy, uw, uh = 80, 230, 260, 330         # 1. USER [Entitas] (Kiri Luar Atas)
    d2_x, d2_y, d2_w, d2_h = 560, 600, 420, 50 # 2. D2: events [Data Store] (Kiri Menjorok Tengah)
    px, py, pw, ph = 80, 870, 280, 180         # 3. PAYMENT GATEWAY [Entitas] (Kiri Luar Tengah)
    d5_x, d5_y, d5_w, d5_h = 560, 1050, 420, 50# 4. D5: promos [Data Store] (Kiri Menjorok Bawah)
    fx, fy, fw, fh = 80, 1490, 260, 310        # 5. FIREBASE [Entitas] (Kiri Luar Bawah)

    # SISI KANAN (Campuran Zig-Zag)
    d1_x, d1_y, d1_w, d1_h = 2120, 255, 480, 50 # 1. D1: users [Data Store] (Kanan Luar Atas)
    d3_x, d3_y, d3_w, d3_h = 1710, 910, 440, 50 # 2. D3: orders [Data Store] (Kanan Menjorok Tengah)
    ax, ay, aw, ah = 2120, 1240, 280, 350        # 3. ADMIN [Entitas] (Kanan Luar Tengah)
    d4_x, d4_y, d4_w, d4_h = 1710, 1275, 440, 50# 4. D4: tickets [Data Store] (Kanan Menjorok Bawah)

    # ==================== 0. GAMBAR VERTICAL CONTAINER TERLEBIH DAHULU ====================
    # Kotak pembungkus vertikal
    c.fill_rect(cont_x, cont_y, cont_w, cont_h, fill=WHITE)
    c.rect(cont_x, cont_y, cont_w, cont_h, lw=2.0)
    # Header bar container
    c.rect(cont_x, cont_y, cont_w, 42, lw=1.8)
    c.text(cont_x + cont_w / 2, cont_y + 21, "SISTEM UTAMA SOUNDWAVE (GANE & SARSON)", f_cont_header, anchor="mm")

    # ==================== 1. GAMBAR GARIS KONEKTOR ====================
    # --- PROSES 1.0 (Manajemen Akun & Autentikasi) ---
    # User -> 1.0 (Horiz)
    c.line(ux + uw, 260, proc_x, 260, lw=1.3)
    c.head(proc_x, 260, "right", size=6.5)

    # 1.0 -> User (Horiz)
    c.line(proc_x, 305, ux + uw, 305, lw=1.3)
    c.head(ux + uw, 305, "left", size=6.5)

    # Firebase -> 1.0 (Naik via koridor x=440 dengan jumper)
    c.line(fx + fw, 1540, 440, 1540, lw=1.3)
    v_line_with_jumpers(440, 1540, 335, [1075, 960, 910, 625], lw=1.3)
    c.line(440, 335, proc_x, 335, lw=1.3)
    c.head(proc_x, 335, "right", size=6.5)

    # 1.0 -> D1: users (Horiz lurus ke kanan)
    c.line(proc_x + proc_w, d1_y + d1_h / 2, d1_x, d1_y + d1_h / 2, lw=1.3)
    c.head(d1_x, d1_y + d1_h / 2, "right", size=6.5)

    # --- PROSES 2.0 (Manajemen Event & Katalog Tiket) ---
    # Admin -> 2.0 (Naik dari kanan: Admin y=1270 via koridor x=2040 ke P2.0 y=595)
    c.line(ax, 1270, 2040, 1270, lw=1.3)
    v_line_with_jumpers(2040, 1270, 595, [935], lw=1.3)
    c.line(2040, 595, proc_x + proc_w, 595, lw=1.3)
    c.head(proc_x + proc_w, 595, "left", size=6.5)

    # 2.0 -> User (Horiz ke kiri)
    c.line(proc_x, 585, ux + uw, 585, lw=1.3)
    c.head(ux + uw, 585, "left", size=6.5)

    # 2.0 -> D2: events (Horiz ke D2 di kiri)
    c.line(proc_x, 625, d2_x + d2_w, 625, lw=1.3)
    c.head(d2_x + d2_w, 625, "left", size=6.5)

    # --- PROSES 3.0 (Pemesanan, Hold Kuota & Pembayaran) ---
    # User -> 3.0 (Pemesanan Tiket via koridor x=390)
    c.line(ux + uw, 490, 390, 490, lw=1.3)
    c.line(390, 490, 390, 930, lw=1.3)
    c.line(390, 930, proc_x, 930, lw=1.3)
    c.head(proc_x, 930, "right", size=6.5)

    # 3.0 -> User (Invoice & Hold via koridor x=415)
    c.line(proc_x, 960, 415, 960, lw=1.3)
    c.line(415, 960, 415, 530, lw=1.3)
    c.line(415, 530, ux + uw, 530, lw=1.3)
    c.head(ux + uw, 530, "left", size=6.5)

    # 3.0 -> Payment Gateway (Horiz ke kiri di y=910)
    c.line(proc_x, 910, px + pw, 910, lw=1.3)
    c.head(px + pw, 910, "left", size=6.5)

    # Payment Gateway -> 3.0 (Horiz dari kiri di y=980)
    c.line(px + pw, 980, proc_x, 980, lw=1.3)
    c.head(proc_x, 980, "right", size=6.5)

    # 3.0 -> D2: events (Atomic Hold Kuota - naik ke D2 di kiri)
    c.line(proc_x, 995, 1010, 995, lw=1.3)
    c.line(1010, 995, 1010, 640, lw=1.3)
    c.line(1010, 640, d2_x + d2_w, 640, lw=1.3)
    c.head(d2_x + d2_w, 640, "left", size=6.5)

    # 3.0 -> D5: promos (Validasi Promo - turun ke D5 di kiri)
    c.line(proc_x, 1015, 1030, 1015, lw=1.3)
    c.line(1030, 1015, 1030, 1075, lw=1.3)
    c.line(1030, 1075, d5_x + d5_w, 1075, lw=1.3)
    c.head(d5_x + d5_w, 1075, "left", size=6.5)

    # 3.0 -> D3: orders (Horiz langsung ke D3 di kanan)
    c.line(proc_x + proc_w, d3_y + d3_h / 2, d3_x, d3_y + d3_h / 2, lw=1.3)
    c.head(d3_x, d3_y + d3_h / 2, "right", size=6.5)

    # 3.0 -> D4: tickets (Generate Tiket - turun ke D4 di kanan)
    c.line(proc_x + proc_w, 985, 1660, 985, lw=1.3)
    c.line(1660, 985, 1660, 1285, lw=1.3)
    c.line(1660, 1285, d4_x, 1285, lw=1.3)
    c.head(d4_x, 1285, "right", size=6.5)

    # --- PROSES 4.0 (Penerbitan Tiket & Validasi Gate) ---
    # D4 -> 4.0 (Horiz dari D4 di kanan)
    c.line(d4_x, 1310, proc_x + proc_w, 1310, lw=1.3)
    c.head(proc_x + proc_w, 1310, "left", size=6.5)

    # Admin -> 4.0 (Scan Tiket dari kanan)
    c.line(ax, 1330, proc_x + proc_w, 1330, lw=1.3)
    c.head(proc_x + proc_w, 1330, "left", size=6.5)

    # 4.0 -> Admin (Status Validasi ke kanan)
    c.line(proc_x + proc_w, 1355, ax, 1355, lw=1.3)
    c.head(ax, 1355, "right", size=6.5)

    # 4.0 -> User (E-Tiket QR ke kiri luar via x=360)
    c.line(proc_x, 1265, 360, 1265, lw=1.3)
    c.line(360, 1265, 360, 390, lw=1.3)
    c.line(360, 390, ux + uw, 390, lw=1.3)
    c.head(ux + uw, 390, "left", size=6.5)

    # --- PROSES 5.0 (Pelaporan & Notifikasi Sistem) ---
    # D3 -> 5.0 (Data Rekap Omset dari D3 via koridor x=2100)
    c.line(d3_x + d3_w, d3_y + d3_h / 2, 2100, d3_y + d3_h / 2, lw=1.3)
    v_line_with_jumpers(2100, d3_y + d3_h / 2, 1605, [1270, 1310, 1330, 1355], lw=1.3)
    c.line(2100, 1605, proc_x + proc_w, 1605, lw=1.3)
    c.head(proc_x + proc_w, 1605, "left", size=6.5)

    # 5.0 -> Admin (Laporan Penjualan ke Admin di kanan)
    c.line(proc_x + proc_w, 1640, ax, 1640, lw=1.3)
    c.head(ax, 1640, "right", size=6.5)

    # 5.0 -> Firebase (Push Notif ke Firebase di kiri bawah)
    c.line(proc_x, 1660, fx + fw, 1660, lw=1.3)
    c.head(fx + fw, 1660, "left", size=6.5)

    # ==================== 2. GAMBAR SHAPES DI ATAS GARIS ====================
    def draw_full_process(x, y, w, h, pid, title, desc=""):
        c.d.rounded_rectangle(
            [c._p(x, y), c._p(x + w, y + h)],
            radius=int(12 * c.S),
            outline=BLACK,
            width=max(1, int(round(1.8 * c.S))),
            fill=WHITE
        )
        sekat_y = y + 32
        c.line(x, sekat_y, x + w, sekat_y, lw=1.4)
        c.text(x + w / 2, y + 16, f"PROSES {pid}", f_p_id, anchor="mm")
        if desc:
            c.text(x + w / 2, y + 55, title, f_p_title, anchor="mm")
            c.text(x + w / 2, y + 80, desc, f_p_sub, anchor="mm")
        else:
            c.text(x + w / 2, y + 68, title, f_p_title, anchor="mm")

    def draw_full_datastore(x, y, w, h, ds_id, ds_name):
        c.fill_rect(x, y, w, h, fill=WHITE)
        c.line(x, y, x + w, y, lw=1.4)
        c.line(x, y + h, x + w, y + h, lw=1.4)
        c.line(x, y, x, y + h, lw=1.4)
        c.line(x + 52, y, x + 52, y + h, lw=1.2)
        c.text(x + 26, y + h / 2, ds_id, f_ds_id, anchor="mm")
        c.text(x + 65, y + h / 2, ds_name, f_ds_name, anchor="lm")

    # ENTITAS SISI KIRI
    c.fill_rect(ux, uy, uw, uh, fill=WHITE)
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 145, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 175, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    c.fill_rect(px, py, pw, ph, fill=WHITE)
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 75, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 105, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    c.fill_rect(fx, fy, fw, fh, fill=WHITE)
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 140, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 170, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # DATA STORE SISI KIRI
    draw_full_datastore(d2_x, d2_y, d2_w, d2_h, "D2", "events (Jadwal Konser & Kuota Tiket)")
    draw_full_datastore(d5_x, d5_y, d5_w, d5_h, "D5", "promos (Kupon Diskon & Kuota Kupon)")

    # 5 PROSES (KOLOM TENGGAH DENGAN NAMA LENGKAP ASLI)
    draw_full_process(proc_x, p1_y, proc_w, proc_h, "1.0", "MANAJEMEN AKUN & AUTENTIKASI", "Registrasi, Login, Profil User & Admin")
    draw_full_process(proc_x, p2_y, proc_w, proc_h, "2.0", "MANAJEMEN EVENT & KATALOG TIKET", "Setup Konser, Alokasi Kuota, Katalog Musik")
    draw_full_process(proc_x, p3_y, proc_w, proc_h, "3.0", "PEMESANAN, HOLD KUOTA & PEMBAYARAN", "Atomic Hold 5 Mnt, Promo, Snap VA/QRIS, Webhook")
    draw_full_process(proc_x, p4_y, proc_w, proc_h, "4.0", "PENERBITAN TIKET & VALIDASI GATE", "Generate QR Ed25519 & Offline Gate Scanner")
    draw_full_process(proc_x, p5_y, proc_w, proc_h, "5.0", "PELAPORAN & NOTIFIKASI SISTEM", "Rekap Penjualan, Kehadiran Venue & FCM Push")

    # DATA STORE SISI KANAN
    draw_full_datastore(d1_x, d1_y, d1_w, d1_h, "D1", "users (Profil Akun & Kredensial)")
    draw_full_datastore(d3_x, d3_y, d3_w, d3_h, "D3", "orders (Pemesanan & Status Bayar)")
    draw_full_datastore(d4_x, d4_y, d4_w, d4_h, "D4", "tickets (Record E-Tiket & Status Scan)")

    # ENTITAS SISI KANAN
    c.fill_rect(ax, ay, aw, ah, fill=WHITE)
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 160, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 190, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    # ==================== 3. GAMBAR SEMUA LABEL BADGE LENGKAP ASLI ====================
    # Label P1.0
    label_badge((ux + uw + proc_x) / 2, 260, "Data Registrasi & Kredensial Login")
    label_badge((ux + uw + proc_x) / 2, 305, "Informasi Profil & Token Sesi")
    label_badge(810, 335, "Verifikasi Token UID", border=True)
    label_badge((proc_x + proc_w + d1_x) / 2, d1_y + d1_h / 2, "Simpan / Baca Data User")

    # Label P2.0
    label_badge(1830, 595, "Setup Event Konser & Kuota")
    label_badge((ux + uw + proc_x) / 2, 585, "Katalog Konser & Info Tiket")
    label_badge(1030, 625, "Simpan / Update Jadwal & Kuota")

    # Label P3.0
    label_badge(490, 910, "Parameter Tagihan Transaksi")
    label_badge(490, 980, "Snap Token, VA, QRIS & Webhook SHA-512")
    label_badge(390, 770, "Pemesanan Tiket & Kupon Promo")
    label_badge(520, 530, "Invoice & Hold Kuota 5 Menit")
    label_badge(1010, 790, "Atomic Hold Kuota Tiket")
    label_badge(1030, 1075, "Validasi Kupon Diskon")
    label_badge((proc_x + proc_w + d3_x) / 2, d3_y + d3_h / 2, "Simpan Record Pemesanan Lunas")
    label_badge(1660, 1140, "Generate Record Tiket Lunas")

    # Label P4.0
    label_badge(1660, 1310, "Ambil Tiket Terbit & Data QR Ed25519")
    label_badge(420, 390, "Penerbitan E-Tiket QR Ed25519")
    label_badge(1890, 1330, "Data Scan Tiket Gate (Offline)")
    label_badge(1890, 1355, "Status Validasi Gate (Valid / Invalid)")

    # Label P5.0
    label_badge(1890, 1605, "Data Rekap Omset Penjualan")
    label_badge(1890, 1640, "Laporan Penjualan & Kehadiran Venue")
    label_badge(710, 1660, "Dispatch Payload Push Notifikasi FCM")

    # ==================== FOOTER ====================
    fy_line = 2050
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 1 (DFD 1) — Style Zig-Zag Terdistribusi (Hybrid Left & Right).", f_foot)
    c.text(60, fy_line + 30, "Teks Asli Lengkap & Baku: Kolom tengah proses vertikal, entitas & data store zig-zag di kiri-kanan sesuai kedekatan alur data.", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Gane & Sarson Akademik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_style1_distributed_zigzag_legacy_text.png"
    c.save(out_path)
    print("OK Distributed Legacy Text DFD rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_distributed_legacy_text_dfd()
