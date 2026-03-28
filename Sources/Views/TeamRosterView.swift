import SwiftUI

struct TeamRosterView: View {
    @Environment(GameState.self) var gameState
    @State private var selectedPlayer: Player? = nil
    @State private var showCoachHire = false

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerBar

                ScrollView {
                    VStack(spacing: 2) {
                        // Coach slot
                        coachSlot
                            .padding(.horizontal, 12)
                            .padding(.top, 8)

                        Divider().background(Color.gbDark).padding(.horizontal, 12)

                        if gameState.playerTeam.roster.isEmpty {
                            emptyState
                        } else {
                            ForEach(gameState.playerTeam.roster) { player in
                                PlayerRowView(player: player)
                                    .onTapGesture { selectedPlayer = player }
                            }
                            .padding(.horizontal, 12)
                        }

                        // Empty slots
                        let empty = 5 - gameState.playerTeam.roster.count
                        ForEach(0..<empty, id: \.self) { _ in
                            EmptySlotView()
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.top, 0)
                }

                // Team stats footer
                if !gameState.playerTeam.roster.isEmpty {
                    teamStatsFooter
                }

                GBBackButton { gameState.screen = .overworld }
            }
        }
        .sheet(item: $selectedPlayer) { player in
            PlayerDetailView(player: player)
                .environment(gameState)
        }
        .sheet(isPresented: $showCoachHire) {
            CoachHireView()
                .environment(gameState)
        }
    }

    // MARK: - Coach Slot
    @ViewBuilder
    var coachSlot: some View {
        if let coach = gameState.playerTeam.coach {
            CoachRowView(coach: coach) {
                gameState.fireCoach()
            }
        } else {
            Button {
                gameState.openCoachHire()
                showCoachHire = true
            } label: {
                HStack {
                    Text("COACH")
                        .font(.custom(GB.font, size: 10))
                        .foregroundColor(.gbDarkest)
                        .frame(width: 44, height: 22)
                        .background(Color.gbDark)

                    Text("── NO COACH HIRED ──")
                        .font(.custom(GB.fontMono, size: 12))
                        .foregroundColor(.gbDark)

                    Spacer()

                    Text("HIRE ▶")
                        .font(.custom(GB.font, size: 11))
                        .foregroundColor(.gbLightest)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gbDarkest)
                        .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gbDarkest)
                .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark
            // Subtle pixel-grid texture rows
            VStack(spacing: 8) {
                Rectangle().fill(Color.gbDarkest.opacity(0.3)).frame(height: 1)
                Rectangle().fill(Color.gbDarkest.opacity(0.3)).frame(height: 1)
            }

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    // Team icon block
                    Rectangle()
                        .fill(Color.gbDarkest)
                        .frame(width: 6, height: 20)
                    Text(gameState.playerTeam.name.uppercased())
                        .font(.custom(GB.font, size: 15))
                        .foregroundColor(.gbLightest)
                    Rectangle()
                        .fill(Color.gbDarkest)
                        .frame(width: 6, height: 20)
                }

                HStack(spacing: 14) {
                    statPill("W", "\(gameState.playerTeam.wins)", .gbLightest)
                    statPill("L", "\(gameState.playerTeam.losses)", .gbLight)
                    statPill("OVR", "\(gameState.playerTeam.averageOverall)", .gbLight)
                }
            }
        }
        .frame(height: 60)
    }

    func statPill(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.custom(GB.fontMono, size: 9))
                .foregroundColor(.gbDark)
            Text(value)
                .font(.custom(GB.font, size: 12))
                .foregroundColor(color)
        }
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 12) {
            Text("NO PLAYERS YET")
                .font(.custom(GB.font, size: 14))
                .foregroundColor(.gbDark)
            Text("Walk into the Training Grounds\nor Gaming Cafes to find recruits.")
                .font(.custom(GB.fontMono, size: 11))
                .foregroundColor(.gbDark)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Footer
    var teamStatsFooter: some View {
        VStack(spacing: 4) {
            Divider().background(Color.gbDark)
            HStack {
                Text("SYNERGY BONUS")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbLight)
                Spacer()
                Text("+\(gameState.playerTeam.synergyBonus)")
                    .font(.custom(GB.font, size: 12))
                    .foregroundColor(.gbLightest)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
        .background(Color.gbDarkest)
    }
}

// MARK: - Coach Row
struct CoachRowView: View {
    let coach: Coach
    let onFire: () -> Void
    @State private var confirmFire = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("COACH")
                    .font(.custom(GB.font, size: 9))
                    .foregroundColor(.gbDarkest)
                    .frame(width: 44, height: 22)
                    .background(Color.gbLight)

                VStack(alignment: .leading, spacing: 2) {
                    Text(coach.name.uppercased())
                        .font(.custom(GB.font, size: 12))
                        .foregroundColor(.gbLightest)
                    Text("「\(coach.tag)」· \(coach.style.rawValue)")
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbLight)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("OVR \(coach.stats.overall)")
                        .font(.custom(GB.font, size: 12))
                        .foregroundColor(.gbLightest)
                    Text(coach.style.subtitle.uppercased())
                        .font(.custom(GB.fontMono, size: 8))
                        .foregroundColor(.gbDark)
                        .multilineTextAlignment(.trailing)
                }

                Button {
                    confirmFire = true
                } label: {
                    Text("✕")
                        .font(.custom(GB.font, size: 11))
                        .foregroundColor(.gbDark)
                        .frame(width: 26, height: 26)
                        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.gbDark)
            .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
        }
        .alert("FIRE COACH?", isPresented: $confirmFire) {
            Button("Cancel", role: .cancel) {}
            Button("Fire", role: .destructive) { onFire() }
        } message: {
            Text("This cannot be undone.")
        }
    }
}

