"""Perbaiki urutan entri Daftar Isi yang terbalik (bug insert_paragraph_before).

Isi dan format tiap entri sudah benar, hanya urutan elemen XML-nya terbalik
untuk entri ke-13 dan seterusnya. Skrip ini menyusun ulang elemen sesuai
urutan yang seharusnya, tanpa menyentuh teks maupun formatnya.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"

URUTAN = [
    "HALAMAN JUDUL", "KATA PENGANTAR", "DAFTAR ISI",
    "BAB I", "1.1", "1.2", "1.3", "1.4", "1.4.1", "1.4.2",
    "BAB II", "2.1", "2.2", "2.2.1", "2.2.2", "2.2.3", "2.2.4", "2.2.5", "2.2.6",
    "2.3", "2.3.1", "2.3.2",
    "BAB III", "3.1", "3.1.1", "3.1.2", "3.1.3", "3.2", "3.3",
    "BAB IV", "4.1", "4.1.1", "4.1.2", "4.1.3", "4.1.4", "4.1.5", "4.2", "4.3", "4.4",
    "BAB V", "5.1", "5.2",
    "DAFTAR PUSTAKA",
]


def kunci(teks: str) -> str | None:
    """Ambil kunci pengenal dari teks entri."""
    bagian = teks.split("\t")[0].strip()
    if bagian.startswith("BAB"):
        return bagian.split()[0] + " " + bagian.split()[1]
    if bagian.startswith("DAFTAR PUSTAKA"):
        return "DAFTAR PUSTAKA"
    if bagian.startswith("HALAMAN JUDUL"):
        return "HALAMAN JUDUL"
    if bagian.startswith("KATA PENGANTAR"):
        return "KATA PENGANTAR"
    if bagian.startswith("DAFTAR ISI"):
        return "DAFTAR ISI"
    token = bagian.split()[0]
    return token


def main() -> None:
    doc = Document(str(BERKAS))
    ps = doc.paragraphs
    i_judul = next(i for i, p in enumerate(ps) if p.text.strip() == "DAFTAR ISI")

    # kumpulkan entri (paragraf setelah judul yang punya tab)
    entri = []
    j = i_judul + 1
    while j < len(ps) and "\t" in ps[j].text:
        entri.append(ps[j])
        j += 1
    print(f"entri terkumpul: {len(entri)}")
    if len(entri) != len(URUTAN):
        print(f"!! jumlah tidak cocok (butuh {len(URUTAN)})")
        return

    # penanda: paragraf kosong sesudah blok
    penanda = ps[j]._element

    # peta kunci -> elemen
    peta = {}
    for p in entri:
        k = kunci(p.text)
        if k in peta:
            print(f"!! kunci ganda: {k}")
        peta[k] = p._element

    hilang = [u for u in URUTAN if u not in peta]
    if hilang:
        print("!! kunci tidak ditemukan:", hilang)
        return

    # lepas semua lalu sisipkan ulang sesuai urutan
    for el in peta.values():
        el.getparent().remove(el)
    for u in URUTAN:
        penanda.addprevious(peta[u])

    doc.save(str(BERKAS))
    print("urutan diperbaiki")

    # ---------- verifikasi ----------
    d = Document(str(BERKAS))
    ps2 = d.paragraphs
    i2 = next(i for i, p in enumerate(ps2) if p.text.strip() == "DAFTAR ISI")
    print("\n=== DAFTAR ISI ===")
    n = 0
    k = i2 + 1
    while k < len(ps2) and "\t" in ps2[k].text:
        print(f"  {ps2[k].text}")
        n += 1
        k += 1
    print(f"\n  entri: {n}")
    print(f"  paragraf: {len(ps2)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")


if __name__ == "__main__":
    main()
