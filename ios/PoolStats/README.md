# PoolStats iOS

Native SwiftUI iOS app for logging pool matches and drill-based practice sessions, syncing through CloudKit, and surfacing actionable stats.

## Current structure
- Custom bottom nav with `Dashboard`, `Log`, `Drills`, `Goals`, and `Settings`; History lives in Settings
- Match logging around `Break`, `Layout`, `Unforced errors`, and `Result`
- Drill-based practice logging with drill, adaptive difficulty, target, W:L score, `Potted` slider, and mistake tags
- Log start can create either a match or drill practice; opponent selector appears only for matches and supports typeahead, quick-pick, and inline create
- Drills tab supports search and AND-style multi-skill filtering, fixed SwiftUI layouts, five difficulty levels, and start-from-detail practice
- Goal tracking with custom actions, completion celebration, and reset prompts
- Drill-in Settings sections for `Me`, `Stats`, `Appearance`, `Data`, and `About`
- First-run onboarding + legacy one-time personalize prompt
- Optional Sign in with Apple account linking in `Settings → Me → Account`
- Dashboard includes recent form, training activity heatmap (18-week calendar, fills card width, active-day count in card header), and error composition stacked area chart
- Haptic + press-scale feedback on all logging controls (`ChoiceButton`, `SmallToggleButton`, `ErrorCounterTile`)

## Open in Xcode
1. Open `ios/PoolStats/PoolStats.xcodeproj` in Xcode.
2. Select the `PoolStats` target.
3. Use `Product → Archive` for TestFlight builds.
4. Use the `App Store Connect` upload flow from Organizer.

## Apple Watch companion

A watchOS extension ships alongside the iOS app (`PoolStatsWatchExtension` target). It operates fully standalone for match logging — sessions can be started, logged, and saved from the watch without the phone present, then sync automatically when the phone becomes reachable. For drill practice, the watch mirrors the active phone drill session with difficulty controls, `Potted`, mistake tags, Miss/Success, and Save & Exit.

### Quick Log start screen
Three single-line tap-to-cycle rows (Mode, Game, Opponent) and a Start Session button — all visible without scrolling on a 40 mm watch.

### Active session flow (3 auto-advancing sections)
1. **Break** — Who broke (Me / Opp) and break quality (Good / Ok / Bad). Both chip rows use per-chip semantic colors at 30 % opacity when unselected and full brightness when selected. Advances automatically ~300 ms after both selections are made.
2. **Layout** — 2 × 2 grid: Open (green), Clustered (yellow), Problem (orange), Snookered (red). Advances automatically ~280 ms after a tap.
3. **Errors** — 2 × 2 colored tile grid matching phone app colors: Miss (teal), Position (amber), Safety (blue), Foul (red). Tap a tile to increment, long-press to subtract. Number updates animate with `.contentTransition(.numericText())` and a spring bounce. "End Rack" button opens the result sheet.

### Score flash

After saving a rack the current score is displayed as a full-screen black overlay with large win/loss numbers. It auto-dismisses after 5 seconds or on tap.

### End-rack / finish sheets
- **End Rack sheet**: Won / Lost chips, Runout toggle (visible only on Won), Save Rack / Save & Exit buttons.
- **Finish session sheet**: scrollable summary stats (score, racks, duration, win rate, runout rate) + drag-based 1–10 performance rating capsule bar, then Save or Discard.

### Keep-alive
`WatchRuntimeSession` wraps `WKExtendedRuntimeSession` and auto-restarts on `extendedRuntimeSessionWillExpire`. `WKBackgroundModes` is intentionally absent — `workout-processing` was removed because it requires a HealthKit entitlement that is not provisioned.

### Offline-first sync
`WatchSessionStore` holds local session state in `UserDefaults` so sessions survive watch kills. `WatchConnectivityClient` queues outgoing messages while the phone is unreachable and flushes them (with `rackUUID` stripped to avoid UUID mismatch) when the session becomes reachable. The phone is authoritative — incoming snapshots overwrite local state. The phone deduplicates `startSession` requests by UUID to prevent queue-replay from creating duplicate sessions.

## Notes
- CloudKit is the primary sync layer.
- Drill session metadata and attempt-level drill fields are included in native JSON and CloudKit persistence.
- A local JSON cache in Application Support keeps sessions safe if sync is delayed.
- Sign in with Apple is optional and lives in `Settings → Me → Account`.
- SIWA is profile-only in this phase (not a sync gate); CloudKit remains independent.
- Signing out only clears local auth profile metadata and keeps sessions/history intact.
- Onboarding captures:
  - Skill level (with mapped default Fargo)
  - Optional manual baseline Fargo (`0...850`, clamped integer)
  - Dedication level
  - Primary game and weekly frequency
- Dashboard Fargo estimate is blended:
  - baseline Fargo + performance estimate
  - weighted by confidence from tracked match racks
  - displayed inside the combined Skill + Fargo card
  - includes an in-card info helper explaining Fargo and the app formula
  - performance estimate factors:
    - Potting (25%)
    - Positional (20%)
    - Runout rate (20%)
    - Pattern play (20%)
    - Overall game (15%)
  - radar labels use: Potting, Position, Pattern, Runout, Overall
- Starter goals are generated from profile inputs and marked as `starterGenerated`.
- Regenerating starter goals only replaces `starterGenerated` goals and does not overwrite user-created goals.
