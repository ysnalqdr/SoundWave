"""Generator Diagram Konteks Soundwave: Presisi, Bersih, Sesuai Standar Akademik.
Mengikuti format persis contoh Sistem Perpustakaan:
- 4 Entitas: USER (kiri), ADMIN (kanan), PAYMENT GATEWAY (atas), FIREBASE PLATFORM (bawah).
- Pusat: Lingkaran proses 0.0 SISTEM INFORMASI SOUNDWAVE.
- Aliran data tingkat tinggi (dokumen/data esensial), lapang dan tidak berjejal.
- Garis ortogonal 90 derajat yang rapi, berjarak seragam.
- Label teks di atas garis horizontal / di samping garis vertikal dengan background putih tipis.
- Nol tabrakan, nol garis silang, 100% presisi.
"""
import math
from pathlib import Path
import sys

GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_academic_clean_diagram():
    # Dimensi kanvas ideal
    W, H = 2000, 1500
    c = Canvas(W, H, s=2)

    # 1. Judul di Pojok Kiri Atas (Sesuai Referensi Perpustakaan)
    c.rect(60, 45, 460, 75, lw=1.6)
    c.text(80, 68, "CONTEXT DIAGRAM (DFD LEVEL 0)", c.f(SANS_B, 15), anchor="la")
    c.text(80, 93, "SISTEM INFORMASI SOUNDWAVE", c.f(MONO_B, 12), anchor="la")

    # Font
    f_ent_title = c.f(SANS_B, 16)
    f_ent_sub = c.f(MONO, 11)
    f_lbl = c.f(MONO, 10.5)
    f_sys_num = c.f(MONO_B, 24)
    f_sys_title = c.f(SANS_B, 18)
    f_sys_sub = c.f(MONO_B, 11)
    f_sys_desc = c.f(MONO, 10)
    f_foot = c.f(MONO, 10)

    # 2. PUSAT: LINGKARAN PROSES 0.0 SISTEM SOUNDWAVE
    cx, cy = 1000, 750
    r_sys = 180  # diameter 360px

    c.d.ellipse(
        [c._p(cx - r_sys, cy - r_sys), c._p(cx + r_sys, cy + r_sys)],
        outline=BLACK,
        width=max(1, int(round(2.0 * c.S))),
        fill=WHITE
    )
    # Garis pembagi nomor proses
    c.line(cx - 130, cy - 40, cx + 130, cy - 40, lw=1.4)
    c.text(cx, cy - 75, "0.0", f_sys_num, anchor="mm")
    c.text(cx, cy - 10, "SISTEM INFORMASI", f_sys_title, anchor="mm")
    c.text(cx, cy + 20, "SOUNDWAVE", f_sys_title, anchor="mm")
    c.text(cx, cy + 62, "[ Core Engine ]", f_sys_sub, anchor="mm")
    # FAKTA (diverifikasi dari functions/package.json): sistem berjalan di
    # Firebase Cloud Functions, Node 18, dengan firebase-admin + firebase-functions
    # + midtrans-client. TIDAK ada dependensi Express. Cloudflare Tunnel hanyalah
    # alat bantu pengembangan, bukan bagian arsitektur.
    # KOREKSI (Okt 2026): sistem ini punya DUA backend, bukan satu.
    #   * Express BFF (`server.js`, 23 rute) — repo terpisah, dijalankan di
    #     laptop dan dibuka ke internet lewat Cloudflare Tunnel. Inilah yang
    #     dipanggil aplikasi Flutter lewat HTTP (/create-va, /checkout-atomic,
    #     /poll-payment, ...).
    #   * Firebase Cloud Functions (Node 18) — repo ini: webhook Midtrans,
    #     transaksi stok, refund, sinkronisasi scan gate offline.
    # Label lama hanya menyebut Cloud Functions, sehingga menghapus komponen
    # nyata dari gambar. Keduanya harus muncul.
    c.text(cx, cy + 88, "Express BFF (Cloudflare Tunnel) + Cloud Functions", f_sys_desc, anchor="mm")

    # 3. EMPAT ENTITAS (Kiri, Kanan, Atas, Bawah)
    # A. USER (Kiri)
    ux, uy, uw, uh = 70, 560, 250, 380
    c.rect(ux, uy, uw, uh, lw=1.8)
    c.text(ux + uw / 2, uy + 175, "USER", f_ent_title, anchor="mm")
    c.text(ux + uw / 2, uy + 205, "(Pembeli / Penonton)", f_ent_sub, anchor="mm")

    # B. ADMIN (Kanan)
    ax, ay, aw, ah = 1680, 560, 250, 380
    c.rect(ax, ay, aw, ah, lw=1.8)
    c.text(ax + aw / 2, ay + 175, "ADMIN", f_ent_title, anchor="mm")
    c.text(ax + aw / 2, ay + 205, "(Promotor & Petugas)", f_ent_sub, anchor="mm")

    # C. PAYMENT GATEWAY (Atas)
    px, py, pw, ph = 800, 50, 400, 100
    c.rect(px, py, pw, ph, lw=1.8)
    c.text(px + pw / 2, py + 40, "PAYMENT GATEWAY", f_ent_title, anchor="mm")
    c.text(px + pw / 2, py + 68, "(Midtrans Sandbox)", f_ent_sub, anchor="mm")

    # D. FIREBASE PLATFORM (Bawah)
    fx, fy, fw, fh = 800, 1350, 400, 100
    c.rect(fx, fy, fw, fh, lw=1.8)
    c.text(fx + fw / 2, fy + 40, "FIREBASE PLATFORM", f_ent_title, anchor="mm")
    c.text(fx + fw / 2, fy + 68, "(Auth & FCM Service)", f_ent_sub, anchor="mm")

    # Helper menghitung titik sentuh horizontal lingkaran
    def circle_touch_x(y, side="left"):
        dy = y - cy
        dx = math.sqrt(max(0, r_sys**2 - dy**2))
        return cx - dx if side == "left" else cx + dx

    # ==================== ALIRAN SISI KIRI (USER <-> SISTEM) ====================
    # Aliran Masuk (User -> Sistem): 3 garis di paruh atas (y = 610, 660, 710)
    user_in = [
        ("Data Akun & Kredensial Login", 610),
        ("Data Pemesanan Tiket & Kode Promo", 660),
        ("Data Pembayaran Tagihan (VA/QRIS)", 710),
    ]
    for label, y in user_in:
        x_touch = circle_touch_x(y, side="left")
        c.line(ux + uw, y, x_touch, y, lw=1.3)
        c.head(x_touch, y, "right", size=7.0)
        # Label 10px di atas garis
        lx = (ux + uw + x_touch) / 2
        c.mask_text(lx, y - 10, label, f_lbl, pad=3)

    # Aliran Keluar (Sistem -> User): 3 garis di paruh bawah (y = 790, 840, 890)
    user_out = [
        ("Informasi Katalog Konser & Kuota", 790),
        ("Tagihan Pembayaran & Hold Kuota 5 Mnt", 840),
        ("E-Tiket Digital (QR Code Ed25519)", 890),
    ]
    for label, y in user_out:
        x_touch = circle_touch_x(y, side="left")
        c.line(x_touch, y, ux + uw, y, lw=1.3)
        c.head(ux + uw, y, "left", size=7.0)
        lx = (ux + uw + x_touch) / 2
        c.mask_text(lx, y - 10, label, f_lbl, pad=3)

    # ==================== ALIRAN SISI KANAN (ADMIN <-> SISTEM) ====================
    # Aliran Masuk (Admin -> Sistem): 3 garis di paruh atas (y = 610, 660, 710)
    admin_in = [
        ("Data Event Konser & Setup Tiket", 610),
        ("Data Promo Diskon & Batas Kuota", 660),
        ("Data Scan Tiket Gate (Offline)", 710),
    ]
    for label, y in admin_in:
        x_touch = circle_touch_x(y, side="right")
        c.line(ax, y, x_touch, y, lw=1.3)
        c.head(x_touch, y, "left", size=7.0)
        lx = (ax + x_touch) / 2
        c.mask_text(lx, y - 10, label, f_lbl, pad=3)

    # Aliran Keluar (Sistem -> Admin): 3 garis di paruh bawah (y = 790, 840, 890)
    admin_out = [
        ("Status Validasi Gate (Valid/Invalid)", 790),
        ("Laporan Penjualan & Pendapatan Tiket", 840),
        ("Laporan Kehadiran Penonton di Venue", 890),
    ]
    for label, y in admin_out:
        x_touch = circle_touch_x(y, side="right")
        c.line(x_touch, y, ax, y, lw=1.3)
        c.head(ax, y, "right", size=7.0)
        lx = (ax + x_touch) / 2
        c.mask_text(lx, y - 10, label, f_lbl, pad=3)

    # ==================== ALIRAN SISI ATAS (MIDTRANS <-> SISTEM) ====================
    # 2 Jalur vertikal lapang: x1 = 920 (Up), x2 = 1080 (Down)
    # Jalur 1: Sistem -> Midtrans (x=920)
    x1 = 920
    dx1 = x1 - cx
    y_touch1 = cy - math.sqrt(max(0, r_sys**2 - dx1**2))
    c.line(x1, y_touch1, x1, py + ph, lw=1.3)
    c.head(x1, py + ph, "up", size=7.0)
    c.mask_text(x1 - 105, (py + ph + y_touch1) / 2, "Data Tagihan Pembayaran", f_lbl, pad=3)

    # Jalur 2: Midtrans -> Sistem (x=1080)
    x2 = 1080
    dx2 = x2 - cx
    y_touch2 = cy - math.sqrt(max(0, r_sys**2 - dx2**2))
    c.line(x2, py + ph, x2, y_touch2, lw=1.3)
    c.head(x2, y_touch2, "down", size=7.0)
    y_mid2 = (py + ph + y_touch2) / 2
    c.mask_text(x2 + 130, y_mid2 - 12, "Token Snap, VA & QRIS Dinamis", f_lbl, pad=3)
    c.mask_text(x2 + 130, y_mid2 + 12, "Webhook Status Bayar (SHA-512)", f_lbl, pad=3)

    # ==================== ALIRAN SISI BAWAH (FIREBASE <-> SISTEM) ====================
    # 2 Jalur vertikal lapang: x1 = 920 (Down), x2 = 1080 (Up)
    # Jalur 1: Sistem -> Firebase (x=920)
    y_touch1_b = cy + math.sqrt(max(0, r_sys**2 - dx1**2))
    c.line(x1, y_touch1_b, x1, fy, lw=1.3)
    c.head(x1, fy, "down", size=7.0)
    c.mask_text(x1 - 110, (y_touch1_b + fy) / 2, "Permintaan Verifikasi & FCM", f_lbl, pad=3)

    # Jalur 2: Firebase -> Sistem (x=1080)
    y_touch2_b = cy + math.sqrt(max(0, r_sys**2 - dx2**2))
    c.line(x2, fy, x2, y_touch2_b, lw=1.3)
    c.head(x2, y_touch2_b, "up", size=7.0)
    y_mid2_b = (y_touch2_b + fy) / 2
    c.mask_text(x2 + 120, y_mid2_b - 12, "Token Kredensial & UID Akun", f_lbl, pad=3)
    c.mask_text(x2 + 120, y_mid2_b + 12, "Delivery Report Notifikasi FCM", f_lbl, pad=3)

    # ==================== FOOTER ====================
    fy_line = 1440
    c.line(60, fy_line, W - 60, fy_line, lw=1.2)
    c.text(60, fy_line + 15, "Catatan: DFD Level 0 (Context Diagram) mengisolasi sistem SoundWave sebagai proses tunggal 0.0.", f_foot)
    c.text(60, fy_line + 30, "Dua backend: (1) Express BFF — server.js, 23 rute, lewat Cloudflare Tunnel, melayani transaksi & Midtrans.", f_foot)
    c.text(60, fy_line + 45, "(2) Cloud Functions Node 18 — webhook pembayaran, transaksi stok, refund, dan sinkronisasi scan gate offline.", f_foot)
    c.text(W - 60, fy_line + 15, "SoundWave Architecture v4.0 · Notasi: Yourdon / DeMarco Klasik", f_foot, anchor="ra")

    out_path = Path(__file__).resolve().parents[1] / "diagram_konteks_soundwave_final.png"
    c.save(out_path)
    print("OK", str(out_path), f"({W}x{H})")

if __name__ == '__main__':
    build_academic_clean_diagram()
