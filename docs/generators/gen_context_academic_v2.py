"""Generator Diagram Konteks Soundwave: Presisi & Terstruktur (Gaya Klasik Akademik DFD v2).
Mengikuti referensi resmi:
- Lingkaran Proses 0 di tengah.
- 4 Entitas: USER (kiri), ADMIN (kanan), PAYMENT GATEWAY (atas), FIREBASE (bawah).
- Garis horizontal sejajar & siku 90 derajat yang presisi MENEMPEL pada keliling lingkaran.
- Teks label berada 6px DI ATAS garis horizontal (tanpa strikethrough) dengan padding putih bersih.
- Teks vertikal tidak menabrak garis, spacing konstan.
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

    # 1. Judul & Header (Kotak Sudut Kiri Atas seperti referensi)
    c.rect(60, 50, 480, 75, lw=1.6)
    c.text(80, 72, "CONTEXT DIAGRAM (DFD LEVEL 0)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 97, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font
    f_ent_title = c.f(SANS_B, 16)
    f_ent_sub = c.f(MONO, 11)
    f_lbl = c.f(MONO, 10.5)
    f_lbl_b = c.f(MONO_B, 10.5)
    f_sys_num = c.f(MONO_B, 22)
    f_sys_title = c.f(SANS_B, 18)
    f_sys_sub = c.f(MONO, 11)
    f_foot = c.f(MONO, 10)

    # 2. PUSAT: LINGKARAN PROSES 0.0 SISTEM SOUNDWAVE
    cx, cy = 1100, 800
    r_sys = 160  # radius 160px (diameter 320px)

    c.d.ellipse(
        [c._p(cx - r_sys, cy - r_sys), c._p(cx + r_sys, cy + r_sys)],
        outline=BLACK,
        width=max(1, int(round(2.0 * c.S))),
        fill=WHITE
    )
    # Garis pembagi nomor proses
    c.line(cx - 120, cy - 35, cx + 120, cy - 35, lw=1.4)
    c.text(cx, cy - 65, "0.0", f_sys_num, anchor="mm")
    c.text(cx, cy - 5, "SISTEM INFORMASI", f_sys_title, anchor="mm")
    c.text(cx, cy + 25, "SOUNDWAVE", f_sys_title, anchor="mm")
    c.text(cx, cy + 65, "[ Core Engine ]", f_sys_sub, anchor="mm")

    # 3. EMPAT ENTITAS EKSTERNAL
    # USER (Kiri)
    ux, uy, uw, uh = 80, 520, 240, 560
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 265, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 295, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    # ADMIN (Kanan)
    ax, ay, aw, ah = 1880, 520, 240, 560
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 265, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 295, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    # PAYMENT GATEWAY (Atas)
    px, py, pw, ph = 920, 60, 360, 110
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 45, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 72, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    # FIREBASE PLATFORM (Bawah)
    fx, fy, fw, fh = 920, 1430, 360, 110
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 45, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 72, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # Helper fungsi hitung titik potong horizontal dengan lingkaran proses
    def get_circle_x(y, side="left"):
        dy = y - cy
        if abs(dy) >= r_sys:
            return cx - r_sys if side == "left" else cx + r_sys
        dx = math.sqrt(r_sys**2 - dy**2)
        return cx - dx if side == "left" else cx + dx

    # ==================== A. ALIRAN SISI KIRI (USER <-> SISTEM) ====================
    # Aliran masuk (User -> Sistem) di paruh atas (y = 560 .. 760)
    user_flows_in = [
        ("Data Registrasi & Login Akun", 560),
        ("Pencarian & Filter Konser Musik", 610),
        ("Data Pemesanan Tiket & Kode Promo", 660),
        ("Konfirmasi Pembayaran Tagihan (VA/QRIS)", 710),
        ("Pengajuan Refund / Pembatalan Tiket", 760),
    ]

    for label, y in user_flows_in:
        x_touch = get_circle_x(y, side="left")
        # Garis lurus horizontal dari tepi kotak User (x=320) ke keliling lingkaran (x_touch)
        c.line(ux + uw, y, x_touch, y, lw=1.3)
        c.head(x_touch, y, "right", size=7.0)
        # Teks label diletakkan 6px DI ATAS garis horizontal dengan mask tipis
        lx = (ux + uw + x_touch) / 2
        c.mask_text(lx, y - 10, label, f_lbl, pad=4)

    # Aliran keluar (Sistem -> User) di paruh bawah (y = 840 .. 1040)
    user_flows_out = [
        ("Info Profil, UID Akun & Sesi Login", 840),
        ("Katalog Event, Detail Konser & Kuota", 890),
        ("Invoice Tagihan & Hold Kuota 5 Menit", 940),
        ("Penerbitan E-Tiket QR Code Ed25519", 990),
        ("Notifikasi Status Pesanan & Putusan Refund", 1040),
    ]

    for label, y in user_flows_out:
        x_touch = get_circle_x(y, side="left")
        # Garis lurus horizontal dari keliling lingkaran (x_touch) ke tepi kotak User (x=320)
        c.line(x_touch, y, ux + uw, y, lw=1.3)
        c.head(ux + uw, y, "left", size=7.0)
        lx = (ux + uw + x_touch) / 2
        c.mask_text(lx, y - 10, label, f_lbl, pad=4)

    # ==================== B. ALIRAN SISI KANAN (ADMIN <-> SISTEM) ====================
    # Aliran masuk (Admin -> Sistem) di paruh atas (y = 560 .. 760)
    admin_flows_in = [
        ("Kredensial Login Admin & Autentikasi", 560),
        ("Data Event Konser, Artis, Jadwal & Venue", 610),
        ("Setup Kategori Tiket, Tarif & Alokasi Kuota", 660),
        ("Penerbitan Kode Promo & Batas Pemakaian", 710),
        ("Data Pindaian QR Tiket di Gate (Offline)", 760),
    ]

    for label, y in admin_flows_in:
        x_touch = get_circle_x(y, side="right")
        # Garis horizontal dari Admin (ax=1880) ke lingkaran (x_touch)
        c.line(ax, y, x_touch, y, lw=1.3)
        c.head(x_touch, y, "left", size=7.0)
        lx = (ax + x_touch) / 2
        c.mask_text(lx, y - 10, label, f_lbl, pad=4)

    # Aliran keluar (Sistem -> Admin) di paruh bawah (y = 840 .. 1040)
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
        c.mask_text(lx, y - 10, label, f_lbl, pad=4)

    # ==================== C. ALIRAN SISI ATAS (MIDTRANS <-> SISTEM) ====================
    # Jalur vertikal antara kotak Midtrans (py+ph=170) dan keliling atas lingkaran (cy-r_sys=640)
    # Jarak vertikal: 470px. Luas sekali!
    # 4 Jalur vertikal terdistribusi rapi di x = 980, 1060, 1140, 1220:
    midtrans_flows = [
        (980, "Sistem -> Midtrans", "Data Tagihan & Parameter Bayar", "up", "left"),
        (1060, "Midtrans -> Sistem", "Token Snap, Nomor VA & QRIS Dinamis", "down", "left"),
        (1140, "Midtrans -> Sistem", "Webhook Status Bayar (SHA-512)", "down", "right"),
        (1220, "Midtrans -> Sistem", "Notifikasi Transaksi Kedaluwarsa", "down", "right"),
    ]

    for x, direction_str, label, arrow_dir, text_side in midtrans_flows:
        # Hitung titik potong lingkaran di atas:
        dx = x - cx
        y_touch = cy - math.sqrt(r_sys**2 - dx**2)
        c.line(x, py + ph, x, y_touch, lw=1.3)
        if arrow_dir == "up":
            c.head(x, py + ph, "up", size=7.0)
        else:
            c.head(x, y_touch, "down", size=7.0)

        # Label vertikal ditulis bersih dengan rotasi 90 derajat atau dipisah rapi
        # Agar mudah dibaca manusia tanpa miringkan kepala:
        # Pecah label menjadi 2 baris pendek dan letakkan di tengah jalur vertikal
        y_mid = (py + ph + y_touch) / 2
        words = label.split(" ")
        if len(words) > 3:
            line1 = " ".join(words[:len(words)//2])
            line2 = " ".join(words[len(words)//2:])
        else:
            line1 = label
            line2 = ""

        if text_side == "left":
            c.mask_text(x - 90, y_mid - 8, line1, f_lbl, pad=2)
            if line2:
                c.mask_text(x - 90, y_mid + 8, line2, f_lbl, pad=2)
        else:
            c.mask_text(x + 90, y_mid - 8, line1, f_lbl, pad=2)
            if line2:
                c.mask_text(x + 90, y_mid + 8, line2, f_lbl, pad=2)

    # ==================== D. ALIRAN SISI BAWAH (FIREBASE <-> SISTEM) ====================
    # Jalur vertikal antara keliling bawah lingkaran (cy+r_sys=960) dan kotak Firebase (fy=1430)
    # Jarak vertikal: 470px.
    # 4 Jalur vertikal di x = 980, 1060, 1140, 1220:
    firebase_flows = [
        (980, "Sistem -> Firebase", "Request Verifikasi Autentikasi", "down", "left"),
        (1060, "Firebase -> Sistem", "Token Kredensial & UID Akun", "up", "left"),
        (1140, "Sistem -> Firebase", "Payload Push Notifikasi FCM", "down", "right"),
        (1220, "Firebase -> Sistem", "Delivery Report & Event Stream", "up", "right"),
    ]

    for x, direction_str, label, arrow_dir, text_side in firebase_flows:
        dx = x - cx
        y_touch = cy + math.sqrt(r_sys**2 - dx**2)
        c.line(x, y_touch, x, fy, lw=1.3)
        if arrow_dir == "down":
            c.head(x, fy, "down", size=7.0)
        else:
            c.head(x, y_touch, "up", size=7.0)

        y_mid = (y_touch + fy) / 2
        words = label.split(" ")
        if len(words) > 3:
            line1 = " ".join(words[:len(words)//2])
            line2 = " ".join(words[len(words)//2:])
        else:
            line1 = label
            line2 = ""

        if text_side == "left":
            c.mask_text(x - 90, y_mid - 8, line1, f_lbl, pad=2)
            if line2:
                c.mask_text(x - 90, y_mid + 8, line2, f_lbl, pad=2)
        else:
            c.mask_text(x + 90, y_mid - 8, line1, f_lbl, pad=2)
            if line2:
                c.mask_text(x + 90, y_mid + 8, line2, f_lbl, pad=2)

    # ==================== FOOTER ====================
    fy_line = 1530
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Catatan: DFD Level 0 (Context Diagram) mengisolasi sistem SoundWave sebagai satu proses utuh (0.0).", f_foot)
    c.text(60, fy_line + 32, "Seluruh pertukaran data berlangsung secara sinkron/asinkron melalui REST API backend dan webhook.", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Engineering Standard v2.4.7", c.f(MONO_B, 10), anchor="ra")
    c.text(W - 60, fy_line + 32, "Notasi: Yourdon / DeMarco Klasik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "diagram_konteks_soundwave_presisi.png"
    c.save(out_path)
    print("OK", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_perfect_context_diagram()
