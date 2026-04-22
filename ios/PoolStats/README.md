# PoolStats iOS

Native SwiftUI iOS app for logging pool matches and practice sessions, syncing through CloudKit, and surfacing actionable stats.

## Current structure
- Custom bottom nav with `Dashboard`, `Log`, `History`, `Goals`, and `Settings`
- Session logging around `Break`, `Layout`, `Unforced errors`, and `Result`
- Log start opponent selector supports typeahead, quick-pick, and inline create
- Goal tracking with custom actions, completion celebration, and reset prompts
- Drill-in Settings sections for `Me`, `Stats`, `Recent form`, `Appearance`, `Data`, and `About`
- First-run onboarding + legacy one-time personalize prompt
- Optional Sign in with Apple account linking in `Settings → Me → Account`

## Open in Xcode
1. Open `ios/PoolStats/PoolStats.xcodeproj` in Xcode.
2. Select the `PoolStats` target.
3. Use `Product → Archive` for TestFlight builds.
4. Use the `App Store Connect` upload flow from Organizer.

## Notes
- CloudKit is the primary sync layer.
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
- Starter goals are generated from profile inputs and marked as `starterGenerated`.
- Regenerating starter goals only replaces `starterGenerated` goals and does not overwrite user-created goals.
