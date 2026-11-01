"""
Ganti referensi Tulus dkk. (2026) dengan Syahputra dkk. (2023).

ALASAN
  Server jurnal.univrab.ac.id menolak SELURUH permintaan otomatis dengan
  HTTP 403 — sudah dicoba 4 jalur berbeda (view, download, http, https) dengan
  beberapa user-agent. PDF-nya tidak dapat diperoleh. Referensi yang tidak bisa
  diakses pembaca tidak layak dipakai.

PENGGANTI
  Syahputra, B., Pratama, J., & Vinson, V. (2023). Designing 3D animation for
  dental health care using MDLC method. Pixel: Jurnal Ilmiah Komputer Grafis,
  16(2), 115-123. https://doi.org/10.51903/pixel.v16i2.1432

  Sudah diverifikasi: PDF terunduh (631 KB, 9 halaman), DOI resolve 200, dan
  topiknya MDLC + animasi 3D — sama seperti Tulus.

YANG DIUBAH
  1. Daftar pustaka: entri Tulus -> Syahputra, urutan alfabet dijaga.
  2. Sitasi dalam teks: "(Putra Kang & Fauzi, 2025; Tulus dkk., 2026)"
     -> "(Putra Kang & Fauzi, 2025; Syahputra dkk., 2023)"

Jalankan: python docs/generators/ganti_referensi_tulus.py
"""

from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

ENTRI_BARU = (
    "Syahputra, B., Pratama, J., & Vinson, V. (2023). Designing 3D animation for "
    "dental health care using MDLC method. Pixel: Jurnal Ilmiah Komputer Grafis, "
    "16(2), 115–123. https://doi.org/10.51903/pixel.v16i2.1432"
)

POLA_ENTRI = re.compile(r"^[A-ZÀ-Ý][^.]{1,60},\s.*\(\d{4}\)\.")


def main() -> None:
    doc = Document(str(BERKAS))

    # ---------- 1. ganti entri daftar pustaka DULU ----------
    target = None
    for par in doc.paragraphs:
        if par.text.strip().startswith("Tulus, A."):
            target = par
            break

    if target is None:
        print("  entri Tulus tidak ditemukan — dibatalkan")
        return

    for r in list(target.runs):
        r._element.getparent().remove(r._element)
    r = target.add_run(ENTRI_BARU)
    r.font.name = FONT
    r.font.size = Pt(12)
    print("  entri daftar pustaka diganti")

    # ---------- 2. ganti sitasi dalam teks ----------
    n = 0
    for par in doc.paragraphs:
        if par.text.strip().startswith("Syahputra, B."):
            continue
        if "fldChar" in par._element.xml:
            continue
        if "Tulus" not in par.text:
            continue
        baru = (par.text.replace("Tulus dkk., 2026", "Syahputra dkk., 2023")
                         .replace("Tulus", "Syahputra"))
        for r in list(par.runs):
            r._element.getparent().remove(r._element)
        r = par.add_run(baru)
        r.font.name = FONT
        r.font.size = Pt(12)
        n += 1
    print(f"  sitasi dalam teks diganti: {n} paragraf")

    # ---------- 3. jaga urutan alfabet ----------
    # Syahputra harus sesudah Supriyono, sebelum Tulus (yang sudah hilang)
    paras = doc.paragraphs
    idx_sy = idx_sup = None
    for i, par in enumerate(paras):
        t = par.text.strip()
        if t.startswith("Syahputra, B."):
            idx_sy = i
        elif t.startswith("Supriyono, H."):
            idx_sup = i

    if idx_sy is not None and idx_sup is not None and idx_sy < idx_sup:
        el = paras[idx_sy]._element
        el.getparent().remove(el)
        paras[idx_sup]._element.addnext(el)
        print("  urutan alfabet diperbaiki (Syahputra sesudah Supriyono)")

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    teks = " ".join(p.text for p in d.paragraphs)
    print("\n=== VERIFIKASI ===")
    print("sisa 'Tulus':", "MASIH ADA" if "Tulus" in teks else "bersih")
    print("'Syahputra' disebut:", teks.count("Syahputra"), "kali")

    paras = [p.text.strip() for p in d.paragraphs]
    i_dp = next(i for i, t in enumerate(paras) if t == "DAFTAR PUSTAKA")
    pustaka = [t for t in paras[i_dp + 1:] if POLA_ENTRI.match(t)]
    print(f"\ndaftar pustaka: {len(pustaka)} entri")
    for n2, p in enumerate(pustaka, 1):
        print(f"  {n2:2}. {p.split(',')[0]:16} {p[:58]}")


if __name__ == "__main__":
    main()
