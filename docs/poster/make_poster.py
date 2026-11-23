"""Attendance App poster, A4 portrait at 300 dpi. Drawn at 2x and downsampled."""
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

PROJECT = sys.argv[1]
FONTS = sys.argv[2]
OUT = PROJECT + "/docs/poster"
SHOTS = PROJECT + "/docs/screenshots"

W, H = 2480, 3508
SS = 2
M = 170  # side margin


def s(v):
    return int(round(v * SS))


TEAL = (15, 118, 110)
TEAL_DARK = (17, 94, 89)
MINT = (204, 251, 241)
MINT_SOFT = (230, 246, 242)
GROUND = (246, 250, 249)
INK = (15, 23, 42)
SLATE = (71, 85, 105)
LINE = (203, 219, 215)
DOT = (214, 230, 226)
WHITE = (255, 255, 255)


def font(name, size):
    return ImageFont.truetype(f"{FONTS}/{name}", s(size))


DISPLAY = "BricolageGrotesque-Bold.ttf"
SANS = "InstrumentSans-Regular.ttf"
SANS_B = "InstrumentSans-Bold.ttf"
MONO = "GeistMono-Regular.ttf"

img = Image.new("RGB", (s(W), s(H)), GROUND)
d = ImageDraw.Draw(img)

# Dot lattice: measurement under everything.
for y in range(0, H, 46):
    for x in range(M % 46, W, 46):
        r = 1.6
        d.ellipse([s(x - r), s(y - r), s(x + r), s(y + r)], fill=DOT)

# Header mass.
HEADER_H = 1180
d.rectangle([0, 0, s(W), s(HEADER_H)], fill=TEAL)
# lattice continues faintly inside the mass
for y in range(0, HEADER_H, 46):
    for x in range(M % 46, W, 46):
        r = 1.6
        d.ellipse([s(x - r), s(y - r), s(x + r), s(y + r)], fill=TEAL_DARK)


def text(xy, value, f, fill, anchor="la"):
    d.text((s(xy[0]), s(xy[1])), value, font=f, fill=fill, anchor=anchor)


def width(value, f):
    return d.textlength(value, font=f) / SS


# Header text.
text((M, 190), "XI RPL  ·  IDN BOARDING SCHOOL SOLO", font(MONO, 34), MINT)
title = font(DISPLAY, 236)
text((M - 8, 262), "Attendance", title, WHITE)
text((M - 8, 498), "App", title, WHITE)
tag = font(SANS, 58)
text((M, 786), "Presensi sekolah dengan QR, swafoto, dan GPS.", tag, MINT)
text((M, 860), "Rekap kehadiran langsung tersedia.", tag, MINT)



# Phones.
def phone(path, cx, top, height):
    shot = Image.open(path).convert("RGB")
    bezel = 22
    screen_h = height - 2 * bezel
    screen_w = int(screen_h * shot.width / shot.height)
    w = screen_w + 2 * bezel
    x0, y0 = cx - w / 2, top

    # Soft shadow.
    shadow = Image.new("L", img.size, 0)
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([s(x0 + 30), s(y0 + 60), s(x0 + w - 30), s(y0 + height + 40)], radius=s(80), fill=110)
    shadow = shadow.filter(ImageFilter.GaussianBlur(s(42)))
    img.paste((10, 40, 38), (0, 0), shadow)

    d.rounded_rectangle([s(x0), s(y0), s(x0 + w), s(y0 + height)], radius=s(78), fill=INK)
    scr = shot.resize((s(screen_w), s(screen_h)), Image.LANCZOS)
    mask = Image.new("L", scr.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, scr.width - 1, scr.height - 1], radius=s(58), fill=255)
    img.paste(scr, (s(x0 + bezel), s(y0 + bezel)), mask)
    return x0, y0, w, height


GAP = 64
side_h, mid_h = 1040, 1200
side_w = (side_h - 44) * 1080 / 2400 + 44
mid_w = (mid_h - 44) * 1080 / 2400 + 44
row_w = side_w * 2 + mid_w + GAP * 2
left_cx = W / 2 - row_w / 2 + side_w / 2
right_cx = W / 2 + row_w / 2 - side_w / 2
mid_top = 960
side_top = mid_top + 110

phones = [
    (SHOTS + "/01-login.png", left_cx, side_top, side_h, "01", "Masuk", "Isi nama, pilih peran"),
    (SHOTS + "/03-dashboard-guru.png", right_cx, side_top, side_h, "03", "Dashboard Guru", "Sesi, kehadiran, rekap"),
    (SHOTS + "/02-home-siswa.png", W / 2, mid_top, mid_h, "02", "Home Siswa", "Status hari ini dan scan QR"),
]
caption_y = mid_top + mid_h + 56
for path, cx, top, h, num, label, sub in phones:
    phone(path, cx, top, h)
