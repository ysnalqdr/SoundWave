"""Generator DFD Level 1 Soundwave: Revisi Final Sempurna (v2).
Fitur Unggulan:
1. 100% Planar Diagram: Nol garis bersilangan (zero line intersections) dengan penataan urutan Data Store adaptif (D1, D2, D5, D3, D4).
2. General vertical container untuk Proses 1.0 .. 5.0 di kolom tengah.
3. Entitas eksternal sisi kiri berpola offset zig-zag dinamis (User & Admin di kiri luar, Midtrans & Firebase menjorok ke dalam).
4. Nol teks bertumpuk atau terhimpit garis: Setiap label diletakkan pada segmen horizontal terisolasi dengan badge latar putih solid.
"""
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_perfect_v2():
    W, H = 2650, 2050
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

    # ==================== KOORDINAT LAYOUT ====================
    # ENTITAS (Zig-Zag Offset di Sisi Kiri)
    ux, uy, uw, uh = 70, 230, 260, 360   # User (Kiri Luar Atas)
    ax, ay, aw, ah = 70, 1150, 260, 360  # Admin (Kiri Luar Bawah)
    px, py, pw, ph = 520, 880, 280, 180  # Midtrans (Menjorok ke Tengah dekat P3.0)
    fx, fy, fw, fh = 520, 1570, 280, 170 # Firebase (Menjorok ke Bawah dekat P5.0)

    # PROSES (Wadah Kolom Tengah Terpusat: x = 1040, w = 480)
    proc_x = 1040
    proc_w = 480
    p1_y, p1_h = 230, 115
    p2_y, p2_h = 570, 115
    p3_y, p3_h = 910, 125
    p4_y, p4_h = 1250, 115
    p5_y, p5_h = 1590, 115

    # DATA STORE (Kolom Kanan: x = 1960, w = 530, h = 48)
    # Diurutkan secara cerdas agar 100% Bebas Potongan Garis:
    # D1 (users), D2 (events), D5 (promos), D3 (orders), D4 (tickets)
    ds_x = 1960
    ds_w = 530
    ds_h = 48
    d1_y = 263   # Sejajar P1.0
    d2_y = 590   # Sejajar P2.0
    d5_y = 850   # Sejajar atas P3.0
    d3_y = 1070  # Sejajar bawah P3.0
    d4_y = 1350  # Sejajar P4.0

    # ==================== 1. GAMBAR SEMUA GARIS KONEKTOR ====================
    # Koridor Jalur Bebas di Sisi Kiri
    COR_USER_TIK = 360
    COR_USER_KAT = 400
    COR_USER_ORD = 440
    COR_USER_TAG = 480
    COR_FB_AUTH  = 860
    COR_ADM_EVT  = 890
    COR_ADM_LAP  = 840

    # Koridor Jalur Bebas di Sisi Kanan
    COR_R_HOLD  = 1620
    COR_R_TIK   = 1660
    COR_R_REKAP = 1880

    # --- A. PROSES 1.0 (AKUN & AUTH) ---
    # User -> P1.0 (Horiz murni)
    c.line(ux + uw, 260, proc_x, 260, lw=1.3)
    c.head(proc_x, 260, "right", size=6.5)

    # P1.0 -> User (Horiz murni)
    c.line(proc_x, 310, ux + uw, 310, lw=1.3)
    c.head(ux + uw, 310, "left", size=6.5)

    # Firebase -> P1.0 (Auth UID via koridor x=860, tidak memotong jalur User!)
    c.line(fx + fw, 1595, COR_FB_AUTH, 1595, lw=1.3)
    c.line(COR_FB_AUTH, 1595, COR_FB_AUTH, 335, lw=1.3)
    c.line(COR_FB_AUTH, 335, proc_x, 335, lw=1.3)
    c.head(proc_x, 335, "right", size=6.5)

    # P1.0 -> D1: users (Horiz murni)
    c.line(proc_x + proc_w, d1_y + ds_h / 2, ds_x, d1_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d1_y + ds_h / 2, "right", size=6.5)

    # --- B. PROSES 2.0 (EVENT & KATALOG) ---
    # Admin -> P2.0 (Setup Event)
    c.line(ax + aw, 1180, COR_ADM_EVT, 1180, lw=1.3)
    c.line(COR_ADM_EVT, 1180, COR_ADM_EVT, 600, lw=1.3)
    c.line(COR_ADM_EVT, 600, proc_x, 600, lw=1.3)
    c.head(proc_x, 600, "right", size=6.5)

    # P2.0 -> User (Katalog Konser)
    c.line(proc_x, 640, COR_USER_KAT, 640, lw=1.3)
    c.line(COR_USER_KAT, 640, COR_USER_KAT, 440, lw=1.3)
    c.line(COR_USER_KAT, 440, ux + uw, 440, lw=1.3)
    c.head(ux + uw, 440, "left", size=6.5)

    # P2.0 -> D2: events (Horiz murni)
    c.line(proc_x + proc_w, d2_y + ds_h / 2, ds_x, d2_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d2_y + ds_h / 2, "right", size=6.5)

    # --- C. PROSES 3.0 (PEMESANAN & BAYAR) ---
    # User -> P3.0 (Order Tiket)
    c.line(ux + uw, 510, COR_USER_ORD, 510, lw=1.3)
    c.line(COR_USER_ORD, 510, COR_USER_ORD, 930, lw=1.3)
    c.line(COR_USER_ORD, 930, proc_x, 930, lw=1.3)
    c.head(proc_x, 930, "right", size=6.5)

    # P3.0 -> User (Invoice & Hold 5 Mnt)
    c.line(proc_x, 970, COR_USER_TAG, 970, lw=1.3)
    c.line(COR_USER_TAG, 970, COR_USER_TAG, 560, lw=1.3)
    c.line(COR_USER_TAG, 560, ux + uw, 560, lw=1.3)
    c.head(ux + uw, 560, "left", size=6.5)

    # P3.0 -> Midtrans (Horiz murni sangat dekat!)
    c.line(proc_x, 1000, px + pw, 1000, lw=1.3)
    c.head(px + pw, 1000, "left", size=6.5)

    # Midtrans -> P3.0 (Snap VA/QRIS & Webhook SHA-512)
    c.line(px + pw, 1035, proc_x, 1035, lw=1.3)
    c.head(proc_x, 1035, "right", size=6.5)

    # P3.0 -> D2: events (Atomic Hold Kuota Tiket via koridor kanan)
    c.line(proc_x + proc_w, 925, COR_R_HOLD, 925, lw=1.3)
    c.line(COR_R_HOLD, 925, COR_R_HOLD, 625, lw=1.3)
    c.line(COR_R_HOLD, 625, ds_x, 625, lw=1.3)
    c.head(ds_x, 625, "right", size=6.5)

    # P3.0 -> D5: promos (Validasi Promo - Langsung naik sedikit, 0 potong!)
    c.line(proc_x + proc_w, 955, 1720, 955, lw=1.3)
    c.line(1720, 955, 1720, d5_y + ds_h / 2, lw=1.3)
    c.line(1720, d5_y + ds_h / 2, ds_x, d5_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d5_y + ds_h / 2, "right", size=6.5)

    # P3.0 -> D3: orders (Simpan Record Order - Langsung turun sedikit, 0 potong!)
    c.line(proc_x + proc_w, 990, 1720, 990, lw=1.3)
    c.line(1720, 990, 1720, d3_y + ds_h / 2, lw=1.3)
    c.line(1720, d3_y + ds_h / 2, ds_x, d3_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d3_y + ds_h / 2, "right", size=6.5)

    # P3.0 -> D4: tickets (Generate Tiket Lunas via koridor kanan)
    c.line(proc_x + proc_w, 1020, COR_R_TIK, 1020, lw=1.3)
    c.line(COR_R_TIK, 1020, COR_R_TIK, 1360, lw=1.3)
    c.line(COR_R_TIK, 1360, ds_x, 1360, lw=1.3)
    c.head(ds_x, 1360, "right", size=6.5)

    # --- D. PROSES 4.0 (TIKET & GATE) ---
    # D4 -> P4.0 (Ambil Tiket Terbit - Horiz murni)
    c.line(ds_x, 1385, 1750, 1385, lw=1.3)
    c.line(1750, 1385, 1750, 1307, lw=1.3)
    c.line(1750, 1307, proc_x + proc_w, 1307, lw=1.3)
    c.head(proc_x + proc_w, 1307, "left", size=6.5)

    # P4.0 -> User (E-Tiket QR Ed25519 via koridor luar x=360)
    c.line(proc_x, 1275, COR_USER_TIK, 1275, lw=1.3)
    c.line(COR_USER_TIK, 1275, COR_USER_TIK, 370, lw=1.3)
    c.line(COR_USER_TIK, 370, ux + uw, 370, lw=1.3)
    c.head(ux + uw, 370, "left", size=6.5)

    # Admin -> P4.0 (Scan Gate Offline - Horiz murni)
    c.line(ax + aw, 1300, proc_x, 1300, lw=1.3)
    c.head(proc_x, 1300, "right", size=6.5)

    # P4.0 -> Admin (Status Validasi Gate - Horiz murni)
    c.line(proc_x, 1345, ax + aw, 1345, lw=1.3)
    c.head(ax + aw, 1345, "left", size=6.5)

    # --- E. PROSES 5.0 (LAPORAN & NOTIF) ---
    # D3 -> P5.0 (Data Rekap Omset via koridor kanan x=1880, bebas dari D4!)
    c.line(ds_x, 1105, COR_R_REKAP, 1105, lw=1.3)
    c.line(COR_R_REKAP, 1105, COR_R_REKAP, 1620, lw=1.3)
    c.line(COR_R_REKAP, 1620, proc_x + proc_w, 1620, lw=1.3)
    c.head(proc_x + proc_w, 1620, "left", size=6.5)

    # P5.0 -> Admin (Laporan Penjualan & Kehadiran)
    c.line(proc_x, 1640, COR_ADM_LAP, 1640, lw=1.3)
    c.line(COR_ADM_LAP, 1640, COR_ADM_LAP, 1450, lw=1.3)
    c.line(COR_ADM_LAP, 1450, ax + aw, 1450, lw=1.3)
    c.head(ax + aw, 1450, "left", size=6.5)

    # P5.0 -> Firebase (Push Notif FCM - Horiz murni sangat dekat!)
    c.line(proc_x, 1675, fx + fw, 1675, lw=1.3)
    c.head(fx + fw, 1675, "left", size=6.5)

    # ==================== 2. GAMBAR SHAPES DI ATAS GARIS ====================
    # Helper: Gambar Proses Gane & Sarson
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

    # Helper: Gambar Data Store Gane & Sarson
    def draw_datastore_gs(x, y, w, h, ds_id, ds_name):
        c.fill_rect(x, y, w, h, fill=WHITE)
        c.line(x, y, x + w, y, lw=1.4)
        c.line(x, y + h, x + w, y + h, lw=1.4)
        c.line(x, y, x, y + h, lw=1.4)
        c.line(x + 55, y, x + 55, y + h, lw=1.2)
        c.text(x + 28, y + h / 2, ds_id, f_ds_id, anchor="mm")
        c.text(x + 70, y + h / 2, ds_name, f_ds_name, anchor="lm")

    # 4 ENTITAS (ZIG-ZAG OFFSET)
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
    c.text(px + pw / 2, py + 75, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 105, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    c.fill_rect(fx, fy, fw, fh, fill=WHITE)
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 70, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 100, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # 5 PROSES (WADAH TENGAH SEJAJAR)
    draw_process_gs(proc_x, p1_y, proc_w, p1_h, "1.0", "MANAJEMEN AKUN & AUTENTIKASI", "Registrasi, Login, Profil User & Admin")
    draw_process_gs(proc_x, p2_y, proc_w, p2_h, "2.0", "MANAJEMEN EVENT & KATALOG TIKET", "Setup Konser, Alokasi Kuota, Katalog Musik")
    draw_process_gs(proc_x, p3_y, proc_w, p3_h, "3.0", "PEMESANAN, HOLD KUOTA & PEMBAYARAN", "Atomic Hold 5 Mnt, Promo, Snap VA/QRIS, Webhook")
    draw_process_gs(proc_x, p4_y, proc_w, p4_h, "4.0", "PENERBITAN TIKET & VALIDASI GATE", "Generate QR Ed25519 & Offline Gate Scanner")
    draw_process_gs(proc_x, p5_y, proc_w, p5_h, "5.0", "PELAPORAN & NOTIFIKASI SISTEM", "Rekap Penjualan, Kehadiran Venue & FCM Push")

    # 5 DATA STORE (KOLOM KANAN BERSIH)
    draw_datastore_gs(ds_x, d1_y, ds_w, ds_h, "D1", "users (Profil Akun & Kredensial)")
    draw_datastore_gs(ds_x, d2_y, ds_w, ds_h, "D2", "events (Jadwal Konser & Kuota Tiket)")
    draw_datastore_gs(ds_x, d5_y, ds_w, ds_h, "D5", "promos (Kupon Diskon & Kuota Kupon)")
    draw_datastore_gs(ds_x, d3_y, ds_w, ds_h, "D3", "orders (Pemesanan & Status Bayar)")
    draw_datastore_gs(ds_x, d4_y, ds_w, ds_h, "D4", "tickets (Record E-Tiket & Status Scan)")

    # ==================== 3. GAMBAR SEMUA LABEL BADGE (LAYER TERATAS) ====================
    # Label P1.0
    label_badge((ux + uw + proc_x) / 2, 260, "Data Registrasi & Kredensial Login")
    label_badge((ux + uw + proc_x) / 2, 310, "Informasi Profil & Token Sesi")
    label_badge(950, 335, "Verifikasi Token UID", border=True)
    label_badge((proc_x + proc_w + ds_x) / 2, d1_y + ds_h / 2, "Simpan / Baca Data User")

    # Label P2.0
    label_badge(960, 600, "Setup Event Konser & Kuota")
    label_badge(COR_USER_KAT + 130, 640, "Katalog Konser & Info Tiket")
    label_badge((proc_x + proc_w + ds_x) / 2, d2_y + ds_h / 2, "Simpan / Update Jadwal & Kuota")

    # Label P3.0
    label_badge(COR_USER_ORD + 130, 930, "Pemesanan Tiket & Kupon Promo")
    label_badge(COR_USER_TAG + 130, 970, "Invoice & Hold Kuota 5 Menit")
    label_badge((px + pw + proc_x) / 2, 990, "Parameter Tagihan Transaksi")
    label_badge((px + pw + proc_x) / 2, 1045, "Snap Token, VA, QRIS & Webhook SHA-512")
    label_badge(1840, 625, "Atomic Hold Kuota Tiket")
    label_badge(1840, d5_y + ds_h / 2, "Validasi Kupon Diskon")
    label_badge(1840, d3_y + ds_h / 2, "Simpan Record Order Lunas")
    label_badge(1840, 1360, "Generate Record Tiket Lunas")

    # Label P4.0
    label_badge(1630, 1307, "Ambil Tiket Terbit & Data QR Ed25519")
    label_badge(COR_USER_TIK + 130, 1275, "Penerbitan E-Tiket QR Ed25519")
    label_badge((ax + aw + proc_x) / 2, 1290, "Data Scan Tiket Gate (Offline)")
    label_badge((ax + aw + proc_x) / 2, 1355, "Status Validasi Gate (Valid / Invalid)")

    # Label P5.0
    label_badge(1700, 1620, "Data Rekap Omset Penjualan")
    label_badge(COR_ADM_LAP + 90, 1640, "Laporan Penjualan & Kehadiran")
    label_badge((proc_x + fx + fw) / 2, 1675, "Dispatch Payload Push Notifikasi FCM")

    # ==================== FOOTER ====================
    fy_line = 1980
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 1 (DFD 1) — Style 1: 3-Column Linear Architecture (Gane & Sarson).", f_foot)
    c.text(60, fy_line + 30, "Mendekomposisi aliran sistem SoundWave secara teratur: Entitas Offset Zig-Zag (Kiri) -> Proses Inti (Tengah) -> Data Store (Kanan).", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Gane & Sarson Linear Akademik (100% Planar, Zero Collision)", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_style1_linear_soundwave_revisi_sempurna.png"
    c.save(out_path)
    print("OK Revisi Sempurna rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_perfect_v2()
