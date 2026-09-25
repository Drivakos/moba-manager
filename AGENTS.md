# AGENTS.md

Repository-specific notes for agents working on `mobaManager`.

## Build & Run

The project is generated from `project.yml` with **xcodegen**; rerun it after
adding or removing source files:

```bash
xcodegen generate
```

The real build is `xcodebuild` on an iOS simulator (see `CLAUDE.md`).

### Headless Swift on Linux (simulator not available)

The game logic in `Sources/Models`, `Sources/Core`, and `Sources/Views` is pure
Swift, so it can be compiled and exercised headlessly against the Linux Swift
toolchain instead of booting a simulator. This is how the core systems are
verified in CI-less environments.

```bash
export PATH=$HOME/swift/usr/bin:$PATH
export LD_LIBRARY_PATH=$HOME/liblink      # symlinks libncurses.so.6 for the toolchain
swiftc -swift-version 5 -o /tmp/harness/run \
  Sources/Models/*.swift Sources/Core/GameState.swift \
  Sources/Core/SaveManager.swift Sources/Core/FranchiseStore.swift \
  /tmp/harness/main.swift
```

Notes:
- `swiftc` must not be invoked through a pipe that consumes its exit status
  (e.g. `swiftc ... 2>&1 | head` followed by `&&`): the pipeline's status is the
  status of `head`, so a failed compile silently runs a stale binary. Redirect to
  a file and check `$?` instead.
- SwiftUI/SpriteKit views cannot be compiled on Linux; the harness imports only
  the model and core files.

## Verification Harness

`Sources/**` has no XCTest target. Core systems are checked with a headless
harness that drives `GameState`/`MatchEngine` directly:

- Squad construction, AI squad legality, and league strength ordering.
- Best-of-three series invariants (score is always 2-0 or 2-1).
- Difficulty ramp per chapter and win rates for the starting five.
- Season record reset on advancement, boss matches staying exhibition-only.
- Economy ledger, training costs/gains, and save/load round trips.

Keep the harness in sync when changing match, league, economy, or save logic.

## Domain Rules That Are Easy To Get Wrong

- **Two records exist.** `playerTeam.wins/losses` is the lifetime franchise
  record (shown on the roster screen). `seasonWins/seasonLosses` is the current
  league season and is what standings, `playerRank`, and qualification use.
  Reset the season record whenever a league is regenerated.
- **Boss matches are exhibition games.** They pay a bonus, count double toward
  lifetime reputation, and set a story flag, but they must not advance
  `league.matchday` or affect the season record.
- **League strength is derived, not stored.** `AmateurLeague.generate(chapter:
  referenceOverall:)` builds each team's advertised `averageOverall`; the actual
  battle lineup is built by `Team.leagueOpponent(...)`, which may add a coach.
  Always measure balance through `leagueOpponent`, never through
  `LeagueTeam.averageOverall`.
- **AI squads are assigned by strength rank.** `PlayerDatabase.assignSquads`
  pairs ranked teams with ranked free agents per role. A greedy
  nearest-to-target assignment previously let early teams claim the players the
  strongest team needed, producing a non-monotonic league.
- **The match plays all three phases.** Cap `gamesWon`/`gamesLost` at
  `MatchResult.gamesToWin` and award a tiebreak for drawn phases so the score is
  never level and never a 3-0 sweep.

## Style

- GB palette only: `Color.gbDarkest / gbDark / gbLight / gbLightest` (and the
  `SKColor` equivalents). Fonts are `GB.font` / `GB.fontMono`. See `CLAUDE.md`.
- Commits use Angular-style messages (`feat(scope): ...`); common scopes are
  `overworld`, `match`, `draft`, `roster`, `save`, `story`, `ui`.
