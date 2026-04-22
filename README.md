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
- Break section combines breaker and break outcome
- Layout section is separate and uses the four layout states above
- Result section includes the runout tracker
- Unforced errors are logged as a small set of categories rather than by shot difficulty
- Backdated sessions are supported
- Session and rack timers are tracked for current sessions
- Session summary includes a drag-to-rate performance control
- Session summary also shows raw time and adjusted time with a 45-second rack buffer

**Dashboard analytics**
- Win rate over time
- Outcome rings for match and rack results
- Fargo estimate
- Skill radar: Potting, Position, Safety, Fouls, Consistency
- Unforced-error breakdowns
- Break and layout insights
- Conversion rate based on open-layout racks only
- Biggest leak card and opponent-aware filtering

**History**
- Clean session list with date, duration, and outcome styling
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

## Usage

Open `ios/PoolStats/PoolStats.xcodeproj` in Xcode, select a simulator or device, then run the app.

- **Dashboard** — stats and charts
- **Log** — start a new session
- **History** — browse and manage past sessions
- **Goals** — track long-term training targets
- **Settings** — personal summary, appearance, sync, and app actions

To move data between devices or keep a backup, use the JSON export/import flow.

Future idea:
- Sign in with Apple is a later enhancement we may add if the app grows beyond iCloud-only identity and sync.

---

## Tech

SwiftUI, Swift Charts, CloudKit, and a local JSON cache for resilience.
