"""
Pratinjau DFD Level 0 dari berkas .drawio memakai PIL.

Tujuan: memeriksa apakah panah baru menabrak simpul atau label, TANPA perlu
membuka draw.io. Rutenya didekati dengan pola ortogonal yang sama seperti
`orthogonalEdgeStyle` draw.io (keluar tegak lurus sisi, belok di titik
tengah, masuk tegak lurus sisi tujuan).

Ini alat pemeriksa, bukan pengganti draw.io — hasil akhir tetap digambar
draw.io saat berkasnya dibuka.

Jalankan: python docs/generators/pratinjau_dfd0.py
"""

from __future__ import annotations

import html
import io
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BERKAS = Path(__file__).resolve().parents[1] / "soundwave3d.drawio"
KELUARAN = Path(__file__).resolve().parents[1] / "mockup" / "dfd0_pratinjau.png"

SKALA = 0.42  # perkecil supaya muat dilihat sekaligus


def font(ukuran: int) -> ImageFont.FreeTypeFont:
    for p in (
        r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        if Path(p).exists():
            return ImageFont.truetype(p, ukuran)
    return ImageFont.load_default()


def main() -> None:
    s = io.open(BERKAS, encoding="utf-8").read()
    _i = s.find('<diagram name="Data Flow Diagram 0"')
    s = s[_i:s.find("</diagram>", _i)]

    # --- simpul ---
    simpul: dict[str, dict] = {}
    for m in re.finditer(
        r'<mxCell id="([^"]+)"[^>]*value="([^"]*)"[^>]*vertex="1"[^>]*>\s*'
        r'<mxGeometry([^/]*)/>',
        s,
    ):
        id_, val, geo = m.group(1), m.group(2), m.group(3)
        d = dict(re.findall(r'(\w+)="([^"]*)"', geo))
        teks = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", html.unescape(val))).strip()
        simpul[id_] = dict(
            x=float(d.get("x", 0)), y=float(d.get("y", 0)),
            w=float(d.get("width", 0)), h=float(d.get("height", 0)),
            teks=teks,
        )

    # --- panah ---
    panah = []
    for m in re.finditer(r'<mxCell([^>]*edge="1"[^>]*)>', s):
        tag = m.group(1)
        src = re.search(r'source="([^"]+)"', tag)
        tgt = re.search(r'target="([^"]+)"', tag)
        st = re.search(r'style="([^"]*)"', tag)
        val = re.search(r'value="([^"]*)"', tag)
        if not (src and tgt and st):
            continue
        ex = re.search(r"exitX=([\d.]+);exitY=([\d.]+)", st.group(1))
        en = re.search(r"entryX=([\d.]+);entryY=([\d.]+)", st.group(1))
        panah.append(dict(
            src=src.group(1), tgt=tgt.group(1),
            ex=(float(ex.group(1)), float(ex.group(2))) if ex else (0.5, 0.5),
            en=(float(en.group(1)), float(en.group(2))) if en else (0.5, 0.5),
            label=html.unescape(val.group(1)) if val else "",
        ))

    lebar = int(max(v["x"] + v["w"] for v in simpul.values()) * SKALA) + 40
    tinggi = int(max(v["y"] + v["h"] for v in simpul.values()) * SKALA) + 40
    img = Image.new("RGB", (lebar, tinggi), "white")
    d = ImageDraw.Draw(img)
    f_kotak = font(9)
    f_label = font(7)

    def sk(nilai: float) -> float:
        return nilai * SKALA + 20

    # --- gambar panah dulu, supaya kotak menutupinya ---
    for p in panah:
        a, b = simpul[p["src"]], simpul[p["tgt"]]
        ax, ay = sk(a["x"] + a["w"] * p["ex"][0]), sk(a["y"] + a["h"] * p["ex"][1])
        bx, by = sk(b["x"] + b["w"] * p["en"][0]), sk(b["y"] + b["h"] * p["en"][1])

        keluar_horizontal = p["ex"][0] in (0.0, 1.0)
        masuk_horizontal = p["en"][0] in (0.0, 1.0)

        if keluar_horizontal and masuk_horizontal:
            mx = (ax + bx) / 2
            titik = [(ax, ay), (mx, ay), (mx, by), (bx, by)]
        elif keluar_horizontal:
            titik = [(ax, ay), (bx, ay), (bx, by)]
        elif masuk_horizontal:
            titik = [(ax, ay), (ax, by), (bx, by)]
        else:
            my = (ay + by) / 2
            titik = [(ax, ay), (ax, my), (bx, my), (bx, by)]

        d.line(titik, fill="#333333", width=1)
        # kepala panah
        d.ellipse([bx - 1.6, by - 1.6, bx + 1.6, by + 1.6], fill="#333333")
        # label di tengah segmen terpanjang
        if p["label"]:
            tengah = titik[len(titik) // 2]
            d.text((tengah[0] + 2, tengah[1] - 7), p["label"][:34],
                   fill="#666666", font=f_label)

    # --- gambar simpul ---
    for v in simpul.values():
        x0, y0 = sk(v["x"]), sk(v["y"])
        x1, y1 = sk(v["x"] + v["w"]), sk(v["y"] + v["h"])
        d.rectangle([x0, y0, x1, y1], outline="black", width=1, fill="white")
        d.text((x0 + 3, y0 + 3), v["teks"][:30], fill="black", font=f_kotak)

    KELUARAN.parent.mkdir(parents=True, exist_ok=True)
    img.save(KELUARAN)
    print(f"tersimpan: {KELUARAN}  ({lebar}x{tinggi})")
    print(f"simpul: {len(simpul)}  panah: {len(panah)}")


if __name__ == "__main__":
    main()
