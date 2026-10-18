# Generator diagram

Dua gambar di `docs/` dibuat oleh skrip di folder ini, bukan digambar tangan.

| Skrip | Keluaran | Ukuran |
|---|---|---|
| `gen_workflow.py` | `docs/workflow_beli_tiket.png` | 1380 × 1730 |
| `gen_kerangka.py` | `docs/kerangka_sistem.png` | 1600 × 1180 |

## Menjalankan

```bash
pip install pillow
python docs/generators/gen_workflow.py
python docs/generators/gen_kerangka.py
```

Keduanya menulis langsung ke `docs/`, jadi jalankan dari mana saja. Path keluarannya dihitung dari lokasi skrip, bukan dari folder kerja.

## Gaya yang dipakai

`gen_common.py` menyimpan seluruh helper: gambar diskala 2× lalu diperkecil dengan LANCZOS supaya teks tajam, font Consolas untuk label teknis, garis 1,3 px, latar putih penuh, teks hitam. Tidak ada gradien, bayangan, ikon, atau emoji.

Font diambil dari `C:\Windows\Fonts` (`consola.ttf`, `consolab.ttf`, `segoeuib.ttf`), jadi skrip ini berjalan di Windows. Di sistem lain, ganti tiga konstanta font di bagian atas `gen_common.py`.

## Kalau angka di kode berubah

Beberapa angka di gambar diketik manual: jumlah layar, provider, service, koleksi Firestore, jumlah rute backend, versi, dan jumlah test. Setelah menambah layar atau rute, perbarui daftar di skrip lalu jalankan ulang. Kalau tidak, gambar akan berbohong lebih cepat daripada README.