for _, cx, _, _, num, label, sub in phones:
    text((cx, caption_y), num, font(MONO, 30), TEAL, anchor="ma")
    text((cx, caption_y + 48), label, font(DISPLAY, 50), INK, anchor="ma")
    text((cx, caption_y + 118), sub, font(SANS, 36), SLATE, anchor="ma")


def section_label(y, num, label):
    text((M, y), num, font(MONO, 30), TEAL)
    text((M + 80, y - 6), label, font(DISPLAY, 46), INK)
    lx = M + 80 + width(label, font(DISPLAY, 46)) + 36
    d.line([s(lx), s(y + 20), s(W - M), s(y + 20)], fill=LINE, width=s(2))


# How it works.
flow_y = caption_y + 220
section_label(flow_y, "A", "Cara kerja")
steps = [
    ("Guru membuat sesi", "kelas, masa QR, batas telat"),
    ("QR tampil", "dengan hitung mundur"),
    ("Siswa scan QR", "lalu swafoto dan GPS"),
    ("Rekap otomatis", "Attend atau Late, realtime"),
]
col = (W - 2 * M) / len(steps)
node_y = flow_y + 140
d.line([s(M + col / 2), s(node_y), s(W - M - col / 2), s(node_y)], fill=TEAL, width=s(4))
for i, (head, sub) in enumerate(steps):
    cx = M + col * i + col / 2
    r = 38
    d.ellipse([s(cx - r), s(node_y - r), s(cx + r), s(node_y + r)], fill=TEAL,
              outline=TEAL, width=s(5))
    text((cx, node_y), str(i + 1), font(MONO, 32), WHITE, anchor="mm")
    text((cx, node_y + 72), head, font(SANS_B, 38), INK, anchor="ma")
    text((cx, node_y + 124), sub, font(SANS, 32), SLATE, anchor="ma")

# Features.
feat_y = node_y + 230
section_label(feat_y, "B", "Fitur utama")
features = [
    ("F1", "QR berbatas waktu", "Sesi tertutup saat QR habis"),
    ("F2", "Batas terlambat", "Ditentukan guru per sesi"),
    ("F3", "Cek wajah", "Google ML Kit pada swafoto"),
    ("F4", "Lokasi GPS", "Koordinat dan alamat dicatat"),
    ("F5", "Izin dan sakit", "Diajukan dari aplikasi"),
    ("F6", "Rekap realtime", "Jumlah per status, bisa dikoreksi"),
]
fcol = (W - 2 * M) / 3
for i, (code, head, sub) in enumerate(features):
    x = M + fcol * (i % 3)
    y = feat_y + 100 + (i // 3) * 160
    d.rounded_rectangle([s(x), s(y + 4), s(x + 64), s(y + 50)], radius=s(10), fill=MINT)
    text((x + 32, y + 27), code, font(MONO, 26), TEAL_DARK, anchor="mm")
    text((x + 88, y), head, font(SANS_B, 38), INK)
    text((x + 88, y + 56), sub, font(SANS, 32), SLATE)

# Footer.
foot_y = H - 190
d.line([s(M), s(foot_y - 40), s(W - M), s(foot_y - 40)], fill=LINE, width=s(2))
text((M, foot_y), "FLUTTER  ·  CLOUD FIRESTORE  ·  GOOGLE ML KIT  ·  MATERIAL 3", font(MONO, 28), SLATE)
pills = [
    ("Attend", (220, 252, 231), (20, 83, 45), (22, 163, 74)),
    ("Late", (255, 237, 213), (124, 45, 18), (234, 88, 12)),
    ("Sick", (254, 249, 195), (113, 63, 18), (234, 179, 8)),
    ("Permission", (224, 231, 255), (55, 48, 163), (99, 102, 241)),
]
pf = font(SANS_B, 28)
x = W - M
for label, bg, fg, dot in reversed(pills):
    pw = width(label, pf) + 92
    x0 = x - pw
    d.rounded_rectangle([s(x0), s(foot_y - 10), s(x), s(foot_y + 46)], radius=s(28), fill=bg)
    d.ellipse([s(x0 + 14), s(foot_y + 4), s(x0 + 42), s(foot_y + 32)], fill=dot)
    text((x0 + 56, foot_y + 18), label, pf, fg, anchor="lm")
    x = x0 - 16

final = img.resize((W, H), Image.LANCZOS)
final.save(OUT + "/attendance-app-poster.png", dpi=(300, 300))
final.save(OUT + "/attendance-app-poster.pdf", resolution=300)
print("saved", final.size, "flow", flow_y, "features", feat_y, "feat end", feat_y + 100 + 160 + 96, "footer", foot_y)
