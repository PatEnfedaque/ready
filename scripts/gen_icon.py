#!/usr/bin/env python3
"""Generate launcher_icon.svg: green-to-yellow triangle, blue EKG, Bresenham lines."""

def bresenham(x0, y0, x1, y1):
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    while True:
        yield (x0, y0)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x0 += sx
        if e2 < dx:
            err += dx
            y0 += sy

COLS  = 9
PIXEL = 3   # block size (for color grouping only — rects are 1x1)
LEFT  = 15
TOP   = 3

EKG_COLOR = "#7882B3"   # blue  — r=120, g=130, b=179

def block_color(row, col):
    # green (top, row 0) → yellow (bottom, row 16), power curve for aggressiveness
    t = row / (2 * COLS - 2)
    r = int(120 + t * 59)    # 120 → 179
    g = int(148 + t * 62)    # 148 → 179  (darker green at top)
    b = 120
    return f"#{r:02X}{g:02X}{b:02X}"

def in_triangle(cx, cy):
    if cx < LEFT or cy < TOP:
        return False
    col = (cx - LEFT) // PIXEL
    row = (cy - TOP) // PIXEL
    if col >= COLS:
        return False
    return col <= row <= (2 * COLS - 2 - col)

# EKG control points in canvas coordinates.
# Baseline y=27 (top pixel of centre block row 8).
# P wave, QRS complex (R peak at col-4 top boundary y=15, S dip near col-4 bottom y=37),
# return, T wave.
EKG_POINTS = [
    (15, 30),   # baseline left edge
    (19, 30),   # flat baseline
    (21, 28),   # P wave rising
    (23, 25),   # P wave peak
    (25, 30),   # return to baseline
    (26, 32),   # Q dip (slight below baseline)
    (27, 18),   # R peak  (col 4 — shifted down 3px)
    (28, 40),   # S dip   (col 4 — shifted down 3px)
    (30, 30),   # return to baseline
    (35, 27),   # T wave peak
    (38, 30),   # T wave end
]

ekg_pixels = set()
for i in range(len(EKG_POINTS) - 1):
    x0, y0 = EKG_POINTS[i]
    x1, y1 = EKG_POINTS[i + 1]
    for px, py in bresenham(x0, y0, x1, y1):
        if in_triangle(px, py):
            ekg_pixels.add((px, py))

lines = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 56 56">',
    '  <!-- 9-col play triangle, green-to-yellow gradient, blue EKG -->',
    f'  <!-- EKG pixels removed: {len(ekg_pixels)} -->',
]

for col in range(COLS):
    row_min = col
    row_max = 2 * COLS - 2 - col
    for row in range(row_min, row_max + 1):
        color = block_color(row, col)
        bx = LEFT + col * PIXEL
        by = TOP  + row * PIXEL
        for dy in range(PIXEL):
            for dx in range(PIXEL):
                px = bx + dx
                py = by + dy
                if (px, py) not in ekg_pixels:
                    lines.append(f'  <rect x="{px}" y="{py}" width="1" height="1" fill="{color}"/>')

# Draw EKG pixels in blue over the triangle
for px, py in sorted(ekg_pixels):
    if in_triangle(px, py):
        lines.append(f'  <rect x="{px}" y="{py}" width="1" height="1" fill="{EKG_COLOR}"/>')

lines.append('</svg>')

import os
out = os.path.join(os.path.dirname(__file__), '..', 'resources', 'drawables', 'launcher_icon.svg')
with open(out, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')
print(f"Written {len(lines)-2} rect elements, {len(ekg_pixels)} EKG pixels removed.")
