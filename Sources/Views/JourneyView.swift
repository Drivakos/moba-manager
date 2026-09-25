import SwiftUI

// MARK: - Journey View
// The game's objective, in plain terms, plus optional detours and a way out.
struct JourneyView: View {
    @Environment(GameState.self) var gameState
    @State private var confirmQuit = false

    private var chapter: Int { min(gameState.chapter, GameState.finalChapter) }
    private var chapterTitle: String {
        switch chapter {
        case 1: return "ROOKIE LEAGUE"
        case 2: return "PRO CIRCUIT"
        default: return "GRAND FINALS"
        }
    }
    private var objective: String {
        switch chapter {
        case 1: return "Finish TOP 2 in the amateur league to reach the Pro Circuit."
        case 2: return "Finish TOP 2 again to earn a place in the Grand Finals."
        default: return "Finish TOP 2 to be crowned Amateur League champion."
        }
    }
    private var bossAvailable: Bool {
        gameState.chapter >= 2 && !gameState.hasFlag("boss_\(gameState.chapter)_done")
    }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                GBScreenHeader(title: "The Journey", subtitle: "Season Roadmap")

                ScrollView {
                    VStack(spacing: 12) {
                        objectiveCard
                        chapterTrack
                        if bossAvailable { bossCard }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                }

                quitButton
                GBBackButton { gameState.screen = .overworld }
            }
        }
        .alert("QUIT YOUR CLUB?", isPresented: $confirmQuit) {
            Button("Cancel", role: .cancel) {}
            Button("QUIT", role: .destructive) { quit() }
        } message: {
            Text("Your career will be erased. This cannot be undone.")
        }
    }

    // MARK: - Objective
    var objectiveCard: some View {
        VStack(spacing: 0) {
            GBSectionLabel(text: "Objective")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("CHAPTER \(chapter)  ·  \(chapterTitle)")
                        .font(.custom(GB.font, size: 13))
                        .foregroundColor(.gbLightest)
                    Spacer()
                    Text("SEASON \(gameState.league.season)")
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbLight)
                }

                Text(objective)
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbLight)
                    .fixedSize(horizontal: false, vertical: true)

                // Progress toward qualification
                let rank = gameState.league.playerRank(
                    playerWins: gameState.seasonWins,
                    playerLosses: gameState.seasonLosses
                )
                let played = gameState.league.matchday
                let total = gameState.league.teams.count

                HStack(spacing: 10) {
                    progressPill("RANK", "#\(rank)", rank <= 2 ? .gbLightest : .gbLight)
                    progressPill("PLAYED", "\(played)/\(total)", .gbLight)
                    progressPill("RECORD", "\(gameState.seasonWins)W \(gameState.seasonLosses)L", .gbLight)
                }
                .padding(.top, 2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    func progressPill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom(GB.font, size: 13))
                .foregroundColor(color)
            Text(label)
                .font(.custom(GB.fontMono, size: 8))
                .foregroundColor(.gbDark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.gbDark.opacity(0.5))
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Chapter Track
    var chapterTrack: some View {
        VStack(spacing: 0) {
            GBSectionLabel(text: "Roadmap")
            ForEach(1...GameState.finalChapter, id: \.self) { step in
                HStack(spacing: 10) {
                    ZStack {
                        Rectangle()
                            .fill(step <= gameState.chapter ? Color.gbLight : Color.gbDarkest)
                            .frame(width: 26, height: 26)
                        Text("\(step)")
                            .font(.custom(GB.font, size: 12))
                            .foregroundColor(step <= gameState.chapter ? .gbDarkest : .gbDark)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(chapterName(step))
                            .font(.custom(GB.font, size: 11))
                            .foregroundColor(step <= gameState.chapter ? .gbLightest : .gbDark)
                        Text(step < GameState.finalChapter ? "Top 2 to advance" : "Top 2 to win it all")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                    }
                    Spacer()
                    if step < gameState.chapter {
                        Text("DONE")
                            .font(.custom(GB.font, size: 9))
                            .foregroundColor(.gbLight)
                    } else if step == gameState.chapter {
                        Text("NOW")
                            .font(.custom(GB.font, size: 9))
                            .foregroundColor(.gbLightest)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(step == gameState.chapter ? Color.gbDark : Color.gbDarkest)
                .overlay(Rectangle().stroke(Color.gbDarkest.opacity(0.5), lineWidth: 0.5))
            }
        }
        .background(Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    private func chapterName(_ step: Int) -> String {
        switch step {
        case 1: return "ROOKIE LEAGUE"
        case 2: return "PRO CIRCUIT"
        default: return "GRAND FINALS"
        }
    }

    // MARK: - Optional Boss
    var bossCard: some View {
        VStack(spacing: 0) {
            GBSectionLabel(text: "Optional Challenge")
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("TAKE ON AXIOM ELITE")
                        .font(.custom(GB.font, size: 12))
                        .foregroundColor(.gbLightest)
                    Spacer()
                    Text("+$15,000")
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbLight)
                }
                Text("A stronger squad, outside the league. A win pays a big bonus and does not affect the table.")
                    .font(.custom(GB.fontMono, size: 10))
                    .foregroundColor(.gbDark)
                    .fixedSize(horizontal: false, vertical: true)

                GBPrimaryButton(label: "CHALLENGE AXIOM  ▶") {
                    gameState.startBossMatch()
                }
            }
            .padding(12)
        }
        .background(Color.gbDarkest)
        .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
    }

    // MARK: - Quit
    var quitButton: some View {
        Button {
            confirmQuit = true
        } label: {
            Text("ABANDON CLUB  ✕")
                .font(.custom(GB.font, size: 12))
                .foregroundColor(.gbLight)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.gbDarkest)
                .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private func quit() {
        SaveManager.delete(slot: SaveManager.lastUsedSlot)
        FranchiseStore.delete()
        gameState.pendingChapterResult = nil
        gameState.screen = .title
    }
}