// MARK: - Player Row
struct PlayerRowView: View {
    let player: Player

    private var roleAccent: Color {
        switch player.role {
        case .carry:    return .gbLightest
        case .support:  return .gbLight
        case .jungler:  return .gbDark
        case .mid:      return .gbLightest
        case .offlaner: return .gbLight
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Role color accent strip
            Rectangle()
                .fill(roleAccent)
                .frame(width: 4)

            HStack(spacing: 10) {
                // Role badge
                Text(player.role.abbreviation)
                    .font(.custom(GB.font, size: 10))
                    .foregroundColor(.gbDarkest)
                    .frame(width: 36, height: 22)
                    .background(roleAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name.uppercased())
                        .font(.custom(GB.font, size: 12))
                        .foregroundColor(.gbLightest)
                    HStack(spacing: 6) {
                        Text("「\(player.tag)」")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbLight)
                        Text(player.personality.rawValue.uppercased())
                            .font(.custom(GB.fontMono, size: 8))
                            .foregroundColor(.gbDark)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("OVR \(player.stats.overall)")
                        .font(.custom(GB.font, size: 13))
                        .foregroundColor(.gbLightest)
                    Text(player.starDisplay)
                        .font(.system(size: 8))
                        .foregroundColor(.gbLight)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
        }
        .background(Color.gbDark)
        .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 1))
    }
}

// MARK: - Empty Slot
struct EmptySlotView: View {
    var body: some View {
        HStack(spacing: 10) {
            // Dashed accent strip
            Rectangle()
                .fill(Color.gbDarkest)
                .frame(width: 4)
            HStack {
                Text("·  ·  ·")
                    .font(.custom(GB.fontMono, size: 10))
                    .foregroundColor(.gbDarkest)
                Text("EMPTY SLOT")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbDark)
                Spacer()
                Text("[ RECRUIT ]")
                    .font(.custom(GB.fontMono, size: 9))
                    .foregroundColor(.gbDarkest)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 11)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gbDarkest.opacity(0.5))
        .overlay(
            Rectangle().stroke(Color.gbDarkest.opacity(0.6), lineWidth: 1)
                .overlay(Rectangle().stroke(Color.gbDark.opacity(0.15), lineWidth: 0.5).padding(2))
        )
    }
}

// MARK: - Player Detail
struct PlayerDetailView: View {
    @Environment(GameState.self) var gameState
    @Environment(\.dismiss) var dismiss
    let player: Player

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    Color.gbDark
                    Text(player.name.uppercased())
                        .font(.custom(GB.font, size: 16))
                        .foregroundColor(.gbLightest)
                }
                .frame(height: 48)

                ScrollView {
                    VStack(spacing: 16) {
                        // Portrait + basic info
                        HStack(alignment: .top, spacing: 16) {
                            PixelPortrait(index: player.portraitIndex, role: player.role)
                                .frame(width: 90, height: 110)

                            VStack(alignment: .leading, spacing: 6) {
                                infoRow("TAG", "「\(player.tag)」")
                                infoRow("AGE", "\(player.age)")
                                infoRow("ROLE", "\(player.role.rawValue) [\(player.role.abbreviation)]")
                                infoRow("PERS", player.personality.rawValue)
                                infoRow("OVR", "\(player.stats.overall)/100")
                            }
                        }
                        .padding()
                        .background(Color.gbDark)
                        .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))

                        // Stats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("STATS")
                                .font(.custom(GB.font, size: 12))
                                .foregroundColor(.gbLight)

                            ForEach(player.stats.display, id: \.0.rawValue) { key, val in
                                StatRowView(label: key.rawValue, value: val)
                            }
                        }
                        .padding()
                        .background(Color.gbDark)
                        .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))

                        // Personality description
                        GBDialogueBar(text: "「\(player.tag)」: \"\(player.catchphrase)\"")

                        // Release button
                        Button {
                            gameState.releasePlayer(id: player.id)
                            dismiss()
                        } label: {
                            Text("RELEASE PLAYER")
                                .font(.custom(GB.font, size: 13))
                                .foregroundColor(.gbDarkest)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.gbLight)
                                .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                }

                GBBackButton { dismiss() }
            }
        }
    }

    func infoRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLight)
                .frame(width: 40, alignment: .leading)
            Text(value)
                .font(.custom(GB.fontMono, size: 11))
                .foregroundColor(.gbLightest)
        }
    }
}
