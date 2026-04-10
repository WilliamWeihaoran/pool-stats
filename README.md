# pool-stats

A native iOS app for tracking 8-ball and 9-ball sessions with rich analytics. Built in SwiftUI with CloudKit sync.

---

## What it does

pool-stats lets you log every rack you play and gives you real analytics on your game over time. It tracks not just wins and losses, but *why* you're losing — position errors, bad safeties, missed shots by difficulty, fouls, and pattern mistakes. After enough sessions, you'll have a clear picture of what's actually holding you back.

---

## Core features

**Session logging**
- Supports 8-ball and 9-ball, match and practice modes
- Log break details (who broke, balls potted, break foul)
- Rate layout at first visit: open, clustered, problematic, or snookered
- Track mistakes per rack: fouls, bad safety, bad position, pattern changes
- Track misses by difficulty: easy, medium, hard
- Record rack outcome: runout, safety win, error, or other
- Mark runout-first-visit and break-and-run achievements
- Tap to increment counters, long-press to decrement

**Dashboard analytics**
- Win rate over time chart, bucketed intelligently by filter (daily / weekly / biweekly / monthly)
- Mistakes per rack breakdown by category
- Won vs. lost mistake comparison — shows your biggest loss factor
- Skill radar: Potting, Position, Safety, Fouls, Consistency
- Fargo rating estimate based on execution metrics
- Break & layout insights: win rate by who broke, layout type, and break quality

**History**
- Full session log with search and filtering by game type
- Click any session to view its full rack-by-rack summary
- Select and delete sessions
- Export and import data as JSON
- Restore built-in sample data from the History view when empty

**Data privacy**
- CloudKit is used for storage and sync (iCloud account required)
- Export JSON to back up your data or transfer it to another device

---

## Usage

Open `ios/PoolStats/PoolStats.xcodeproj` in Xcode, select a simulator or device, then Run.

- **Dashboard** — your stats and charts
- **Log** — start a new session
- **History** — browse past sessions

To back up your data, tap **Export JSON** on the dashboard. To restore, tap **Import JSON** and select your file.

---

## Tech

SwiftUI + Swift Charts. CloudKit for storage. JSON import/export for portability.
