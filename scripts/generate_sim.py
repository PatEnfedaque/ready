#!/usr/bin/env python3
"""
Generate a FIT simulation file for testing garmin-auto-activity.

Scenario (10 minutes):
  0–120s  : 500m from zone, HR resting ~70 bpm
  120–240s: approaching zone, HR rising 70 → 135
  240–420s: inside zone, HR ~135  → auto-START triggers when HR >= HR_START
  420–510s: HR drops 135 → 85     → auto-STOP triggers 30s after HR < HR_STOP
  510–600s: walking away from zone

Load the output file in the simulator via:
  Simulation menu → FIT Player → Open → simulation.fit
"""

import struct
from datetime import datetime, timezone

# ── Configuration — adjust to match your saved zone and app settings ──────────
ZONE_LAT    = 51.5074   # latitude of your saved zone
ZONE_LON    = -0.1278   # longitude of your saved zone
ZONE_RADIUS = 200       # metres — match TriggerRadius setting in app
HR_START    = 120       # bpm — match HrStart setting in app
HR_STOP     = 100       # bpm — match HrStop setting in app
OUTPUT_FILE = "simulation.fit"
# ─────────────────────────────────────────────────────────────────────────────

FIT_EPOCH          = datetime(1989, 1, 1, tzinfo=timezone.utc)
METRES_PER_DEG_LAT = 111_000.0

# FIT base type codes
ENUM    = 0x00  # 1 byte, unsigned
UINT8   = 0x02  # 1 byte, unsigned
UINT16  = 0x84  # 2 bytes, unsigned
UINT32  = 0x86  # 4 bytes, unsigned
UINT32Z = 0x8C  # 4 bytes, unsigned (zero-invalid)
SINT32  = 0x85  # 4 bytes, signed


def fit_timestamp(dt: datetime) -> int:
    return int((dt - FIT_EPOCH).total_seconds())


def semicircles(degrees: float) -> int:
    return int(degrees * (2 ** 31 / 180.0))


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * max(0.0, min(1.0, t))


def crc_update(crc: int, byte: int) -> int:
    table = [0x0000, 0xCC01, 0xD801, 0x1400,
             0xF001, 0x3C00, 0x2800, 0xE401,
             0xA001, 0x6C00, 0x7800, 0xB401,
             0x5000, 0x9C01, 0x8801, 0x4400]
    tmp = table[crc & 0xF]
    crc = (crc >> 4) & 0x0FFF
    crc ^= tmp ^ table[byte & 0xF]
    tmp = table[crc & 0xF]
    crc = (crc >> 4) & 0x0FFF
    crc ^= tmp ^ table[(byte >> 4) & 0xF]
    return crc


def compute_crc(data: bytes) -> int:
    crc = 0
    for b in data:
        crc = crc_update(crc, b)
    return crc


def definition_message(local_num: int, global_num: int, fields: list) -> bytes:
    """fields: list of (field_def_num, size_bytes, base_type)"""
    header = 0x40 | (local_num & 0x0F)
    msg = bytes([header, 0x00, 0x00])                    # header, reserved, little-endian
    msg += struct.pack('<HB', global_num, len(fields))   # global msg num, field count
    for field_def_num, size, base_type in fields:
        msg += struct.pack('BBB', field_def_num, size, base_type)
    return msg


# ── Build record data ─────────────────────────────────────────────────────────
records = bytearray()

# Definition: file_id (global msg 0, local 0)
records += definition_message(0, 0, [
    (0, 1, ENUM),     # type
    (1, 2, UINT16),   # manufacturer
    (2, 2, UINT16),   # product
    (3, 4, UINT32Z),  # serial_number
    (4, 4, UINT32),   # time_created
])

now       = datetime.now(timezone.utc)
start_ts  = fit_timestamp(now)

# Data: file_id  (type=4=activity, manufacturer=1=Garmin)
records += bytes([0x00])
records += struct.pack('<BHHII', 4, 1, 1, 12345678, start_ts)

