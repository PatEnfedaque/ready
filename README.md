# Ready

A Garmin Connect IQ watch app that automatically starts and stops activity recording based on your GPS location and heart rate.

Walk into a zone you've defined, get your heart rate up, and recording starts. Heart rate drops for long enough, recording saves. No fiddling required.

## Supported Devices

epix 2, epix 2 Pro, fenix 7 / 7S / 7X / 7 Pro / 7S Pro / 7X Pro, fenix 8, fenix E, Forerunner 165 / 255 / 265 / 570 / 955 / 965 / 970, Venu 3 / 3S / 4 / X1, vivoactive 5 / 6

## Installation

Install from the Garmin Connect IQ Store.

## Setting Up Your First Zone

1. Go to the location you want to trigger recording (your gym, boxing club, sports field, etc.)
2. Open the app on your watch
3. Once GPS locks, swipe up (or press MENU) to open settings
4. Tap **Add Zone Here** — your current location is saved as a zone
5. Select the new zone to set the sport type

Repeat for up to 5 zones. Each zone remembers its own sport type, auto-stop preference, and stop timeout.

## How It Works

| Condition | What happens |
|---|---|
| Inside a zone + HR >= HR Start | Recording begins automatically |
| Inside a zone + HR < HR Stop for [timeout] | Recording saves automatically |
| Recording active | HR display turns purple |
| Manually stopped | HR display turns green; monitoring paused until HR drops or you resume |


## Controls

| Button / Gesture | Action |
|---|---|
| Swipe up or MENU | Open settings |
| SELECT (while recording) | Confirm manual stop |
| SELECT (while paused) | Confirm resume monitoring |
| BACK | Exit app (saves any active recording) |

## Settings

All settings are in the in-app menu (swipe up / MENU).

**Zone settings** (per zone):

| Setting | Options | Default |
|---|---|---|
| Sport | 75+ sport types | Boxing |
| Auto Stop | On / Off | On |
| Stop Timeout | 15s, 30s, 1 min, 2 min, 5 min, 10 min | 30s |

**Global settings**:

| Setting | Options | Default |
|---|---|---|
| HR Start | 100–150 bpm | 120 bpm |
| HR Stop | 50–120 bpm | 100 bpm |
| Zone Radius | 100–500 m | 200 m |
| Zone Radius (Connect IQ) | 50–2000 m | 200 m |

> **Zone Radius** can also be set from the Garmin Connect app under the app's settings panel.

## Display

The main screen shows your heart rate as large pixel-art digits in the centre, with a status line below.

| Status text | Meaning |
|---|---|
| `Waiting for GPS...` | GPS not yet acquired |
| `No zones set` | No zones have been added |
| `[Sport] at [N]bpm` | Inside a zone, waiting for HR to reach HR Start |
| `Recording [Sport]` | Activity is recording |
| `Stop in [N]s` | HR below threshold; auto-stop countdown |
| `Saved! Monitoring...` | Recording just saved |
| `Monitoring paused` | Manual stop active |
| `[N]m away` / `[N.N]km away` | Outside all zones; distance to nearest zone |
