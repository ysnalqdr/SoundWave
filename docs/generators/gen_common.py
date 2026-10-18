"""Helper gambar diagram SoundWave: putih penuh, teks hitam, garis tipis.

Semua koordinat ditulis pada skala akhir (1x). Skala gambar S dipakai di dalam
helper, jadi kode tata letak tidak perlu mengalikan sendiri.
"""
from PIL import Image, ImageDraw, ImageFont

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GREY = (247, 247, 247)

MONO = r"C:\Windows\Fonts\consola.ttf"
MONO_B = r"C:\Windows\Fonts\consolab.ttf"
SANS_B = r"C:\Windows\Fonts\segoeuib.ttf"


class Canvas:
    def __init__(self, w, h, s=2):
        self.W, self.H, self.S = w, h, s
        self.img = Image.new("RGB", (w * s, h * s), WHITE)
        self.d = ImageDraw.Draw(self.img)
        self._fonts = {}

    # ---------- dasar ----------
    def f(self, path, size):
        key = (path, size)
        if key not in self._fonts:
            self._fonts[key] = ImageFont.truetype(path, int(round(size * self.S)))
        return self._fonts[key]

    def _p(self, x, y):
        return (x * self.S, y * self.S)

    def text(self, x, y, t, font, anchor="la"):
        self.d.text(self._p(x, y), t, font=font, fill=BLACK, anchor=anchor)

    def tw(self, t, font):
        return self.d.textlength(t, font=font) / self.S

    def line(self, x1, y1, x2, y2, lw=1.3):
        self.d.line([self._p(x1, y1), self._p(x2, y2)], fill=BLACK, width=max(1, int(round(lw * self.S))))

    def rect(self, x, y, w, h, lw=1.3, fill=None):
        self.d.rectangle([self._p(x, y), self._p(x + w, y + h)], outline=BLACK,
                         width=max(1, int(round(lw * self.S))), fill=fill)

    def fill_rect(self, x, y, w, h, fill=WHITE):
        self.d.rectangle([self._p(x, y), self._p(x + w, y + h)], fill=fill, outline=fill)

    def dashed(self, x1, y1, x2, y2, dash=7, gap=5, lw=1.3):
        import math
        dx, dy = x2 - x1, y2 - y1
        dist = math.hypot(dx, dy)
        if dist == 0:
            return
        ux, uy = dx / dist, dy / dist
        pos = 0.0
        while pos < dist:
            end = min(pos + dash, dist)
            self.line(x1 + ux * pos, y1 + uy * pos, x1 + ux * end, y1 + uy * end, lw)
            pos = end + gap

    # ---------- bentuk ----------
    def head(self, x, y, direction, size=7.0):
        """Segitiga ujung panah. (x, y) = titik ujung."""
        s = size
        pts = {
            "right": [(x, y), (x - s, y - s * 0.62), (x - s, y + s * 0.62)],
            "left": [(x, y), (x + s, y - s * 0.62), (x + s, y + s * 0.62)],
            "down": [(x, y), (x - s * 0.62, y - s), (x + s * 0.62, y - s)],
            "up": [(x, y), (x - s * 0.62, y + s), (x + s * 0.62, y + s)],
        }[direction]
        self.d.polygon([self._p(px, py) for px, py in pts], fill=BLACK)

    def arrow(self, pts, dashed=False, lw=1.3, head=7.0):
        """pts = daftar titik; panah di titik terakhir."""
        for i in range(len(pts) - 1):
            x1, y1 = pts[i]
            x2, y2 = pts[i + 1]
            if dashed:
                self.dashed(x1, y1, x2, y2, lw=lw)
            else:
                self.line(x1, y1, x2, y2, lw)
        (xa, ya), (xb, yb) = pts[-2], pts[-1]
        if abs(xb - xa) >= abs(yb - ya):
            direction = "right" if xb > xa else "left"
        else:
            direction = "down" if yb > ya else "up"
        self.head(xb, yb, direction, head)

    def diamond(self, cx, cy, w, h, lw=1.3):
        pts = [(cx, cy - h / 2), (cx + w / 2, cy), (cx, cy + h / 2), (cx - w / 2, cy)]
        self.d.polygon([self._p(x, y) for x, y in pts], outline=BLACK,
                       width=max(1, int(round(lw * self.S))))

    def badge(self, x, y, label, size=22, font=None):
        """Kotak kecil bernomor di luar bentuk. (x, y) = pojok kiri atas."""
        self.rect(x, y, size, size, lw=1.2)
        fnt = font or self.f(MONO_B, 12)
        self.text(x + size / 2, y + size / 2, label, fnt, anchor="mm")

    def mask_text(self, cx, cy, t, font, pad=5, fill=WHITE):
        """Tulis teks dengan latar putih, dipakai untuk label di atas garis."""
        w = self.tw(t, font)
        self.fill_rect(cx - w / 2 - pad, cy - font.size / self.S / 2 - 3, w + pad * 2,
                       font.size / self.S + 6, fill)
        self.text(cx, cy, t, font, anchor="mm")

    # ---------- komponen bersama ----------
    def header(self, eyebrow, title, subtitle, w, x=72, y=54):
        mono = self.f(MONO, 13)
        spaced = " ".join(eyebrow)
        self.text(x, y, spaced, mono)
        self.text(x, y + 26, title, self.f(SANS_B, 31))
        self.text(x, y + 74, subtitle, self.f(MONO, 13))
        self.line(x, y + 112, w - x, y + 112, 1.4)

    def save(self, path):
        resample = getattr(Image, "Resampling", Image).LANCZOS
        out = self.img.resize((self.W, self.H), resample)
        out.save(path, "PNG")
        print("OK", path, out.size)
