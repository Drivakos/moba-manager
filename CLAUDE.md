# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This project uses **xcodegen** to generate the `.xcodeproj` from `project.yml`. Run this after adding or removing source files.

```bash
# Regenerate Xcode project (required after adding/removing files)
xcodegen generate

# Build
xcodebuild -project mobaManager.xcodeproj -scheme mobaManager \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Open in Xcode
open mobaManager.xcodeproj
```

There are no automated tests. Verification is done by building and running on the simulator.

## Commit Style

Use **Angular commit messages**:
```
feat(scope): short description
fix(scope): short description
refactor(scope): short description
chore(scope): short description
```
Common scopes: `overworld`, `match`, `draft`, `roster`, `save`, `story`, `ui`.

## Architecture

### SwiftUI + SpriteKit hybrid

The app is a **SwiftUI shell around a SpriteKit overworld**. All menus, cards, and HUD screens are SwiftUI views. The tile-based overworld map and player movement live in `OverworldScene` (SpriteKit). The two are bridged via callback closures set on the scene from `OverworldContainerView`.

### State machine navigation

`GameState` (`@Observable`) owns a single `screen: AppScreen` enum that drives the entire app. `RootView` in `mobaManagerApp.swift` switches on this value to render the correct full-screen view. There is no NavigationStack — every transition is a direct `gameState.screen = .xxx` assignment.

Modal flows (encounter, draft) are presented as `fullScreenCover` driven by boolean flags on `GameState` (`isEncountering`, `isDrafting`), bound via `@Bindable` in `OverworldContainerView`. Coach hire is a `sheet` inside `TeamRosterView`.

### Data model ownership

`GameState` owns `playerTeam: Team` which contains the full `[Player]` roster and optional `Coach`. All game logic methods live on `GameState` — views call methods, never mutate model structs directly.

`MatchEngine` is a stateless struct with a single static `simulate(player:opponent:tactic:)` entry point. Coach bonuses are applied inside `phasePower()`.

`SaveManager` is a stateless enum that encodes/decodes `SaveSlot` (which embeds `SaveData`) to `UserDefaults`. Auto-save is triggered from `GameState.recruit()` and `GameState.recordMatchResult()`.

### SpriteKit ↔ SwiftUI bridge

`OverworldScene` exposes three callbacks:
- `onEncounterTriggered(Player)` → sets `isEncountering = true`
- `onEnterArena()` → navigates to `.tournamentBracket`
- `onEnterHQ()` → navigates to `.training`

After a modal dismisses, `OverworldContainerView.onChange(isEncountering)` calls `scene.unblock()` to resume player movement.

Dialogue is handled entirely inside SpriteKit via `DialogueBoxNode`. Tapping the screen or pressing A/B calls `dialogueBox.advance()` — which either skips typing or fires the stored completion closure. The completion is stored at the **start** of `show()`, not inside the SKAction sequence, to survive `skipTyping()`.

### Map & encounter zones

`MapData` holds a hardcoded 16×16 `Int` grid. Special tiles (`hq=2`, `cafe=3`, `training=4`, `arena=5`) trigger actions on player collision in `OverworldScene.movePlayer()`. Encounter chance: training = 75%, cafe = 65%.

Player spawn: `col=1, row=1`. Training is 4 steps right. HQ is at `col=2-3, row=2-3`. Arena is at `col=12-13, row=9-10`.

### GB visual system

All colours come from the 4-colour GameBoy palette defined in `Constants.swift` as `Color` extensions (SwiftUI) and `SKColor` extensions (SpriteKit): `gbDarkest / gbDark / gbLight / gbLightest`. Font is always `Courier-Bold` (heading) or `Courier` (body) via `GB.font` / `GB.fontMono`. Never use system fonts or colours outside this palette.

### Draft vs. encounter

- **Random encounter**: triggered by walking over `cafe`/`training` tiles. Shows a single `EncounterView` with one candidate.
- **Draft**: triggered by the DRAFT overworld button. `GameState.openDraft()` generates 3 candidates, prioritising roles missing from the roster. Shows `DraftView`.
- Both flows recruit via `GameState.recruit(_:)` which auto-saves.
