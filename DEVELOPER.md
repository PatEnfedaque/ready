# Ready — Developer Reference

## Overview

Garmin Connect IQ watch app written in Monkey C (v1.0.2). Foreground-only app: continuous GPS + HR monitoring, auto-start/stop of activity recording based on GPS zones and heart rate.

## Build

**Requirements:**
- `SDK` — path to the Garmin Connect IQ SDK (set in `build.bat`)
- `KEY` — path to your developer key file (set in `build.bat`)
- Java on PATH (used by `build.bat` to call `%SDK%\bin\monkeybrains.jar`)

**VS Code setup:**
Copy `.vscode/settings.json.example` to `.vscode/settings.json` and fill in your local `SDK` and `KEY` paths. The real `settings.json` is gitignored.

**Build:**
```
build.bat [prg|iq|all]
```

| Argument | Output | Use case |
|---|---|---|
| `all` (default) | `ready.iq` + `ready.prg` | Full release build |
| `prg` | `ready.prg` only | Simulator testing (faster) |
| `iq` | `ready.iq` only | Release package only |

- `ready.iq` — signed release package for all supported devices
- `ready.prg` — vivoactive5 sideload binary for simulator testing

Flags: `-e` (entry point), `-r` (release), `-w` (warnings as errors), `-l 3` (optimization level 3).

## File Structure

| File | Role |
|---|---|
| `src/App.mc` | `AppBase` subclass; `getInitialView` wires `MainView` + `InputDelegate` |
| `src/View.mc` | All foreground logic: sensor callbacks, auto-start/stop state machine, zone management, settings persistence, UI drawing |
| `src/Delegate.mc` | Button/swipe input; confirmation dialogs for manual stop and resume |
| `src/MenuDelegate.mc` | All settings menus: zones, sport picker, HR thresholds, radius, debug offset |
| `src/Shared.mc` | Constants (`MAX_ZONES`, `DEFAULT_RADIUS`, `APP_VERSION`) and `haversineMetres()` |
| `manifest.xml` | App metadata, supported device list, permissions |
| `monkey.jungle` | Build manifest pointer (source discovery is handled by SDK defaults) |
| `build.bat` | Build script — accepts `prg`, `iq`, or `all` (default); runs `monkeybrains.jar` accordingly |
| `scripts/generate_sim.py` | Generates `simulation.fit` for simulator FIT playback testing |
| `scripts/gen_icon.py` | Generates `resources/drawables/launcher_icon.svg` (56×56 pixel art) |
| `scripts/gen_icon_hires.py` | Generates `launcher_icon_hires.svg` at 10× scale (560×560) for JPEG export |
| `ready-settings.json` | Connect IQ settings panel definition (`TriggerRadius` only) |
| `resources/settings/properties.xml` | Property defaults (all persisted state) |
| `resources/settings/settings.xml` | User-visible settings panel (TriggerRadius only) |
| `.vscode/settings.json.example` | VS Code template — copy to `settings.json` and set local `SDK`/`KEY` paths |

## Architecture

`MainView` owns all state. `InputDelegate` and all `MenuDelegate` subclasses hold a reference to the view and call its public methods directly — there is no shared state outside the view.

### Sensor loop

Three event sources all feed into `checkAutoLogic()`:

- `Sensor.enableSensorEvents` → `onSensor()` on every HR reading
- `Position.enableLocationEvents(LOCATION_CONTINUOUS)` → `onPosition()` on each GPS fix
- 1-second `Timer` → `onTimer()` for the auto-stop countdown and forced UI refresh

### Auto-start (`checkAutoLogic`)

All conditions must be true simultaneously:

1. GPS lock acquired (`mGpsReady`)
2. At least one zone defined
3. Not currently recording
4. `mManualStop` is not set
5. Current position is within `TriggerRadius` metres of a zone centre (haversine)
6. HR >= `HrStart - HrDebugReduction` for 5 consecutive seconds (`mHighHrSeconds >= 5`)

On entry to a zone (edge-triggered), a double-pulse vibration fires (500ms–200ms gap–500ms). The 5-second high-HR window starts accumulating from the moment the zone is entered with elevated HR.

### Auto-stop (`onTimer`)

All conditions must be true simultaneously:

1. Currently recording
2. Active zone has auto-stop enabled (`:autoStop == true`)
3. HR > 0 and HR < `HrStop - HrDebugReduction`
4. This has persisted for the zone's `stopTimeout` consecutive seconds (`mLowHrSeconds` counter)

### Manual stop

Triggered by SELECT → "Stop activity?" confirmation. Sets `mManualStop = true` and calls `teardownSession`. Suppresses auto-start even while inside the zone. Clears when:

- User selects "Resume monitoring?" via SELECT
- Device leaves the zone (zone membership check returns `nearestIdx == -1`)
- HR drops below `HrStop` (natural cooldown — treated as completed session)

### Session teardown (`teardownSession`)

Shared path for both auto-stop and manual stop:
1. Stops + saves the session
2. Re-enables continuous GPS (disabled during recording to save battery)
3. Fires 3-pulse vibration (200ms–100ms gap × 3)

