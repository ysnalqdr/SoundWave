"""Generator DFD Level 1 Soundwave: Versi Ramping, Bersih, Baku & Ringkas.
Fitur Pembaruan:
1. Bebas Simbol '&': Semua nama proses menggunakan format baku 'Kata Kerja + Objek' (Verb + Noun).
2. Box Ramping (Compact): Lebar box proses 330px (tidak melebar), hanya memuat ID dan Nama Proses.
3. Label Alur Data Singkat: Semua label panah diringkas menjadi 2-3 kata padat dan jelas.
4. Entitas Zig-Zag Dinamis: User (kiri atas), Midtrans (menjorok tengah), Firebase (kiri bawah), Admin (menjorok bawah).
5. Bridge Jumpers & Masking: Semua persilangan memakai lengkungan jumper, semua teks berpelindung badge putih.
"""
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_compact_clean_dfd():
    W, H = 2500, 1950
    c = Canvas(W, H, s=2)

    # 1. HEADER KIRI ATAS
    c.rect(60, 40, 520, 75, lw=1.6)
    c.text(80, 62, "DATA FLOW DIAGRAM (DFD LEVEL 1)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 86, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font styles
    f_col_header = c.f(SANS_B, 13)
    f_ent_title = c.f(SANS_B, 14)
    f_ent_sub = c.f(MONO, 10.5)
    f_p_id = c.f(MONO_B, 13)
    f_p_title = c.f(SANS_B, 13.5)
    f_ds_id = c.f(MONO_B, 12.5)
    f_ds_name = c.f(MONO_B, 11)
    f_lbl = c.f(MONO, 9.5)
    f_foot = c.f(MONO, 9.5)

    # Header Kolom
    c.text(280, 140, "[ 1. ENTITAS EKSTERNAL (ZIG-ZAG) ]", f_col_header, anchor="mm")
    c.text(1250, 140, "[ 2. PROSES BISNIS (GANE & SARSON) ]", f_col_header, anchor="mm")
    c.text(2160, 140, "[ 3. DATA STORE ]", f_col_header, anchor="mm")

    # Helper: Kotak Label Badge Putih Solid
    def label_badge(cx, cy, text, font=f_lbl, pad_x=5, pad_y=3, border=True):
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
    # ENTITAS (Kiri Zig-Zag: Ramping & Rapi)
    ux, uy, uw, uh = 70, 220, 240, 320    # 1. USER (Kiri Luar Atas)
    px, py, pw, ph = 460, 780, 250, 160   # 2. MIDTRANS (Menjorok Tengah dekat P3.0)
    fx, fy, fw, fh = 70, 1340, 240, 310   # 3. FIREBASE (Kiri Luar Bawah)
    ax, ay, aw, ah = 460, 1140, 250, 330  # 4. ADMIN (Menjorok Tengah dekat P4.0 & P5.0)

    # PROSES (Kolom Tengah Ramping: Lebar 330, Tinggi 85)
    proc_x = 1085
    proc_w = 330
    proc_h = 85
    p1_y = 220
    p2_y = 530
    p3_y = 840
    p4_y = 1150
    p5_y = 1460

    # DATA STORE (Kolom Kanan Terbuka: Lebar 420, Tinggi 46)
    ds_x = 1950
    ds_w = 420
    ds_h = 46
    d1_y = 240
    d2_y = 550
    d3_y = 860
    d4_y = 1170
    d5_y = 1480

    # ==================== 1. GAMBAR GARIS KONEKTOR ====================
    # Koridor Jalur Bebas
    L_USER_P3 = 360
    L_P3_USER = 390
    L_P4_USER = 330
    L_FB_AUTH = 800

    R_HOLD   = 1550
    R_TIKET  = 1630
    R_PROMO  = 1710
    R_REKAP  = 1810

    # --- A. PROSES 1.0 (PENGELOLAAN AKUN) ---
    # User -> 1.0
    c.line(ux + uw, 245, proc_x, 245, lw=1.3)
    c.head(proc_x, 245, "right", size=6.5)

    # 1.0 -> User
    c.line(proc_x, 280, ux + uw, 280, lw=1.3)
    c.head(ux + uw, 280, "left", size=6.5)

    # Firebase -> 1.0
    c.line(fx + fw, 1420, L_FB_AUTH, 1420, lw=1.3)
    v_line_with_jumpers(L_FB_AUTH, 1420, 295, [1170, 1205, 905, 865], lw=1.3)
    c.line(L_FB_AUTH, 295, proc_x, 295, lw=1.3)
    c.head(proc_x, 295, "right", size=6.5)

    # 1.0 -> D1
    c.line(proc_x + proc_w, d1_y + ds_h / 2, ds_x, d1_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d1_y + ds_h / 2, "right", size=6.5)

    # --- B. PROSES 2.0 (PENGELOLAAN EVENT) ---
    # Admin -> 2.0
    c.line(ax + aw, 1170, 840, 1170, lw=1.3)
    v_line_with_jumpers(840, 1170, 555, [905, 865], lw=1.3)
    c.line(840, 555, proc_x, 555, lw=1.3)
    c.head(proc_x, 555, "right", size=6.5)

    # 2.0 -> User
    c.line(proc_x, 585, ux + uw, 585, lw=1.3)
    c.head(ux + uw, 585, "left", size=6.5)

    # 2.0 -> D2
    c.line(proc_x + proc_w, d2_y + ds_h / 2, ds_x, d2_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d2_y + ds_h / 2, "right", size=6.5)

    # --- C. PROSES 3.0 (TRANSAKSI PEMESANAN) ---
    # User -> 3.0
    c.line(ux + uw, 470, L_USER_P3, 470, lw=1.3)
    c.line(L_USER_P3, 470, L_USER_P3, 865, lw=1.3)
    c.line(L_USER_P3, 865, px, 865, lw=1.3)
    c.line(px + pw, 865, proc_x, 865, lw=1.3)
    c.head(proc_x, 865, "right", size=6.5)

    # 3.0 -> User
    c.line(proc_x, 905, px + pw, 905, lw=1.3)
    c.line(px, 905, L_P3_USER, 905, lw=1.3)
    c.line(L_P3_USER, 905, L_P3_USER, 510, lw=1.3)
    c.line(L_P3_USER, 510, ux + uw, 510, lw=1.3)
    c.head(ux + uw, 510, "left", size=6.5)

    # 3.0 -> Midtrans
    c.line(proc_x, 840, px + pw, 840, lw=1.3)
    c.head(px + pw, 840, "left", size=6.5)

    # Midtrans -> 3.0
    c.line(px + pw, 925, proc_x, 925, lw=1.3)
    c.head(proc_x, 925, "right", size=6.5)

    # 3.0 -> D3
    c.line(proc_x + proc_w, d3_y + ds_h / 2, ds_x, d3_y + ds_h / 2, lw=1.3)
    c.head(ds_x, d3_y + ds_h / 2, "right", size=6.5)

    # 3.0 -> D2 (Hold Kuota)
    c.line(proc_x + proc_w, 855, R_HOLD, 855, lw=1.3)
    c.line(R_HOLD, 855, R_HOLD, 585, lw=1.3)
    c.line(R_HOLD, 585, ds_x, 585, lw=1.3)
    c.head(ds_x, 585, "right", size=6.5)

    # 3.0 -> D4 (Penerbitan Tiket)
    c.line(proc_x + proc_w, 895, R_TIKET, 895, lw=1.3)
    c.line(R_TIKET, 895, R_TIKET, 1175, lw=1.3)
    c.line(R_TIKET, 1175, ds_x, 1175, lw=1.3)
    c.head(ds_x, 1175, "right", size=6.5)

    # 3.0 -> D5 (Validasi Promo)
    c.line(proc_x + proc_w, 920, R_PROMO, 920, lw=1.3)
    v_line_with_jumpers(R_PROMO, 920, 1503, [1193, 1175], lw=1.3)
    c.line(R_PROMO, 1503, ds_x, 1503, lw=1.3)
    c.head(ds_x, 1503, "right", size=6.5)

    # --- D. PROSES 4.0 (VALIDASI TIKET) ---
    # D4 -> 4.0
    c.line(ds_x, 1193, proc_x + proc_w, 1193, lw=1.3)
    c.head(proc_x + proc_w, 1193, "left", size=6.5)

    # 4.0 -> User
    c.line(proc_x, 1165, ax + aw, 1165, lw=1.3)
    c.line(ax, 1165, L_P4_USER, 1165, lw=1.3)
    c.line(L_P4_USER, 1165, L_P4_USER, 370, lw=1.3)
    c.line(L_P4_USER, 370, ux + uw, 370, lw=1.3)
    c.head(ux + uw, 370, "left", size=6.5)

    # Admin -> 4.0
    c.line(ax + aw, 1205, proc_x, 1205, lw=1.3)
    c.head(proc_x, 1205, "right", size=6.5)

    # 4.0 -> Admin
    c.line(proc_x, 1230, ax + aw, 1230, lw=1.3)
    c.head(ax + aw, 1230, "left", size=6.5)

    # --- E. PROSES 5.0 (PEMBUATAN LAPORAN) ---
    # D3 -> 5.0
    c.line(ds_x, 900, R_REKAP, 900, lw=1.3)
    v_line_with_jumpers(R_REKAP, 900, 1485, [1193, 1175], lw=1.3)
    c.line(R_REKAP, 1485, proc_x + proc_w, 1485, lw=1.3)
    c.head(proc_x + proc_w, 1485, "left", size=6.5)

    # 5.0 -> Admin
    c.line(proc_x, 1510, ax + aw, 1510, lw=1.3)
    c.head(ax + aw, 1510, "left", size=6.5)

    # 5.0 -> Firebase
    c.line(proc_x, 1535, 380, 1535, lw=1.3)
    c.line(380, 1535, 380, 1490, lw=1.3)
    c.line(380, 1490, fx + fw, 1490, lw=1.3)
    c.head(fx + fw, 1490, "left", size=6.5)

    # ==================== 2. GAMBAR SHAPES DI ATAS GARIS ====================
    def draw_compact_process(x, y, w, h, pid, name):
        c.d.rounded_rectangle(
            [c._p(x, y), c._p(x + w, y + h)],
            radius=int(10 * c.S),
            outline=BLACK,
            width=max(1, int(round(1.8 * c.S))),
            fill=WHITE
        )
        sekat_y = y + 28
        c.line(x, sekat_y, x + w, sekat_y, lw=1.3)
        c.text(x + w / 2, y + 14, pid, f_p_id, anchor="mm")
        c.text(x + w / 2, y + 56, name, f_p_title, anchor="mm")

    def draw_compact_datastore(x, y, w, h, ds_id, name):
        c.fill_rect(x, y, w, h, fill=WHITE)
        c.line(x, y, x + w, y, lw=1.4)
        c.line(x, y + h, x + w, y + h, lw=1.4)
        c.line(x, y, x, y + h, lw=1.4)
        c.line(x + 50, y, x + 50, y + h, lw=1.2)
        c.text(x + 25, y + h / 2, ds_id, f_ds_id, anchor="mm")
        c.text(x + 65, y + h / 2, name, f_ds_name, anchor="lm")

    # 4 ENTITAS (ZIG-ZAG)
    c.fill_rect(ux, uy, uw, uh, fill=WHITE)
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 145, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 172, "(Pembeli Tiket)", f_ent_sub, anchor="mm")

    c.fill_rect(px, py, pw, ph, fill=WHITE)
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 65, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 92, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    c.fill_rect(fx, fy, fw, fh, fill=WHITE)
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 140, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 167, "(Auth & FCM)", f_ent_sub, anchor="mm")

    c.fill_rect(ax, ay, aw, ah, fill=WHITE)
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 150, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 177, "(Promotor Konser)", f_ent_sub, anchor="mm")

    # 5 PROSES (RAMPING & BAKU TANPA '&')
    draw_compact_process(proc_x, p1_y, proc_w, proc_h, "1.0", "Pengelolaan Akun")
    draw_compact_process(proc_x, p2_y, proc_w, proc_h, "2.0", "Pengelolaan Event")
    draw_compact_process(proc_x, p3_y, proc_w, proc_h, "3.0", "Transaksi Pemesanan")
    draw_compact_process(proc_x, p4_y, proc_w, proc_h, "4.0", "Validasi Tiket")
    draw_compact_process(proc_x, p5_y, proc_w, proc_h, "5.0", "Pembuatan Laporan")

    # 5 DATA STORE (URUT D1 s/d D5)
    draw_compact_datastore(ds_x, d1_y, ds_w, ds_h, "D1", "users (Data Akun)")
    draw_compact_datastore(ds_x, d2_y, ds_w, ds_h, "D2", "events (Data Event)")
    draw_compact_datastore(ds_x, d3_y, ds_w, ds_h, "D3", "orders (Data Transaksi)")
    draw_compact_datastore(ds_x, d4_y, ds_w, ds_h, "D4", "tickets (Data E-Tiket)")
    draw_compact_datastore(ds_x, d5_y, ds_w, ds_h, "D5", "promos (Data Promo)")

    # ==================== 3. GAMBAR SEMUA LABEL BADGE (RINGKAS & PADAT) ====================
    # Label P1.0
    label_badge((ux + uw + proc_x) / 2, 245, "Data Registrasi")
    label_badge((ux + uw + proc_x) / 2, 280, "Informasi Akun")
    label_badge(950, 295, "Verifikasi Akun", border=True)
    label_badge((proc_x + proc_w + ds_x) / 2, d1_y + ds_h / 2, "Data Akun")

    # Label P2.0
    label_badge(960, 555, "Data Event")
    label_badge((ux + uw + proc_x) / 2, 585, "Katalog Event")
    label_badge((proc_x + proc_w + ds_x) / 2, d2_y + ds_h / 2, "Jadwal Kuota")

    # Label P3.0
    label_badge(900, 840, "Data Tagihan")
    label_badge(900, 925, "Status Bayar")
    label_badge(415, 865, "Data Pesanan")
    label_badge(415, 905, "Detail Tagihan")
    label_badge((proc_x + proc_w + ds_x) / 2, d3_y + ds_h / 2, "Data Transaksi")
    label_badge(1750, 585, "Hold Kuota")
    label_badge(1750, 1175, "Penerbitan Tiket")
    label_badge(1750, 1503, "Data Promo")

    # Label P4.0
    label_badge(1680, 1193, "Data Tiket")
    label_badge(415, 370, "E-Tiket QR")
    label_badge(900, 1205, "Scan Tiket")
    label_badge(900, 1230, "Hasil Validasi")

    # Label P5.0
    label_badge(1660, 1485, "Rekap Penjualan")
    label_badge(900, 1510, "Laporan Penjualan")
    label_badge(580, 1535, "Notifikasi Push")

    # ==================== FOOTER ====================
    fy_line = 1880
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 1 (DFD 1) — Style 1: 3-Column Linear Architecture (Gane & Sarson).", f_foot)
    c.text(60, fy_line + 30, "Standar Akademik Skripsi: Nama proses baku tunggal (tanpa simbol &), box kompak ramping, label data flow padat.", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 9.5), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Gane & Sarson Akademik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_style1_linear_soundwave_compact.png"
    c.save(out_path)
    print("OK Compact Clean DFD rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_compact_clean_dfd()
