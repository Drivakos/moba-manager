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
            let s = OverworldScene(size: UIScreen.main.bounds.size, gameState: gameState)
            s.onEnterArena = {
                gameState.screen = .tournamentBracket
            }
            s.onEnterHQ = {
                gameState.screen = .training
            }
            self.scene = s
        }
        .onChange(of: gameState.screen) { _, _ in
            scene?.refreshHUD()
        }
    }

    private func menuButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom(GB.font, size: 11))
                .foregroundColor(.gbLightest)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.gbDarkest)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gbLight, lineWidth: 1)
                )
        }
    }
}
