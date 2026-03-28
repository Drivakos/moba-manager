import SwiftUI

struct MatchSimView: View {
    @Environment(GameState.self) var gameState

    @State private var result: MatchResult? = nil
    @State private var visibleEvents: [MatchEvent] = []
    @State private var done = false
    @State private var screenFlash = false

    // Battle intro states
    @State private var showIntro = true
    @State private var introPhase = 0       // 0=blank 1=player slides in 2=opp slides in 3=flash 4=tactic 5=fadeout
    @State private var playerOffset: CGFloat = -300
    @State private var oppOffset: CGFloat = 300
    @State private var tacticOpacity: Double = 0
    @State private var introOpacity: Double = 1

    private var opponent: Team { gameState.activeOpponent ?? .empty }
    private var tactic: MatchTactic { gameState.selectedTactic }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            if screenFlash {
                Color.gbLightest.ignoresSafeArea().transition(.opacity)
            }

            if showIntro {
                introOverlay
            } else {
                VStack(spacing: 0) {
                    matchHeader
                    if let r = result, done {
                        resultScreen(r)
                    } else {
                        battleLog
                    }
                }
            }
        }
        .onAppear(perform: startIntro)
    }

    // MARK: - Battle Intro Overlay
    var introOverlay: some View {
        ZStack {
            Color.gbDarkest

            VStack(spacing: 20) {
                Spacer()

                // Player team name (slides from left)
                Text(gameState.playerTeam.name.uppercased())
                    .font(.custom(GB.font, size: 22))
                    .foregroundColor(.gbLightest)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 28)
                    .offset(x: playerOffset)

                // VS
                Text("VS")
                    .font(.custom(GB.font, size: 32))
                    .foregroundColor(.gbLight)
                    .scaleEffect(introPhase >= 2 ? 1.0 : 0.4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: introPhase)

                // Opponent name (slides from right)
                Text(opponent.name.uppercased())
                    .font(.custom(GB.font, size: 22))
                    .foregroundColor(.gbLight)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 28)
                    .offset(x: oppOffset)

                Spacer()

                // Tactic banner
                VStack(spacing: 4) {
                    Text("TACTIC: \(tactic.rawValue)")
                        .font(.custom(GB.font, size: 16))
                        .foregroundColor(.gbLightest)
                    Text(tactic.subtitle.uppercased())
                        .font(.custom(GB.fontMono, size: 11))
                        .foregroundColor(.gbLight)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.gbDark)
                .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
                .padding(.horizontal, 28)
                .opacity(tacticOpacity)

                Spacer().frame(height: 60)
            }
        }
        .opacity(introOpacity)
    }

    // MARK: - Match Header
    var matchHeader: some View {
        ZStack {
            Color.gbDark
            HStack {
                Text(gameState.playerTeam.name.uppercased())
                    .font(.custom(GB.font, size: 12))
                    .foregroundColor(.gbLightest)
                Spacer()
                if let r = result {
                    Text("\(r.playerScore) — \(r.opponentScore)")
                        .font(.custom(GB.font, size: 18))
                        .foregroundColor(.gbLightest)
                } else {
                    Text("• • •")
                        .font(.custom(GB.font, size: 14))
                        .foregroundColor(.gbLight)
                }
                Spacer()
                Text(opponent.name.uppercased())
                    .font(.custom(GB.font, size: 12))
                    .foregroundColor(.gbLight)
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 44)
    }

    // MARK: - Battle Log
    var battleLog: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(visibleEvents) { event in
                        EventRowView(event: event).id(event.id)
                    }
                }
                .padding(12)
            }
            .onChange(of: visibleEvents.count) { _, _ in
                if let last = visibleEvents.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Result Screen
    func resultScreen(_ r: MatchResult) -> some View {
        VStack(spacing: 0) {
            ZStack {
                (r.won ? Color.gbDark : Color(red: 0.06, green: 0.10, blue: 0.06))
                VStack(spacing: 6) {
                    Text(r.won ? "VICTORY!" : "DEFEAT")
                        .font(.custom(GB.font, size: 34))
                        .foregroundColor(r.won ? .gbLightest : .gbLight)
                    if let mvp = r.mvpName {
                        Text("MVP: 「\(mvp)」")
                            .font(.custom(GB.fontMono, size: 13))
                            .foregroundColor(.gbLight)
                    }
                    Text(r.won
                         ? "+$\(r.mvpName != nil ? 650 : 500)  +50 XP"
                         : "+$150  +20 XP")
                        .font(.custom(GB.fontMono, size: 11))
                        .foregroundColor(.gbDark)
                }
            }
            .frame(height: 110)

            Divider().background(Color.gbLight)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(r.events) { event in EventRowView(event: event) }
                }
                .padding(12)
            }

            Button {
                let chapterBefore = gameState.chapter
                gameState.recordMatchResult(won: r.won, hasMVP: r.mvpName != nil)
                if r.won { gameState.chapter = min(gameState.chapter + 1, 3) }
                gameState.pendingStoryLines = Story.postChapterDialogue(chapter: chapterBefore, won: r.won)
                gameState.activeOpponent = nil
                gameState.screen = .overworld
            } label: {
                Text("CONTINUE ▶")
                    .font(.custom(GB.font, size: 15))
                    .foregroundColor(.gbLightest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(r.won ? Color.gbDark : Color.gbDarkest)
                    .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Intro Animation
    private func startIntro() {
        // Phase 1 — player name slides in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.35)) {
                introPhase = 1
                playerOffset = 0
            }
        }
        // Phase 2 — opponent slides in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.35)) {
                introPhase = 2
                oppOffset = 0
            }
        }
        // Phase 3 — screen flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.easeIn(duration: 0.08)) { screenFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { screenFlash = false }
            }
        }
        // Phase 4 — tactic banner
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.easeIn(duration: 0.25)) { tacticOpacity = 1 }
        }
        // Phase 5 — fade out intro, start match
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.easeIn(duration: 0.3)) { introOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showIntro = false
                startMatch()
            }
        }
    }

    // MARK: - Match Simulation
    private func startMatch() {
        let r = MatchEngine.simulate(
            player: gameState.playerTeam,
            opponent: opponent,
            tactic: tactic
        )
        result = r

        var delay = 0.2
        for event in r.events {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation { visibleEvents.append(event) }
                if event.isPositive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeIn(duration: 0.07)) { screenFlash = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                            withAnimation { screenFlash = false }
                        }
                    }
                }
            }
            delay += 0.65
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.4) {
            withAnimation { done = true }
        }
    }
}

// MARK: - Event Row
struct EventRowView: View {
    let event: MatchEvent

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(event.isPositive ? "▶" : "✕")
                .font(.custom(GB.font, size: 10))
                .foregroundColor(event.isPositive ? .gbLightest : .gbDark)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 1) {
                Text("[\(event.phase.rawValue)]")
                    .font(.custom(GB.font, size: 9))
                    .foregroundColor(.gbDark)
                Text(event.text)
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(event.isPositive ? .gbLightest : .gbLight)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gbDark.opacity(event.isPositive ? 0.6 : 0.3))
        .overlay(Rectangle().stroke(event.isPositive ? Color.gbLight : Color.gbDarkest, lineWidth: 1))
    }
}
