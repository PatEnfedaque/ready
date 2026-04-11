#!/usr/bin/env python3
"""Generate launcher_icon_hires.svg at 10x resolution (560x560) for JPEG export."""

SCALE = 10

COLS  = 9
PIXEL = 3 * SCALE   # 30px blocks
LEFT  = 15 * SCALE  # 150
TOP   = 3  * SCALE  # 30

EKG_COLOR      = "#7882B3"
EKG_STROKE_W   = 8 * SCALE // 10   # ~8px — visible but not chunky

def block_color(row, col):
    t = row / (2 * COLS - 2)
    r = int(120 + t * 59)
    g = int(148 + t * 62)
    b = 120
    return f"#{r:02X}{g:02X}{b:02X}"

# EKG control points scaled 10x from gen_icon.py
EKG_POINTS = [
    (15 * SCALE, 30 * SCALE),
    (19 * SCALE, 30 * SCALE),
    (21 * SCALE, 28 * SCALE),
    (23 * SCALE, 25 * SCALE),
    (25 * SCALE, 30 * SCALE),
    (26 * SCALE, 32 * SCALE),
    (27 * SCALE, 18 * SCALE),
    (28 * SCALE, 40 * SCALE),
    (30 * SCALE, 30 * SCALE),
    (35 * SCALE, 27 * SCALE),
    (38 * SCALE, 30 * SCALE),
]

canvas = 56 * SCALE

lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {canvas} {canvas}" width="{canvas}" height="{canvas}">',
    f'  <!-- {COLS}-col play triangle {canvas}x{canvas}, green-to-yellow gradient, blue EKG polyline -->',
]

# Draw triangle — one rect per block
for col in range(COLS):
    row_min = col
    row_max = 2 * COLS - 2 - col
    for row in range(row_min, row_max + 1):
        color = block_color(row, col)
        bx = LEFT + col * PIXEL
        by = TOP  + row * PIXEL
        lines.append(f'  <rect x="{bx}" y="{by}" width="{PIXEL}" height="{PIXEL}" fill="{color}"/>')

# Draw EKG as a polyline on top
pts = " ".join(f"{x},{y}" for x, y in EKG_POINTS)
lines.append(f'  <polyline points="{pts}" fill="none" stroke="{EKG_COLOR}" stroke-width="{EKG_STROKE_W}" stroke-linejoin="round" stroke-linecap="round"/>')

lines.append('</svg>')

import os
out = os.path.join(os.path.dirname(__file__), '..', 'launcher_icon_hires.svg')
with open(out, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')
print(f"Written {len(lines)-2} elements to {out}")
