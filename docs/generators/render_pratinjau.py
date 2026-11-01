"""Render pratinjau PNG dari drawio, mengikuti jalur ortogonal draw.io.

Bukan renderer sempurna: teks tidak dibungkus rapi dan font memakai bawaan PIL.
Tujuannya hanya memeriksa tata letak & jalur panah, bukan kualitas cetak.
"""
from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageDraw

SKALA = 0.5


def ambil_style(style: str) -> dict:
    d = {}
    for bagian in (style or "").split(";"):
        if "=" in bagian:
            k, v = bagian.split("=", 1)
            d[k] = v
    return d


def bersihkan(teks: str) -> str:
    """Buang tag HTML, ambil teks yang terlihat."""
    import re

    teks = teks.replace("<br>", " | ").replace("<br/>", " | ")
    teks = re.sub(r"<[^>]+>", "", teks)
    return teks.replace("&nbsp;", " ").replace("&amp;", "&").strip()


def main(path_drawio: str, path_png: str) -> None:
    akar = ET.fromstring(Path(path_drawio).read_text(encoding="utf-8"))

    simpul, garis = [], []
    for c in akar.findall(".//mxCell"):
        g = c.find(".//mxGeometry")
        if g is None:
            continue
        if c.get("vertex") == "1":
            x, y = float(g.get("x", 0)), float(g.get("y", 0))
            w, h = float(g.get("width", 0)), float(g.get("height", 0))
            if w <= 0 or h <= 0:
                continue
            st = ambil_style(c.get("style") or "")
            if "rhombus" in (c.get("style") or ""):
                bentuk = "rhombus"
            elif "ellipse" in (c.get("style") or ""):
                bentuk = "ellipse"
            elif st.get("text") == "1" or "text;html=1" in (c.get("style") or ""):
                bentuk = "teks"
            else:
                bentuk = "rect"
            simpul.append((c.get("id"), bentuk, x, y, w, h, c.get("value") or ""))
        elif c.get("edge") == "1":
            st = ambil_style(c.get("style") or "")
            garis.append((c.get("source"), c.get("target"), c.get("value") or "", st))

    model = akar.find(".//mxGraphModel")
    pw = float(model.get("pageWidth", 850)) if model is not None else 850
    ph = float(model.get("pageHeight", 1100)) if model is not None else 1100

    W, H = int(pw * SKALA), int(ph * SKALA)
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)

    kotak = {}
    for cid, bentuk, x, y, w, h, teks in simpul:
        a = (x * SKALA, y * SKALA, (x + w) * SKALA, (y + h) * SKALA)
        kotak[cid] = (x, y, x + w, y + h)
        if bentuk == "ellipse":
            d.ellipse(a, outline="black", fill="white")
        elif bentuk == "rhombus":
            mx, my = (a[0] + a[2]) / 2, (a[1] + a[3]) / 2
            d.polygon([(mx, a[1]), (a[2], my), (mx, a[3]), (a[0], my)],
                      outline="black", fill="#F2F2F2")
        elif bentuk == "teks":
            pass
        else:
            d.rectangle(a, outline="black", fill="white")
        t = bersihkan(teks)
        if t and bentuk != "teks":
            d.text((a[0] + 3, a[1] + 2), t[:26], fill="black")
        elif t:
            d.text((a[0] + 3, a[1] + 2), t[:90], fill="#333333")

    for s, t, lab, st in garis:
        if s not in kotak or t not in kotak:
            continue
        sb, tb = kotak[s], kotak[t]
        p1 = (sb[0] + (sb[2] - sb[0]) * float(st.get("exitX", 0.5)),
              sb[1] + (sb[3] - sb[1]) * float(st.get("exitY", 0.5)))
        p2 = (tb[0] + (tb[2] - tb[0]) * float(st.get("entryX", 0.5)),
              tb[1] + (tb[3] - tb[1]) * float(st.get("entryY", 0.5)))

        if abs(p1[0] - p2[0]) < 0.5 or abs(p1[1] - p2[1]) < 0.5:
            jalur = [p1, p2]
        else:
            mx = (p1[0] + p2[0]) / 2
            jalur = [p1, (mx, p1[1]), (mx, p2[1]), p2]
        skala = [(px * SKALA, py * SKALA) for px, py in jalur]
        d.line(skala, fill="#333333", width=1)
        if lab:
            mx = sum(px for px, _ in skala) / len(skala)
            my = sum(py for _, py in skala) / len(skala)
            d.text((mx + 2, my - 8), bersihkan(lab)[:14], fill="#B00000")

    img.save(path_png)
    print(f"{path_png}  {W}x{H}  ({len(simpul)} simpul, {len(garis)} garis)")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
