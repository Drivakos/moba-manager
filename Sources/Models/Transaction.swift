import Foundation

// MARK: - Transaction
// A single line of the club ledger, e.g. "-$900  Player wages (matchday)".
struct Transaction: Identifiable, Codable {
    enum Kind: String, Codable {
        case prize
        case wages
        case training
        case coach
        case signing
        case release
        case board
    }

    let id: UUID
    let day: Int          // matches played when the entry was recorded
    let label: String
    let amount: Int       // negative = money out
    let kind: Kind

    init(day: Int, label: String, amount: Int, kind: Kind) {
        self.id = UUID()
        self.day = day
        self.label = label
        self.amount = amount
        self.kind = kind
    }
}
