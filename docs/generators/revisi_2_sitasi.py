"""
TAHAP 2 — Ganti semua penanda sitasi lama dengan 10 referensi final.

Penanda mentah [SITASI: ...] dihapus dan diganti format kurung APA 7th.
Sitasi yang merujuk referensi yang sudah dikeluarkan juga diganti.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

# (teks_lama, teks_baru) — dicocokkan sebagai substring di dalam paragraf
PENGGANTIAN = [
    # ---- Bab I ----
    ("[SITASI: Kusumapratiwi & Waluyo, 2023]", "(Fadhilah dkk., 2025)"),
    ("[SITASI: Biørn-Hansen dkk., 2019]", "(Habibi & Athoillah, 2024)"),
    ("[SITASI: Putra Kang & Fauzi, 2025; Syahputra dkk., 2023]",
     "(Margaretha & Voutama, 2023)"),
    # ---- Bab II ----
    ("[SITASI: Lendo dkk., 2023; Anmi dkk., 2025]",
     "(Lendo dkk., 2023; Anmi dkk., 2025)"),
    ("[SITASI: Hasibuan & Triase, 2022; Fauzi dkk., 2025]", "(Anmi dkk., 2025)"),
    ("[SITASI: Kusumarini & Avito, 2025]",
     "(Kusumarini & Avito, 2025; Nariswari dkk., 2023)"),
    ("[SITASI: Supriyono, 2020]", "(Margaretha & Voutama, 2023)"),
    # ---- Bab IV: Suharsih keluar dari daftar ----
    ("(Suharsih dkk., 2021)", "(Habibi & Athoillah, 2024)"),
    # ---- perbaikan ejaan ----
    ("(Ikhwan et al., 2026)", "(Ikhwan dkk., 2026)"),
]


def main() -> None:
    doc = Document(str(BERKAS))
    total = 0

    for lama, baru in PENGGANTIAN:
        n = 0
        for par in doc.paragraphs:
            if lama not in par.text:
                continue
            # jangan sentuh paragraf berisi field Mendeley
            if "fldChar" in par._element.xml:
                continue
            teks_baru = par.text.replace(lama, baru)
            for r in list(par.runs):
                r._element.getparent().remove(r._element)
            run = par.add_run(teks_baru)
            run.font.name = FONT
            run.font.size = Pt(12)
            n += 1
        total += n
        tanda = "OK " if n else "!! "
        print(f"  {tanda}{lama[:58]:60} -> {n}x")

    doc.save(str(BERKAS))
    print(f"\ntersimpan. paragraf disentuh: {total}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    teks = "\n".join(p.text for p in d.paragraphs)
    print("\n=== VERIFIKASI ===")
    sisa = teks.count("[SITASI:")
    print(f"  sisa penanda [SITASI:]: {sisa}")
    print(f"  'et al.': {teks.count('et al.')}")
    print(f"  'dkk.': {teks.count('dkk.')}")

    print("\n  sitasi yang muncul:")
    import re
    for s in sorted(set(re.findall(r"\(([A-ZÀ-Ý][^()]{2,70}?,\s*\d{4}[a-z]?)\)", teks))):
        print(f"    ({s})")

    print("\n  nama yang seharusnya sudah hilang:")
    for nama in ("Biørn-Hansen", "Supriyono", "Hasibuan", "Kusumapratiwi",
                 "Putra Kang", "Syahputra", "Suharsih"):
        ada = nama in teks
        print(f"    {nama:16} {'!! MASIH ADA' if ada else 'bersih'}")

    print(f"\n  paragraf: {len(d.paragraphs)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")


if __name__ == "__main__":
    main()
