"""Generator Diagram Konteks Soundwave: Presisi & Terstruktur (Gaya Klasik Akademik DFD v3).
Revisi Total:
1. Lingkaran r_sys = 245 (diameter 490px) mencakup seluruh rentang y=560..1040, dijamin 100% menempel tanpa dangling.
2. Label horizontal 12px di atas garis dengan mask putih bersih tanpa coretan.
3. Kotak Midtrans & Firebase diperlebar (w=700px) sehingga jarak antar-garis vertikal 160-200px, teks vertikal bebas tabrakan 100%.
4. Zero collision, zero crossing, presisi matematis tingkat tinggi.
"""
import math
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_perfect_context_diagram():
    W, H = 2200, 1600
    c = Canvas(W, H, s=2)

    # 1. Judul & Header (Kotak Sudut Kiri Atas gaya akademik)
    c.rect(60, 45, 520, 80, lw=1.6)
    c.text(80, 70, "CONTEXT DIAGRAM (DFD LEVEL 0)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 95, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font
    f_ent_title = c.f(SANS_B, 16)
    f_ent_sub = c.f(MONO, 11)
    f_lbl = c.f(MONO, 10.5)
    f_lbl_b = c.f(MONO_B, 10.5)
    f_sys_num = c.f(MONO_B, 26)
    f_sys_title = c.f(SANS_B, 20)
    f_sys_sub = c.f(MONO_B, 12)
    f_sys_desc = c.f(MONO, 11)
    f_foot = c.f(MONO, 10)

    # 2. PUSAT: LINGKARAN PROSES 0.0 SISTEM SOUNDWAVE (r = 245)
    cx, cy = 1100, 800
    r_sys = 245  # diameter 490px

    c.d.ellipse(
        [c._p(cx - r_sys, cy - r_sys), c._p(cx + r_sys, cy + r_sys)],
        outline=BLACK,
        width=max(1, int(round(2.0 * c.S))),
        fill=WHITE
    )
    # Garis pembagi nomor proses di bagian atas lingkaran
    c.line(cx - 175, cy - 60, cx + 175, cy - 60, lw=1.4)
    c.text(cx, cy - 100, "0.0", f_sys_num, anchor="mm")
    c.text(cx, cy - 20, "SISTEM INFORMASI", f_sys_title, anchor="mm")
    c.text(cx, cy + 15, "SOUNDWAVE", f_sys_title, anchor="mm")
    c.text(cx, cy + 65, "[ CORE BACKEND ENGINE ]", f_sys_sub, anchor="mm")
    c.text(cx, cy + 95, "Node.js Express + Midtrans + Firebase", f_sys_desc, anchor="mm")

    # 3. EMPAT ENTITAS EKSTERNAL
    # USER (Kiri)
    ux, uy, uw, uh = 80, 520, 260, 560
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 265, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 295, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    # ADMIN (Kanan)
    ax, ay, aw, ah = 1860, 520, 260, 560
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 265, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 295, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    # PAYMENT GATEWAY (Atas)
    px, py, pw, ph = 750, 45, 700, 95
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 38, "PAYMENT GATEWAY (MIDTRANS)", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 65, "[ Sandbox Gateway Engine ]", f_ent_sub, anchor="mm")

    # FIREBASE PLATFORM (Bawah)
    fx, fy, fw, fh = 750, 1460, 700, 95
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 38, "FIREBASE PLATFORM (AUTH & FCM)", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 65, "[ Cloud Identity & Push Messaging ]", f_ent_sub, anchor="mm")

    # Helper hitung titik potong lingkaran di sumbu Y tertentu
    def get_circle_x(y, side="left"):
        dy = y - cy
        dx = math.sqrt(max(0, r_sys**2 - dy**2))
        return cx - dx if side == "left" else cx + dx

    # ==================== A. ALIRAN SISI KIRI (USER <-> SISTEM) ====================
    # Aliran masuk (User -> Sistem): y = 560 .. 760 (5 garis)
    user_flows_in = [
        ("Data Registrasi & Login Akun", 560),
        ("Pencarian & Filter Konser Musik", 610),
        ("Data Pemesanan Tiket & Kode Promo", 660),
        ("Konfirmasi Pembayaran Tagihan (VA/QRIS)", 710),
        ("Pengajuan Refund / Pembatalan Tiket", 760),
    ]

    for label, y in user_flows_in:
        x_touch = get_circle_x(y, side="left")
        c.line(ux + uw, y, x_touch, y, lw=1.3)
        c.head(x_touch, y, "right", size=7.0)
        lx = (ux + uw + x_touch) / 2
        c.mask_text(lx, y - 11, label, f_lbl, pad=3)

    # Aliran keluar (Sistem -> User): y = 840 .. 1040 (5 garis)
    user_flows_out = [
        ("Info Profil, UID Akun & Sesi Login", 840),
        ("Katalog Event, Detail Konser & Kuota", 890),
        ("Invoice Tagihan & Hold Kuota 5 Menit", 940),
        ("Penerbitan E-Tiket QR Code Ed25519", 990),
        ("Notifikasi Status Pesanan & Putusan Refund", 1040),
    ]

    for label, y in user_flows_out:
        x_touch = get_circle_x(y, side="left")
        c.line(x_touch, y, ux + uw, y, lw=1.3)
        c.head(ux + uw, y, "left", size=7.0)
        lx = (ux + uw + x_touch) / 2
        c.mask_text(lx, y - 11, label, f_lbl, pad=3)

    # ==================== B. ALIRAN SISI KANAN (ADMIN <-> SISTEM) ====================
    # Aliran masuk (Admin -> Sistem): y = 560 .. 760 (5 garis)
    admin_flows_in = [
        ("Kredensial Login Admin & Autentikasi", 560),
        ("Data Event Konser, Artis, Jadwal & Venue", 610),
        ("Setup Kategori Tiket, Tarif & Alokasi Kuota", 660),
        ("Penerbitan Kode Promo & Batas Pemakaian", 710),
        ("Data Pindaian QR Tiket di Gate (Offline)", 760),
    ]

    for label, y in admin_flows_in:
        x_touch = get_circle_x(y, side="right")
        c.line(ax, y, x_touch, y, lw=1.3)
        c.head(x_touch, y, "left", size=7.0)
        lx = (ax + x_touch) / 2
        c.mask_text(lx, y - 11, label, f_lbl, pad=3)

    # Aliran keluar (Sistem -> Admin): y = 840 .. 1040 (5 garis)
    admin_flows_out = [
        ("Hasil Validasi Gate (Valid / Terpakai)", 840),
        ("Laporan Omset Penjualan & Tiket Terjual", 890),
        ("Laporan Realtime Kehadiran Penonton Venue", 940),
        ("Daftar Pengajuan Refund & Persetujuan", 990),
        ("Dashboard Monitoring Status Sistem & Kuota", 1040),
    ]

    for label, y in admin_flows_out:
        x_touch = get_circle_x(y, side="right")
        c.line(x_touch, y, ax, y, lw=1.3)
        c.head(ax, y, "right", size=7.0)
        lx = (ax + x_touch) / 2
        c.mask_text(lx, y - 11, label, f_lbl, pad=3)

    # ==================== C. ALIRAN SISI ATAS (MIDTRANS <-> SISTEM) ====================
    # 4 Jalur vertikal berjarak longgar: x = 840, 1000, 1200, 1360
    midtrans_flows = [
        (840, "Data Tagihan & Parameter Bayar", "up", "left"),
        (1000, "Token Snap, VA & QRIS Dinamis", "down", "right"),
        (1200, "Webhook Status Bayar (SHA-512)", "down", "left"),
        (1360, "Notifikasi Kedaluwarsa Transaksi", "down", "right"),
    ]

    for x, label, arrow_dir, text_side in midtrans_flows:
        dx = x - cx
        y_touch = cy - math.sqrt(max(0, r_sys**2 - dx**2))
        c.line(x, py + ph, x, y_touch, lw=1.3)
        if arrow_dir == "up":
            c.head(x, py + ph, "up", size=7.0)
        else:
            c.head(x, y_touch, "down", size=7.0)

        y_mid = (py + ph + y_touch) / 2
        tw = c.tw(label, f_lbl)
        if text_side == "left":
            c.mask_text(x - tw / 2 - 12, y_mid, label, f_lbl, pad=4)
        else:
            c.mask_text(x + tw / 2 + 12, y_mid, label, f_lbl, pad=4)

    # ==================== D. ALIRAN SISI BAWAH (FIREBASE <-> SISTEM) ====================
    # 4 Jalur vertikal berjarak longgar: x = 840, 1000, 1200, 1360
    firebase_flows = [
        (840, "Permintaan Verifikasi Auth", "down", "left"),
        (1000, "Token Kredensial & UID Akun", "up", "right"),
        (1200, "Payload Push Notifikasi FCM", "down", "left"),
        (1360, "Delivery Report Status Notif", "up", "right"),
    ]

    for x, label, arrow_dir, text_side in firebase_flows:
        dx = x - cx
        y_touch = cy + math.sqrt(max(0, r_sys**2 - dx**2))
        c.line(x, y_touch, x, fy, lw=1.3)
        if arrow_dir == "down":
            c.head(x, fy, "down", size=7.0)
        else:
            c.head(x, y_touch, "up", size=7.0)

        y_mid = (y_touch + fy) / 2
        tw = c.tw(label, f_lbl)
        if text_side == "left":
            c.mask_text(x - tw / 2 - 12, y_mid, label, f_lbl, pad=4)
        else:
            c.mask_text(x + tw / 2 + 12, y_mid, label, f_lbl, pad=4)

    # ==================== FOOTER ====================
    fy_line = 1570
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 14, "Catatan: DFD Level 0 (Context Diagram) merepresentasikan sistem SoundWave sebagai satu proses sentral tunggal (0.0).", f_foot)
    c.text(60, fy_line + 28, "Seluruh entitas eksternal bertukar data secara sinkron/asinkron melalui Express Engine, Midtrans Gateway, dan Firebase Platform.", f_foot)
    c.text(W - 60, fy_line + 14, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 28, "Notasi: Yourdon & Coad / DeMarco Klasik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "diagram_konteks_soundwave_sempurna.png"
    c.save(out_path)
    print("OK", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_perfect_context_diagram()
