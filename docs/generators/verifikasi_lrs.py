"""Verifikasi LRS: kotak, panah, dan jalur ortogonal yang benar-benar dipakai."""
from __future__ import annotations

import xml.etree.ElementTree as ET
from pathlib import Path

BERKAS = Path(__file__).resolve().parents[2] / "LRS_SOUNDWAVE.drawio"


def bbox(e):
    g = e.find(".//mxGeometry")
    if g is None:
        return None
    x, y = float(g.get("x", 0)), float(g.get("y", 0))
    w, h = float(g.get("width", 0)), float(g.get("height", 0))
    return None if (w == 0 or h == 0) else (x, y, x + w, y + h)


def tumpang(a, b):
    return not (a[2] <= b[0] or b[2] <= a[0] or a[3] <= b[1] or b[3] <= a[1])


def ambil_style(style: str) -> dict:
    d = {}
    for bagian in (style or "").split(";"):
        if "=" in bagian:
            k, v = bagian.split("=", 1)
            d[k] = v
    return d


def titik_tepi(b, fx, fy):
    return (b[0] + (b[2] - b[0]) * fx, b[1] + (b[3] - b[1]) * fy)


def segmen_tembus(p1, p2, b, margin=4.0):
    n = 90
    for i in range(1, n):
        t = i / n
        px = p1[0] + (p2[0] - p1[0]) * t
        py = p1[1] + (p2[1] - p1[1]) * t
        if b[0] + margin < px < b[2] - margin and b[1] + margin < py < b[3] - margin:
            return True
    return False


def main() -> None:
    akar = ET.fromstring(BERKAS.read_text(encoding="utf-8"))
    print(f"XML sah — {BERKAS.stat().st_size} byte")

    sel = akar.findall(".//mxCell")
    kotak = {}
    for c in sel:
        cid = c.get("id") or ""
        if cid.startswith("tbl_"):
            b = bbox(c)
            if b:
                kotak[cid] = b
    panah = [c for c in sel if c.get("edge") == "1"]

    print(f"kotak tabel : {len(kotak)}")
    print(f"panah       : {len(panah)}")

    masalah = 0
    ids = list(kotak)
    for i in range(len(ids)):
        for j in range(i + 1, len(ids)):
            if tumpang(kotak[ids[i]], kotak[ids[j]]):
                print(f"  !! KOTAK BERTUMPUK: {ids[i]} vs {ids[j]}")
                masalah += 1

    print("\n=== JALUR PANAH (ortogonal) ===")
    for p in panah:
        s, t = p.get("source"), p.get("target")
        if not s or not t or s not in kotak or t not in kotak:
            print(f"  !! PANAH PUTUS: {p.get('id')}")
            masalah += 1
            continue
        st = ambil_style(p.get("style"))
        p1 = titik_tepi(kotak[s], float(st.get("exitX", 0.5)), float(st.get("exitY", 0.5)))
        p2 = titik_tepi(kotak[t], float(st.get("entryX", 0.5)), float(st.get("entryY", 0.5)))

        # jalur orthogonalEdgeStyle: L kalau salah satu sumbu sama, Z kalau tidak
        if abs(p1[0] - p2[0]) < 0.5 or abs(p1[1] - p2[1]) < 0.5:
            jalur = [p1, p2]
        else:
            mx = (p1[0] + p2[0]) / 2
            jalur = [p1, (mx, p1[1]), (mx, p2[1]), p2]

        tembus = []
        for i in range(len(jalur) - 1):
            for cid, b in kotak.items():
                if cid in (s, t):
                    continue
                if segmen_tembus(jalur[i], jalur[i + 1], b):
                    tembus.append(cid)
        status = "OK" if not tembus else f"!! MENEMBUS {', '.join(sorted(set(tembus)))}"
        print(f"  {p.get('id'):10} {s:12} -> {t:12} {status}")
        if tembus:
            masalah += 1

    model = akar.find(".//mxGraphModel")
    pw = float(model.get("pageWidth", 850)) if model is not None else 850.0
    ph = float(model.get("pageHeight", 1100)) if model is not None else 1100.0
    minx = min(b[0] for b in kotak.values())
    miny = min(b[1] for b in kotak.values())
    maxx = max(b[2] for b in kotak.values())
    maxy = max(b[3] for b in kotak.values())
    print(f"\nbatas kotak: x {minx:.0f}..{maxx:.0f}  y {miny:.0f}..{maxy:.0f}")
    print(f"kanvas     : {pw:.0f} x {ph:.0f}")
    if maxx > pw or maxy > ph or minx < 0 or miny < 0:
        print("  !! MELEBIHI KANVAS")
        masalah += 1

    print(f"\n{'BERSIH — 0 masalah' if masalah == 0 else f'{masalah} MASALAH'}")


if __name__ == "__main__":
    main()
