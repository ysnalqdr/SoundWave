"""Generator DFD Level 1 Soundwave: Style 1 Linear Presisi Sempurna (v2).
Fitur Unggulan:
1. Multi-lane Bus Routing: Setiap jalur vertikal punya koordinat X unik (jarak 50-60px), nol tumpang tindih garis vertikal.
2. 2-Phase Layered Rendering:
   - Phase 1: Render seluruh garis panah ortogonal 90 derajat.
   - Phase 2: Render seluruh shape (Entitas, Proses Gane & Sarson, Data Store) dengan latar putih solid.
   - Phase 3: Render seluruh label teks dengan mask penutup putih ber-padding (NOL teks tertembus garis!).
3. Label teks dipecah 2 baris jika panjang agar tidak melebar keluar segmen.
"""
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_perfect_style1_dfd():
    W, H = 2500, 2050
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
    f_lbl = c.f(MONO, 9.5)
    f_foot = c.f(MONO, 10)

    # Label Kolom
    c.mask_text(205, 150, "[ 1. EXTERNAL ENTITIES ]", f_col_header, pad=3)
    c.mask_text(1175, 150, "[ 2. BUSINESS PROCESSES (GANE & SARSON) ]", f_col_header, pad=3)
    c.mask_text(2160, 150, "[ 3. DATA STORES ]", f_col_header, pad=3)

    # Garis pemisah kolom halus
    c.line(450, 175, 450, 1960, lw=0.8)
    c.line(1820, 175, 1820, 1960, lw=0.8)

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

    # ==================== PHASE 1: GAMBAR SEMUA GARIS ====================
    # Koridor Jalur Bus Kiri (X lanes: 400 .. 880)
    L_USER_KAT = 390
    L_USER_ETIK = 440
    L_USER_ORD = 490
    L_USER_TAG = 540
    L_MID_PARAM = 600
    L_MID_SNAP = 650
    L_ADM_EVT = 710
    L_ADM_SCAN = 760
    L_ADM_VAL = 810
    L_ADM_LAP = 860

    # Koridor Jalur Bus Kanan (X lanes: 1470 .. 1850)
    R_HOLD = 1490
    R_TIK = 1570
    R_PROMO = 1650
    R_REKAP = 1730

    # 1. P1.0 Akun & Auth
    # User -> P1.0 (Horiz murni)
    c.line(ux + uw, 260, proc_x, 260, lw=1.3)
    c.head(proc_x, 260, "right", size=6.5)

    # P1.0 -> User (Horiz murni)
    c.line(proc_x, 310, ux + uw, 310, lw=1.3)
    c.head(ux + uw, 310, "left", size=6.5)

    # P1.0 -> D1: users (Horiz murni)
    c.line(proc_x + proc_w, d1_y + ds_h / 2, ds_x, d1_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d1_y + ds_h / 2, "right", size=6.5)

    # Firebase -> P1.0 (Auth UID)
    c.line(fx + fw, 1590, L_USER_KAT - 20, 1590, lw=1.3)
    c.line(L_USER_KAT - 20, 1590, L_USER_KAT - 20, 335, lw=1.3)
    c.line(L_USER_KAT - 20, 335, proc_x, 335, lw=1.3)
    c.head(proc_x, 335, "right", size=6.5)

    # 2. P2.0 Event & Katalog
    # Admin -> P2.0
    c.line(ax + aw, 710, L_ADM_EVT, 710, lw=1.3)
    c.line(L_ADM_EVT, 710, L_ADM_EVT, 600, lw=1.3)
    c.line(L_ADM_EVT, 600, proc_x, 600, lw=1.3)
    c.head(proc_x, 600, "right", size=6.5)

    # P2.0 -> User (Katalog Event)
    c.line(proc_x, 640, L_USER_KAT, 640, lw=1.3)
    c.line(L_USER_KAT, 640, L_USER_KAT, 470, lw=1.3)
    c.line(L_USER_KAT, 470, ux + uw, 470, lw=1.3)
    c.head(ux + uw, 470, "left", size=6.5)

    # P2.0 -> D2: events (Horiz murni)
    c.line(proc_x + proc_w, d2_y + ds_h / 2, ds_x, d2_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d2_y + ds_h / 2, "right", size=6.5)

    # 3. P3.0 Pemesanan, Hold & Bayar
    # User -> P3.0 (Order & Promo)
    c.line(ux + uw, 520, L_USER_ORD, 520, lw=1.3)
    c.line(L_USER_ORD, 520, L_USER_ORD, 940, lw=1.3)
    c.line(L_USER_ORD, 940, proc_x, 940, lw=1.3)
    c.head(proc_x, 940, "right", size=6.5)

    # P3.0 -> User (Hold 5 Mnt & Tagihan)
    c.line(proc_x, 975, L_USER_TAG, 975, lw=1.3)
    c.line(L_USER_TAG, 975, L_USER_TAG, 565, lw=1.3)
    c.line(L_USER_TAG, 565, ux + uw, 565, lw=1.3)
    c.head(ux + uw, 565, "left", size=6.5)

    # P3.0 -> Midtrans (Parameter Tagihan)
    c.line(proc_x, 1005, L_MID_PARAM, 1005, lw=1.3)
    c.line(L_MID_PARAM, 1005, L_MID_PARAM, 1210, lw=1.3)
    c.line(L_MID_PARAM, 1210, px + pw, 1210, lw=1.3)
    c.head(px + pw, 1210, "left", size=6.5)

    # Midtrans -> P3.0 (Snap Token & Webhook SHA-512)
    c.line(px + pw, 1270, L_MID_SNAP, 1270, lw=1.3)
    c.line(L_MID_SNAP, 1270, L_MID_SNAP, 1025, lw=1.3)
    c.line(L_MID_SNAP, 1025, proc_x, 1025, lw=1.3)
    c.head(proc_x, 1025, "right", size=6.5)

    # P3.0 -> D3: orders (Horiz murni)
    c.line(proc_x + proc_w, d3_y + ds_h / 2, ds_x, d3_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d3_y + ds_h / 2, "right", size=6.5)

    # P3.0 -> D2: events (Atomic Hold Kuota)
    c.line(proc_x + proc_w, 935, R_HOLD, 935, lw=1.3)
    c.line(R_HOLD, 935, R_HOLD, 640, lw=1.3)
    c.line(R_HOLD, 640, ds_x, 640, lw=1.3)
    c.head(ds_x, 640, "right", size=6.5)

    # P3.0 -> D4: tickets (Generate Tiket Lunas)
    c.line(proc_x + proc_w, 995, R_TIK, 995, lw=1.3)
    c.line(R_TIK, 995, R_TIK, 1285, lw=1.3)
    c.line(R_TIK, 1285, ds_x, 1285, lw=1.3)
    c.head(ds_x, 1285, "right", size=6.5)

    # P3.0 -> D5: promos (Validasi Kupon)
    c.line(proc_x + proc_w, 1015, R_PROMO, 1015, lw=1.3)
    c.line(R_PROMO, 1015, R_PROMO, 1625, lw=1.3)
    c.line(R_PROMO, 1625, ds_x, 1625, lw=1.3)
    c.head(ds_x, 1625, "right", size=6.5)

    # 4. P4.0 E-Tiket & Validasi Gate
    # D4 -> P4.0 (Ambil Tiket Terbit)
    c.line(ds_x, d4_y + ds_h / 2, proc_x + proc_w, d4_y + ds_h / 2, lw=1.3)
    c.head(proc_x + proc_w, d4_y + ds_h / 2, "left", size=6.5)

    # P4.0 -> User (E-Tiket QR Ed25519)
    c.line(proc_x, 1290, L_USER_ETIK, 1290, lw=1.3)
    c.line(L_USER_ETIK, 1290, L_USER_ETIK, 410, lw=1.3)
    c.line(L_USER_ETIK, 410, ux + uw, 410, lw=1.3)
    c.head(ux + uw, 410, "left", size=6.5)

    # Admin -> P4.0 (Offline Gate Scan)
    c.line(ax + aw, 830, L_ADM_SCAN, 830, lw=1.3)
    c.line(L_ADM_SCAN, 830, L_ADM_SCAN, 1325, lw=1.3)
    c.line(L_ADM_SCAN, 1325, proc_x, 1325, lw=1.3)
    c.head(proc_x, 1325, "right", size=6.5)

    # P4.0 -> Admin (Status Validasi Gate)
    c.line(proc_x, 1355, L_ADM_VAL, 1355, lw=1.3)
    c.line(L_ADM_VAL, 1355, L_ADM_VAL, 890, lw=1.3)
    c.line(L_ADM_VAL, 890, ax + aw, 890, lw=1.3)
    c.head(ax + aw, 890, "left", size=6.5)

    # 5. P5.0 Pelaporan & Notifikasi
    # D3 -> P5.0 (Data Rekap Omset)
    c.line(ds_x, 1005, R_REKAP, 1005, lw=1.3)
    c.line(R_REKAP, 1005, R_REKAP, 1630, lw=1.3)
    c.line(R_REKAP, 1630, proc_x + proc_w, 1630, lw=1.3)
    c.head(proc_x + proc_w, 1630, "left", size=6.5)

    # P5.0 -> Admin (Laporan Penjualan)
    c.line(proc_x, 1630, L_ADM_LAP, 1630, lw=1.3)
    c.line(L_ADM_LAP, 1630, L_ADM_LAP, 950, lw=1.3)
    c.line(L_ADM_LAP, 950, ax + aw, 950, lw=1.3)
    c.head(ax + aw, 950, "left", size=6.5)

    # P5.0 -> Firebase (Push FCM)
    c.line(proc_x, 1680, fx + fw, 1680, lw=1.3)
    c.head(fx + fw, 1680, "left", size=6.5)

    # ==================== PHASE 2: GAMBAR SEMUA SHAPE ====================
    # Helper: Gambar Proses Gane & Sarson (Rounded Rect)
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

    # ==================== PHASE 3: GAMBAR SEMUA LABEL TEKS (MASK PUTIH) ====================
    # Semua teks di-render di layer teratas dengan mask penutup putih ber-padding 4px!
    c.mask_text((ux + uw + proc_x) / 2, 248, "Data Registrasi & Kredensial Login", f_lbl, pad=4)
    c.mask_text((ux + uw + proc_x) / 2, 298, "Informasi Profil & Token Sesi", f_lbl, pad=4)
    c.mask_text(L_USER_KAT - 20, 950, "Verifikasi Token UID", f_lbl, pad=4)

    c.mask_text((proc_x + proc_w + ds_x) / 2, d1_y + ds_h / 2 - 12, "Simpan / Baca Data User", f_lbl, pad=4)

    # P2.0
    c.mask_text(L_ADM_EVT + 60, 588, "Setup Event Konser & Kuota", f_lbl, pad=4)
    c.mask_text(L_USER_KAT, 540, "Katalog Konser & Info Tiket", f_lbl, pad=4)
    c.mask_text((proc_x + proc_w + ds_x) / 2, d2_y + ds_h / 2 - 12, "Simpan / Update Jadwal & Kuota", f_lbl, pad=4)

    # P3.0
    c.mask_text(L_USER_ORD, 750, "Pemesanan Tiket & Kupon Promo", f_lbl, pad=4)
    c.mask_text(L_USER_TAG, 770, "Invoice & Hold Kuota 5 Menit", f_lbl, pad=4)
    c.mask_text(L_MID_PARAM, 1110, "Parameter Tagihan Transaksi", f_lbl, pad=4)
    c.mask_text(L_MID_SNAP, 1150, "Snap Token, VA, QRIS & Webhook SHA-512", f_lbl, pad=4)
    c.mask_text((proc_x + proc_w + ds_x) / 2, d3_y + ds_h / 2 - 12, "Simpan Record Pemesanan & Status Lunas", f_lbl, pad=4)
    c.mask_text(R_HOLD, 790, "Atomic Hold Kuota Tiket", f_lbl, pad=4)
    c.mask_text(R_TIK, 1140, "Generate Record Tiket Lunas", f_lbl, pad=4)
    c.mask_text(R_PROMO, 1320, "Cek & Validasi Kupon Promo", f_lbl, pad=4)

    # P4.0
    c.mask_text((proc_x + proc_w + ds_x) / 2, d4_y + ds_h / 2 - 12, "Ambil Tiket Terbit & Data QR Ed25519", f_lbl, pad=4)
    c.mask_text(L_USER_ETIK, 850, "Penerbitan E-Tiket QR Ed25519", f_lbl, pad=4)
    c.mask_text(L_ADM_SCAN, 1080, "Data Scan Tiket Gate (Offline)", f_lbl, pad=4)
    c.mask_text(L_ADM_VAL, 1120, "Status Validasi Gate (Valid / Invalid)", f_lbl, pad=4)

    # P5.0
    c.mask_text(R_REKAP, 1320, "Data Rekap Omset Penjualan", f_lbl, pad=4)
    c.mask_text(L_ADM_LAP, 1290, "Laporan Penjualan & Kehadiran", f_lbl, pad=4)
    c.mask_text((proc_x + fx + fw) / 2, 1668, "Dispatch Payload Push Notifikasi FCM", f_lbl, pad=4)

    # ==================== FOOTER ====================
    fy_line = 1980
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 1 (DFD 1) — Style 1: 3-Column Linear Architecture (Gane & Sarson).", f_foot)
    c.text(60, fy_line + 30, "Mendekomposisi aliran sistem SoundWave secara teratur: Entitas Eksternal (Kiri) -> Proses Inti (Tengah) -> Data Store (Kanan).", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Gane & Sarson / DeMarco Linear", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_style1_linear_soundwave_presisi.png"
    c.save(out_path)
    print("OK Style 1 v2 rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_perfect_style1_dfd()
