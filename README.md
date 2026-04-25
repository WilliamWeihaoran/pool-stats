# pool-stats

Pool Stats is a native iOS app for logging pool sessions and turning them into actionable stats. It is built in SwiftUI and uses CloudKit plus a local JSON cache for persistence. The app now includes a custom bottom nav, a Goals tab, and a drill-in Settings page with theme choices.

---

## What It Does

Pool Stats helps you log sessions rack by rack without turning the app into homework. The current model focuses on a small set of high-signal stats:

- Result: win or loss
- Break: who broke and break quality
- Layout: open, clustered, problematic, or snookered
- Unforced errors: miss, positional, safety, foul
- Runout tracking: `Runout at first visit`

That gives you enough detail to improve your game without forcing you to record every tiny shot.

---

## Core Features

**Session logging**
- Supports 8-ball and 9-ball
- Supports match and practice sessions
- Opponent field supports typeahead + quick-pick from existing opponents
- You can create a new opponent inline directly from the log flow
- Break section combines breaker and break outcome
- Layout section is separate and uses the four layout states above
- Result section includes the runout tracker
- Unforced errors are logged as a small set of categories rather than by shot difficulty
- Backdated sessions are supported
- Session and rack timers are tracked for current sessions
- Session summary includes a drag-to-rate performance control (drag the capsule bar left/right)
- Session summary also shows raw time and adjusted time with a 45-second rack buffer
- All logging controls have haptic and press-scale feedback

**Lite scoreboard (landscape mode)**
- Rotate to landscape (or tap the score area) to switch to the Lite scoreboard
- Giant score numbers fill most of the screen — tap a score to record a rack win for that player
- Long-press a score to undo the last rack; a progress ring fills during the hold and drains on early release
- Tap a player name to mark them as the breaker for the current rack
- Left column tracks table layout; right column tracks errors for the current rack
- Custom dot-menu at the top center: Undo, Exit Lite, Save & exit
- Tab bar hides in Lite mode to maximise screen space
- Exiting Lite while in landscape doesn't force portrait; Lite re-enables only after a portrait → landscape round-trip
- Player nickname is configurable in Settings → Me so your name shows above your score

**Dashboard analytics**
- Win rate over time
- Outcome rings for match and rack results
- Combined skill + Fargo visual (single card)
- Fargo estimate (baseline + performance blend)
- Fargo performance factors: Potting (25%), Positional (20%), Runout rate (20%), Pattern play (20%), Overall game (15%)
- Skill radar categories: Potting, Position, Pattern, Runout, Overall
- Info helper on Fargo estimate for a quick explanation of Fargo and the in-app calculation
- Unforced-error breakdowns
- Break and layout insights
- Conversion rate based on open-layout racks only
- Biggest leak card and opponent-aware filtering
- Training activity heatmap (18-week GitHub-style calendar, fills card width, active-day count in header)
- Error composition trend (stacked area chart, 5-session rolling average)

**History**
- Clean session list with date, duration, and outcome styling
- Empty session names now fall back to game+mode labels (for example: `8 ball match`)
- Select mode for deleting sessions
- Practice sessions and match draws are visually distinguished
- Sync status indicator for local cache vs. iCloud
- Import / export JSON
- Built-in sample data can be restored

**Navigation / Settings**
- Custom bottom navigation bar
- Dashboard, Log, History, Goals, and Settings tabs
- Four theme presets: two dark, two light
- Settings is split into drill-in sections for Me, Stats, Recent form, Appearance, Data, and About
- Me section includes a Nickname field used in the Lite scoreboard

**Goals**
- Custom goal cards with completion, archive, edit, delete, and reset actions
- Grow vs Trim metric grouping
- Rolling time frames or due dates
- Goal completion celebration and reset suggestions
- Goal metrics stay tied to the stats already tracked in the app

**Storage**
- Primary sync is CloudKit private database under the app’s iCloud container
- The app also keeps a local JSON cache in Application Support so sessions are not lost if sync is delayed or unavailable

---

## Distribution

The app is distributed via TestFlight. Install the TestFlight app on your iPhone, accept the invite, and tap Install. The watchOS companion installs automatically alongside the iPhone app.

## Usage

Open `ios/PoolStats/PoolStats.xcodeproj` in Xcode, select a simulator or device, then run the app.

- **Dashboard** — stats and charts
- **Log** — start a new session
- **History** — browse and manage past sessions
- **Goals** — track long-term training targets
- **Settings** — personal summary, appearance, sync, and app actions

To move data between devices or keep a backup, use the JSON export/import flow.

---

## Tech

SwiftUI, Swift Charts, CloudKit, and a local JSON cache for resilience.
