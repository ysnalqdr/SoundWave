"""
Perbarui nomor halaman Daftar Isi setelah Tabel 3.1-3.4 diubah jadi narasi.

Nomor diambil dari pengukuran Word. Halaman tercetak = halaman fisik - 4,
karena ada empat halaman berangka romawi (i sampul, ii kata pengantar,
iii-iv daftar isi).

Hanya nomor halaman yang diubah. Teks entri, indentasi, dan tab-stop
dibiarkan apa adanya.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"

# kunci entri -> nomor halaman tercetak
HALAMAN = {
    "HALAMAN JUDUL": "i",
    "KATA PENGANTAR": "ii",
    "DAFTAR ISI": "iii",
    "BAB I": "1",
    "1.1": "1",
    "1.2": "3",
    "1.3": "3",
    "1.4": "4",
    "1.4.1": "4",
    "1.4.2": "4",
    "BAB II": "5",
    "2.1": "5",
    "2.2": "6",
    "2.2.1": "6",
    "2.2.2": "6",
    "2.2.3": "7",
    "2.2.4": "7",
    "2.2.5": "7",
    "2.2.6": "8",
    "2.3": "8",
    "2.3.1": "8",
    "2.3.2": "8",
    "BAB III": "10",
    "3.1": "10",
    "3.1.1": "10",
    "3.1.2": "11",
    "3.1.3": "12",
    "3.2": "12",
    "3.3": "15",
    "BAB IV": "17",
    "4.1": "17",
    "4.1.1": "17",
    "4.1.2": "17",
    "4.1.3": "18",
    "4.1.4": "18",
    "4.1.5": "19",
    "4.2": "19",
    "4.3": "36",
    "4.4": "37",
    "BAB V": "39",
    "5.1": "39",
    "5.2": "39",
    "DAFTAR PUSTAKA": "40",
}


def kunci(teks: str) -> str | None:
    bagian = teks.split("\t")[0].strip()
    if bagian.startswith("BAB"):
        p = bagian.split()
        return f"{p[0]} {p[1]}" if len(p) > 1 else p[0]
    for awalan in ("DAFTAR PUSTAKA", "HALAMAN JUDUL", "KATA PENGANTAR", "DAFTAR ISI"):
        if bagian.startswith(awalan):
            return awalan
    return bagian.split()[0] if bagian else None


def main() -> None:
    doc = Document(str(BERKAS))
    ps = doc.paragraphs
    i_judul = next(i for i, p in enumerate(ps) if p.text.strip() == "DAFTAR ISI")

    n = 0
    for p in ps[i_judul + 1:]:
        if "\t" not in p.text:
            break
        k = kunci(p.text)
        if k not in HALAMAN:
            print(f"  !! kunci tak dikenal: {k!r}")
            continue
        label = p.text.split("\t")[0]
        lama = p.text.split("\t")[-1]
        baru = HALAMAN[k]

        if lama == baru:
            continue

        for r in list(p.runs):
            r._element.getparent().remove(r._element)
        run = p.add_run(f"{label}\t{baru}")
        run.font.name = "Times New Roman"
        run.font.size = Pt(12)
        run.font.bold = label.startswith("BAB") or label in (
            "DAFTAR PUSTAKA", "HALAMAN JUDUL", "KATA PENGANTAR", "DAFTAR ISI")
        n += 1

    doc.save(str(BERKAS))
    print(f"entri diperbarui: {n}")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    ps2 = d.paragraphs
    j = next(i for i, p in enumerate(ps2) if p.text.strip() == "DAFTAR ISI")
    print("\n=== DAFTAR ISI ===")
    c = 0
    for p in ps2[j + 1:]:
        if "\t" not in p.text:
            break
        print(f"  {p.text}")
        c += 1
    print(f"\n  entri: {c}  paragraf: {len(ps2)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")


if __name__ == "__main__":
    main()
