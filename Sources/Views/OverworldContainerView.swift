import SwiftUI
import SpriteKit

struct OverworldContainerView: View {
    @Environment(GameState.self) var gameState
    @State private var scene: OverworldScene? = nil

    var body: some View {
        ZStack {
            // SpriteKit game view
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            // D-pad controls
            VStack {
                Spacer()
                GameControlsView(
                    onDirection: { dir in scene?.movePlayer(direction: dir) },
                    onAButton:   { scene?.handleAButton() },
                    onBButton:   { scene?.handleBButton() }
                )
            }

            // Menu buttons (top-right)
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        menuButton("JOURNEY") { gameState.screen = .journey }
                        menuButton("ROSTER")  { gameState.screen = .teamRoster }
                        menuButton("MARKET")  { gameState.screen = .transferMarket }
                        menuButton("LEAGUE")  { gameState.screen = .tournamentBracket }
                        menuButton("BUDGET")  { gameState.screen = .finances }
                        menuButton("SAVE")    { gameState.screen = .saveGame }
                    }
                    .padding(.trailing, 14)
                    .padding(.top, 48)
                }
                Spacer()
            }
        }
        .onAppear {
            // Guard against SwiftUI re-running onAppear, which would swap in a
            // second OverworldScene and reset the player to spawn.
            guard scene == nil else { return }
            let s = OverworldScene(size: UIScreen.main.bounds.size, gameState: gameState)
            s.onEnterArena = {
                gameState.screen = .tournamentBracket
            }
            s.onEnterHQ = {
                gameState.screen = .training
            }
            s.onStoryComplete = { [weak scene] in
                _ = scene
                if gameState.pendingChapterResult != nil {
                    gameState.screen = .gameOver
                }
            }
            self.scene = s
        }
        .onChange(of: gameState.pendingChapterResult) { _, result in
            guard result != nil else { return }
            // If a wrap-up dialogue is queued the overworld will play it first and
            // hand off via onStoryComplete; otherwise go straight to the summary.
            if (scene?.hasQueuedStory ?? false) == false {
                gameState.screen = .gameOver
            }
        }
    }

    private func menuButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom(GB.font, size: 11))
                .foregroundColor(.gbLightest)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gbDarkest.opacity(0.92))
                .overlay(
                    ZStack {
                        Rectangle().stroke(Color.gbLight, lineWidth: 1)
                        GBCornerBorder(color: .gbDark, lineWidth: 1, cornerSize: 5)
                    }
                )
        }
        .buttonStyle(.plain)
    }
}
