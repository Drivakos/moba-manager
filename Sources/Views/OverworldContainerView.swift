import SwiftUI
import SpriteKit

struct OverworldContainerView: View {
    @Environment(GameState.self) var gameState
    @State private var scene: OverworldScene? = nil
    @State private var rosterFull = false

    var body: some View {
        @Bindable var gs = gameState
        let teamFull = gameState.playerTeam.isFull
        ZStack {
            // SpriteKit game view
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            // Controls overlay
            VStack {
                Spacer()
                GameControlsView(
                    onDirection: { dir in
                        scene?.movePlayer(direction: dir)
                    },
                    onAButton: {
                        // A = confirm / interact (advance dialogue if open)
                        scene?.handleAButton()
                    },
                    onBButton: {
                        // B = cancel / close dialogue
                        scene?.handleBButton()
                    }
                )
            }

            // Menu buttons (top-right)
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Button {
                            gameState.screen = .teamRoster
                        } label: {
                            Text("ROSTER")
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
                        Button {
                            if teamFull {
                                rosterFull = true
                            } else {
                                gameState.openDraft()
                            }
                        } label: {
                            Text("DRAFT")
                                .font(.custom(GB.font, size: 11))
                                .foregroundColor(teamFull ? .gbDark : .gbLightest)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.gbDarkest)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(teamFull ? Color.gbDarkest : Color.gbLight, lineWidth: 1)
                                )
                        }
                        Button {
                            gameState.screen = .saveGame
                        } label: {
                            Text("SAVE")
                                .font(.custom(GB.font, size: 11))
                                .foregroundColor(.gbLight)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.gbDarkest)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.gbDark, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.trailing, 14)
                    .padding(.top, 48)
                }
                Spacer()
            }
        }
        .onAppear {
            let s = OverworldScene(
                size: UIScreen.main.bounds.size,
                gameState: gameState
            )
            s.onEncounterTriggered = { recruit in
                gameState.pendingRecruit = recruit
                gameState.isEncountering = true
            }
            s.onEnterArena = {
                if !gameState.playerTeam.roster.isEmpty {
                    gameState.screen = .tournamentBracket
                }
            }
            s.onEnterHQ = {
                gameState.screen = .training
            }
            self.scene = s
        }
        .onChange(of: gameState.screen) { _, _ in
            scene?.refreshHUD()
        }
        .onChange(of: gameState.isEncountering) { _, encountering in
            if !encountering {
                // Encounter view dismissed — unblock the overworld
                scene?.unblock()
            }
        }
        .fullScreenCover(isPresented: $gs.isEncountering) {
            EncounterView()
                .environment(gameState)
        }
        .fullScreenCover(isPresented: $gs.isDrafting) {
            DraftView()
                .environment(gameState)
        }
        .alert("ROSTER FULL", isPresented: $rosterFull) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Release a player before drafting.")
        }
    }
}
