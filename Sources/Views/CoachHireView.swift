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
                // Header with funds on the right
                ZStack {
                    Color.gbDark

                    HStack(spacing: 0) {
                        Rectangle().fill(Color.gbDarkest).frame(width: 5)
                        Spacer()
                        Text("HIRE COACH")
                            .font(.custom(GB.font, size: 15))
                            .foregroundColor(.gbLightest)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("FUNDS")
                                .font(.custom(GB.fontMono, size: 8))
                                .foregroundColor(.gbDark)
                            Text("$\(gameState.funds)")
                                .font(.custom(GB.font, size: 13))
                                .foregroundColor(.gbLightest)
                        }
                        .padding(.trailing, 14)
                    }
                }
                .frame(height: 52)

                // Subtitle bar
                HStack(spacing: 6) {
                    Rectangle().fill(Color.gbDark).frame(width: 3, height: 12)
                    Text("Interview and hire one coach for your team")
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbDark)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.gbDarkest)
                .overlay(Rectangle().stroke(Color.gbDark.opacity(0.4), lineWidth: 0.5), alignment: .bottom)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(pool.indices, id: \.self) { i in
                            CoachCandidateCard(coach: pool[i], isSelected: selectedIndex == i)
                                .onTapGesture { selectedIndex = i }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }

                actionBar
            }
        }
    }

    // MARK: - Action Bar
    var actionBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.gbDark).frame(height: 1)

            HStack(spacing: 10) {
                Button {
                    gameState.isHiringCoach = false
                    gameState.pendingCoachPool = []
                    dismiss()
                } label: {
                    Text("PASS")
                        .font(.custom(GB.font, size: 13))
                        .foregroundColor(.gbLight)
                        .frame(width: 90)
                        .padding(.vertical, 14)
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
                    Text(selectedIndex != nil ? "HIRE  ✓" : "SELECT ONE FIRST")
                        .font(.custom(GB.font, size: 14))
                        .foregroundColor(selectedIndex != nil ? .gbDarkest : .gbDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedIndex != nil ? Color.gbLightest : Color.gbDarkest)
                        .overlay(
                            ZStack {
                                Rectangle().stroke(
                                    selectedIndex != nil ? Color.gbLight : Color.gbDarkest,
                                    lineWidth: selectedIndex != nil ? 2 : 1
                                )
                                if selectedIndex != nil {
                                    GBCornerBorder(color: .gbDark, lineWidth: 1, cornerSize: 7)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedIndex == nil)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .padding(.bottom, 16)
        }
        .background(Color.gbDarkest)
    }
}

// MARK: - Coach Candidate Card
struct CoachCandidateCard: View {
    let coach: Coach
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Name row
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isSelected ? Color.gbLightest : Color.gbDark)
                    .frame(width: 4)

                HStack(spacing: 10) {
                    // COACH badge
                    Text("COACH")
                        .font(.custom(GB.font, size: 8))
                        .foregroundColor(.gbDarkest)
                        .frame(width: 44, height: 24)
                        .background(isSelected ? Color.gbLightest : Color.gbLight)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(coach.name.uppercased())
                            .font(.custom(GB.font, size: 13))
                            .foregroundColor(isSelected ? .gbLightest : .gbLight)
                        HStack(spacing: 6) {
                            Text("「\(coach.tag)」")
                                .font(.custom(GB.fontMono, size: 9))
                                .foregroundColor(.gbLight)
                            Text(coach.style.rawValue.uppercased())
                                .font(.custom(GB.fontMono, size: 8))
                                .foregroundColor(.gbDark)
                            Text("·  Age \(coach.age)")
                                .font(.custom(GB.fontMono, size: 8))
                                .foregroundColor(.gbDark)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("OVR")
                            .font(.custom(GB.fontMono, size: 8))
                            .foregroundColor(.gbDark)
                        Text("\(coach.stats.overall)")
                            .font(.custom(GB.font, size: 20))
                            .foregroundColor(isSelected ? .gbLightest : .gbLight)
                        Text(coach.starDisplay)
                            .font(.system(size: 9))
                            .foregroundColor(isSelected ? .gbLight : .gbDark)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .background(Color.gbDark)

            // Specialty description
            HStack(spacing: 6) {
                Rectangle().fill(Color.gbDark).frame(width: 3, height: 12)
                Text(coach.style.subtitle.uppercased())
                    .font(.custom(GB.fontMono, size: 9))
                    .foregroundColor(.gbDark)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gbDarkest.opacity(0.7))

            // Stats — segmented bars
            VStack(spacing: 5) {
                ForEach(coach.stats.display, id: \.0) { label, val in
                    HStack(spacing: 8) {
                        Text(label)
                            .font(.custom(GB.fontMono, size: 10))
                            .foregroundColor(.gbLight)
                            .frame(width: 52, alignment: .leading)
                        GBSegmentBar(value: val)
                        Text("\(val)")
                            .font(.custom(GB.fontMono, size: 10))
                            .foregroundColor(.gbLightest)
                            .frame(width: 26, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.gbDarkest.opacity(0.7))

            // Catchphrase
            Text("\"  \(coach.catchphrase)  \"")
                .font(.custom(GB.fontMono, size: 10))
                .foregroundColor(.gbDark)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gbDarkest.opacity(0.7))
        }
        .overlay(
            Rectangle().stroke(isSelected ? Color.gbLightest : Color.gbDark, lineWidth: isSelected ? 2 : 1)
        )
    }
}
