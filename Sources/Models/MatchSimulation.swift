import Foundation

// MARK: - Rift Simulation
//
// A deterministic, tick-based MOBA match simulation. Ten units (five per side)
// spawn at their bases, push their assigned lanes, meet in skirmishes, take
// neutral objectives, and race to destroy the enemy nexus.
//
// This file is deliberately free of SpriteKit/SwiftUI so it can be exercised
// headlessly. `MatchArenaScene` renders whatever this produces; it never decides
// the outcome.
//
// Given the same seed and the same rosters the simulation is reproducible
// tick-for-tick.

// MARK: - Deterministic RNG

/// SplitMix64 — small, fast, and reproducible across platforms.
struct SimRandom {
    private var state: UInt64
    let seed: UInt64

    init(seed: UInt64) {
        let s = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
        self.seed = s
        state = s
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform in [0, 1).
    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    mutating func range(_ lo: Double, _ hi: Double) -> Double {
        lo + (hi - lo) * unit()
    }

    mutating func chance(_ p: Double) -> Bool {
        unit() < p
    }

    /// Order-independent noise in [0, 1), keyed by a pair of integers instead of
    /// by call position. Combat variance uses this so that resolving blue's units
    /// before red's cannot give either side systematically luckier rolls.
    func noise(_ a: Int, _ b: Int) -> Double {
        var z = seed &+ UInt64(bitPattern: Int64(a)) &* 0x9E37_79B9_7F4A_7C15
        z &+= UInt64(bitPattern: Int64(b)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z = z ^ (z >> 31)
        return Double(z >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}

// MARK: - Geometry

/// Normalised 0…1 coordinates. The scene scales them to its own size.
struct SimPoint: Equatable, Codable {
    var x: Double
    var y: Double

    static let zero = SimPoint(x: 0, y: 0)

    func distance(to other: SimPoint) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }

    /// A point `step` closer to `target`, never overshooting.
    func moved(toward target: SimPoint, by step: Double) -> SimPoint {
        let d = distance(to: target)
        guard d > 0 else { return target }
        if step >= d { return target }
        let f = step / d
        return SimPoint(x: x + (target.x - x) * f, y: y + (target.y - y) * f)
    }

    static func + (l: SimPoint, r: SimPoint) -> SimPoint {
        SimPoint(x: l.x + r.x, y: l.y + r.y)
    }
}

/// Which side of the rift.
enum SimSide: String, Codable {
    case blue   // player team, bottom-left
    case red    // opponent, top-right

    var opposite: SimSide { self == .blue ? .red : .blue }
}

/// Lane assignments. `jungle` roams between neutral objectives.
enum Lane: String, Codable, CaseIterable {
    case top, mid, bot, jungle

    var display: String {
        switch self {
        case .top:    return "TOP"
        case .mid:    return "MID"
        case .bot:    return "BOT"
        case .jungle: return "JNG"
        }
    }
}

/// Static rift layout: bases, lanes, river, objective pits, structures.
enum RiftMap {
    static let blueBase = SimPoint(x: 0.13, y: 0.13)
    static let redBase  = SimPoint(x: 0.87, y: 0.87)

    // Both pits sit on the anti-diagonal x + y = 1. That is the perpendicular
    // bisector of the two bases, so each base is exactly the same distance from
    // each pit and the neutral objective is a real contest, not a gift to the
    // side whose base happens to be nearer.
    static let dragonPit = SimPoint(x: 0.66, y: 0.34)
    static let baronPit  = SimPoint(x: 0.34, y: 0.66)

    /// Lanes run base→base through their waypoints.
    static func path(_ lane: Lane, for side: SimSide) -> [SimPoint] {
        // Authored for blue (bottom-left → top-right); red walks it reversed.
        let blue: [SimPoint]
        switch lane {
        case .mid:
            blue = [blueBase,
                    SimPoint(x: 0.30, y: 0.30),
                    SimPoint(x: 0.50, y: 0.50),
                    SimPoint(x: 0.70, y: 0.70),
                    redBase]
        case .bot:
            blue = [blueBase,
                    SimPoint(x: 0.16, y: 0.07),
                    SimPoint(x: 0.50, y: 0.07),
                    SimPoint(x: 0.93, y: 0.50),
                    SimPoint(x: 0.93, y: 0.84),
                    redBase]
        case .top:
            blue = [blueBase,
                    SimPoint(x: 0.07, y: 0.16),
                    SimPoint(x: 0.07, y: 0.50),
                    SimPoint(x: 0.50, y: 0.93),
                    SimPoint(x: 0.84, y: 0.93),
                    redBase]
        case .jungle:
            // Waypoints must be 180°-symmetric about the map centre, because red
            // walks this path reversed. (0.32,0.24) mirrors to (0.68,0.76): using
            // anything else sends the two junglers on different routes and skews
            // every mirror match toward one side.
            blue = [blueBase,
                    SimPoint(x: 0.32, y: 0.24),
                    baronPit,
                    dragonPit,
                    SimPoint(x: 0.68, y: 0.76),
                    redBase]
        }
        return side == .blue ? blue : blue.reversed()
    }

    /// River crosses the map perpendicular to mid, through both pits.
    static let riverSegments: [(SimPoint, SimPoint)] = [
        (SimPoint(x: 0.07, y: 0.93), SimPoint(x: 0.93, y: 0.07)),
        (SimPoint(x: 0.34, y: 0.69), SimPoint(x: 0.66, y: 0.31)),
    ]

    /// Three towers per lane, at fixed fractions along the path from each base.
    static let towerFractions: [Double] = [0.28, 0.46, 0.64]

    /// Spawn seats inside a base, so five units don't stack. The map is symmetric
    /// under the anti-diagonal reflection (x, y) → (1 − y, 1 − x), which swaps the
    /// two bases while leaving top and bot lanes in place. Red's seats must use
    /// that same reflection — a 180° rotation looks symmetric but maps top to bot,
    /// and since bot fields two units that asymmetry hands one side the match.
    static func seat(_ index: Int, side: SimSide) -> SimPoint {
        let base = side == .blue ? blueBase : redBase
        var dx = Double(index % 3) - 1
        var dy = Double(index / 3)
        if side == .red { swap(&dx, &dy); dx = -dx; dy = -dy }
        return SimPoint(x: base.x + dx * 0.022, y: base.y + dy * 0.022)
    }
}

// MARK: - Structures

enum StructureKind: String, Codable {
    case tower, nexus

    var maxHP: Double {
        switch self {
        // Tuned against the objective-first AI: five units focus a structure at
        // once, so HP has to be large enough that a lane takes real time to crack
        // and the match lasts minutes rather than seconds.
        case .tower: return 2600
        case .nexus: return 4200
        }
    }
}

struct SimStructure {
    let id: Int
    let side: SimSide
    let lane: Lane
    let kind: StructureKind
    var position: SimPoint
    var maxHP: Double
    var hp: Double
    /// Seeded tiebreak so simultaneous falls have no array-order bias.
    let tiebreak: Double
    /// Set once the fall has been announced, so the destruction event fires once.
    var wasDestroyed: Bool = false
    var alive: Bool { hp > 0 }
}

// MARK: - Units

struct SimUnit {
    let id: Int
    let side: SimSide
    let role: Role
    let name: String
    let lane: Lane
    let seat: Int

    var maxHP: Double
    var hp: Double
    var attack: Double
    var defense: Double
    var speed: Double

    var position: SimPoint
    var facing: SimPoint
    var alive: Bool
    var respawnAt: Double
    var kills: Int
    var deaths: Int

    var hpFraction: Double { maxHP > 0 ? max(0, hp / maxHP) : 0 }

    /// Built from the player's real stats, so a stronger roster fields stronger
    /// units and the simulation's outcome tracks overall rating.
    init(id: Int, side: SimSide, player: Player, seat: Int, lane: Lane) {
        self.id = id
        self.side = side
        self.role = player.role
        self.name = player.tag.isEmpty ? player.name : player.tag
        self.lane = lane
        self.seat = seat

        let s = player.stats
        let levelBonus = Double(player.level - 1) * 1.5

        // HP leans on durability stats; damage leans on execution.
        self.maxHP = 520 + Double(s.mental + s.stamina) * 4.0 + levelBonus * 8
        self.hp = maxHP
        self.attack = 9 + (Double(s.mechanics) * 0.42 + Double(s.gameSense) * 0.20) + levelBonus * 0.5
        self.defense = Double(s.mental) * 0.30 + Double(s.stamina) * 0.22
        self.speed = 0.085 + Double(s.gameSense) * 0.00035

        self.position = RiftMap.seat(seat, side: side)
        self.facing = self.position
        self.alive = true
        self.respawnAt = 0
        self.kills = 0
        self.deaths = 0
    }
}

// MARK: - Events

enum SimEventKind: String, Codable {
    case firstBlood, kill, teamfight, towerDown, dragon, baron, nexus, respawn, rotation
}

struct SimEvent: Identifiable, Codable {
    let id: Int
    let time: Double
    let kind: SimEventKind
    let text: String
    /// Side that benefited, or nil when neutral.
    let side: SimSide?
    let position: SimPoint
    let phase: MatchPhase
    /// The play hinged on one player.
    let isStarPlay: Bool

    var isPositive: Bool { side == nil }
}

// MARK: - Outcome

struct SimOutcome {
    let winner: SimSide
    let events: [SimEvent]
    let units: [SimUnit]
    let duration: Double
    /// Who took each phase's signature objective (nil = nobody before it closed).
    let phaseWinners: [MatchPhase: SimSide?]
    let mvp: String?
    let starPlayName: String?
}

// MARK: - Simulation

struct RiftSimulation {

    // Tuning. Damage numbers are per-tick; HP pools are a few hundred, so a
    // 1v1 lane skirmish resolves in a handful of seconds.
    private let dt = 0.5
    private let timeLimit = 360.0
    private let visionRadius = 0.17
    private let attackRange = 0.045
    private let towerRange = 0.075
    private let respawnBase = 8.0
    private let damageScale = 0.42
    /// Siege damage multiplier. Tunable so a lane of towers falls in a few
    /// minutes of uncontested pushing, letting the nexus be reached in time.
    private let siegeMultiplier: Double
    /// Siege damage ramps up from the mid game. Without it, two evenly matched
    /// sides trade forever and neither base ever opens, so every match times out.
    private let siegeRampStart = 150.0
    private let siegeRampPerSecond = 0.014

    private(set) var time: Double = 0
    private var rng: SimRandom
    private let tactic: MatchTactic

    /// Per-match form for each side. A team has good and bad days: without this,
    /// a stat gap decides every game and an underdog can never steal one, which
    /// would make the whole "build a team from nothing" arc pointless.
    private var form: [SimSide: Double] = [:]
    /// Snowball: a side that wins fights converts those kills into a lasting
    /// power lead, so early aggression (DIVE) can actually decide a game instead
    /// of every match being settled by the final nexus race in the late phase.
    private var momentum: [SimSide: Double] = [:]
    private let momentumPerKill = 0.008
    private let momentumCap = 0.20
    private let playerSide: SimSide

    private(set) var units: [SimUnit] = []
    private(set) var structures: [SimStructure] = []
    private(set) var events: [SimEvent] = []
    private var eventCounter = 0
    /// Damage each attacker has contributed to each unit, keyed `[victim][attacker]`.
    /// Using cumulative damage instead of "last hit" keeps kill credit independent
    /// of the order units are resolved in.
    private var damageContributed: [[Int: Double]] = []

    private var firstBloodTaken = false
    private var dragonKilled = false
    private var baronKilled = false
    private var firstTowerDown: SimSide?
    private var dragonWinner: SimSide?
    private var baronWinner: SimSide?
    private var nexusWinner: SimSide?
    /// Side whose structure landed a tower kill this tick, if any.
    private var structureCredit: [SimSide?]
    /// The objective a unit last stood on. Damage only lands on an objective the
    /// unit has actually reached, so a unit cannot shell a tower from across the map.
    private var arrivedObjective: [Int?]

    init(player: Team, opponent: Team, tactic: MatchTactic, seed: UInt64,
         siegeMultiplier: Double = 1.3) {
        self.rng = SimRandom(seed: seed)
        self.tactic = tactic
        self.siegeMultiplier = siegeMultiplier
        self.playerSide = .blue
        // Lane assignment by role — the classic 1-1-2 + jungler split.
        let laneForRole: [Role: Lane] = [
            .offlaner: .top,
            .mid:      .mid,
            .carry:    .bot,
            .support:  .bot,
            .jungler:  .jungle,
        ]

        // Build both sides from their real rosters, one unit per role slot.
        var built: [SimUnit] = []
        var id = 0
        for (side, roster) in [(SimSide.blue, player.roster), (.red, opponent.roster)] {
            let padded = Self.padToFive(roster)
            for (seat, member) in padded.enumerated() {
                built.append(SimUnit(id: id,
                                     side: side,
                                     player: member,
                                     seat: seat,
                                     lane: laneForRole[member.role] ?? .mid))
                id += 1
            }
        }
        self.units = built
        self.damageContributed = Array(repeating: [:], count: built.count)
        self.structureCredit = Array(repeating: nil, count: built.count)
        self.arrivedObjective = Array(repeating: nil, count: built.count)
        buildStructures()
        // Roll form after building, so both sides draw from the same stream.
        form[.blue] = rng.range(0.60, 1.40)
        form[.red]  = rng.range(0.60, 1.40)
    }

    /// Ensures exactly five role-distinct slots, so a short roster still fields a team.
    private static func padToFive(_ roster: [Player]) -> [Player] {
        var result: [Player] = []
        let byRole = Dictionary(grouping: roster, by: \.role)
        for role in [Role.offlaner, .jungler, .mid, .carry, .support] {
            if let exact = byRole[role]?.first {
                result.append(exact)
            } else {
                // Clone the best remaining player into the missing role slot.
                let fallback = roster.max { $0.stats.overall < $1.stats.overall }
                    ?? Player.blank(role: role)
                result.append(fallback.withRole(role))
            }
        }
        return result
    }

    private mutating func buildStructures() {
        var id = 0
        for side in [SimSide.blue, SimSide.red] {
            for lane in [Lane.top, .mid, .bot] {
                let path = RiftMap.path(lane, for: side)
                let total = pathLength(path)
                for fraction in RiftMap.towerFractions {
                    structures.append(SimStructure(id: id,
                                                   side: side,
                                                   lane: lane,
                                                   kind: .tower,
                                                   position: pointAlong(path, at: total * fraction),
                                                   maxHP: StructureKind.tower.maxHP,
                                                   hp: StructureKind.tower.maxHP,
                                                   tiebreak: rng.range(0, 1)))
                    id += 1
                }
            }
            let base = side == .blue ? RiftMap.blueBase : RiftMap.redBase
            structures.append(SimStructure(id: id,
                                           side: side,
                                           lane: .mid,
                                           kind: .nexus,
                                           position: base,
                                           maxHP: StructureKind.nexus.maxHP,
                                           hp: StructureKind.nexus.maxHP,
                                           tiebreak: rng.range(0, 1)))
            id += 1
        }
    }

    // MARK: Run

    mutating func run() -> SimOutcome {
        // Opening skirmish so the first minutes aren't silent.
        emit(kind: .rotation, side: nil, at: RiftMap.blueBase,
             text: "Both squads leave base — lanes set up.")

        while time < timeLimit && nexusWinner == nil {
            step()
        }

        if nexusWinner == nil {
            nexusWinner = judgeByAttrition()
            emit(kind: .nexus, side: nexusWinner, at: RiftMap.redBase,
                 text: "Time called. \(sideName(nexusWinner!)) lead on structures and take the match.")
        }

        return SimOutcome(winner: nexusWinner ?? .blue,
                          events: events,
                          units: units,
                          duration: time,
                          phaseWinners: phaseWinners(),
                          mvp: mvpName(),
                          starPlayName: starPlayName())
    }

    /// A tick is resolved in two phases: every unit plans from the *same*
    /// pre-tick snapshot, then all plans are committed together. Nothing a unit
    /// decides can depend on whether an earlier-indexed unit already moved,
    /// which is what keeps the two sides symmetric.
    /// Advances the match by one tick. Exposed so a UI can animate the rift
    /// frame by frame instead of jumping straight to the final score.
    mutating func step() {
        time += dt

        for i in units.indices where !units[i].alive {
            if time >= units[i].respawnAt {
                units[i].alive = true
                units[i].hp = units[i].maxHP
                units[i].position = RiftMap.seat(units[i].seat, side: units[i].side)
                arrivedObjective[i] = nil
                emit(kind: .respawn, side: units[i].side, at: units[i].position,
                     text: "\(units[i].name) is back on the map.")
            }
        }

        // Phase 1 — plan, against the frozen pre-tick board.
        var plans: [UnitPlan?] = Array(repeating: nil, count: units.count)
        var pendingDamage = [Double](repeating: 0, count: units.count)
        var pendingStructure = [Double](repeating: 0, count: structures.count)
        var pendingDragon = 0.0, pendingBaron = 0.0
        var dragonBySide: [SimSide: Double] = [:]
        var baronBySide: [SimSide: Double] = [:]
        for i in units.indices where units[i].alive {
            let planned = plan(for: i)
            plans[i] = planned
            if let t = planned.damageTo {
                pendingDamage[t] += planned.damageAmount
                damageContributed[t][i, default: 0] += planned.damageAmount
            }
            if let s = planned.structureHit { pendingStructure[s] += planned.structureDamage }
            switch planned.neutralHit {
            case .dragon:
                pendingDragon += planned.neutralDamage
                dragonBySide[units[i].side, default: 0] += planned.neutralDamage
            case .baron:
                pendingBaron += planned.neutralDamage
                baronBySide[units[i].side, default: 0] += planned.neutralDamage
            default: break
            }
        }

        // Towers shoot into the same buffers, so structure order cannot hand one
        // side the first strike either.
        for s in structures.indices where structures[s].alive {
            guard let targetIdx = nearestEnemyUnit(of: structures[s].side,
                                                   to: structures[s].position,
                                                   within: towerRange) else { continue }
            pendingDamage[targetIdx] += (structures[s].kind == .tower ? 34.0 : 55.0) * dt
            structureCredit[targetIdx] = structures[s].side
        }

        // Phase 2 — commit every plan.
        for i in units.indices {
            guard let plan = plans[i] else { continue }
            units[i].facing = plan.facing
            if let dest = plan.moveTo {
                units[i].position = units[i].position.moved(toward: dest, by: units[i].speed * dt)
            }
            if plan.marksArrived { arrivedObjective[i] = objectiveKey(for: units[i]) }
        }
        for s in structures.indices where pendingStructure[s] > 0 && structures[s].alive {
            structures[s].hp -= pendingStructure[s]
        }
        // Resolve structures that just fell. In a true mirror both bases can fall
        // on the same tick, so the resolution order is a seeded tiebreak rather
        // than array order — otherwise the side listed first always wins the
        // simultaneous race.
        var fallen: [(index: Int, tiebreak: Double)] = []
        for s in structures.indices where !structures[s].alive && !structures[s].wasDestroyed {
            structures[s].wasDestroyed = true
            fallen.append((s, structures[s].tiebreak))
        }
        fallen.sort { $0.tiebreak < $1.tiebreak }
        for entry in fallen {
            structureDestroyed(at: entry.index, by: structures[entry.index].side.opposite)
        }
        if pendingDragon > 0 {
            dragonHP -= pendingDragon
            for (side, dealt) in dragonBySide { dragonDamageBySide[side, default: 0] += dealt }
        }
        if pendingBaron > 0 {
            baronHP -= pendingBaron
            for (side, dealt) in baronBySide { baronDamageBySide[side, default: 0] += dealt }
        }

        for i in units.indices where pendingDamage[i] > 0 && units[i].alive {
            units[i].hp -= pendingDamage[i]
        }
        for i in units.indices where units[i].alive && units[i].hp <= 0 {
            let credit = structureCredit[i]
            structureCredit[i] = nil
            killUnit(victim: i, killer: topContributor(to: i), attributedTo: credit)
            damageContributed[i].removeAll()
        }

        resolveNeutralObjectives()
    }

    /// What a unit intends to do this tick. Pure: it only reads state.
    private struct UnitPlan {
        var facing: SimPoint
        var moveTo: SimPoint?
        var damageTo: Int?
        var damageAmount: Double
        var structureHit: Int?
        var structureDamage: Double
        var neutralHit: SimEventKind?
        var neutralDamage: Double
        var marksArrived: Bool
    }

    /// Priority is objective-first: a unit that has reached its objective hits it,
    /// otherwise it trades with an enemy in reach, otherwise it walks. Attacking
    /// only what is in reach — rather than chasing anything on screen — is what
    /// stops ten units locking into a permanent blob at mid.
    ///
    /// Damage is only ever dealt at an objective the unit has stood on
    /// (`arrivedObjective`). Without that, a unit travelling to a tower would
    /// already be hitting it from across the map.
    private mutating func plan(for i: Int) -> UnitPlan {
        let me = units[i]
        let objective = objectivePosition(for: me)
        let kind = objectiveKind(for: me)
        let distance = me.position.distance(to: objective)
        let onObjective = distance <= attackRange
        let arrived = onObjective || arrivedObjective[i] == objectiveKey(for: me)

        let hold = { UnitPlan(facing: objective, moveTo: nil, damageTo: nil,
                              damageAmount: 0, structureHit: nil, structureDamage: 0,
                              neutralHit: nil, neutralDamage: 0, marksArrived: onObjective) }

        // An objective the unit has already committed to — a live neutral it has
        // started hitting, or the enemy nexus once a base is open — outranks a
        // brawl. Without this the jungler starts a fight and forgets the dragon,
        // so a neutral is never actually finished.
        let committedToNeutral = onObjective &&
            (arrivedObjective[i] == -1 || arrivedObjective[i] == -2)
        let committedToNexus: Bool = {
            if case .structure(let idx) = kind { return structures[idx].kind == .nexus && arrived }
            return false
        }()
        let focused = committedToNeutral || committedToNexus

        // 1. On a structure, hit it — this is the behaviour that ends a game.
        if case .structure(let idx) = kind, arrived {
            var p = hold()
            p.structureHit = idx
            p.structureDamage = me.attack * dt * damageScale * effectiveSiege
                * tacticMultiplier(for: me.side, phase: phase(of: time))
                * sideMomentum(me.side)
            return p
        }
        // 2. On a neutral objective, hit it.
        if case .dragon = kind, arrived {
            var p = hold()
            p.neutralHit = .dragon
            p.neutralDamage = me.attack * dt * damageScale * 1.4 * sideMomentum(me.side)
            return p
        }
        if case .baron = kind, arrived {
            var p = hold()
            p.neutralHit = .baron
            p.neutralDamage = me.attack * dt * damageScale * 1.4 * sideMomentum(me.side)
            return p
        }
        // 3. Trade with an enemy in reach, unless we're finishing an objective.
        // Keep walking to the objective while trading: stopping dead to brawl
        // creates a permanent mid-map standoff where neither lane ever arrives,
        // so no tower or neutral is ever actually contested.
        if !focused, let targetIdx = nearestEnemyUnit(to: me, within: attackRange) {
            return UnitPlan(facing: units[targetIdx].position,
                            moveTo: onObjective ? nil : objective,
                            damageTo: targetIdx,
                            damageAmount: damageFrom(attacker: me, defender: units[targetIdx])
                                * dt * damageScale * tacticMultiplier(for: me.side, phase: phase(of: time))
                                * (0.85 + 0.30 * rng.noise(i, Int(time * 2))),
                            structureHit: nil, structureDamage: 0,
                            neutralHit: nil, neutralDamage: 0, marksArrived: onObjective)
        }
        // 4. Otherwise keep walking toward the objective.
        return UnitPlan(facing: objective, moveTo: objective, damageTo: nil,
                        damageAmount: 0, structureHit: nil, structureDamage: 0,
                        neutralHit: nil, neutralDamage: 0, marksArrived: onObjective)
    }

    /// The unit that dealt the most damage to a victim over its current life.
    /// Ties are broken by seeded noise so credit never depends on iteration order.
    private func topContributor(to victim: Int) -> Int? {
        let entries = damageContributed[victim]
        guard !entries.isEmpty else { return nil }
        let best = entries.values.max()!
        let tied = entries.filter { $0.value == best }.map { $0.key }.sorted()
        if tied.count == 1 { return tied[0] }
        return tied.min { rng.noise($0, victim) < rng.noise($1, victim) }
    }

    /// Picks the side that did the most to a neutral objective. Ties fall to the
    /// seeded RNG so neither side gains a default advantage.
    private mutating func dominantSide(_ damage: [SimSide: Double]) -> SimSide {
        let blue = damage[.blue] ?? 0
        let red = damage[.red] ?? 0
        if blue == red { return rng.chance(0.5) ? .blue : .red }
        return blue > red ? .blue : .red
    }

    private func objectiveKey(for unit: SimUnit) -> Int {
        switch objectiveKind(for: unit) {
        case .structure(let idx): return idx
        case .dragon:             return -1
        case .baron:              return -2
        case .defend:             return -3
        case .none:               return -4
        }
    }

    // MARK: Objectives

    private enum ObjectiveKind {
        case structure(Int), dragon, baron, defend(Int), none
    }

    private func objectiveKind(for unit: SimUnit) -> ObjectiveKind {
        // Defend first. If our base is open and an enemy is in our base, the only
        // correct play is to collapse on them — otherwise the game degenerates
        // into a base race that the faster pusher always wins.
        if nexusExposed(unit.side) {
            let ownNexus = structures.first { $0.kind == .nexus && $0.side == unit.side }?.position
                ?? (unit.side == .blue ? RiftMap.blueBase : RiftMap.redBase)
            if let invader = nearestEnemyUnit(of: unit.side, to: ownNexus, within: 0.30) {
                return .defend(invader)
            }
        }
        // Jungler prioritises neutral objectives once they are live. Baron opens
        // at 160s: with the snowball tuned in, an even match now closes around
        // 185s, so a 200s gate meant baron was still asleep when the nexus fell.
        if unit.lane == .jungle {
            if time > 160 && !baronKilled { return .baron }
            if time > 90 && !dragonKilled { return .dragon }
        }
        // Once the enemy base is open, everyone who can should close it out
        // rather than farming towers in a lane that no longer matters.
        if nexusExposed(unit.side.opposite),
           let nexus = structures.firstIndex(where: { $0.kind == .nexus && $0.side == unit.side.opposite }) {
            return .structure(nexus)
        }
        // Laners advance to the nearest standing enemy structure in their lane.
        let candidates = structures.enumerated().filter { _, s in
            s.alive && s.side == unit.side.opposite && s.lane == unit.lane
        }
        if let nearest = candidates.min(by: { a, b in
            unit.position.distance(to: a.element.position)
                < unit.position.distance(to: b.element.position)
        }) {
            return .structure(nearest.offset)
        }
        return .none
    }

    private func objectivePosition(for unit: SimUnit) -> SimPoint {
        switch objectiveKind(for: unit) {
        case .structure(let idx): return structures[idx].position
        case .defend(let idx):    return units[idx].position
        case .dragon:             return RiftMap.dragonPit
        case .baron:              return RiftMap.baronPit
        case .none:
            // The jungler has no lane, so its idle post is the map centre — the
            // point equidistant from both bases. Sending it to the end of a lane
            // path would park it next to the enemy base and silently bias the map.
            return unit.lane == .jungle ? SimPoint(x: 0.5, y: 0.5)
                                        : (RiftMap.path(unit.lane, for: unit.side).last ?? unit.position)
        }
    }

    /// A side's nexus is vulnerable once any single lane has lost all its towers,
    /// mirroring how an exposed inhibitor opens a base in a real MOBA.
    private func nexusExposed(_ side: SimSide) -> Bool {
        for lane in [Lane.top, .mid, .bot] {
            let standing = structures.contains {
                $0.side == side && $0.kind == .tower && $0.lane == lane && $0.alive
            }
            if !standing { return true }
        }
        return false
    }

    private mutating func resolveNeutralObjectives() {
        // Dragon and baron are damaged directly in `act`; deaths are resolved here
        // so a single killing blow maps to one event no matter how many units hit.
        if !dragonKilled && dragonHP <= 0 { claimNeutral(.dragon, by: dominantSide(dragonDamageBySide)) }
        if !baronKilled && baronHP <= 0 { claimNeutral(.baron, by: dominantSide(baronDamageBySide)) }
    }

    // Neutral objective HP, tracked alongside the structure array.
    private var dragonHP: Double = 700
    private var baronHP: Double = 1400
    // Damage each side has contributed to an objective over the whole fight.
    // The claim must be the side that did the most across the fight, not whichever
    // side happened to land the last noisy tick.
    private var dragonDamageBySide: [SimSide: Double] = [:]
    private var baronDamageBySide: [SimSide: Double] = [:]

    private mutating func claimNeutral(_ kind: SimEventKind, by side: SimSide) {
        switch kind {
        case .dragon:
            dragonKilled = true
            dragonWinner = side
            emit(kind: .dragon, side: side, at: RiftMap.dragonPit,
                 text: "\(sideName(side)) slay the dragon and take the mid-game buff.")
        case .baron:
            baronKilled = true
            baronWinner = side
            emit(kind: .baron, side: side, at: RiftMap.baronPit,
                 text: "\(sideName(side)) secure Baron — lanes push hard.")
        default:
            break
        }
    }

    // MARK: Structures & combat resolution

    private func damageFrom(attacker: SimUnit, defender: SimUnit) -> Double {
        let mitigation = 1.0 + defender.defense / 120.0
        return attacker.attack / mitigation * sideMomentum(attacker.side)
    }

    /// The form roll multiplied by banked snowball. Both scale a side's output —
    /// in fights and when pushing — so a good day or an early lead can decide the
    /// match, which is what makes upsets possible.
    private func sideMomentum(_ side: SimSide) -> Double {
        (form[side] ?? 1.0) * (1.0 + (momentum[side] ?? 0))
    }

    /// Siege strength grows as the match runs long, so a stalemate eventually
    /// breaks and bases fall instead of every even game ending on the clock.
    private var effectiveSiege: Double {
        let ramp = max(0, time - siegeRampStart) * siegeRampPerSecond
        return siegeMultiplier * (1.0 + ramp)
    }

    private mutating func killUnit(victim: Int, killer: Int?, attributedTo: SimSide? = nil) {
        let dead = units[victim]
        units[victim].alive = false
        units[victim].hp = 0
        units[victim].deaths += 1
        units[victim].respawnAt = time + respawnBase + Double(dead.deaths) * 1.5

        // Credit the unit that contributed the most damage, unless overridden.
        let effectiveKiller = killer
        let credit = effectiveKiller.map { units[$0].side } ?? attributedTo

        if let k = effectiveKiller, k != victim {
            units[k].kills += 1
        }

        let killerName = effectiveKiller.map { units[$0].name } ?? sideName(credit ?? .red)
        // The killing side banks a small lasting power lead.
        if let s = credit {
            momentum[s] = min(momentumCap, (momentum[s] ?? 0) + momentumPerKill)
        }
        let star = (effectiveKiller.map { units[$0].kills } ?? 0) >= 3
        if !firstBloodTaken {
            firstBloodTaken = true
            emit(kind: .firstBlood, side: credit, at: dead.position,
                 text: "FIRST BLOOD — \(killerName) opens the score.",
                 star: star)
        } else {
            emit(kind: .kill, side: credit, at: dead.position,
                 text: "\(killerName) takes down \(dead.name).",
                 star: star)
        }
    }

    private mutating func structureDestroyed(at index: Int, by side: SimSide) {
        let s = structures[index]
        let name = "\(sideName(s.side)) \(s.lane.display) \(s.kind == .nexus ? "nexus" : "tower")"
        switch s.kind {
        case .tower:
            if firstTowerDown == nil { firstTowerDown = side }
            emit(kind: .towerDown, side: side, at: s.position,
                 text: "\(name) falls — \(sideName(side)) push deeper.")
        case .nexus:
            // Only the first nexus to fall decides the match. Resolving a second
            // one in the same tick (possible in a base race) must not overwrite
            // the winner.
            if nexusWinner == nil { nexusWinner = side }
            emit(kind: .nexus, side: side, at: s.position,
                 text: "\(name) is destroyed. \(sideName(side)) win the match.")
        }
    }

    // MARK: Queries

    private func nearestEnemyUnit(to unit: SimUnit, within radius: Double) -> Int? {
        nearestEnemyUnit(of: unit.side, to: unit.position, within: radius)
    }

    private func nearestEnemyUnit(of side: SimSide, to point: SimPoint, within radius: Double) -> Int? {
        var best: (index: Int, distance: Double)?
        for (i, u) in units.enumerated() where u.alive && u.side == side.opposite {
            let d = u.position.distance(to: point)
            guard d <= radius else { continue }
            if best == nil || d < best!.distance { best = (i, d) }
        }
        return best?.index
    }

    private mutating func judgeByAttrition() -> SimSide {
        func towersRemaining(_ side: SimSide) -> Int {
            structures.filter { $0.side == side && $0.kind == .tower && $0.alive }.count
        }
        func totalKills(_ side: SimSide) -> Int {
            units.filter { $0.side == side }.reduce(0) { $0 + $1.kills }
        }
        let blueT = towersRemaining(.blue), redT = towersRemaining(.red)
        if blueT != redT { return blueT > redT ? .blue : .red }
        let blueK = totalKills(.blue), redK = totalKills(.red)
        if blueK != redK { return blueK > redK ? .blue : .red }
        // Genuinely even — let the seeded RNG decide instead of favouring blue.
        return rng.chance(0.5) ? .blue : .red
    }

    private func phaseWinners() -> [MatchPhase: SimSide?] {
        [.early: firstTowerDown,
         .mid:   dragonWinner,
         .late:  nexusWinner]
    }

    private func mvpName() -> String? {
        units.max { a, b in
            (a.kills * 3 - a.deaths) < (b.kills * 3 - b.deaths)
        }?.name
    }

    private func starPlayName() -> String? {
        units.first { $0.kills >= 3 }?.name
    }

    private func sideName(_ side: SimSide) -> String {
        side == playerSide ? "Blue" : "Red"
    }

    private func phase(of t: Double) -> MatchPhase {
        if t < timeLimit / 3 { return .early }
        if t < timeLimit * 2 / 3 { return .mid }
        return .late
    }

    /// Phase bonus for a specific side. The player's chosen tactic only boosts the
    /// player's own units; the opponent plays a neutral, always-adaptive baseline.
    /// Applying the player's tactic to both sides made the choice meaningless — it
    /// shifted both teams equally, so "DIVE vs SCALE" was really DIVE vs DIVE.
    private func tacticMultiplier(for side: SimSide, phase: MatchPhase) -> Double {
        let tactic = side == playerSide ? self.tactic : MatchTactic.adapt
        return 1.0 + Double(tactic.bonus(for: phase)) / 100.0
    }

    private mutating func emit(kind: SimEventKind, side: SimSide?, at position: SimPoint,
                               text: String, star: Bool = false) {
        eventCounter += 1
        events.append(SimEvent(id: eventCounter,
                               time: time,
                               kind: kind,
                               text: text,
                               side: side,
                               position: position,
                               phase: phase(of: time),
                               isStarPlay: star))
    }
}

// MARK: - Path helpers

private func pathLength(_ points: [SimPoint]) -> Double {
    guard points.count > 1 else { return 0 }
    return zip(points, points.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) }
}

private func pointAlong(_ points: [SimPoint], at distance: Double) -> SimPoint {
    guard let first = points.first, points.count > 1 else { return points.first ?? .zero }
    var remaining = distance
    var current = first
    for next in points.dropFirst() {
        let segment = current.distance(to: next)
        if remaining <= segment {
            return current.moved(toward: next, by: remaining)
        }
        remaining -= segment
        current = next
    }
    return points.last ?? current
}
