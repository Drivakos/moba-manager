import SwiftUI

struct FinancesView: View {
    @Environment(GameState.self) var gameState

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                GBScreenHeader(title: "Club Finances", subtitle: "Budget Overview")

                ScrollView {
                    VStack(spacing: 12) {
                        balanceCard
                        expensesCard
                        incomeCard
                        rosterWagesCard
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                }

                GBBackButton { gameState.screen = .overworld }
            }
        }
    }

    // MARK: - Balance
    var balanceCard: some View {
        VStack(spacing: 0) {
            GBSectionLabel(text: "Current Balance")

            ZStack {
                Color.gbDarkest

                VStack(spacing: 6) {
                    Text("$\(gameState.funds)")
                        .font(.custom(GB.font, size: 42))
                        .foregroundColor(gameState.funds >= 0 ? .gbLightest : .gbLight)
                        .shadow(color: .gbDark, radius: 0, x: 3, y: 3)
                    Text("AVAILABLE FUNDS")
                        .font(.custom(GB.fontMono, size: 10))
                        .foregroundColor(.gbDark)
                        .tracking(2)
                }
                .padding(.vertical, 20)

                GBCornerBorder(color: .gbDark.opacity(0.5), lineWidth: 1, cornerSize: 12)
                    .padding(10)
            }
            .overlay(Rectangle().stroke(Color.gbDark.opacity(0.4), lineWidth: 1), alignment: .bottom)
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Expenses
    var expensesCard: some View {
        let playerWages = gameState.playerTeam.roster.reduce(0) { $0 + $1.salary }
        let coachWage   = gameState.playerTeam.coach != nil ? 600 : 0

        return VStack(spacing: 0) {
            GBSectionLabel(text: "Expenses Per Match")

            expenseRow("PLAYER WAGES",  amount: playerWages, isTotal: false)
            expenseRow("COACH SALARY",  amount: coachWage,   isTotal: false)
            expenseRow("FACILITY COSTS", amount: gameState.facilityCostPerMatch, isTotal: false)

            // Total row — stronger styling
            HStack {
                Text("TOTAL OUTGOING")
                    .font(.custom(GB.font, size: 12))
                    .foregroundColor(.gbLight)
                Spacer()
                Text("−$\(gameState.weeklyWages)")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLightest)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.gbDark)
            .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 0.5), alignment: .top)
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Income
    var incomeCard: some View {
        VStack(spacing: 0) {
            GBSectionLabel(text: "Prize Money — Amateur League")
            incomeRow("MATCH WIN",              amount: 5_000)
            incomeRow("MATCH LOSS",             amount: 1_500)
            Rectangle().fill(Color.gbDark.opacity(0.5)).frame(height: 1).padding(.horizontal, 12)
            incomeRow("NET  WIN  (after wages)", amount: 5_000 - gameState.weeklyWages)
            incomeRow("NET  LOSS (after wages)", amount: 1_500 - gameState.weeklyWages)
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Roster Wages
    var rosterWagesCard: some View {
        VStack(spacing: 0) {
            GBSectionLabel(text: "Player Contracts")

            if gameState.playerTeam.roster.isEmpty {
                Text("No players signed. Visit MARKET to recruit.")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbDark)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.gbDarkest)
            } else {
                ForEach(gameState.playerTeam.roster) { player in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gbDark)
                            .frame(width: 3)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name.uppercased())
                                    .font(.custom(GB.font, size: 11))
                                    .foregroundColor(.gbLightest)
                                HStack(spacing: 6) {
                                    Text(player.role.abbreviation)
                                        .font(.custom(GB.font, size: 8))
                                        .foregroundColor(.gbDarkest)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(Color.gbLight)
                                    Text("OVR \(player.stats.overall)")
                                        .font(.custom(GB.fontMono, size: 9))
                                        .foregroundColor(.gbDark)
                                }
                            }
                            Spacer()
                            Text("$\(player.salary)")
                                .font(.custom(GB.font, size: 13))
                                .foregroundColor(.gbLight)
                            Text("/match")
                                .font(.custom(GB.fontMono, size: 9))
                                .foregroundColor(.gbDark)
                                .padding(.leading, 2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                    }
                    .background(Color.gbDarkest)
                    .overlay(Rectangle().stroke(Color.gbDarkest.opacity(0.6), lineWidth: 0.5))
                }
            }

            if let coach = gameState.playerTeam.coach {
                HStack(spacing: 0) {
                    Rectangle().fill(Color.gbLight).frame(width: 3)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(coach.name.uppercased())
                                .font(.custom(GB.font, size: 11))
                                .foregroundColor(.gbLightest)
                            Text("HEAD COACH  ·  \(coach.style.rawValue.uppercased())")
                                .font(.custom(GB.fontMono, size: 9))
                                .foregroundColor(.gbDark)
                        }
                        Spacer()
                        Text("$600")
                            .font(.custom(GB.font, size: 13))
                            .foregroundColor(.gbLight)
                        Text("/match")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                            .padding(.leading, 2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                }
                .background(Color.gbDarkest)
                .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 0.5), alignment: .top)
            }
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Row helpers
    func expenseRow(_ label: String, amount: Int, isTotal: Bool) -> some View {
        HStack {
            Text(label)
                .font(.custom(GB.fontMono, size: 11))
                .foregroundColor(.gbLight)
            Spacer()
            Text("−$\(amount)")
                .font(.custom(GB.fontMono, size: 11))
                .foregroundColor(.gbDark)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gbDarkest)
    }

    func incomeRow(_ label: String, amount: Int) -> some View {
        HStack {
            Text(label)
                .font(.custom(GB.fontMono, size: 11))
                .foregroundColor(.gbLight)
            Spacer()
            Text(amount >= 0 ? "+$\(amount)" : "−$\(abs(amount))")
                .font(.custom(amount >= 0 ? GB.font : GB.fontMono, size: 12))
                .foregroundColor(amount >= 0 ? .gbLightest : .gbDark)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gbDarkest)
    }
}
