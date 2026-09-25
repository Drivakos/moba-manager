import SwiftUI

// MARK: - Game Over / Career Complete
// Shown once the Grand Final resolves. Presents the final record and lets the
// player start a fresh career without leaving the app.
struct GameOverView: View {
    @Environment(GameState.self) var gameState
    @State private var appeared = false

    private var champion: Bool { gameState.pendingChapterResult == .champion }
    private var team: Team { gameState.playerTeam }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()
            GBScanlineView(opacity: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 10) {
                    Text(champion ? "CHAMPIONS" : "SEASON OVER")
                        .font(.custom(GB.font, size: 34))
                        .foregroundColor(champion ? .gbLightest : .gbLight)
                        .shadow(color: .gbDark, radius: 0, x: 3, y: 3)

                    Text(champion
                         ? "\(team.name) lift the Amateur League trophy."
                         : "\(team.name) fall short of the Grand Final.")
                        .font(.custom(GB.fontMono, size: 11))
                        .foregroundColor(.gbLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer().frame(height: 26)

                summaryCard
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 22)

                ButtonsView
                Spacer()

                Text("THANKS FOR PLAYING")
                    .font(.custom(GB.fontMono, size: 9))
                    .foregroundColor(.gbDark)
                    .padding(.bottom, 18)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    // MARK: - Summary
    var summaryCard: some View {
        VStack(spacing: 0) {
            GBSectionLabel(text: "Career Summary")

            summaryRow("FINAL RECORD", "\(team.wins)W  \(team.losses)L")
            summaryRow("CHAPTERS", "\(min(gameState.chapter - 1, GameState.finalChapter)) / \(GameState.finalChapter)")
            summaryRow("FUNDS", "$\(gameState.funds)")
            summaryRow("COACH", team.coach?.name.uppercased() ?? "NONE")
            summaryRow("MVP", team.roster.max { $0.stats.overall < $1.stats.overall }?.tag ?? "—")
        }
        .background(Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbDark)
            Spacer()
            Text(value)
                .font(.custom(GB.font, size: 12))
                .foregroundColor(.gbLightest)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbDarkest.opacity(0.6), lineWidth: 0.5))
    }

    // MARK: - Buttons
    var ButtonsView: some View {
        VStack(spacing: 10) {
            GBPrimaryButton(label: "NEW CAREER  ▶") {
                startNewCareer()
            }
            .padding(.horizontal, 20)

            GBBackButton(label: "◈  TITLE SCREEN") {
                gameState.screen = .title
            }
        }
    }

    private func startNewCareer() {
        SaveManager.delete(slot: SaveManager.lastUsedSlot)
        FranchiseStore.delete()
        gameState.playerTeam = .empty
        gameState.chapter = 1
        gameState.storyFlags = []
        gameState.playerPosition = TilePosition(col: 1, row: 1)
        gameState.managerName = "COACH"
        gameState.funds = 25_000
        gameState.league = AmateurLeague.generate(chapter: 1, referenceOverall: 0)
        gameState.playerDatabase = PlayerDatabase.generate()
        gameState.ledger = []
        gameState.pendingChapterResult = nil
        gameState.pendingStoryLines = []
        gameState.activeOpponent = nil
        gameState.seasonWins = 0
        gameState.seasonLosses = 0
        gameState.screen = .teamSetup
    }
}
