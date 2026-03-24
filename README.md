# pool-stats

A mobile-first web app for tracking your 8-ball and 9-ball pool sessions. No account needed, no server, no ads — just open it and play.

**Live app:** https://williamweihaoran.github.io/pool-stats/

---

## What it does

pool-stats lets you log every rack you play and gives you real analytics on your game over time. It tracks not just wins and losses, but *why* you're losing — position errors, bad safeties, missed shots by difficulty, fouls, and pattern mistakes. After enough sessions, you'll have a clear picture of what's actually holding you back.

---

## Core features

**Session logging**
- Supports 8-ball and 9-ball, match and practice modes
- Log break details (who broke, balls potted, dry break)
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

**Data privacy**
- All data is stored locally in your browser — nothing is sent anywhere
- Each person who opens the app has their own completely separate data
- Export JSON to back up your data or transfer it to another device

---

## Usage

Just open the link. No install, no login.

- **Dashboard** — your stats and charts
- **Log** — start a new session
- **History** — browse past sessions

To back up your data, tap **Export JSON** on the dashboard or history page. To restore, tap **Import JSON** and select your file.

---

## Tech

Plain HTML, CSS, and JavaScript. No frameworks, no backend. Uses [Chart.js](https://www.chartjs.org/) for charts and `localStorage` for data persistence.
