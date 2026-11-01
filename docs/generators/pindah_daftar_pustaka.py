"""
Pindahkan DAFTAR PUSTAKA dari antara Bab II dan Bab III ke akhir dokumen.

MASALAH
  Blok daftar pustaka berada di paragraf 103, yaitu sesudah Bab II dan sebelum
  Bab III. Akibatnya Bab III, IV, dan V muncul setelah daftar pustaka — urutan
  yang salah untuk sebuah makalah.

PENYEBAB
  Skrip Bab III-V dulu menyisipkan bab baru tepat sesudah blok daftar pustaka
  yang sudah ada, bukan sesudah Bab II. Daftar pustaka pun tertinggal di tengah.

PERBAIKAN
  Ambil seluruh elemen blok daftar pustaka (judul + 13 entri), lalu pindahkan
  ke akhir dokumen. Tidak ada isi yang dihapus.

Jalankan: python docs/generators/pindah_daftar_pustaka.py
"""

from __future__ import annotations

import re
from pathlib import Path

from docx import Document

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"

POLA_ENTRI = re.compile(r"^[A-ZÀ-Ý][^.]{1,60},\s.*\(\d{4}\)\.")


def main() -> None:
    doc = Document(str(BERKAS))
    paras = doc.paragraphs

    # ---------- 1. temukan judul DAFTAR PUSTAKA yang berdiri sendiri ----------
    idx_judul = None
    for i, par in enumerate(paras):
        if par.text.strip() == "DAFTAR PUSTAKA":
            idx_judul = i
            break

    if idx_judul is None:
        raise SystemExit("Judul DAFTAR PUSTAKA tidak ditemukan")

    # ---------- 2. kumpulkan elemen blok (judul + entri + paragraf kosong) ----------
    blok = []
    for par in paras[idx_judul:]:
        t = par.text.strip()
        if t == "DAFTAR PUSTAKA" or POLA_ENTRI.match(t) or t == "":
            blok.append(par._element)
        else:
            break      # berhenti di paragraf pertama yang bukan bagian blok

    if not blok:
        raise SystemExit("Blok daftar pustaka kosong")

    print(f"  elemen blok ditemukan: {len(blok)}")
    print(f"  entri pustaka        : {sum(1 for e in blok if POLA_ENTRI.match(e.text.strip() if hasattr(e,'text') else ''))}")

    # ---------- 3. lepaskan dari posisi lama ----------
    induk = blok[0].getparent()
    for el in blok:
        induk.remove(el)

    # ---------- 4. tempel di akhir dokumen ----------
    body = doc.element.body
    # sisipkan sebelum elemen sectPr (kalau ada), supaya tidak merusak layout
    sect = body.find(
        "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}sectPr")
    for el in blok:
        if sect is not None:
            sect.addprevious(el)
        else:
            body.append(el)

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    print("\n=== VERIFIKASI URUTAN ===")
    for i, p in enumerate(d.paragraphs):
        t = p.text.strip()
        if "DAFTAR PUSTAKA" in t or (t.startswith("BAB ") and len(t) < 40):
            print(f"  par {i:3}: {t[:50]!r}")
    print(f"\n  total paragraf: {len(d.paragraphs)}")


if __name__ == "__main__":
    main()
