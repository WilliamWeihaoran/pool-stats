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
  - `nickname` — optional display name shown in the Lite scoreboard; `displayName` computed property trims whitespace and falls back to `"Me"`

## Lite Scoreboard (Landscape Mode)

`LogView` has a dedicated Lite scoreboard that activates in landscape orientation or via a tap-to-Lite gesture. The scoreboard is implemented as `LandscapeScoreboardView` inside `LogActiveView.swift`.

### Lite mode activation state machine

Three booleans in `LogView` control whether Lite mode is shown:

| State | Effect |
|---|---|
| `forceLiteScoreboard` | User tapped "tap to Lite"; forces Lite on regardless of orientation |
| `suppressAutoLite` | User explicitly exited Lite while in landscape; blocks auto-Lite until next portrait round-trip |
| `isLandscape` | Derived from `GeometryReader` size comparison; triggers auto-Lite |

Priority: `forceLite` > `suppressAutoLite` > `isLandscape`.

When the device returns to portrait, both `forceLiteScoreboard` and `suppressAutoLite` are cleared.

### `LogLiteModeKey` PreferenceKey

`LogView` publishes `showLite` up to `RootView` via a `PreferenceKey`. `RootView` consumes it to hide the tab bar during Lite mode without storing presentation state in the data layer.

### Orientation management

`AppDelegate.orientationLock` is a `UIInterfaceOrientationMask` that defaults to `.allButUpsideDown`. `LogView.enterLite()` calls `requestOrientation(.landscape)` which:
1. Sets `AppDelegate.orientationLock = .allButUpsideDown`
2. Calls `scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()`
3. Calls `scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))`

Both steps are required — `requestGeometryUpdate` alone does not trigger a full SwiftUI layout update.

`Info.plist` must list `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight` under `UISupportedInterfaceOrientations`; omitting these blocks rotation at OS level regardless of runtime code.

### `LandscapeScoreboardView` layout

Three-column `HStack`:
- **Layout column** (92 pt fixed width): 4 layout choice buttons stacked with `maxHeight: .infinity`
- **Center column** (`maxWidth: .infinity`): player name (breaker selector) above 280 pt `.black` score number; opponent below
- **Errors column** (92 pt fixed width): 4 error counters stacked with `maxHeight: .infinity`

Name boxes always show a border and background to signal they are tappable (breaker selector). The active breaker's box uses a colored accent.

### Gesture interactions

- **Tap score** → saves the current rack (adds 1 to that player's score), clears layout/error state, fires a spring pulse animation (`scaleEffect` 1.18)
- **Long press score (0.55 s)** → subtracts 1 from score and restores previous rack data; animated progress ring (245 pt `Circle`, `.trim(from:to:)`) fills linearly during hold and drains with `easeOut` if released early
- **Tap name** → sets that player as the breaker for the current rack

### Custom menu

A small dot at top-center toggles a custom overlay menu (not `Menu {}`). The overlay is a `ZStack` with a dimmed backdrop and a 240 pt wide panel containing: Undo last rack, Exit Lite view (always present), Save & exit.

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

## Watch App Architecture

The `PoolStatsWatchExtension` target lives under `ios/PoolStats/Watch/`. Key files:

| File | Role |
|---|---|
| `PoolStatsWatchApp.swift` | `@main` App entry + entire watch UI (start screen, active session, sheets) |
| `WatchConnectivityClient.swift` | WCSession layer; queues outbound messages; handles incoming phone snapshots |
| `WatchSessionStore.swift` | Local offline session state persisted to UserDefaults |
| `WatchRuntimeSession.swift` | `WKExtendedRuntimeSession` wrapper; auto-restarts on `willExpire` |

### UI sections

Three `LogSection` cases drive the active session flow, auto-advancing on selection:
- `.breakSection` — breaker (Me/Opp) + quality (Good/Ok/Bad) chips, colored at 30 % when unselected
- `.layout` — 2×2 grid: Open/Clustered/Problem/Snookered each with a semantic color
- `.errors` — 2×2 error tile grid; tap = +1, long-press = −1; colors match phone: Miss=teal, Position=amber, Safety=blue, Foul=red

Auto-advance: both Break and Layout wait ~280–300 ms after the completing tap (so the selection is visibly highlighted) before spring-transitioning to the next section.

### Sync / offline model

- `WatchSessionStore` is the local source of truth. All action methods (patch, saveRack, etc.) update local state first, then send to phone.
- `WatchConnectivityClient.send()` guards on `activationState == .activated` before sending; otherwise enqueues.
- `flushQueueIfPossible` strips `rackUUID` from queued envelopes so the phone's `matchesActiveRack(nil)` check accepts them regardless of locally-generated UUID.
- Phone-side `WatchSyncStore.handle(.startSession)` deduplicates by `sessionUUID` to prevent queue replay from restarting an already-active session.
- Phone snapshot arriving via `handleIncomingSnapshot` is authoritative — `sessionStore?.applyRemote(active)` overwrites local watch state.

### Keep-alive

`WatchRuntimeSession` wraps `WKExtendedRuntimeSession`. `start()` / `stop()` are no-ops on simulator (`#if targetEnvironment(simulator)`). `extendedRuntimeSessionWillExpire` creates a new session immediately before the old one expires. `WKBackgroundModes: [workout-processing]` must be present in `WatchExtension-Info.plist`.

### Watch UI rules

- Navigation title carries the section name ("Break" / "Layout" / "Errors"); no separate in-content label row.
- Error tile grid is 2×2; never use a `List` for error counts on watch.
- Unselected chips show the chip's semantic color at 30 % opacity — never flat gray.
- "End Rack" button is always full-width at the bottom of the Errors section.

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
