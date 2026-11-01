"""
Ganti referensi Patil dkk. (2022) dengan Maftoha & Oktavira (2025).

ALASAN
  DOI Patil dkk. (2022) memang terdaftar di Crossref, tetapi saat diakses
  mengembalikan 404 karena situs penerbitnya (matjournals.co.in) sudah tidak
  aktif. Referensi yang tidak dapat diakses pembaca tidak layak dipertahankan
  dalam daftar pustaka.

PENGGANTI
  Maftoha, B., & Oktavira, R. (2025). Mobile-Based Regional Song Application
  Using the Flutter Framework. Jurnal TAM (Technology Acceptance Model), 15(2).
  https://doi.org/10.56327/jurnaltam.v15i2.1517

  Sudah diverifikasi: DOI resolve 200, PDF tersedia, dan domainnya lebih dekat
  (aplikasi musik berbasis Flutter).

YANG DIUBAH
  1. Daftar pustaka: entri Patil -> Maftoha & Oktavira, urutan alfabet dijaga.
  2. Sitasi dalam teks: "(Lendo dkk., 2023; Patil dkk., 2022)"
     -> "(Lendo dkk., 2023; Maftoha & Oktavira, 2025)"

Jalankan: python docs/generators/ganti_referensi_patil.py
"""

from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

ENTRI_BARU = (
    "Maftoha, B., & Oktavira, R. (2025). Mobile-based regional song application "
    "using the Flutter framework. Jurnal TAM (Technology Acceptance Model), "
    "15(2). https://doi.org/10.56327/jurnaltam.v15i2.1517"
)


def main() -> None:
    doc = Document(str(BERKAS))

    # ---------- 1. ganti entri daftar pustaka DULU ----------
    target = None
    for par in doc.paragraphs:
        if par.text.strip().startswith("Patil, S. G."):
            target = par
            break

    if target is None:
        print("  entri Patil tidak ditemukan — dibatalkan")
        return

    for r in list(target.runs):
        r._element.getparent().remove(r._element)
    r = target.add_run(ENTRI_BARU)
    r.font.name = FONT
    r.font.size = Pt(12)
    print("  entri daftar pustaka diganti")

    # ---------- 2. baru ganti sitasi dalam teks ----------
    n_sitasi = 0
    for par in doc.paragraphs:
        if par.text.strip().startswith("Maftoha, B."):
            continue
        for r in par.runs:
            if "Patil dkk., 2022" in r.text:
                r.text = r.text.replace("Patil dkk., 2022",
                                        "Maftoha & Oktavira, 2025")
                n_sitasi += 1
    print(f"  sitasi dalam teks diganti: {n_sitasi}")

    # ---------- 3. jaga urutan alfabet ----------
    # Maftoha seharusnya berada setelah Lendo dan sebelum Putra Kang.
    paras = doc.paragraphs
    idx_maf = idx_lendo = None
    for i, par in enumerate(paras):
        t = par.text.strip()
        if t.startswith("Maftoha, B."):
            idx_maf = i
        elif t.startswith("Lendo, R."):
            idx_lendo = i

    if idx_maf is not None and idx_lendo is not None and idx_maf < idx_lendo:
        el = paras[idx_maf]._element
        el.getparent().remove(el)
        paras[idx_lendo]._element.addnext(el)
        print("  urutan alfabet diperbaiki (Maftoha setelah Lendo)")

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    print("\nverifikasi:")
    for p in d.paragraphs:
        if "Maftoha" in p.text:
            print(f"  {p.text[:150]}")
    sisa = [p.text[:80] for p in d.paragraphs if "Patil" in p.text]
    print(f"  sisa 'Patil': {sisa if sisa else 'TIDAK ADA'}")


if __name__ == "__main__":
    main()
