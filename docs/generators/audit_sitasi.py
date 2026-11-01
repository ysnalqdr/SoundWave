"""Audit menyeluruh: semua sitasi [SITASI:] vs daftar pustaka."""
import re
import docx

f = r"D:\Projects\Big Projects\Soundwave\Makalah Multimedia.docx"
d = docx.Document(f)
paras = [p.text.strip() for p in d.paragraphs]

i_dp = next(i for i, t in enumerate(paras) if t == "DAFTAR PUSTAKA")
tubuh = paras[:i_dp]
pustaka = [t for t in paras[i_dp + 1:]
           if re.match(r"^[A-ZÀ-Ý][^.]{1,60},\s.*\(\d{4}\)\.", t)]
kunci = [p.split(",")[0].strip() for p in pustaka]

print(f"DAFTAR PUSTAKA: {len(pustaka)} entri\n")

# ---------- 1. semua penanda [SITASI: ...] ----------
teks = "\n".join(tubuh)
penanda = re.findall(r"\[SITASI:\s*([^\]]+)\]", teks)
print(f"=== PENANDA [SITASI:] — {len(penanda)} buah ===")
nama_dipakai = set()
for i, p in enumerate(penanda, 1):
    print(f"  {i}. {p}")
    for bagian in p.split(";"):
        m = re.match(r"^\s*([A-ZÀ-Ý][A-Za-zÀ-ÿ\- ]+?)(?:\s+(?:dkk|&)|,)", bagian)
        if m:
            nama_dipakai.add(m.group(1).strip())

# ---------- 2. sitasi format kurung (kalau ada) ----------
kurung = re.findall(r"\(([A-ZÀ-Ý][^()]{2,80}?,\s*\d{4}[a-z]?)\)", teks)
print(f"\n=== SITASI FORMAT KURUNG — {len(kurung)} buah ===")
for k in kurung:
    print(f"  ({k})")

# ---------- 3. cocokkan ke pustaka ----------
print("\n=== COCOK DENGAN DAFTAR PUSTAKA ===")
semua_disebut = set()
for p in penanda:
    for bagian in re.split(r"[;,]", p):
        bagian = bagian.strip()
        m = re.match(r"^([A-ZÀ-Ý][A-Za-zÀ-ÿ\-]+)", bagian)
        if m:
            semua_disebut.add(m.group(1))

for s in sorted(semua_disebut):
    cocok = [k for k in kunci if s in k or k in s]
    print(f"  {s:18} {'OK -> ' + cocok[0] if cocok else '!! TIDAK ADA DI PUSTAKA'}")

print("\n=== PUSTAKA YANG BELUM DISITASI DI TEKS ===")
belum = [k for k in kunci if k not in teks]
print("  " + (", ".join(belum) if belum else "tidak ada — semua nama muncul di teks"))