GPS is disabled while recording because `Position.enableLocationEvents` is the largest battery drain and zone membership no longer matters once a session is active.

## Data Model (Application.Properties)

All state is persisted in `Application.Properties`. Lat/lon stored as strings because `Double` does not round-trip reliably through the Properties API.

| Key | Type | Default | Description |
|---|---|---|---|
| `TriggerRadius` | Float | 200.0 | Zone trigger radius in metres |
| `HrStart` | Number | 120 | HR threshold to start recording |
| `HrStop` | Number | 100 | HR threshold to begin stop countdown |
| `HrDebugReduction` | Number | 0 | Offset subtracted from both thresholds (testing) |
| `ZoneCount` | Number | 0 | Number of saved zones (0–5) |
| `Zone{i}Lat` | String | "0.0" | Zone latitude as decimal string (6 d.p.) |
| `Zone{i}Lon` | String | "0.0" | Zone longitude as decimal string (6 d.p.) |
| `Zone{i}Sport` | Number | 0 | Index into `SPORT_LABELS`/`SPORT_SPORTS` arrays |
| `Zone{i}AutoStop` | Boolean | true | Whether auto-stop is enabled for this zone |
| `Zone{i}StopTimeout` | Number | 30 | Seconds of low HR before auto-stop fires |

`ZoneCount = 0` on first install — zones are inactive until the user adds one.

## Annotation Rules

CIQ enforces strict symbol visibility at compile time. This app is foreground-only, so all classes and functions are annotated `(:foreground)`. Exceptions:

- `APP_VERSION` in `Shared.mc` — `(:foreground)` (not needed in background but kept consistent)
- `haversineMetres()` in `Shared.mc` — `(:foreground)` (background service was removed)
- `App.getInitialView` — annotated `(:typecheck(false))` because it returns a mixed-type array `[view, delegate]` that the type checker cannot verify; the override scope must match the base class and cannot be narrowed to `(:foreground)`

## Sport List

`SPORT_LABELS` and `SPORT_SPORTS` in `View.mc` are parallel arrays of 75 entries, index-matched and sorted alphabetically by display label. A zone's `:sport` property stores the index. Index 6 = Boxing (default when a zone is added).

## UI

**Pixel HR display:** `drawPixelHR` renders the heart rate as 2–3 pixel-art digits using a hand-coded 5×7 bitmap font (`getCharRows`). Each pixel is drawn with a dark border + bright fill to produce a subtle glow. Colour is derived from a deterministic hash of digit index and pixel position, producing a consistent pastel palette per digit.

**Glow arc:** Drawn at the SELECT button position (45°→15° clockwise) using 60 concentric arcs with a quadratic brightness ramp. Purple while recording, muted green while manually paused. Only drawn on round screens.

**Pixel size:** `ps = screenWidth / 48` — scales the display across device sizes (e.g. 8px on vivoactive5 at 390px, 9px on fenix 8 at 454px).

**Menu arrow:** Swipe-up chevron shown on touchscreen devices after a tap. Visible for 2 seconds; swipe up within that window opens the settings menu.

**Status line:** `FONT_XTINY`, centred below the HR display. Shows a countdown (`Stop in Ns`) when auto-stop is actively counting down, otherwise shows zone/GPS/mode status.

## Simulator Testing

**Full workflow (run these in order):**

1. Build the sideload binary:
   ```
   build.bat prg
   ```

2. Launch the simulator (leave it running):
   ```
   %SDK%\bin\simulator.exe
   ```

3. From the project root, load the app into the running simulator:
   ```
   %SDK%\bin\monkeydo.bat ready.prg vivoactive5
   ```
   The app will appear in the simulator window. `monkeydo` connects to the already-running simulator — if the simulator is not open first, this will fail.

4. Add a zone (first time only):
   - Simulation menu → GPS → set a lat/lon
   - In the app, swipe up or press MENU → **Add Zone Here**

`SDK` is defined at the top of `build.bat`.

**Manual sensor input (quickest):**
1. Simulation menu → GPS → set lat/lon to a coordinate inside a saved zone
2. Simulation menu → Heart Rate → set bpm above HR Start (default 120)
3. Wait ~5 seconds for auto-start to fire

**FIT playback (full end-to-end scenario):**
1. Edit `ZONE_LAT` / `ZONE_LON` in `scripts/generate_sim.py` to match a saved zone
2. `python scripts/generate_sim.py` — writes `simulation.fit`
3. Simulator → Simulation → FIT Player → Open → `simulation.fit`
   - Select **Playable file (FIT/GPX)**, not "Workout FIT File"

The generated scenario (240 seconds) covers: approach from 500m outside the zone, zone entry, HR ramp above HR Start (first auto-start after 5s), HR drop below HR Stop (30s countdown, auto-stop), zone exit, re-entry with elevated HR, second auto-start.

**Debug HR offset:**
Settings menu → "Debug HR" — subtracts a fixed offset from both thresholds, so auto-start/stop can be triggered at resting heart rate during simulator testing.