# Definition: record (global msg 20, local 1)
records += definition_message(1, 20, [
    (253, 4, UINT32),  # timestamp
    (0,   4, SINT32),  # position_lat  (semicircles)
    (1,   4, SINT32),  # position_long (semicircles)
    (3,   1, UINT8),   # heart_rate
])

# ── Simulate 4-minute scenario with zone exit and re-entry ────────────────────
# t=0-54s  : approaching, HR ramps 70→100
# t=~54s   : enters zone at HR=100 (no auto-start yet)
# t=~75s   : HR crosses HR_START → first auto-START
# t=~134s  : HR crosses HR_STOP → 30s countdown
# t=~164s  : first auto-STOP
# t=~183s  : exits zone (resets mHasLeftZone when outside)
# t=~222s  : re-enters zone at HR=85
# t=~233s  : HR crosses HR_START → second auto-START
TOTAL = 240

for i in range(TOTAL):

    # Distance north of zone center (metres)
    if i < 50:
        dist = lerp(500, ZONE_RADIUS + 20, i / 50)          # approaching
    elif i < 80:
        dist = lerp(ZONE_RADIUS + 20, 50, (i - 50) / 30)    # entering zone
    elif i < 165:
        dist = 50                                             # inside zone
    elif i < 195:
        dist = lerp(50, 300, (i - 165) / 30)                 # leaving zone
    elif i < 210:
        dist = 300                                            # outside, resting
    else:
        dist = lerp(300, 50, (i - 210) / 30)                 # re-entering zone

    lat = ZONE_LAT + (dist / METRES_PER_DEG_LAT)
    lon = ZONE_LON

    # HR profile
    if i < 54:
        hr = int(lerp(70, HR_STOP, i / 54))                               # 70→100 approaching
    elif i < 90:
        hr = int(lerp(HR_STOP, HR_START + 15, (i - 54) / 36))            # 100→135 inside zone
    elif i < 110:
        hr = HR_START + 15                                                 # steady 135
    elif i < 145:
        hr = int(lerp(HR_START + 15, HR_STOP - 15, (i - 110) / 35))      # 135→85 dropping
    elif i < 220:
        hr = HR_STOP - 15                                                  # 85 resting outside
    else:
        hr = int(lerp(HR_STOP - 15, HR_START + 20, (i - 220) / 20))      # 85→140 re-entering

    records += bytes([0x01])
    records += struct.pack('<IiiB',
        start_ts + i,
        semicircles(lat),
        semicircles(lon),
        hr,
    )

# ── Assemble FIT file ─────────────────────────────────────────────────────────
data      = bytes(records)
data_size = len(data)

header  = struct.pack('<BBH', 14, 0x10, 2132)   # size, protocol ver, profile ver
header += struct.pack('<I', data_size)
header += b'.FIT'
header += struct.pack('<H', compute_crc(header))  # header CRC (bytes 0-11)

fit_file = header + data + struct.pack('<H', compute_crc(data))

with open(OUTPUT_FILE, 'wb') as f:
    f.write(fit_file)

# ── Summary ───────────────────────────────────────────────────────────────────
print(f"Written {OUTPUT_FILE}  ({len(fit_file):,} bytes, {TOTAL}s)")
print()
print(f"  Zone center : {ZONE_LAT}, {ZONE_LON}")
print(f"  Zone radius : {ZONE_RADIUS}m")
print()
print(f"  t=0s    : 500m away, HR 70 bpm")
print(f"  t=~54s  : enters zone at HR={HR_STOP} bpm — shows 'Sport at {HR_START}bpm'")
print(f"  t=~75s  : HR crosses {HR_START} bpm → first auto-START")
print(f"  t=~134s : HR crosses {HR_STOP} bpm → 30s countdown")
print(f"  t=~164s : first auto-STOP")
print(f"  t=~183s : exits zone — resets re-entry lock")
print(f"  t=~222s : re-enters zone at HR=85 — shows 'Sport at {HR_START}bpm'")
print(f"  t=~233s : HR crosses {HR_START} bpm → second auto-START")
print()
print("Load in simulator: Simulation → FIT Player → Open → simulation.fit")
