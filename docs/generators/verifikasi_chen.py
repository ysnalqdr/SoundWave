"""Verifikasi geometri ERD Chen: tumpang tindih & atribut nyasar."""
from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from pathlib import Path

BERKAS = Path(__file__).resolve().parents[2] / "ERD_CHEN_SOUNDWAVE.drawio"


def bbox(elemen):
    g = elemen.find(".//mxGeometry")
    if g is None:
        return None
    x = float(g.get("x", 0))
    y = float(g.get("y", 0))
    w = float(g.get("width", 0))
    h = float(g.get("height", 0))
    if w == 0 or h == 0:
        return None
    return (x, y, x + w, y + h)


def tumpang(a, b, toleransi=0.0):
    """True kalau dua kotak bersinggungan/menumpuk."""
    return not (
        a[2] <= b[0] + toleransi
        or b[2] <= a[0] + toleransi
        or a[3] <= b[1] + toleransi
        or b[3] <= a[1] + toleransi
    )


def main() -> None:
    teks = BERKAS.read_text(encoding="utf-8")
    akar = ET.fromstring(teks)          # validasi XML
    print(f"XML sah. ukuran berkas {BERKAS.stat().st_size} byte")

    sel = akar.findall(".//mxCell")
    print(f"total mxCell: {len(sel)}")

    kategori = {"ent_": [], "rel_": [], "at_": []}
    for c in sel:
        cid = c.get("id") or ""
        b = bbox(c)
        if b is None:
            continue
        for pref in kategori:
            if cid.startswith(pref):
                kategori[pref].append((cid, b))

    for k, v in kategori.items():
        print(f"  {k:5} {len(v):2} sel")

    # ---------- 1. entitas tidak boleh tumpang tindih ----------
    ent = kategori["ent_"]
    masalah = 0
    for i in range(len(ent)):
        for j in range(i + 1, len(ent)):
            if tumpang(ent[i][1], ent[j][1]):
                print(f"  !! ENTITAS MENUMPUK: {ent[i][0]} vs {ent[j][0]}")
                masalah += 1

    # ---------- 2. elips tidak boleh menimpa entitas ----------
    for cid_a, ba in kategori["at_"]:
        for cid_e, be in ent:
            if tumpang(ba, be):
                print(f"  !! ELIPS MENIMPA ENTITAS: {cid_a} vs {cid_e}")
                masalah += 1

    # ---------- 3. elips tidak boleh menimpa belah ketupat ----------
    for cid_a, ba in kategori["at_"]:
        for cid_r, br in kategori["rel_"]:
            if tumpang(ba, br):
                print(f"  !! ELIPS MENIMPA RELASI: {cid_a} vs {cid_r}")
                masalah += 1

    # ---------- 4. elips vs elips ----------
    at = kategori["at_"]
    for i in range(len(at)):
        for j in range(i + 1, len(at)):
            if tumpang(at[i][1], at[j][1]):
                print(f"  !! ELIPS BERTUMPUK: {at[i][0]} vs {at[j][0]}")
                masalah += 1

    # ---------- 6. garis tidak boleh menembus simpul lain ----------
    def pusat(b):
        return ((b[0] + b[2]) / 2, (b[1] + b[3]) / 2)

    def lewat(p1, p2, b, margin=3.0):
        n = 80
        for i in range(1, n):
            t = i / n
            px = p1[0] + (p2[0] - p1[0]) * t
            py = p1[1] + (p2[1] - p1[1]) * t
            if (b[0] + margin < px < b[2] - margin
                    and b[1] + margin < py < b[3] - margin):
                return True
        return False

    kotak = {cid: b for k in kategori.values() for cid, b in k}
    for c in akar.findall(".//mxCell"):
        if c.get("edge") != "1":
            continue
        s, t = c.get("source"), c.get("target")
        if s not in kotak or t not in kotak:
            continue
        p1, p2 = pusat(kotak[s]), pusat(kotak[t])
        for cid, b in kotak.items():
            if cid in (s, t):
                continue
            if lewat(p1, p2, b):
                print(f"  !! GARIS {c.get('id')} MENEMBUS {cid}")
                masalah += 1

    # ---------- 7. batas halaman ----------
    semua = [b for _, b in sum(kategori.values(), [])]
    minx = min(b[0] for b in semua)
    miny = min(b[1] for b in semua)
    maxx = max(b[2] for b in semua)
    maxy = max(b[3] for b in semua)
    model = akar.find(".//mxGraphModel")
    pw = float(model.get("pageWidth", 850))
    ph = float(model.get("pageHeight", 1100))
    print(f"\nbatas isi: x {minx:.0f}..{maxx:.0f}  y {miny:.0f}..{maxy:.0f}")
    print(f"kanvas   : {pw:.0f} x {ph:.0f}")
    if minx < 0 or miny < 0:
        print("  !! ADA SEL DI LUAR KANVAS (koordinat negatif)")
        masalah += 1
    if maxx > pw or maxy > ph:
        print(f"  !! ADA SEL MELEBIHI KANVAS (butuh minimal {maxx:.0f} x {maxy:.0f})")
        masalah += 1

    print(f"\n{'BERSIH — 0 masalah' if masalah == 0 else f'{masalah} MASALAH'}")


if __name__ == "__main__":
    main()
