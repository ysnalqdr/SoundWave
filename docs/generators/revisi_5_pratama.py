"""Sisipkan sitasi Pratama dkk. (2025) pada narasi alur admin Bab III.

Pratama dkk. (2025) membahas validasi QR Code sekali pakai — topik yang
persis sama dengan fitur pemindai gerbang SoundWave. Sitasi ini disisipkan
di paragraf alur admin, tempat pemindaian tiket pertama kali disebut.
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.shared import Pt

BERKAS = Path(__file__).resolve().parents[2] / "Makalah Multimedia.docx"
FONT = "Times New Roman"

LAMA = (
    "Alur admin dimulai dari halaman masuk, lalu dilanjutkan ke dashboard. "
    "Admin membuat data konser beserta aset multimedia, mengatur tipe tiket dan kuota, lalu "
    "mempublikasikan konser. Pada hari penyelenggaraan, admin memindai kode QR tiket di "
    "gerbang masuk. Pemindaian yang sah mengubah status tiket menjadi terpakai. Pemindaian "
    "yang tidak sah sistem tolak."
)

BARU = (
    "Alur admin dimulai dari halaman masuk, lalu dilanjutkan ke dashboard. "
    "Admin membuat data konser beserta aset multimedia, mengatur tipe tiket dan kuota, lalu "
    "mempublikasikan konser. Pada hari penyelenggaraan, admin memindai kode QR tiket di "
    "gerbang masuk. Pemindaian yang sah mengubah status tiket menjadi terpakai. Pemindaian "
    "yang tidak sah sistem tolak. Pratama dkk. (2025) membangun aplikasi tiket dengan "
    "validasi QR Code sekali pakai dan melaporkan bahwa fitur tersebut mencegah duplikasi "
    "tiket serta mempermudah proses pemeriksaan di pintu masuk."
)


def main() -> None:
    doc = Document(str(BERKAS))
    target = None
    for par in doc.paragraphs:
        if par.text.strip().startswith("Alur admin dimulai dari halaman masuk"):
            target = par
            break

    if target is None:
        print("!! paragraf tidak ditemukan")
        return

    for r in list(target.runs):
        r._element.getparent().remove(r._element)
    run = target.add_run(BARU)
    run.font.name = FONT
    run.font.size = Pt(12)

    doc.save(str(BERKAS))
    print("tersimpan")

    # verifikasi
    d = Document(str(BERKAS))
    teks = "\n".join(p.text for p in d.paragraphs)
    print(f"  'Pratama dkk. (2025)' muncul: {teks.count('Pratama dkk. (2025)')}x")
    print(f"  paragraf: {len(d.paragraphs)}  tabel: {len(d.tables)}  gambar: {len(d.inline_shapes)}")


if __name__ == "__main__":
    main()
