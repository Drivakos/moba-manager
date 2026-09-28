import Foundation

// Headless harness for the rift simulation.

var failures = 0
func check(_ label: String, _ condition: Bool, _ detail: String = "") {
    if condition { print("  PASS  \(label)") }
    else { failures += 1; print("  FAIL  \(label) \(detail)") }
}

// Rosters are built from fixed stat blocks rather than Player.generate, whose
// internal Int.random would make the whole harness differ between runs.
func makePlayer(role: Role, overall: Int, seed: Int) -> Player {
    func spread(_ base: Int, _ v: Int) -> Int { min(98, max(10, base + v)) }
    let stats = PlayerStats(mechanics: spread(overall, seed % 5),
                            gameSense: spread(overall, (seed / 3) % 5),
                            teamwork:  spread(overall, (seed / 5) % 5),
                            mental:    spread(overall, (seed / 7) % 5),
                            stamina:   spread(overall, (seed / 11) % 5))
    return Player(id: UUID(),
                  name: "\(role.abbreviation)-WALKON",
                  tag: "\(role.abbreviation)K\(seed)",
                  age: 18, role: role, stats: stats, personality: .consistent,
                  potential: 3, catchphrase: "-", isRecruited: true,
                  portraitIndex: 0, level: max(1, (overall - 40) / 6),
                  xp: 0, salary: Player.salaryFor(overall: stats.overall))
}
func makeTeam(_ name: String, _ overall: Int) -> Team {
    Team(id: UUID(), name: name,
         roster: Array(Role.allCases.enumerated()).map { makePlayer(role: $0.element, overall: overall, seed: $0.offset) },
         coach: nil, wins: 0, losses: 0)
}

print("== Fielding ==")
let blue = makeTeam("Blue", 70), red = makeTeam("Red", 68)
var sim = RiftSimulation(player: blue, opponent: red, tactic: .adapt, seed: 42)
let outcome = sim.run()

check("ten units fielded", outcome.units.count == 10, "got \(outcome.units.count)")
check("five per side",
      outcome.units.filter { $0.side == .blue }.count == 5 &&
      outcome.units.filter { $0.side == .red }.count == 5)
check("every unit has positive max HP", outcome.units.allSatisfy { $0.maxHP > 0 })
check("every role represented",
      Set(outcome.units.filter { $0.side == .blue }.map(\.role)).count == 5)
check("lanes follow roles",
      outcome.units.filter { $0.side == .blue }.allSatisfy { $0.lane != .mid || $0.role == .mid })

print("== Match reaches a real conclusion ==")
check("events produced", !outcome.events.isEmpty, "got \(outcome.events.count)")
check("has a first blood", outcome.events.contains { $0.kind == .firstBlood })
check("kills happened", outcome.events.contains { $0.kind == .kill })
let nexusAt = outcome.events.first { $0.kind == .nexus }?.time ?? .infinity
check("nexus falls before the time limit", nexusAt <= 360.0,
      "nexus at \(String(format: "%.0f", nexusAt))s")
check("MVP named", outcome.mvp != nil)
check("MVP is a real unit",
      outcome.mvp.map { n in outcome.units.contains { $0.name == n } } ?? false)
check("phase winners recorded",
      outcome.phaseWinners[.early] != nil || outcome.phaseWinners[.mid] != nil)
print("  duration=\(String(format: "%.0f", outcome.duration))s events=\(outcome.events.count) winner=\(outcome.winner) mvp=\(outcome.mvp ?? "-")")

print("== Events name real players ==")
let knownNames = Set(outcome.units.map(\.name))
let killTexts = outcome.events.filter { $0.kind == .kill || $0.kind == .firstBlood }
check("kill lines reference real players",
      !killTexts.contains { e in !knownNames.contains { e.text.contains($0) } })
check("events are time-ordered",
      outcome.events.enumerated().allSatisfy { i, e in
          i == 0 || e.time >= outcome.events[i - 1].time })

print("== Determinism ==")
var a = RiftSimulation(player: blue, opponent: red, tactic: .adapt, seed: 7)
var b = RiftSimulation(player: blue, opponent: red, tactic: .adapt, seed: 7)
let ra = a.run(), rb = b.run()
check("same seed same winner", ra.winner == rb.winner, "\(ra.winner) vs \(rb.winner)")
check("same seed same event count", ra.events.count == rb.events.count)
check("same seed same duration", ra.duration == rb.duration)
check("same seed same text", zip(ra.events, rb.events).allSatisfy { $0.text == $1.text })
var c = RiftSimulation(player: blue, opponent: red, tactic: .adapt, seed: 8)
let rc = c.run()
check("different seeds diverge",
      rc.events.count != ra.events.count || rc.duration != ra.duration)

