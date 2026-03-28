import SwiftUI

struct FinancesView: View {
    @Environment(GameState.self) var gameState

    var body: some View {
        ZStack {
            Color.gbDarkest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView {
                    VStack(spacing: 10) {
                        balanceCard
                        expensesCard
                        incomeCard
                        rosterWagesCard
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }

                backButton
            }
        }
    }

    // MARK: - Header
    var headerBar: some View {
        ZStack {
            Color.gbDark
            VStack(spacing: 2) {
                Text("CLUB FINANCES")
                    .font(.custom(GB.font, size: 14))
                    .foregroundColor(.gbLightest)
                Text("BUDGET OVERVIEW")
                    .font(.custom(GB.fontMono, size: 10))
                    .foregroundColor(.gbLight)
            }
        }
        .frame(height: 52)
    }

    // MARK: - Balance
    var balanceCard: some View {
        VStack(spacing: 0) {
            sectionHeader("CURRENT BALANCE")
            HStack {
                Text("AVAILABLE FUNDS")
                    .font(.custom(GB.fontMono, size: 12))
                    .foregroundColor(.gbLight)
                Spacer()
                Text("$\(gameState.funds)")
                    .font(.custom(GB.font, size: 18))
                    .foregroundColor(gameState.funds >= 0 ? .gbLightest : .gbLight)
            }
            .padding(12)
            .background(Color.gbDarkest)
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Expenses
    var expensesCard: some View {
        VStack(spacing: 0) {
            sectionHeader("EXPENSES PER MATCH")

            let playerWages = gameState.playerTeam.roster.reduce(0) { $0 + $1.salary }
            let coachWage   = gameState.playerTeam.coach != nil ? 600 : 0

            expenseRow("PLAYER WAGES", amount: playerWages, isTotal: false)
            expenseRow("COACH SALARY", amount: coachWage, isTotal: false)
            expenseRow("FACILITY COSTS", amount: gameState.facilityCostPerMatch, isTotal: false)

            Divider().background(Color.gbDark)

            expenseRow("TOTAL OUTGOING", amount: gameState.weeklyWages, isTotal: true)
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Income
    var incomeCard: some View {
        VStack(spacing: 0) {
            sectionHeader("PRIZE MONEY (AMATEUR LEAGUE)")
            incomeRow("MATCH WIN", amount: 5_000)
            incomeRow("MATCH LOSS", amount: 1_500)
            incomeRow("NET WIN (after wages)", amount: 5_000 - gameState.weeklyWages)
            incomeRow("NET LOSS (after wages)", amount: 1_500 - gameState.weeklyWages)
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Roster Wages
    var rosterWagesCard: some View {
        VStack(spacing: 0) {
            sectionHeader("PLAYER CONTRACTS")

            if gameState.playerTeam.roster.isEmpty {
                Text("No players signed. Visit MARKET to recruit.")
                    .font(.custom(GB.fontMono, size: 11))
                    .foregroundColor(.gbDark)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.gbDarkest)
            } else {
                ForEach(gameState.playerTeam.roster) { player in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name.uppercased())
                                .font(.custom(GB.font, size: 11))
                                .foregroundColor(.gbLightest)
                            Text("\(player.role.rawValue.uppercased())  OVR \(player.stats.overall)")
                                .font(.custom(GB.fontMono, size: 9))
                                .foregroundColor(.gbDark)
                        }
                        Spacer()
                        Text("$\(player.salary)/match")
                            .font(.custom(GB.fontMono, size: 11))
                            .foregroundColor(.gbLight)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gbDarkest)
                    .overlay(Rectangle().stroke(Color.gbDarkest, lineWidth: 0.5))
                }
            }

            if let coach = gameState.playerTeam.coach {
                Divider().background(Color.gbDark)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(coach.name.uppercased())
                            .font(.custom(GB.font, size: 11))
                            .foregroundColor(.gbLightest)
                        Text("HEAD COACH")
                            .font(.custom(GB.fontMono, size: 9))
                            .foregroundColor(.gbDark)
                    }
                    Spacer()
                    Text("$600/match")
                        .font(.custom(GB.fontMono, size: 11))
                        .foregroundColor(.gbLight)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gbDarkest)
            }
        }
        .overlay(Rectangle().stroke(Color.gbDark, lineWidth: 1))
    }

    // MARK: - Helpers

    func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.custom(GB.font, size: 10))
                .foregroundColor(.gbLight)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gbDark)
    }

    func expenseRow(_ label: String, amount: Int, isTotal: Bool) -> some View {
        HStack {
            Text(label)
                .font(.custom(isTotal ? GB.font : GB.fontMono, size: isTotal ? 11 : 11))
                .foregroundColor(isTotal ? .gbLightest : .gbLight)
            Spacer()
            Text("−$\(amount)")
                .font(.custom(isTotal ? GB.font : GB.fontMono, size: 11))
                .foregroundColor(isTotal ? .gbLight : .gbDark)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(isTotal ? Color.gbDark : Color.gbDarkest)
    }

    func incomeRow(_ label: String, amount: Int) -> some View {
        HStack {
            Text(label)
                .font(.custom(GB.fontMono, size: 11))
                .foregroundColor(.gbLight)
            Spacer()
            Text(amount >= 0 ? "+$\(amount)" : "−$\(abs(amount))")
                .font(.custom(GB.fontMono, size: 11))
                .foregroundColor(amount >= 0 ? .gbLightest : .gbDark)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.gbDarkest)
    }

    // MARK: - Back
    var backButton: some View {
        Button {
            gameState.screen = .overworld
        } label: {
            Text("◀ BACK")
                .font(.custom(GB.font, size: 14))
                .foregroundColor(.gbLightest)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gbDark)
                .overlay(Rectangle().stroke(Color.gbLight, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
