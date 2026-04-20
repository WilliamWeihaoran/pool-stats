# CLAUDE.md

This repository contains `pool-stats`, a native SwiftUI iOS app for logging pool matches and practice sessions, syncing data with CloudKit, and surfacing analytics in Dashboard / Log / History.

## Scope

- Work only inside this repository.
- Prefer keeping changes inside `ios/PoolStats/`.
- Do not change files outside the repo root unless explicitly asked.

## Build And Verify

- Open `ios/PoolStats/PoolStats.xcodeproj` in Xcode.
- Use `xcodebuild` for verification:
```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project ios/PoolStats/PoolStats.xcodeproj -scheme PoolStats -destination 'generic/platform=iOS Simulator' build
```
- The build currently succeeds with a recurring headermap warning; treat that warning as non-blocking unless it becomes a real issue.
- After meaningful edits, run the `xcodebuild` command above to catch regressions.

## App Architecture

- `ios/PoolStats/UI/` holds the SwiftUI views.
- `ios/PoolStats/Models/` holds the data model and analytics helpers.
- `ios/PoolStats/Cloud/` holds CloudKit and local persistence logic.
- `ios/PoolStats/Resources/` holds app resources, including `Info.plist` and the app icon catalog.

## Current Data Model

- `Session` represents a logged session and now includes optional `durationSeconds`.
- `Rack` is the core logging unit.
- `Rack.outcome` currently uses:
  - `runout`
  - `noRunout`
  - `safety`
  - `error`
  - `other`
- `Rack.converted` is defined as `outcome == "runout"`.
- `Rack.breaker` uses `me` or `opp`, with `open` and `none` only for older compatibility paths.
- `Rack.layout` uses:
  - `open`
  - `clustered`
  - `problematic`
  - `snookered`
- `Rack.unforcedErrorCount` is the dashboard-facing aggregate for miss / positional / safety / foul errors.

## Logging Flow

- The active logging screen has been redesigned around these sections:
  - `Break`
  - `Layout`
  - `Unforced errors`
  - `Result`
- `Break` combines who broke and break quality.
- `Runout at first visit` lives inside the Result section and is the conversion tracker.
- Unselected layout and break buttons are intentionally faint.
- The save gate requires the key rack fields to be set before a rack can be saved.

## Stats Rules

- Treat `converted` as runout for UI and analytics.
- Conversion rate is computed from open layouts only:
  - numerator: racks marked converted
  - denominator: racks with `layout == "open"`
- Non-open converted racks should still be stored.
- Dashboard charts should read from the updated schema:
  - unforced errors = `miss` + `positional` + `safety` + `foul`
  - the win-rate trend chart should use a single cleaned series and date-based x-axis

## Session Timing

- Timers are shown only for sessions started “today”.
- Backdated sessions are supported via the session date picker on the log start screen.
- Backdated sessions do not show the live timer / avg rack time strip.

## Persistence

- CloudKit is the primary sync layer.
- A local JSON cache is also maintained in Application Support so sessions survive app relaunches and CloudKit hiccups.
- The History page now shows a sync status chip in the header.
- JSON import supports both:
  - the app’s native JSON format
  - the legacy `index.html` session structure

## Editing Notes

- Keep UI changes consistent with the app’s dark panel style.
- Prefer small, high-signal logging controls over dense “all mistakes” screens.
- When touching analytics, update Dashboard and Summary together so labels and logic stay aligned.
- After meaningful edits, run the `xcodebuild` command above to catch regressions.
