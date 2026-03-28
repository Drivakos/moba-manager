import SwiftUI

struct DraftView: View {
    @Environment(GameState.self) var gameState
    @State private var selectedIndex: Int? = nil

    var pool: [Player] { gameState.pendingDraftPool }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                Text("Select one candidate to recruit")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbDark)
                    .padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(pool.indices, id: \.self) { i in
                            DraftCandidateCard(
                                player: pool[i],
                                isSelected: selectedIndex == i
                            )
                            .onTapGesture { selectedIndex = i }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }

                actionBar
            }
        }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark
            HStack {
                Text("PLAYER DRAFT")
                    .font(.custom(GB.font, size: 16))
                    .foregroundColor(.gbLightest)
                Spacer()
                Text("CH.\(gameState.chapter)")
                    .font(.custom(GB.fontMono, size: 12))
                    .foregroundColor(.gbLight)
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 48)
    }

    // MARK: - Action Bar
    var actionBar: some View {
        HStack(spacing: 0) {
            Button {
                gameState.skipDraft()
            } label: {
                Text("SKIP")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.gbDarkest)
                    .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button {
                if let i = selectedIndex {
                    gameState.pickDraftPlayer(pool[i])
                }
            } label: {
                Text(selectedIndex != nil ? "RECRUIT ✓" : "SELECT ONE")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(selectedIndex != nil ? .gbDarkest : .gbDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(selectedIndex != nil ? Color.gbLightest : Color.gbDarkest)
                    .overlay(Rectangle().stroke(selectedIndex != nil ? Color.gbLight : Color.gbDarkest, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(selectedIndex == nil)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 20)
    }
}

// MARK: - Draft Candidate Card
struct DraftCandidateCard: View {
    let player: Player
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Top row: role + name + OVR
            HStack(spacing: 10) {
                Text(player.role.abbreviation)
                    .font(.custom(GB.font, size: 11))
                    .foregroundColor(.gbDarkest)
                    .frame(width: 40, height: 26)
                    .background(Color.gbLight)

                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name.uppercased())
                        .font(.custom(GB.font, size: 12))
                        .foregroundColor(.gbLightest)
                    Text("「\(player.tag)」· Age \(player.age)")
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbLight)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("OVR \(player.stats.overall)")
                        .font(.custom(GB.font, size: 12))
                        .foregroundColor(.gbLightest)
                    Text(player.personality.rawValue)
                        .font(.custom(GB.fontMono, size: 9))
                        .foregroundColor(.gbDark)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.gbDark)

            // Stats
            VStack(spacing: 4) {
                ForEach(player.stats.display, id: \.0.rawValue) { key, val in
                    StatRowView(label: key.rawValue, value: val)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gbDarkest.opacity(0.6))
        }
        .overlay(
            Rectangle().stroke(isSelected ? Color.gbLightest : Color.gbDark, lineWidth: isSelected ? 2 : 1)
        )
    }
}
