"""Audit konsistensi sitasi dan daftar pustaka makalah."""
import re
import docx

f = r"D:\Projects\Big Projects\Soundwave\Makalah Multimedia.docx"
d = docx.Document(f)
paras = [p.text.strip() for p in d.paragraphs]

i_dp = next(i for i, t in enumerate(paras) if t == "DAFTAR PUSTAKA")
tubuh = paras[:i_dp]
pustaka = [t for t in paras[i_dp + 1:]
           if re.match(r"^[A-ZÀ-Ý][^.]{1,60},\s.*\(\d{4}\)\.", t)]

print(f"=== DAFTAR PUSTAKA ({len(pustaka)} entri) ===")
kunci = []
for n, p in enumerate(pustaka, 1):
    nama = p.split(",")[0].strip()
    kunci.append(nama)
    print(f"  {n:2}. {nama:16} {p[:60]}")

teks = " ".join(tubuh)
print()
print("=== SITASI DALAM TEKS ===")
pola = re.findall(r"\(([^()]{3,90}?,\s*\d{4}[a-z]?)\)", teks)
nama_sitasi = set()
for s in pola:
    for bagian in s.split(";"):
        m = re.match(r"^([A-ZÀ-Ý][A-Za-zÀ-ÿ\-]+)", bagian.strip())
        if m:
            nama_sitasi.add(m.group(1))

hilang = []
for s in sorted(nama_sitasi):
    ada = any(s in k for k in kunci)
    if not ada:
        hilang.append(s)
    print(f"  {s:18} {'OK' if ada else '!! TIDAK ADA DI PUSTAKA'}")

print()
print("=== PUSTAKA TANPA SITASI ===")
tak = [n for n in kunci if n not in teks]
print("  " + (", ".join(tak) if tak else "tidak ada — semua disitasi"))

print()
print("=== SISA NAMA LAMA ===")
for lama in ("Patil", "Maftoha"):
    print(f"  {lama:10} {'MASIH ADA' if lama in teks else 'bersih'}")

print()
print("=== CEK BAGIAN ===")
import zipfile
z = zipfile.ZipFile(f)
xml = z.read("word/document.xml").decode("utf-8")
print(f"  paragraf : {len(d.paragraphs)}")
print(f"  tabel    : {len(d.tables)}")
print(f"  gambar   : {len([n for n in z.namelist() if n.startswith('word/media/')])}")
print(f"  Mendeley : {'hidup' if 'CSL_CITATION' in xml else 'HILANG'}")
for p in d.paragraphs:
    t = p.text.strip()
    if t.startswith("BAB ") and len(t) < 40:
        print("  " + t.replace("\n", " / "))
