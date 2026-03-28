import SwiftUI

struct CoachHireView: View {
    @Environment(GameState.self) var gameState
    @Environment(\.dismiss) var dismiss
    @State private var selectedIndex: Int? = nil

    var pool: [Coach] { gameState.pendingCoachPool }

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                Text("Interview and hire one coach")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbDark)
                    .padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(pool.indices, id: \.self) { i in
                            CoachCandidateCard(
                                coach: pool[i],
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
                Text("HIRE COACH")
                    .font(.custom(GB.font, size: 16))
                    .foregroundColor(.gbLightest)
                Spacer()
                Text("$\(gameState.funds)")
                    .font(.custom(GB.fontMono, size: 12))
                    .foregroundColor(.gbLightest)
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 48)
    }

    // MARK: - Action Bar
    var actionBar: some View {
        HStack(spacing: 0) {
            Button {
                gameState.isHiringCoach = false
                gameState.pendingCoachPool = []
                dismiss()
            } label: {
                Text("PASS")
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
                    gameState.hireCoach(pool[i])
                    dismiss()
                }
            } label: {
                Text(selectedIndex != nil ? "HIRE ✓" : "SELECT ONE")
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

// MARK: - Coach Candidate Card
struct CoachCandidateCard: View {
    let coach: Coach
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Top: style badge + name + OVR
            HStack(spacing: 10) {
                Text("COACH")
                    .font(.custom(GB.font, size: 9))
                    .foregroundColor(.gbDarkest)
                    .frame(width: 44, height: 26)
                    .background(Color.gbLight)

                VStack(alignment: .leading, spacing: 2) {
                    Text(coach.name.uppercased())
                        .font(.custom(GB.font, size: 12))
                        .foregroundColor(.gbLightest)
                    Text("「\(coach.tag)」· \(coach.style.rawValue) · Age \(coach.age)")
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbLight)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("OVR \(coach.stats.overall)")
                        .font(.custom(GB.font, size: 12))
                        .foregroundColor(.gbLightest)
                    Text(coach.starDisplay)
                        .font(.system(size: 9))
                        .foregroundColor(.gbLight)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.gbDark)

            // Specialty subtitle
            Text(coach.style.subtitle.uppercased())
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbDark)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .background(Color.gbDarkest.opacity(0.6))

            // Stats
            VStack(spacing: 4) {
                ForEach(coach.stats.display, id: \.0) { label, val in
                    CoachStatRow(label: label, value: val)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gbDarkest.opacity(0.6))

            // Catchphrase
            Text("\"\(coach.catchphrase)\"")
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLight)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gbDarkest.opacity(0.6))
        }
        .overlay(
            Rectangle().stroke(isSelected ? Color.gbLightest : Color.gbDark, lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Coach Stat Row
struct CoachStatRow: View {
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLight)
                .frame(width: 52, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.gbDarkest).frame(height: 7)
                    Rectangle()
                        .fill(barColor(value))
                        .frame(width: geo.size.width * CGFloat(value) / 100, height: 7)
                }
            }
            .frame(height: 7)

            Text("\(value)")
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbLightest)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func barColor(_ v: Int) -> Color {
        if v >= 75 { return .gbLightest }
        if v >= 50 { return .gbLight }
        return .gbDark
    }
}
