import SwiftUI

@main
struct mobaManagerApp: App {
    @State private var gameState = GameState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(gameState)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @Environment(GameState.self) var gameState

    var body: some View {
        Group {
            switch gameState.screen {
            case .title:
                TitleView()
            case .teamSetup:
                TeamSetupView()
            case .overworld:
                OverworldContainerView()
            case .teamRoster:
                TeamRosterView()
            case .training:
                TrainingView()
            case .tactics:
                TacticsView()
            case .tournamentBracket:
                TournamentBracketView()
            case .matchSim:
                MatchSimView()
            case .encounter:
                OverworldContainerView()
            case .pauseMenu:
                OverworldContainerView()
            case .loadGame:
                SaveLoadView(mode: .load)
            case .saveGame:
                SaveLoadView(mode: .save)
            }
        }
    }
}
