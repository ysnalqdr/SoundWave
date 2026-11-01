"""Generator DFD Level 1 Soundwave: Distributed Zig-Zag (Hybrid Left & Right).
Sesuai Permintaan Spesifik:
1. Kolom Tengah: Proses Bisnis 1.0 s/d 5.0 berada di tengah secara vertikal murni.
2. Sisi Kiri (Campuran Zig-Zag Entitas & Data Store):
   - USER [Entitas] (Kiri Luar Atas, x=80)
   - D2: events [Data Store] (Kiri Menjorok Tengah, x=530)
   - PAYMENT GATEWAY [Entitas] (Kiri Luar Tengah, x=80)
   - D5: promos [Data Store] (Kiri Menjorok Bawah, x=530)
   - FIREBASE PLATFORM [Entitas] (Kiri Luar Bawah, x=80)
3. Sisi Kanan (Campuran Zig-Zag Data Store & Entitas):
   - D1: users [Data Store] (Kanan Luar Atas, x=1980)
   - D3: orders [Data Store] (Kanan Menjorok Tengah, x=1560)
   - ADMIN [Entitas] (Kanan Luar Tengah, x=1980)
   - D4: tickets [Data Store] (Kanan Menjorok Bawah, x=1560)
4. Fitur Bebas Simbol '&', Box Kompak (330x85), Label 2 Kata, Bridge Jumper, dan White Badge.
"""
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_distributed_zigzag_dfd():
    W, H = 2500, 1950
    c = Canvas(W, H, s=2)

    # 1. HEADER KIRI ATAS
    c.rect(60, 40, 530, 75, lw=1.6)
    c.text(80, 62, "DATA FLOW DIAGRAM (DFD LEVEL 1)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 86, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font styles
    f_col_header = c.f(SANS_B, 12.5)
    f_ent_title = c.f(SANS_B, 14)
    f_ent_sub = c.f(MONO, 10.5)
    f_p_id = c.f(MONO_B, 13)
    f_p_title = c.f(SANS_B, 13.5)
    f_ds_id = c.f(MONO_B, 12.5)
    f_ds_name = c.f(MONO_B, 11)
    f_lbl = c.f(MONO, 9.5)
    f_foot = c.f(MONO, 9.5)

    # Header Kolom
    c.text(350, 140, "[ SISI KIRI: ENTITAS & DATA STORE ]", f_col_header, anchor="mm")
    c.text(1250, 140, "[ PROSES BISNIS SOUNDWAVE ]", f_col_header, anchor="mm")
    c.text(2150, 140, "[ SISI KANAN: DATA STORE & ENTITAS ]", f_col_header, anchor="mm")

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
    # PROSES (Tengah Murni: Lebar 330, Tinggi 85)
    proc_x = 1085
    proc_w = 330
    proc_h = 85
    p1_y = 220
    p2_y = 530
    p3_y = 840
    p4_y = 1150
    p5_y = 1460

    # SISI KIRI (Campuran Zig-Zag)
    ux, uy, uw, uh = 80, 220, 250, 310    # 1. USER [Entitas] (Kiri Luar Atas)
    d2_x, d2_y, d2_w, d2_h = 510, 550, 380, 48 # 2. D2: events [Data Store] (Kiri Menjorok Tengah)
    px, py, pw, ph = 80, 790, 270, 160   # 3. PAYMENT GATEWAY [Entitas] (Kiri Luar Tengah)
    d5_x, d5_y, d5_w, d5_h = 510, 940, 380, 48 # 4. D5: promos [Data Store] (Kiri Menjorok Bawah)
    fx, fy, fw, fh = 80, 1370, 250, 280  # 5. FIREBASE [Entitas] (Kiri Luar Bawah)

    # SISI KANAN (Campuran Zig-Zag)
    d1_x, d1_y, d1_w, d1_h = 1960, 240, 420, 48 # 1. D1: users [Data Store] (Kanan Luar Atas)
    d3_x, d3_y, d3_w, d3_h = 1550, 835, 380, 48 # 2. D3: orders [Data Store] (Kanan Menjorok Tengah)
    ax, ay, aw, ah = 1960, 1140, 260, 330        # 3. ADMIN [Entitas] (Kanan Luar Tengah)
    d4_x, d4_y, d4_w, d4_h = 1550, 1170, 380, 48 # 4. D4: tickets [Data Store] (Kanan Menjorok Bawah)

    # ==================== 1. GAMBAR GARIS KONEKTOR ====================
    # --- PROSES 1.0 (Pengelolaan Akun) ---
    # User -> 1.0 (Horiz)
    c.line(ux + uw, 245, proc_x, 245, lw=1.3)
    c.head(proc_x, 245, "right", size=6.5)

    # 1.0 -> User (Horiz)
    c.line(proc_x, 280, ux + uw, 280, lw=1.3)
    c.head(ux + uw, 280, "left", size=6.5)

    # Firebase -> 1.0 (Naik via koridor x=410 dengan jumper)
    c.line(fx + fw, 1420, 410, 1420, lw=1.3)
    v_line_with_jumpers(410, 1420, 295, [964, 870, 825, 574], lw=1.3)
    c.line(410, 295, proc_x, 295, lw=1.3)
    c.head(proc_x, 295, "right", size=6.5)

    # 1.0 -> D1: users (Horiz lurus ke kanan)
    c.line(proc_x + proc_w, d1_y + d1_h / 2, d1_x, d1_y + d1_h / 2, lw=1.3)
    c.head(d1_x, d1_y + d1_h / 2, "right", size=6.5)

    # --- PROSES 2.0 (Pengelolaan Event) ---
    # Admin -> 2.0 (Naik dari kanan: Admin y=1170 via koridor x=1860 ke P2.0 y=555)
    c.line(ax, 1170, 1860, 1170, lw=1.3)
    v_line_with_jumpers(1860, 1170, 555, [859], lw=1.3)
    c.line(1860, 555, proc_x + proc_w, 555, lw=1.3)
    c.head(proc_x + proc_w, 555, "left", size=6.5)

    # 2.0 -> User (Horiz ke kiri)
    c.line(proc_x, 545, ux + uw, 545, lw=1.3)
    c.head(ux + uw, 545, "left", size=6.5)

    # 2.0 -> D2: events (Horiz ke D2 di kiri!)
    c.line(proc_x, 574, d2_x + d2_w, 574, lw=1.3)
    c.head(d2_x + d2_w, 574, "left", size=6.5)

    # --- PROSES 3.0 (Transaksi Pemesanan) ---
    # User -> 3.0 (Data Pesanan via koridor x=370)
    c.line(ux + uw, 470, 370, 470, lw=1.3)
    c.line(370, 470, 370, 855, lw=1.3)
    c.line(370, 855, proc_x, 855, lw=1.3)
    c.head(proc_x, 855, "right", size=6.5)

    # 3.0 -> User (Detail Tagihan via koridor x=390)
    c.line(proc_x, 875, 390, 875, lw=1.3)
    c.line(390, 875, 390, 505, lw=1.3)
    c.line(390, 505, ux + uw, 505, lw=1.3)
    c.head(ux + uw, 505, "left", size=6.5)

    # 3.0 -> Payment Gateway (Horiz ke kiri di y=825)
    c.line(proc_x, 825, px + pw, 825, lw=1.3)
    c.head(px + pw, 825, "left", size=6.5)

    # Payment Gateway -> 3.0 (Horiz dari kiri di y=870)
    c.line(px + pw, 870, proc_x, 870, lw=1.3)
    c.head(proc_x, 870, "right", size=6.5)

    # 3.0 -> D2: events (Hold Kuota - naik ke D2 di kiri)
    c.line(proc_x, 895, 950, 895, lw=1.3)
    c.line(950, 895, 950, 585, lw=1.3)
    c.line(950, 585, d2_x + d2_w, 585, lw=1.3)
    c.head(d2_x + d2_w, 585, "left", size=6.5)

    # 3.0 -> D5: promos (Data Promo - turun ke D5 di kiri)
    c.line(proc_x, 915, 970, 915, lw=1.3)
    c.line(970, 915, 970, 964, lw=1.3)
    c.line(970, 964, d5_x + d5_w, 964, lw=1.3)
    c.head(d5_x + d5_w, 964, "left", size=6.5)

    # 3.0 -> D3: orders (Horiz langsung ke D3 di kanan!)
    c.line(proc_x + proc_w, d3_y + d3_h / 2, d3_x, d3_y + d3_h / 2, lw=1.3)
    c.head(d3_x, d3_y + d3_h / 2, "right", size=6.5)

    # 3.0 -> D4: tickets (Penerbitan Tiket - turun ke D4 di kanan)
    c.line(proc_x + proc_w, 895, 1490, 895, lw=1.3)
    c.line(1490, 895, 1490, 1180, lw=1.3)
    c.line(1490, 1180, d4_x, 1180, lw=1.3)
    c.head(d4_x, 1180, "right", size=6.5)

    # --- PROSES 4.0 (Validasi Tiket) ---
    # D4 -> 4.0 (Horiz dari D4 di kanan!)
    c.line(d4_x, 1200, proc_x + proc_w, 1200, lw=1.3)
    c.head(proc_x + proc_w, 1200, "left", size=6.5)

    # Admin -> 4.0 (Scan Tiket dari kanan)
    c.line(ax, 1220, proc_x + proc_w, 1220, lw=1.3)
    c.head(proc_x + proc_w, 1220, "left", size=6.5)

    # 4.0 -> Admin (Hasil Validasi ke kanan)
    c.line(proc_x + proc_w, 1245, ax, 1245, lw=1.3)
    c.head(ax, 1245, "right", size=6.5)

    # 4.0 -> User (E-Tiket QR ke kiri luar via x=340)
    c.line(proc_x, 1165, 340, 1165, lw=1.3)
    c.line(340, 1165, 340, 360, lw=1.3)
    c.line(340, 360, ux + uw, 360, lw=1.3)
    c.head(ux + uw, 360, "left", size=6.5)

    # --- PROSES 5.0 (Pembuatan Laporan) ---
    # D3 -> 5.0 (Rekap Penjualan dari D3 via koridor x=1920)
    c.line(d3_x + d3_w, d3_y + d3_h / 2, 1940, d3_y + d3_h / 2, lw=1.3)
    v_line_with_jumpers(1940, d3_y + d3_h / 2, 1475, [1170, 1200, 1220, 1245], lw=1.3)
    c.line(1940, 1475, proc_x + proc_w, 1475, lw=1.3)
    c.head(proc_x + proc_w, 1475, "left", size=6.5)

    # 5.0 -> Admin (Laporan Penjualan ke Admin di kanan)
    c.line(proc_x + proc_w, 1505, ax, 1505, lw=1.3)
    c.head(ax, 1505, "right", size=6.5)

    # 5.0 -> Firebase (Notifikasi Push ke Firebase di kiri bawah)
    c.line(proc_x, 1520, fx + fw, 1520, lw=1.3)
    c.head(fx + fw, 1520, "left", size=6.5)

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
        c.line(x + 48, y, x + 48, y + h, lw=1.2)
        c.text(x + 24, y + h / 2, ds_id, f_ds_id, anchor="mm")
        c.text(x + 60, y + h / 2, name, f_ds_name, anchor="lm")

    # ENTITAS SISI KIRI
    c.fill_rect(ux, uy, uw, uh, fill=WHITE)
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 140, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 168, "(Pembeli Tiket)", f_ent_sub, anchor="mm")

    c.fill_rect(px, py, pw, ph, fill=WHITE)
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 65, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 92, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    c.fill_rect(fx, fy, fw, fh, fill=WHITE)
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 125, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 152, "(Auth & FCM)", f_ent_sub, anchor="mm")

    # DATA STORE SISI KIRI
    draw_compact_datastore(d2_x, d2_y, d2_w, d2_h, "D2", "events (Data Event)")
    draw_compact_datastore(d5_x, d5_y, d5_w, d5_h, "D5", "promos (Data Promo)")

    # 5 PROSES (KOLOM TENGGAH)
    draw_compact_process(proc_x, p1_y, proc_w, proc_h, "1.0", "Pengelolaan Akun")
    draw_compact_process(proc_x, p2_y, proc_w, proc_h, "2.0", "Pengelolaan Event")
    draw_compact_process(proc_x, p3_y, proc_w, proc_h, "3.0", "Transaksi Pemesanan")
    draw_compact_process(proc_x, p4_y, proc_w, proc_h, "4.0", "Validasi Tiket")
    draw_compact_process(proc_x, p5_y, proc_w, proc_h, "5.0", "Pembuatan Laporan")

    # DATA STORE SISI KANAN
    draw_compact_datastore(d1_x, d1_y, d1_w, d1_h, "D1", "users (Data Akun)")
    draw_compact_datastore(d3_x, d3_y, d3_w, d3_h, "D3", "orders (Data Transaksi)")
    draw_compact_datastore(d4_x, d4_y, d4_w, d4_h, "D4", "tickets (Data E-Tiket)")

    # ENTITAS SISI KANAN
    c.fill_rect(ax, ay, aw, ah, fill=WHITE)
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 150, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 178, "(Promotor Konser)", f_ent_sub, anchor="mm")

    # ==================== 3. GAMBAR SEMUA LABEL BADGE ====================
    # Label P1.0
    label_badge((ux + uw + proc_x) / 2, 245, "Data Registrasi")
    label_badge((ux + uw + proc_x) / 2, 280, "Informasi Akun")
    label_badge(750, 295, "Verifikasi Akun", border=True)
    label_badge((proc_x + proc_w + d1_x) / 2, d1_y + d1_h / 2, "Data Akun")

    # Label P2.0
    label_badge(1650, 555, "Data Event")
    label_badge((ux + uw + proc_x) / 2, 545, "Katalog Event")
    label_badge(990, 574, "Jadwal Kuota")

    # Label P3.0
    label_badge(450, 825, "Data Tagihan")
    label_badge(450, 870, "Status Bayar")
    label_badge(370, 700, "Data Pesanan")
    label_badge(470, 505, "Detail Tagihan")
    label_badge(950, 740, "Hold Kuota")
    label_badge(970, 964, "Data Promo")
    label_badge((proc_x + proc_w + d3_x) / 2, d3_y + d3_h / 2, "Data Transaksi")
    label_badge(1490, 1040, "Penerbitan Tiket")

    # Label P4.0
    label_badge(1490, 1200, "Data Tiket")
    label_badge(415, 360, "E-Tiket QR")
    label_badge(1750, 1220, "Scan Tiket")
    label_badge(1750, 1245, "Hasil Validasi")

    # Label P5.0
    label_badge(1750, 1475, "Rekap Penjualan")
    label_badge(1750, 1505, "Laporan Penjualan")
    label_badge(680, 1520, "Notifikasi Push")

    # ==================== FOOTER ====================
    fy_line = 1880
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Data Flow Diagram Level 1 (DFD 1) — Style Zig-Zag Terdistribusi (Hybrid Left & Right).", f_foot)
    c.text(60, fy_line + 30, "Entitas & Data Store disebar berimbang di kiri & kanan sesuai kedekatan relasi alur proses inti di tengah.", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 9.5), anchor="ra")
    c.text(W - 60, fy_line + 30, "Notasi: Gane & Sarson Akademik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "dfd_style1_distributed_zigzag.png"
    c.save(out_path)
    print("OK Distributed Zig-Zag DFD rendered at:", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_distributed_zigzag_dfd()
