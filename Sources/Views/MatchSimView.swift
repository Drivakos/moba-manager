import SwiftUI
import SpriteKit

struct MatchSimView: View {
    @Environment(GameState.self) var gameState

    @State private var result: MatchResult? = nil
    @State private var visibleEvents: [MatchEvent] = []
    @State private var done = false
    @State private var screenFlash = false
    @State private var mapScene: MatchMapScene? = nil
    @State private var currentPhaseLabel: String = ""

    // Battle intro
    @State private var showIntro = true
    @State private var playerOffset: CGFloat = -300
    @State private var oppOffset: CGFloat    =  300
    @State private var tacticOpacity: Double = 0
    @State private var introOpacity: Double  = 1

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

                    // Map
                    ZStack(alignment: .bottom) {
                        if let scene = mapScene {
                            SpriteView(scene: scene, options: [.allowsTransparency])
                                .frame(height: 260)
                                .background(Color.gbDarkest)
                        }
                        if !currentPhaseLabel.isEmpty {
                            Text(currentPhaseLabel)
                                .font(.custom(GB.font, size: 11))
                                .foregroundColor(.gbLightest)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gbDarkest.opacity(0.85))
                                .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
                                .padding(.bottom, 6)
                        }
                    }

                    Divider().background(Color.gbDark)

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

    // MARK: - Intro Overlay
    var introOverlay: some View {
        ZStack {
            Color.gbDarkest
            VStack(spacing: 20) {
                Spacer()
                Text(gameState.playerTeam.name.uppercased())
                    .font(.custom(GB.font, size: 22))
                    .foregroundColor(.gbLightest)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 28)
                    .offset(x: playerOffset)

                Text("VS")
                    .font(.custom(GB.font, size: 32))
                    .foregroundColor(.gbLight)

                Text(opponent.name.uppercased())
                    .font(.custom(GB.font, size: 22))
                    .foregroundColor(.gbLight)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 28)
                    .offset(x: oppOffset)

                Spacer()

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
                (r.won ? Color.gbDark : Color(red: 0.04, green: 0.09, blue: 0.04))

                // Scanlines over result banner
                GBScanlineView(opacity: 0.12)

                VStack(spacing: 0) {
                    // Decorative top stripe
                    Rectangle()
                        .fill(r.won ? Color.gbLightest : Color.gbDark)
                        .frame(height: 3)

                    Spacer()

                    // Big result text
                    VStack(spacing: 5) {
                        Text(r.won ? "VICTORY!" : "DEFEAT")
                            .font(.custom(GB.font, size: 40))
                            .foregroundColor(r.won ? .gbLightest : .gbLight)
                            .shadow(color: r.won ? .gbDarkest : .black, radius: 0, x: 3, y: 3)
                            .overlay(
                                GBCornerBorder(color: r.won ? .gbLightest.opacity(0.3) : .gbDark.opacity(0.3), lineWidth: 1, cornerSize: 8)
                                    .padding(-8)
                            )

                        if let mvp = r.mvpName {
                            Text("MVP  ·  「\(mvp)」")
                                .font(.custom(GB.fontMono, size: 12))
                                .foregroundColor(.gbLight)
                                .padding(.top, 4)
                        }

                        HStack(spacing: 16) {
                            Label(r.won ? "+$5,000" : "+$1,500", systemImage: "dollarsign")
                            Label(r.won ? "+50 XP" : "+20 XP", systemImage: "bolt.fill")
                        }
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbDark)
                        .padding(.top, 2)
                        .labelStyle(.titleAndIcon)
                    }

                    Spacer()

                    // Score display
                    HStack(spacing: 0) {
                        Text(gameState.playerTeam.name.uppercased())
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbLight)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 10)
                        Text("\(r.playerScore) — \(r.opponentScore)")
                            .font(.custom(GB.font, size: 20))
                            .foregroundColor(.gbLightest)
                        Text(opponent.name.uppercased())
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 10)
                    }
                    .padding(.bottom, 8)
                }
            }
            .frame(height: 130)

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
                gameState.pendingStoryLines = Story.postChapterDialogue(chapter: chapterBefore, won: r.won)
                gameState.activeOpponent = nil
                gameState.screen = .overworld
            } label: {
                Text("CONTINUE  ▶")
                    .font(.custom(GB.font, size: 15))
                    .foregroundColor(.gbLightest)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(r.won ? Color.gbDark : Color.gbDarkest)
                    .overlay(
                        ZStack {
                            Rectangle().stroke(Color.gbLight, lineWidth: 2)
                            GBCornerBorder(color: .gbLight, lineWidth: 1, cornerSize: 8)
                        }
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Intro Animation
    private func startIntro() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.35)) { playerOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.35)) { oppOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.easeIn(duration: 0.08)) { screenFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation { screenFlash = false }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.easeIn(duration: 0.25)) { tacticOpacity = 1 }
        }
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
        // Build and configure the map scene
        let scene = MatchMapScene(size: CGSize(width: 320, height: 260))
        scene.configure(playerTeam: gameState.playerTeam, opponent: opponent)
        mapScene = scene

        // Simulate
        let r = MatchEngine.simulate(player: gameState.playerTeam, opponent: opponent, tactic: tactic)
        result = r

        let phases: [MatchPhase] = MatchPhase.allCases
        let eventGroups = Dictionary(grouping: r.events, by: \.phase)
        let phaseWins = r.phaseResults  // [early, mid, late]

        var phaseStart = 0.4  // start first phase slightly after map appears

        for (idx, phase) in phases.enumerated() {
            let phaseName = phase.rawValue
            let events    = eventGroups[phase] ?? []
            let playerWon = idx < phaseWins.count ? phaseWins[idx] : false
            let t         = phaseStart

            // Show phase label
            DispatchQueue.main.asyncAfter(deadline: .now() + t - 0.1) {
                withAnimation { currentPhaseLabel = "▶ \(phaseName)" }
            }

            // Fire map animation
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                scene.animatePhase(phase, playerWon: playerWon, events: events) {}
            }

            // Reveal events in log
            for (ei, event) in events.enumerated() {
                let evtDelay = t + Double(ei) * 0.72
                DispatchQueue.main.asyncAfter(deadline: .now() + evtDelay) {
                    withAnimation { visibleEvents.append(event) }
                    if event.isPositive { flashScreen() }
                }
            }

            // Per-phase duration: 0.5s move + events * 0.72 + 0.6s resolve gap
            phaseStart += 0.5 + Double(events.count) * 0.72 + 0.8
        }

        // Victory animation + result reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + phaseStart) {
            withAnimation { currentPhaseLabel = "" }
            scene.animateVictory(playerWon: r.won)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation { done = true }
            }
        }
    }

    private func flashScreen() {
        withAnimation(.easeIn(duration: 0.07)) { screenFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation { screenFlash = false }
        }
    }
}

// MARK: - Event Row
struct EventRowView: View {
    let event: MatchEvent

    var body: some View {
        HStack(spacing: 0) {
            // Colored left accent
            Rectangle()
                .fill(event.isPositive ? Color.gbLightest : Color.gbDark)
                .frame(width: 3)

            HStack(alignment: .top, spacing: 8) {
                Text(event.isPositive ? "▶" : "✕")
                    .font(.custom(GB.font, size: 9))
                    .foregroundColor(event.isPositive ? .gbLightest : .gbDark)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.phase.rawValue.uppercased())
                        .font(.custom(GB.font, size: 8))
                        .foregroundColor(.gbDark)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.gbDarkest)
                    Text(event.text)
                        .font(.custom(GB.fontMono, size: 11))
                        .foregroundColor(event.isPositive ? .gbLightest : .gbLight)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
        }
        .background(Color.gbDarkest.opacity(event.isPositive ? 0.0 : 0.4))
        .background(Color.gbDark.opacity(event.isPositive ? 0.5 : 0.15))
        .overlay(Rectangle().stroke(event.isPositive ? Color.gbDark : Color.gbDarkest, lineWidth: 1))
    }
}
