"""Generator Diagram Konteks (DFD Level 0) SoundWave: gaya teknik anti-AI-slop.
Latar putih, teks hitam, garis tajam, label teks di dalam garis (<- Text ->),
rinci dan detail mencakup seluruh aliran data nyata sistem.
"""
from pathlib import Path
import sys

# Tambahkan folder generators ke sys.path agar import gen_common bekerja
GEN_DIR = Path(__file__).resolve().parent
if str(GEN_DIR) not in sys.path:
    sys.path.insert(0, str(GEN_DIR))

from gen_common import Canvas, MONO, MONO_B, SANS_B, BLACK, WHITE

def build_context_diagram():
    # Dimensi kanvas 1x: 1960 x 1440
    W, H = 1960, 1440
    c = Canvas(W, H, s=2)

    # 1. Header
    c.header(
        eyebrow="S O U N D W A V E   /   C O N T E X T   D I A G R A M   ( D F D   L E V E L   0 )",
        title="DIAGRAM KONTEKS SISTEM INFORMASI PENJUALAN TIKET SOUNDWAVE",
        subtitle="Model Aliran Data Tingkat Nol Antara 4 Entitas Eksternal dan Batas Proses Utama Sistem",
        w=W,
        x=72,
        y=45
    )

    # Helper font
    f_title_box = c.f(SANS_B, 16)
    f_sub_box = c.f(MONO, 11)
    f_flow = c.f(MONO, 10.5)
    f_flow_b = c.f(MONO_B, 10.5)
    f_core_id = c.f(MONO_B, 18)
    f_core_title = c.f(SANS_B, 20)
    f_core_sub = c.f(MONO_B, 12)
    f_foot = c.f(MONO, 10)

    # 2. Entitas Eksternal (4 Kotak Persegi)
    # A. USER (Kiri Atas)
    ux, uy, uw, uh = 72, 180, 260, 90
    c.rect(ux, uy, uw, uh, lw=1.6)
    c.badge(ux, uy, "E1", size=24, font=c.f(MONO_B, 11))
    c.text(ux + uw / 2, uy + 32, "USER", f_title_box, anchor="mm")
    c.text(ux + uw / 2, uy + 58, "[ Calon Penonton / Pembeli ]", f_sub_box, anchor="mm")

    # B. ADMIN (Kiri Bawah)
    ax, ay, aw, ah = 72, 880, 260, 90
    c.rect(ax, ay, aw, ah, lw=1.6)
    c.badge(ax, ay, "E2", size=24, font=c.f(MONO_B, 11))
    c.text(ax + aw / 2, ay + 32, "ADMIN", f_title_box, anchor="mm")
    c.text(ax + aw / 2, ay + 58, "[ Promotor & Petugas Gate ]", f_sub_box, anchor="mm")

    # C. PAYMENT GATEWAY (Kanan Atas)
    px, py, pw, ph = 1628, 180, 260, 90
    c.rect(px, py, pw, ph, lw=1.6)
    c.badge(px + pw - 24, py, "E3", size=24, font=c.f(MONO_B, 11))
    c.text(px + pw / 2, py + 32, "PAYMENT GATEWAY", f_title_box, anchor="mm")
    c.text(px + pw / 2, py + 58, "[ Midtrans Sandbox ]", f_sub_box, anchor="mm")

    # D. FIREBASE PLATFORM (Kanan Bawah)
    fx, fy, fw, fh = 1628, 880, 260, 90
    c.rect(fx, fy, fw, fh, lw=1.6)
    c.badge(fx + fw - 24, fy, "E4", size=24, font=c.f(MONO_B, 11))
    c.text(fx + fw / 2, fy + 32, "FIREBASE PLATFORM", f_title_box, anchor="mm")
    c.text(fx + fw / 2, fy + 58, "[ Auth & FCM Push ]", f_sub_box, anchor="mm")

    # 3. Proses Sentral: 0.0 SISTEM INFORMASI SOUNDWAVE
    cx_sys, cy_sys = 980, 680
    r_sys = 175
    # Gambar lingkaran proses
    c.d.ellipse(
        [c._p(cx_sys - r_sys, cy_sys - r_sys), c._p(cx_sys + r_sys, cy_sys + r_sys)],
        outline=BLACK,
        width=max(1, int(round(1.8 * c.S))),
        fill=WHITE
    )
    # Garis pembagi nomor proses
    c.line(cx_sys - 130, cy_sys - 48, cx_sys + 130, cy_sys - 48, lw=1.3)
    c.text(cx_sys, cy_sys - 80, "0.0", f_core_id, anchor="mm")
    c.text(cx_sys, cy_sys - 12, "SISTEM INFORMASI", f_core_title, anchor="mm")
    c.text(cx_sys, cy_sys + 18, "SOUNDWAVE", f_core_title, anchor="mm")
    c.text(cx_sys, cy_sys + 62, "[ CORE ENGINE & BACKEND ]", f_core_sub, anchor="mm")
    c.text(cx_sys, cy_sys + 86, "Node Express + Cloudflare Tunnel", f_sub_box, anchor="mm")

    # Helper untuk menggambar aliran data di dalam garis: <- Label ->
    def draw_data_flow(x_start, x_end, y, label, direction):
        """
        direction: 'right' (->) atau 'left' (<-)
        Menggambar garis, mask teks di tengah dengan format:
        direction=='right' -> [ Label -> ]
        direction=='left'  -> [ <- Label ]
        """
        # Gambar garis penuh dulu
        c.line(x_start, y, x_end, y, lw=1.2)
        # Gambar kepala panah di ujung tujuan
        if direction == "right":
            c.head(x_end, y, "right", size=7.0)
            full_text = f"{label} ──>"
        else:
            c.head(x_start, y, "left", size=7.0)
            full_text = f"<── {label}"

        # Mask teks di tengah garis
        mx = (x_start + x_end) / 2
        c.mask_text(mx, y, full_text, f_flow, pad=8)

    # ==================== ALIRAN DATA SISI KIRI (USER & ADMIN) ====================
    # Titik keluar/masuk:
    # Sisi entitas kiri: x = 332 (tepi kanan kotak User/Admin)
    # Sisi sistem kiri: x = 805 (batas kiri lingkaran)

    # --- KELOMPOK USER (y = 205 .. 565) ---
    flows_user = [
        (205, "1. Kredensial Registrasi & Login (Email / Google)", "right"),
        (245, "2. Token Sesi, UID Akun & Status Verifikasi Profil", "left"),
        (285, "3. Permintaan Pencarian & Filter Katalog Konser Musik", "right"),
        (325, "4. Metadata Event, Jadwal Konser & Daftar Kategori Tiket", "left"),
        (365, "5. Data Pemesanan Tiket (ID Konser, Kategori, Qty, Promo)", "right"),
        (405, "6. Tagihan Pembayaran & Hitung Mundur Hold Kuota 5 Menit", "left"),
        (445, "7. Konfirmasi Pembayaran Tagihan (VA Bank / QRIS Dinamis)", "right"),
        (485, "8. Penerbitan E-Tiket Digital (QR Code Ed25519 Offline)", "left"),
        (525, "9. Permohonan Pembatalan & Refund Tiket Konser", "right"),
        (565, "10. Notifikasi Status Tiket, Pesanan & Putusan Refund", "left"),
    ]

    for y_pos, lbl, direct in flows_user:
        # Garis horizontal dari x=332 ke x=805
        # Untuk baris yang tidak sejajar langsung dengan lingkaran, garis siku ortogonal
        # tapi karena x=332 ke x=805 jaraknya lebar (473 px), kita hubungkan dengan garis bersih
        draw_data_flow(332, 805, y_pos, lbl, direct)

    # --- KELOMPOK ADMIN (y = 755 .. 1115) ---
    flows_admin = [
        (755, "1. Kredensial Login Admin & Autentikasi Pengelola", "right"),
        (795, "2. Otorisasi Akses Dashboard Manajemen & Monitoring", "left"),
        (835, "3. Input Data Event Konser, Artis, Jadwal, Lokasi & Poster", "right"),
        (875, "4. Setup Kategori Tiket, Alokasi Batas Kuota & Tarif Harga", "right"),
        (915, "5. Penerbitan Kode Promo Diskon, Kuota & Batas Berlaku", "right"),
        (955, "6. Data Pindaian QR Tiket di Gate Masuk (Offline Gate Scan)", "right"),
        (995, "7. Hasil Verifikasi Tiket di Pintu Masuk (Valid / Terpakai)", "left"),
        (1035, "8. Keputusan Tinjauan Refund User (Approved / Rejected)", "right"),
        (1075, "9. Laporan Omset Penjualan, Tiket Terjual & Kehadiran Venue", "left"),
        (1115, "10. Status Penahanan Kuota & Log Aktivitas Sistem", "left"),
    ]

    for y_pos, lbl, direct in flows_admin:
        draw_data_flow(332, 805, y_pos, lbl, direct)

    # ==================== ALIRAN DATA SISI KANAN (MIDTRANS & FIREBASE) ====================
    # Titik keluar/masuk:
    # Sisi sistem kanan: x = 1155 (batas kanan lingkaran)
    # Sisi entitas kanan: x = 1628 (tepi kiri kotak Midtrans/Firebase)

    # --- KELOMPOK MIDTRANS (y = 205 .. 445) ---
    flows_midtrans = [
        (225, "1. Request Transaksi (Order ID, Gross Amount, Expire 300s)", "right"),
        (285, "2. Response Token Snap, Nomor Virtual Account & QRIS", "left"),
        (345, "3. Webhook Notifikasi Status Pembayaran (Settlement SHA-512)", "left"),
        (405, "4. Notifikasi Transaksi Kedaluwarsa / Dibatalkan (Expire)", "left"),
    ]

    for y_pos, lbl, direct in flows_midtrans:
        draw_data_flow(1155, 1628, y_pos, lbl, direct)

    # --- KELOMPOK FIREBASE PLATFORM (y = 805 .. 1085) ---
    flows_firebase = [
        (825, "1. Request Verifikasi Autentikasi (Google Auth / Email)", "right"),
        (885, "2. Token Kredensial User, UID & Email Terverifikasi", "left"),
        (945, "3. Registrasi Device Token Pengguna & Payload Notifikasi FCM", "right"),
        (1005, "4. Delivery Status & Laporan Pengiriman Push Notifikasi", "left"),
        (1065, "5. Realtime Stream Pembaruan Status Transaksi & Stok", "left"),
    ]

    for y_pos, lbl, direct in flows_firebase:
        draw_data_flow(1155, 1628, y_pos, lbl, direct)

    # ==================== CATATAN KAKI (FOOTER) ====================
    # Garis pembatas footer
    fy_line = 1200
    c.line(72, fy_line, W - 72, fy_line, lw=1.4)

    c.text(72, fy_line + 16, "CATATAN TEKNIK SISTEM SOUNDWAVE (DFD LEVEL 0 / CONTEXT DIAGRAM):", c.f(MONO_B, 11))
    notes = [
        "1. ENTITAS EKSTERNAL: User (pembeli), Admin (promotor acara), Payment Gateway (Midtrans), dan Firebase Platform (Auth & FCM).",
        "2. RESERVASI ATOMIK 5 MENIT: Transaksi checkout mengunci kuota tiket selama 300 detik. Webhook Midtrans dengan signature SHA-512 memicu status AKTIF.",
        "3. OFFLINE GATE SCANNER: Kode QR e-tiket memuat tanda tangan kriptografi Ed25519 (Key ID v3), diverifikasi mandiri di venue tanpa internet.",
        "4. SINGLE SOURCE OF TRUTH: Seluruh aturan harga, batas kuota, dan validasi status pesanan diputuskan di server backend, bukan di aplikasi mobile.",
    ]
    for idx, note in enumerate(notes):
        c.text(72, fy_line + 38 + idx * 20, note, f_foot)

    # Metadata & Version di kanan bawah
    c.text(W - 72, fy_line + 16, "SoundWave Engineering Model", c.f(MONO_B, 11), anchor="ra")
    c.text(W - 72, fy_line + 38, "Versi Arsitektur : 2.4.7+31 (Production Grade)", f_foot, anchor="ra")
    c.text(W - 72, fy_line + 58, "Format Notasi   : Yourdon & Coad / Gane-Sarson", f_foot, anchor="ra")
    c.text(W - 72, fy_line + 78, "Generator Script: docs/generators/gen_context_diagram.py", f_foot, anchor="ra")
    c.text(W - 72, fy_line + 98, "Output Target   : docs/diagram_konteks_soundwave.png", f_foot, anchor="ra")

    # Simpan
    out_path = Path(__file__).resolve().parents[1] / "diagram_konteks_soundwave.png"
    c.save(out_path)
    print("OK", str(out_path), f"({W}x{H})")

if __name__ == "__main__":
    build_context_diagram()
