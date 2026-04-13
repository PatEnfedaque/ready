# Release Notes

## 1.0.5 — 2026-04-13

- Re-release of 1.0.4 to replace a bad binary upload.

## 1.0.4 — 2026-04-12

- Fix: pressing BACK on a confirmation could cause the app to exit unexpectedly (regression in 1.0.3).
- Confirmation dialogs auto-dismiss after 5 seconds (was 10).

## 1.0.3 — 2026-04-12

### Changes

- **Exit confirmation** — pressing the BACK button now shows a confirmation dialog ("Exit Ready?") before closing the app. Previously the app exited immediately.
- **Auto-dismiss confirmations** — the Stop, Resume, and Exit confirmation dialogs now dismiss automatically after 10 seconds if no response is given, treating the timeout as No (i.e. the action is cancelled).

## 1.0.2

- Lowered minimum API level to support a wider range of devices.

## 1.0.1

Initial release.