print("== Skill decides matches ==")
var strongWins = 0, weakWins = 0
let strong = makeTeam("Strong", 82), weak = makeTeam("Weak", 45)
for seed in 1...60 {
    var s1 = RiftSimulation(player: strong, opponent: weak, tactic: .adapt, seed: UInt64(seed))
    if s1.run().winner == .blue { strongWins += 1 }
    var s2 = RiftSimulation(player: weak, opponent: strong, tactic: .adapt, seed: UInt64(seed))
    if s2.run().winner == .blue { weakWins += 1 }
}
print("  strong-as-blue \(strongWins)/60, weak-as-blue \(weakWins)/60")
check("a far stronger roster dominates", strongWins >= 45, "got \(strongWins)")
check("a far weaker roster is not a free win", weakWins <= 15, "got \(weakWins)")

var closeWins = 0
let mid = makeTeam("Mid", 62)
for seed in 1...60 {
    var s = RiftSimulation(player: mid, opponent: weak, tactic: .adapt, seed: UInt64(seed))
    if s.run().winner == .blue { closeWins += 1 }
}
print("  favoured-but-not-dominant wins \(closeWins)/60")
check("a moderate favourite still loses sometimes", closeWins < 60 && closeWins > 40,
      "got \(closeWins)")

print("== Even matchups are fair ==")
var blueWins = 0, decisive = 0
for seed in 100...179 {
    let t1 = makeTeam("A", 65), t2 = makeTeam("B", 65)
    var s = RiftSimulation(player: t1, opponent: t2, tactic: .adapt, seed: UInt64(seed))
    let o = s.run()
    if o.winner == .blue { blueWins += 1 }
    if o.duration < 360 { decisive += 1 }
}
print("  blue wins \(blueWins)/80, decisive \(decisive)/80")
check("no positional advantage", blueWins >= 28 && blueWins <= 52, "got \(blueWins)")
check("most even games still reach a base", decisive >= 55, "got \(decisive)")

print("== Objectives contest properly ==")
var dragons = 0, barons = 0, towers = 0
for seed in 200...259 {
    let t1 = makeTeam("A", 68), t2 = makeTeam("B", 68)
    var s = RiftSimulation(player: t1, opponent: t2, tactic: .adapt, seed: UInt64(seed))
    let o = s.run()
    if o.events.contains(where: { $0.kind == .dragon }) { dragons += 1 }
    if o.events.contains(where: { $0.kind == .baron }) { barons += 1 }
    towers += o.events.filter { $0.kind == .towerDown }.count
}
print("  dragon \(dragons)/60, baron \(barons)/60, avg towers \(towers/60)")
check("dragon is regularly contested", dragons >= 40, "got \(dragons)")
check("towers fall every match", towers >= 60 * 8, "got \(towers)")

print("== Tactics change outcomes ==")
// The player's tactic should actually shift their results, not just be flavour
// text. Same rosters and same seeds, only the tactic differs.
var diveWins = 0, scaleWins = 0
for seed in 300...379 {
    let t1 = makeTeam("A", 68), t2 = makeTeam("B", 68)
    var s1 = RiftSimulation(player: t1, opponent: t2, tactic: .dive, seed: UInt64(seed))
    var s2 = RiftSimulation(player: t1, opponent: t2, tactic: .scale, seed: UInt64(seed))
    if s1.run().winner == .blue { diveWins += 1 }
    if s2.run().winner == .blue { scaleWins += 1 }
}
print("  DIVE wins \(diveWins)/80, SCALE wins \(scaleWins)/80")
check("DIVE materially outperforms SCALE", diveWins >= scaleWins + 8,
      "dive=\(diveWins) scale=\(scaleWins)")

print("== Short roster still fields a team ==")
var shortRoster = Team(id: UUID(), name: "Short",
                       roster: [makePlayer(role: .mid, overall: 60, seed: 0),
                                makePlayer(role: .mid, overall: 58, seed: 1)],
                       coach: nil, wins: 0, losses: 0)
var shortSim = RiftSimulation(player: shortRoster, opponent: mid, tactic: .adapt, seed: 5)
let shortOutcome = shortSim.run()
check("short roster fields five units", shortOutcome.units.filter { $0.side == .blue }.count == 5)
check("short roster match concludes", shortOutcome.duration <= 360)
shortRoster.roster = []
var emptySim = RiftSimulation(player: shortRoster, opponent: mid, tactic: .adapt, seed: 5)
check("empty roster does not crash", emptySim.run().units.count == 10)

print(failures == 0 ? "\nALL SIM CHECKS PASSED" : "\n\(failures) SIM CHECK(S) FAILED")
exit(failures == 0 ? 0 : 1)
