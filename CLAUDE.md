# CLAUDE.md

This repository contains `pool-stats`, a native SwiftUI iOS app for logging pool matches and practice sessions, syncing data with CloudKit, and surfacing analytics in Dashboard / Log / History.
The app also has a custom bottom nav bar, a Goals tab, and a drill-in Settings tab with theme selection.

## Scope

- Work only inside this repository.
- Prefer keeping changes inside `ios/PoolStats/`.
- Do not change files outside the repo root unless explicitly asked.

## Build And Verify

- Open `ios/PoolStats/PoolStats.xcodeproj` in Xcode.
- Use `xcodebuild` for verification:
```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project ios/PoolStats/PoolStats.xcodeproj -scheme PoolStats -destination 'generic/platform=iOS' -derivedDataPath /tmp/poolstats-derived CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```
- The build currently succeeds; if local DerivedData permissions get in the way, prefer the `/tmp/poolstats-derived` path above.
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
- `Session.performanceRating` is a 1-10 user rating set with a drag control on the summary screen.
- `Session.opponent` stores the tracked opponent name when available.
- `Session.displayLabel` falls back to game+mode text when `label` is empty (for example: `8 ball match`).
- `Goal` includes `starterGenerated` to distinguish app-generated starter goals from user-authored goals.
- `PlayerProfile` stores onboarding/profile preferences:
  - `hasCompletedOnboarding`
  - `hasSeenLegacyPrompt`
  - `skillLevel`
  - `baselineFargo`
  - `dedication`
  - `primaryGame`
  - `weeklyFrequencyBand`

## Logging Flow

- The active logging screen has been redesigned around these sections:
  - `Break`
  - `Layout`
  - `Unforced errors`
  - `Result`
- `Break` combines who broke and break quality.
- `Runout at first visit` lives inside the Result section and is the conversion tracker.
- The end-session confirmation supports Save, Cancel, and Discard.
- Opponent selection on `Log a session` supports typeahead, quick-pick suggestions, and inline opponent creation.
- Unselected layout and break buttons are intentionally faint.
- The save gate requires the key rack fields to be set before a rack can be saved.
- The session summary is shared by both History and the post-session view.
- Session summary timing shows raw time and adjusted time with a 45-second rack buffer.
- Active rack timer behavior:
  - first 45 seconds are setup buffer (amber timer/progress)
  - then active rack time starts at 0 and progress switches to green

## Dashboard Visuals

In addition to the existing charts, the Dashboard now includes:

- **Combined Skill + Fargo card**: skill radar and Fargo estimate live in one section. Radar uses the Fargo factor categories (`Potting`, `Position`, `Pattern`, `Runout`, `Overall`) from the current weighted model.
- **Fargo info helper**: an info (`i`) button next to `Fargo estimate` explains what Fargo is and how the app computes the visual.
- **Training activity heatmap** (`activitySection`): GitHub-style 18-week × 7-day calendar using all sessions (not filter-scoped). Cells are color-coded by session count (0 = panel, 1 = dim purple, 2 = mid purple, 3+ = full purple). Implemented as `ActivityHeatmapView` in `DashboardView.swift`.
  - Active-day count is shown in the top-right of the card header on the same line as the title — not inside the heatmap itself.
  - Left column shows a sideways "week" label (rotated -90°) instead of M/W/F day labels. No legend row.
  - Cell size is computed dynamically from `UIScreen.main.bounds.width - 56` (page + card padding) so the grid fills the full card width on every device.
  - Do NOT use `GeometryReader` + `@State` for width measurement here — it causes an infinite layout loop that freezes the entire app. The `UIScreen.main.bounds.width` approach is intentional.
- **Error composition trend** (`errorTrendSection`): Stacked area chart (`AreaMark(x:yStart:yEnd:)`) for the last 30 filtered sessions, with manually computed cumulative bounds per error type and a 5-session rolling average. Implemented via `ErrorTrendChart` + `ErrorStackPoint` private structs in `DashboardView.swift`. Extracted to a sub-view to avoid Swift type-checker timeouts on complex `Chart` bodies.

## Logging Page Feedback

All interactive controls on the logging page have haptic and animation feedback:

- `ChoiceButton` and `SmallToggleButton`: press scales to 93% via `PressScaleStyle` `ButtonStyle`; fires a light impact haptic on every tap.
- `ErrorCounterTile`: medium impact on tap (increment), rigid impact on long-press (decrement). The value number does a spring-bounce pop (scale 1.0 → 1.28 → 1.0) using `onChange(of: value)`.
- Save rack: fires `UINotificationFeedbackGenerator().notificationOccurred(.success)` on a successful save.
- Save & exit: fires a medium impact haptic on press.

## Stats Rules

- Treat `converted` as runout for UI and analytics.
- Conversion rate is computed from open layouts only:
  - numerator: racks marked converted
  - denominator: racks with `layout == "open"`
- Non-open converted racks should still be stored.
- Dashboard charts should read from the updated schema:
  - unforced errors = `miss` + `positional` + `safety` + `foul`
  - the win-rate trend chart should use a single cleaned series and date-based x-axis
- Dashboard Fargo display is a blended estimate:
  - baseline from `PlayerProfile.baselineFargo`
  - performance center from analytics (`FargoResult.estimatedScore`)
  - confidence ramps by tracked match racks (`count / 200`, clamped `0...1`)
- Fargo performance center now uses these weighted factors:
  - Potting: 25%
  - Positional: 20%
  - Runout rate: 20%
  - Pattern play: 20%
  - Overall game: 15%
- Runout-rate denominator follows the app rule:
  - base denominator is runnable/open layouts
  - a runout from non-open layout adds +1 to both numerator and denominator

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
- Sign in with Apple is implemented as an optional profile link in `Settings → Me → Account`.
- SIWA is intentionally independent from CloudKit sync and does not gate app usage.
- Local sign-out clears auth identity metadata only and keeps sessions/history/cache untouched.
- `PlayerProfileStore` is local app config persistence (UserDefaults JSON) and is independent from session sync.
- The app tabs are currently Dashboard, Log, History, Goals, and Settings.
- Settings is a drill-in list with Me, Stats, Recent form, Appearance, Data, and About sections.
- Goals has a custom action panel with Edit, Complete, Archive/Reset, and Delete, plus a celebration/reset flow.
- Goal editor metrics are split into Grow and Trim groups.
- Rolling goal windows use a slider with quick-set chips; due dates use a graphical date picker.

## Onboarding

- Onboarding is optional and non-blocking.
- Trigger behavior:
  - New users: onboarding appears automatically until completed or skipped.
  - Existing users: one-time legacy prompt offers personalization; “Not now” suppresses repeats.
- On completion, user can choose to create starter goals immediately.
- Starter goal regeneration (from Settings dedication changes) only replaces goals with `starterGenerated == true`.
- “Re-run onboarding” is available in `Settings → Me`.

## Editing Notes

- Keep UI changes consistent with the app’s dark panel style.
- Prefer small, high-signal logging controls over dense “all mistakes” screens.
- When touching analytics, update Dashboard and Summary together so labels and logic stay aligned.
- Keep the custom bottom nav bar anchored to the bottom and visually restrained.
- If you touch Goals, keep the custom action panel, completion flow, and reset target nudging in sync with the model.
- If you touch Settings, keep the drill-in section list and detail pages aligned with the current tabs.
- After meaningful edits, run the `xcodebuild` command above to catch regressions.
