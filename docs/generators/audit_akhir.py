"""AUDIT AKHIR — cek kelengkapan, konsistensi sitasi, dan sisa masalah."""
from __future__ import annotations

import re
from pathlib import Path

from docx import Document

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"


def main() -> None:
    d = Document(str(BERKAS))
    ps = [p.text.strip() for p in d.paragraphs]
    teks = "\n".join(ps)

    print("=== UKURAN DOKUMEN ===")
    print(f"  paragraf : {len(d.paragraphs)}")
    print(f"  tabel    : {len(d.tables)}")
    print(f"  gambar   : {len(d.inline_shapes)}")
    print(f"  kata     : {len(teks.split())}")

    # ---------- struktur bab ----------
    print("\n=== STRUKTUR ===")
    for i, t in enumerate(ps):
        if t.startswith("BAB ") and "\n" in t:
            print(f"  {i:3}  {t.replace(chr(10), ' ')[:50]}")
        elif t in ("DAFTAR PUSTAKA", "KATA PENGANTAR", "DAFTAR ISI"):
            print(f"  {i:3}  {t}")

    # ---------- daftar pustaka ----------
    i_dp = next(i for i, t in enumerate(ps) if t == "DAFTAR PUSTAKA")
    pola = re.compile(r"^[A-ZÀ-Ý][^.]{1,80},\s.*\(\d{4}\)\.")
    pustaka = [t for t in ps[i_dp + 1:] if pola.match(t)]
    print(f"\n=== DAFTAR PUSTAKA: {len(pustaka)} entri ===")
    kunci = []
    for n, e in enumerate(pustaka, 1):
        nama = e.split(",")[0].strip()
        kunci.append(nama)
        print(f"  {n:2}. {nama:14} {e[:62]}")

    # ---------- sitasi di teks ----------
    tubuh = "\n".join(ps[:i_dp])
    print("\n=== SITASI DI TEKS ===")
    sitasi = sorted(set(re.findall(r"\(([A-ZÀ-Ý][^()]{2,80}?,\s*\d{4}[a-z]?)\)", tubuh)))
    for s in sitasi:
        print(f"  ({s})")

    # nama yang disebut naratif: "Nama dkk. (2025)" atau "Nama (2025)"
    naratif = sorted(set(re.findall(r"([A-ZÀ-Ý][A-Za-zÀ-ÿ\-']+)(?: dkk\.| dan [A-Z][A-Za-zÀ-ÿ\-']+)?\s*\(\d{4}\)", tubuh)))
    print("\n  sitasi naratif:")
    for n in naratif:
        print(f"    {n}")

    # ---------- cocokkan ----------
    print("\n=== COCOK: PUSTAKA vs SITASI ===")
    for k in kunci:
        dipakai = k in tubuh
        print(f"  {k:16} {'OK disitasi' if dipakai else '!! TIDAK DISITASI'}")

    # ---------- sisa masalah ----------
    print("\n=== SISA PENANDA ===")
    for p in ("[SITASI:", "[JUMLAH]", "[ISI DENGAN", "[GAMBAR", "[TABEL"):
        n = teks.count(p)
        print(f"  {p:14} {n}")

    print("\n=== CEK BAHASA ===")
    for p in ("et al.", "masa kini", "Temuan ini menunjukkan", "berfungsi sebagai katalog",
              "Kekhasan metode", "Dengan demikian", "Oleh karena itu"):
        print(f"  '{p}': {teks.count(p)}")

    print("\n=== CEK BLOK KODE ===")
    for k in ("void _pasangPengawasPreview", "static const List<StageBalok>",
              "Timer.periodic", "StageBalok(-1.0, 0.0, -0.9"):
        print(f"  {k[:40]:42} {'ADA' if k in teks else '!! HILANG'}")

    # ---------- kalimat tanpa subjek (perkiraan) ----------
    print("\n=== KALIMAT TERLALU PENDEK / FRAGMEN (cek manual) ===")
    for i, t in enumerate(ps[:i_dp]):
        if not t or len(t) < 25 or t.startswith(("Tabel", "Gambar", "Kode", "BAB", "[")):
            continue
        kalimat = re.split(r"(?<=[.?])\s+", t)
        for k in kalimat:
            k = k.strip()
            if 0 < len(k) < 18 and not k.startswith(("1.", "2.", "3.", "4.", "5.")):
                print(f"  [{i}] '{k}'")


if __name__ == "__main__":
    main()
