# PoolStats iOS

Native SwiftUI iOS app for logging pool matches and practice sessions, syncing through CloudKit, and surfacing actionable stats.

## Current structure
- Custom bottom nav with `Dashboard`, `Log`, `History`, `Goals`, and `Settings`
- Session logging around `Break`, `Layout`, `Unforced errors`, and `Result`
- Goal tracking with custom actions, completion celebration, and reset prompts
- Drill-in Settings sections for `Me`, `Stats`, `Recent form`, `Appearance`, `Data`, and `About`

## Open in Xcode
1. Open `ios/PoolStats/PoolStats.xcodeproj` in Xcode.
2. Select the `PoolStats` target.
3. Use `Product → Archive` for TestFlight builds.
4. Use the `App Store Connect` upload flow from Organizer.

## Notes
- CloudKit is the primary sync layer.
- A local JSON cache in Application Support keeps sessions safe if sync is delayed.
- Sign in with Apple is a future enhancement, not required today.
