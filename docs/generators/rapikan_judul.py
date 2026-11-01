"""
Rapikan halaman judul: nama di kiri, NIM di kanan, seperti contoh user.

Sebelumnya:
    1.  Muhammad Yasin Al Qadri
         NIM:17240123

Sesudah:
    1.  Muhammad Yasin Al Qadri              17240123
    2.  [NAMA MAHASISWA 2]                   [NIM]
    ...

Caranya: ganti empat pasang paragraf nama/NIM dengan satu tabel dua kolom
tanpa garis. Kolom kiri rata kiri (nama), kolom kanan rata kanan (NIM).
Tabel dipusatkan di halaman.

Sekaligus memperbaiki salah tulis "INFROMATIKA" -> "INFORMATIKA".

Jalankan: python docs/generators/rapikan_judul.py
"""

from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

NAMA_DOSEN = "[NAMA DOSEN PEMBIMBING]"



def tanpa_garis(t) -> None:
    """Hilangkan seluruh garis tabel."""
    tblPr = t._tbl.tblPr
    b = OxmlElement("w:tblBorders")
    for sisi in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{sisi}")
        el.set(qn("w:val"), "none")
        el.set(qn("w:sz"), "0")
        el.set(qn("w:space"), "0")
        b.append(el)
    tblPr.append(b)


def sel_teks(cell, teks: str, rata) -> None:
    cell.text = ""
    par = cell.paragraphs[0]
    par.alignment = rata
    pf = par.paragraph_format
    pf.space_before = Pt(0)
    pf.space_after = Pt(4)
    pf.line_spacing = 1.15
    r = par.add_run(teks)
    r.font.name = FONT
    r.font.size = Pt(12)


def par_baru(doc, teks: str, tebal: bool = False, ukuran: int = 12,
             setelah: int = 4):
    """Paragraf baru rata tengah untuk halaman judul."""
    par = doc.add_paragraph()
    par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    pf = par.paragraph_format
    pf.space_before = Pt(0)
    pf.space_after = Pt(setelah)
    pf.line_spacing = 1.15
    if teks:
        r = par.add_run(teks)
        r.font.name = FONT
        r.font.size = Pt(ukuran)
        r.bold = tebal
    return par


def main() -> None:
    doc = Document(str(BERKAS))
    paras = doc.paragraphs

    # ---- kumpulkan pasangan nama / NIM ----
    data: list[tuple[str, str]] = []
    idx_nama: list[int] = []

    for i, par in enumerate(paras):
        t = par.text.strip()
        m = re.match(r"^(\d)\.\s*(.*)$", t)
        if not m:
            continue
        nomor, nama = m.group(1), m.group(2).strip()
        nim = ""
        if i + 1 < len(paras):
            t2 = paras[i + 1].text.strip()
            m2 = re.match(r"^NIM\s*:\s*(.*)$", t2)
            if m2:
                nim = m2.group(1).strip()
                idx_nama.append(i)
        data.append((nama, nim))

    if len(data) < 4:
        while len(data) < 4:
            data.append(("", ""))

    print("data terbaca:")
    for n, m in data[:4]:
        print(f"  nama={n!r:34} nim={m!r}")

    # ---- tambah baris Dosen Pembimbing + ruang logo ----
    anchor_disusun = None
    for par in doc.paragraphs:
        if par.text.strip().lower().startswith("disusun oleh"):
            anchor_disusun = par._element
            break

    sudah_ada = any("Dosen Pembimbing" in p.text for p in doc.paragraphs)
    if anchor_disusun is not None and not sudah_ada:
        p1 = par_baru(doc, "Dosen Pembimbing:", setelah=2)
        p2 = par_baru(doc, NAMA_DOSEN, tebal=True, setelah=6)
        p3 = par_baru(doc, "", setelah=0)
        p3.paragraph_format.space_after = Pt(130)   # ruang untuk logo
        anchor_disusun.addprevious(p1._element)
        anchor_disusun.addprevious(p2._element)
        anchor_disusun.addprevious(p3._element)
        print("  baris Dosen Pembimbing + ruang logo ditambahkan")
    elif sudah_ada:
        print("  baris Dosen Pembimbing sudah ada, dilewati")

    # ---- buat tabel ----
    t = doc.add_table(rows=4, cols=2)
    tanpa_garis(t)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False

    for i, (nama, nim) in enumerate(data[:4], start=1):
        sel_teks(t.rows[i - 1].cells[0], f"{i}.  {nama}", WD_ALIGN_PARAGRAPH.LEFT)
        sel_teks(t.rows[i - 1].cells[1], nim, WD_ALIGN_PARAGRAPH.RIGHT)
        t.rows[i - 1].cells[0].width = Cm(7.4)
        t.rows[i - 1].cells[1].width = Cm(3.6)

    # ---- pindahkan tabel ke posisi paragraf nama pertama ----
    anchor = paras[idx_nama[0]]._element
    anchor.addprevious(t._tbl)

    # ---- hapus paragraf nama/NIM lama ----
    for i in idx_nama:
        for offset in (1, 0):          # hapus NIM dulu, lalu nama
            j = i + offset
            if j < len(paras):
                el = paras[j]._element
                if el.getparent() is not None:
                    el.getparent().remove(el)

    # ---- perbaiki salah tulis ----
    perbaikan = {"INFROMATIKA": "INFORMATIKA"}
    for par in doc.paragraphs:
        for r in par.runs:
            for salah, benar in perbaikan.items():
                if salah in r.text:
                    r.text = r.text.replace(salah, benar)
                    print(f"  diperbaiki: {salah} -> {benar}")

    doc.save(str(BERKAS))
    print(f"tersimpan: {BERKAS}")
    print("  nama di kiri, NIM di kanan, tanpa garis")


if __name__ == "__main__":
    main()
