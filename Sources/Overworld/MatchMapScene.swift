import SpriteKit

// MARK: - MatchMapScene
// Draws a top-down GB-palette MOBA map (Summoner's Rift-style).
// Blue team (player) starts bottom-left; red team (opponent) starts top-right.
final class MatchMapScene: SKScene {

    // MARK: - Geometry
    private var cx: CGFloat { size.width  / 2 }
    private var cy: CGFloat { size.height / 2 }

    private var blueBasePos: CGPoint { CGPoint(x: cx - 95, y: cy - 90) }
    private var redBasePos:  CGPoint { CGPoint(x: cx + 95, y: cy + 90) }
    private var dragonPos:   CGPoint { CGPoint(x: cx + 40, y: cy - 38) }
    private var baronPos:    CGPoint { CGPoint(x: cx - 40, y: cy + 38) }

    // Lane waypoints: index 0 = blue base, 4 = red base
    private var botWaypoints: [CGPoint] { [
        blueBasePos,
        CGPoint(x: cx - 10,  y: cy - 88),
        CGPoint(x: cx + 40,  y: cy - 60),
        CGPoint(x: cx + 78,  y: cy - 10),
        redBasePos
    ] }
    private var topWaypoints: [CGPoint] { [
        blueBasePos,
        CGPoint(x: cx - 88,  y: cy + 10),
        CGPoint(x: cx - 60,  y: cy + 40),
        CGPoint(x: cx - 10,  y: cy + 78),
        redBasePos
    ] }
    private var midWaypoints: [CGPoint] { [
        blueBasePos,
        CGPoint(x: cx - 46,  y: cy - 46),
        CGPoint(x: cx,       y: cy),
        CGPoint(x: cx + 46,  y: cy + 46),
        redBasePos
    ] }
    private var jglWaypoints: [CGPoint] { [
        blueBasePos,
        CGPoint(x: cx - 50, y: cy - 25),
        dragonPos,
        baronPos,
        CGPoint(x: cx + 50, y: cy + 25),
        redBasePos
    ] }

    private func waypoints(for role: Role) -> [CGPoint] {
        switch role {
        case .carry:    return botWaypoints
        case .support:  return botWaypoints
        case .jungler:  return jglWaypoints
        case .mid:      return midWaypoints
        case .offlaner: return topWaypoints
        }
    }

    // MARK: - Nodes
    private var playerUnits: [SKShapeNode] = []
    private var oppUnits:    [SKShapeNode] = []
    private var playerRoles: [Role] = []
    private var oppRoles:    [Role] = []

    // 5 PC seats arranged in the blue base: 3 on top row, 2 on bottom row
    private var pcPositions: [CGPoint] {
        let b = blueBasePos
        let dx: CGFloat = 13
        let dy: CGFloat = 10
        return [
            CGPoint(x: b.x - dx, y: b.y + dy),
            CGPoint(x: b.x,      y: b.y + dy),
            CGPoint(x: b.x + dx, y: b.y + dy),
            CGPoint(x: b.x - dx / 2, y: b.y - dy),
            CGPoint(x: b.x + dx / 2, y: b.y - dy),
        ]
    }
    private var redNexusNode:  SKShapeNode!
    private var blueNexusNode: SKShapeNode!
    private var dragonNode:    SKShapeNode!
    private var baronNode:     SKShapeNode!

    // MARK: - Public API
    func configure(playerTeam: Team, opponent: Team) {
        scaleMode    = .resizeFill
        backgroundColor = .gbDarkest

        // Pad roles to 5
        playerRoles = padRoles(playerTeam.roster.map(\.role))
        oppRoles    = padRoles(opponent.roster.map(\.role))

        drawMap()
        buildUnits()
    }

    /// Animate one match phase. `completion` is called when all unit movement finishes.
    func animatePhase(_ phase: MatchPhase, playerWon: Bool, events: [MatchEvent], completion: @escaping () -> Void) {
        let idx = phaseIndex(phase)
        let moveDur = 0.45

        // Move player units toward the phase waypoint
        for (i, unit) in playerUnits.enumerated() {
            let role   = playerRoles[i]
            let pts    = waypoints(for: role)
            let target = pts[min(idx, pts.count - 1)]
            let jitter = CGPoint(x: CGFloat((i % 3) - 1) * 7, y: CGFloat(i / 3) * 5)
            unit.run(.move(to: target + jitter, duration: moveDur + Double(i) * 0.04))
        }

        // Move opponent units toward their mirrored waypoint
        for (i, unit) in oppUnits.enumerated() {
            let role       = oppRoles[i]
            let pts        = waypoints(for: role)
            let mirrorIdx  = pts.count - 1 - idx
            let target     = pts[max(0, mirrorIdx)]
            let jitter     = CGPoint(x: CGFloat((i % 3) - 1) * 7, y: -CGFloat(i / 3) * 5)
            unit.run(.move(to: target + jitter, duration: moveDur + Double(i) * 0.04))
        }

        // Fight bursts timed with events
        var burstDelay = moveDur + 0.1
        for event in events {
            let d = burstDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + d) { [weak self] in
                guard let self else { return }
                self.spawnFightBurst(phase: phase, isPositive: event.isPositive)
            }
            burstDelay += 0.7
        }

        // After all bursts: advance winner, recall loser
        let resolveDur = burstDelay + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + resolveDur) { [weak self] in
            guard let self else { completion(); return }
            if playerWon {
                self.advanceUnits(self.playerUnits, roles: self.playerRoles, fromIdx: idx, forward: true)
                self.recallUnits(self.oppUnits, toBase: self.redBasePos)
                self.pulseObjective(phase: phase, playerCapture: true)
            } else {
                self.recallPlayerUnitsToPCs()
                self.advanceUnits(self.oppUnits, roles: self.oppRoles, fromIdx: self.oppMirrorIdx(idx), forward: false)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { completion() }
        }
    }

    func animateVictory(playerWon: Bool) {
        let nexus = playerWon ? redNexusNode : blueNexusNode
        nexus?.run(.sequence([
            .scale(to: 1.6, duration: 0.12),
            .scale(to: 0.2, duration: 0.18),
            .scale(to: 0.0, duration: 0.12),
        ]))

        // Win/lose screen flash overlay
        let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        flash.fillColor   = playerWon ? .gbLightest : .gbDarkest
        flash.strokeColor = .clear
        flash.position    = CGPoint(x: cx, y: cy)
        flash.zPosition   = 99
        flash.alpha       = 0
        addChild(flash)
        flash.run(.sequence([
            .fadeAlpha(to: playerWon ? 0.7 : 0.85, duration: 0.12),
            .fadeOut(withDuration: 0.5),
            .removeFromParent()
        ]))
    }

    // MARK: - Map Drawing
    private func drawMap() {
        // Jungle floor
        addRect(size: CGSize(width: 232, height: 232),
                at: CGPoint(x: cx, y: cy),
                fill: SKColor(red: 0.10, green: 0.26, blue: 0.04, alpha: 1),
                stroke: .clear, z: 0)

        // Lanes (thick filled paths with darker inner line)
        drawLane(waypoints: botWaypoints, outerW: 16, innerW: 9)
        drawLane(waypoints: topWaypoints, outerW: 16, innerW: 9)
        drawLane(waypoints: midWaypoints, outerW: 18, innerW: 10)

        // River: two diagonal thick strokes crossing the map
        drawRiverLine(from: CGPoint(x: cx + 116, y: cy - 42), to: CGPoint(x: cx - 42, y: cy - 116))
        drawRiverLine(from: CGPoint(x: cx + 42,  y: cy + 116), to: CGPoint(x: cx - 116, y: cy + 42))

        // Bases
        drawBase(at: blueBasePos, isPlayer: true)
        drawBase(at: redBasePos,  isPlayer: false)

        // Objectives
        dragonNode = addObjectiveNode(at: dragonPos, letter: "D")
        baronNode  = addObjectiveNode(at: baronPos,  letter: "N")

        // Towers
        drawTowers()

        // Map border
        let border = SKShapeNode(rectOf: CGSize(width: 234, height: 234))
        border.fillColor   = .clear
        border.strokeColor = .gbLight
        border.lineWidth   = 1.5
        border.position    = CGPoint(x: cx, y: cy)
        border.zPosition   = 20
        addChild(border)
    }

    private func drawLane(waypoints pts: [CGPoint], outerW: CGFloat, innerW: CGFloat) {
        guard pts.count >= 2 else { return }
        let path = CGMutablePath()
        path.move(to: pts[0])
        pts.dropFirst().forEach { path.addLine(to: $0) }

        let outer = SKShapeNode(path: path)
        outer.strokeColor = SKColor(red: 0.52, green: 0.65, blue: 0.05, alpha: 1)
        outer.lineWidth   = outerW
        outer.lineCap     = .round
        outer.lineJoin    = .round
        outer.zPosition   = 1
        addChild(outer)

        let inner = SKShapeNode(path: path)
        inner.strokeColor = SKColor(red: 0.45, green: 0.58, blue: 0.04, alpha: 1)
        inner.lineWidth   = innerW
        inner.lineCap     = .round
        inner.zPosition   = 2
        addChild(inner)
    }

    private func drawRiverLine(from a: CGPoint, to b: CGPoint) {
        let path = CGMutablePath()
        path.move(to: a); path.addLine(to: b)
        let r = SKShapeNode(path: path)
        r.strokeColor = SKColor(red: 0.07, green: 0.18, blue: 0.28, alpha: 0.85)
        r.lineWidth   = 20
        r.zPosition   = 3
        addChild(r)
    }

    private func drawBase(at pos: CGPoint, isPlayer: Bool) {
        // Base platform
        let base = SKShapeNode(rectOf: CGSize(width: 56, height: 56))
        base.fillColor   = isPlayer
            ? SKColor(red: 0.18, green: 0.38, blue: 0.18, alpha: 1)
            : SKColor(red: 0.06, green: 0.12, blue: 0.06, alpha: 1)
        base.strokeColor = isPlayer ? .gbLight : .gbDark
        base.lineWidth   = 1.5
        base.position    = pos
        base.zPosition   = 3
        addChild(base)

        // Nexus (distinct shape inside base)
        let nexus = SKShapeNode(rectOf: CGSize(width: 15, height: 15))
        nexus.fillColor   = isPlayer ? .gbLightest : .gbDark
        nexus.strokeColor = isPlayer ? .gbDarkest  : .gbLight
        nexus.lineWidth   = 1
        nexus.position    = pos
        nexus.zPosition   = 7

        if isPlayer { blueNexusNode = nexus } else { redNexusNode = nexus }
        addChild(nexus)

        addLabel(isPlayer ? "B" : "R",
                 at: pos,
                 size: 8,
                 color: isPlayer ? .gbDarkest : .gbLightest,
                 z: 8)
    }

    @discardableResult
    private func addObjectiveNode(at pos: CGPoint, letter: String) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 11)
        node.fillColor   = SKColor(red: 0.20, green: 0.42, blue: 0.08, alpha: 1)
        node.strokeColor = .gbLight
        node.lineWidth   = 1.5
        node.position    = pos
        node.zPosition   = 5
        addChild(node)
        addLabel(letter, at: pos, size: 8, color: .gbLightest, z: 6)
        return node
    }

    private func drawTowers() {
        let blueTowers: [CGPoint] = [
            // Bot lane
            CGPoint(x: cx - 52, y: cy - 84),
            CGPoint(x: cx + 18, y: cy - 76),
            // Top lane
            CGPoint(x: cx - 84, y: cy - 52),
            CGPoint(x: cx - 76, y: cy + 18),
            // Mid
            CGPoint(x: cx - 60, y: cy - 60),
            CGPoint(x: cx - 28, y: cy - 28),
        ]
        let redTowers: [CGPoint] = [
            CGPoint(x: cx + 52, y: cy + 84),
            CGPoint(x: cx - 18, y: cy + 76),
            CGPoint(x: cx + 84, y: cy + 52),
            CGPoint(x: cx + 76, y: cy - 18),
            CGPoint(x: cx + 60, y: cy + 60),
            CGPoint(x: cx + 28, y: cy + 28),
        ]
        for pos in blueTowers { addTower(at: pos, isPlayer: true) }
        for pos in redTowers  { addTower(at: pos, isPlayer: false) }
    }

    private func addTower(at pos: CGPoint, isPlayer: Bool) {
        let t = SKShapeNode(rectOf: CGSize(width: 9, height: 9))
        t.fillColor   = isPlayer ? .gbLightest : .gbDark
        t.strokeColor = isPlayer ? .gbDarkest  : .gbDarkest
        t.lineWidth   = 1
        t.position    = pos
        t.zPosition   = 6
        addChild(t)
    }

    // MARK: - Unit Building
    private func buildUnits() {
        playerUnits = makeTeamUnits(roles: playerRoles, isPlayer: true)
        oppUnits    = makeTeamUnits(roles: oppRoles,    isPlayer: false)
        let seats = pcPositions
        for (i, unit) in playerUnits.enumerated() {
            unit.position = seats[min(i, seats.count - 1)]
        }
        oppUnits.forEach { $0.position = redBasePos }
    }

    private func makeTeamUnits(roles: [Role], isPlayer: Bool) -> [SKShapeNode] {
        roles.enumerated().map { _, role in
            let node = SKShapeNode(circleOfRadius: 7)
            node.fillColor   = isPlayer ? .gbLightest : SKColor(red: 0.32, green: 0.52, blue: 0.05, alpha: 1)
            node.strokeColor = isPlayer ? .gbDark      : .gbDarkest
            node.lineWidth   = 1.5
            node.zPosition   = 12

            let lbl = SKLabelNode(text: String(role.abbreviation.prefix(1)))
            lbl.fontName              = GB.font
            lbl.fontSize              = 7
            lbl.fontColor             = isPlayer ? .gbDarkest : .gbLightest
            lbl.verticalAlignmentMode = .center
            node.addChild(lbl)
            addChild(node)
            return node
        }
    }

    // MARK: - Phase Animation Helpers
    private func advanceUnits(_ units: [SKShapeNode], roles: [Role], fromIdx: Int, forward: Bool) {
        for (i, unit) in units.enumerated() {
            let pts    = waypoints(for: roles[i])
            let nextIdx = forward
                ? min(fromIdx + 1, pts.count - 1)
                : max(fromIdx - 1, 0)
            unit.run(.move(to: pts[nextIdx], duration: 0.35))
        }
    }

    private func recallPlayerUnitsToPCs() {
        let seats = pcPositions
        for (i, unit) in playerUnits.enumerated() {
            let seat  = seats[min(i, seats.count - 1)]
            let delay = Double(i) * 0.05
            unit.run(.sequence([
                .wait(forDuration: delay),
                .group([
                    .scale(to: 0.3, duration: 0.25),
                    .rotate(byAngle: .pi, duration: 0.25),
                ]),
                .move(to: seat, duration: 0),
                .group([
                    .scale(to: 1.0, duration: 0.2),
                    .rotate(byAngle: -.pi, duration: 0.2),
                ]),
            ]))
        }
    }

    private func recallUnits(_ units: [SKShapeNode], toBase base: CGPoint) {
        for (i, unit) in units.enumerated() {
            let delay = Double(i) * 0.05
            unit.run(.sequence([
                .wait(forDuration: delay),
                .group([
                    .scale(to: 0.3, duration: 0.25),
                    .rotate(byAngle: .pi, duration: 0.25),
                ]),
                .move(to: base, duration: 0),
                .group([
                    .scale(to: 1.0, duration: 0.2),
                    .rotate(byAngle: -.pi, duration: 0.2),
                ]),
            ]))
        }
    }

    private func spawnFightBurst(phase: MatchPhase, isPositive: Bool) {
        let pos: CGPoint
        switch phase {
        case .early: pos = CGPoint(x: cx - 25, y: cy - 75)
        case .mid:   pos = isPositive ? dragonPos : baronPos
        case .late:  pos = CGPoint(x: cx + 58, y: cy + 42)
        }

        // Impact ring
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.fillColor   = isPositive ? .gbLightest : .gbDark
        ring.strokeColor = isPositive ? .gbLight    : .gbDarkest
        ring.lineWidth   = 2
        ring.position    = pos
        ring.zPosition   = 15
        ring.setScale(0.4)
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 2.8, duration: 0.22), .fadeOut(withDuration: 0.3)]),
            .removeFromParent()
        ]))

        // Sword-clash sparks
        for _ in 0..<4 {
            let spark = SKShapeNode(circleOfRadius: 2)
            spark.fillColor = isPositive ? .gbLightest : .gbLight
            spark.strokeColor = .clear
            spark.position = pos
            spark.zPosition = 16
            addChild(spark)
            let dx = CGFloat.random(in: -14...14)
            let dy = CGFloat.random(in: -14...14)
            spark.run(.sequence([
                .group([
                    .move(to: CGPoint(x: pos.x + dx, y: pos.y + dy), duration: 0.25),
                    .fadeOut(withDuration: 0.25),
                ]),
                .removeFromParent()
            ]))
        }

        // Move nearest player unit toward fight point briefly
        if let unit = nearestUnit(to: pos, in: playerUnits) {
            let saved = unit.position
            unit.run(.sequence([
                .move(to: pos + CGPoint(x: -9, y: 0), duration: 0.12),
                .wait(forDuration: 0.18),
                .move(to: saved, duration: isPositive ? 0.0 : 0.25),
            ]))
        }
    }

    private func pulseObjective(phase: MatchPhase, playerCapture: Bool) {
        let obj: SKShapeNode? = phase == .mid ? (playerCapture ? dragonNode : baronNode) : nil
        guard let obj else { return }
        obj.run(.sequence([
            .scale(to: 1.5, duration: 0.14),
            .scale(to: 1.0, duration: 0.14),
        ]))
        obj.fillColor = playerCapture ? .gbLightest : .gbDarkest
    }

    // MARK: - Utilities
    private func phaseIndex(_ phase: MatchPhase) -> Int {
        switch phase { case .early: return 1; case .mid: return 2; case .late: return 3 }
    }

    private func oppMirrorIdx(_ playerIdx: Int) -> Int {
        // Opponent moves in reverse; mirror their position index
        return max(0, 4 - playerIdx)
    }

    private func nearestUnit(to point: CGPoint, in units: [SKShapeNode]) -> SKShapeNode? {
        units.min { a, b in
            distance(a.position, point) < distance(b.position, point)
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func padRoles(_ roles: [Role]) -> [Role] {
        let all: [Role] = [.carry, .support, .jungler, .mid, .offlaner]
        if roles.count >= 5 { return Array(roles.prefix(5)) }
        let missing = all.filter { !roles.contains($0) }
        return (roles + missing).prefix(5).map { $0 }
    }

    @discardableResult
    private func addLabel(_ text: String, at pos: CGPoint, size s: CGFloat, color: SKColor, z: CGFloat) -> SKLabelNode {
        let lbl = SKLabelNode(text: text)
        lbl.fontName              = GB.font
        lbl.fontSize              = s
        lbl.fontColor             = color
        lbl.verticalAlignmentMode = .center
        lbl.position              = pos
        lbl.zPosition             = z
        addChild(lbl)
        return lbl
    }

    @discardableResult
    private func addRect(size sz: CGSize, at pos: CGPoint, fill: SKColor, stroke: SKColor, z: CGFloat) -> SKShapeNode {
        let n = SKShapeNode(rectOf: sz)
        n.fillColor   = fill
        n.strokeColor = stroke
        n.position    = pos
        n.zPosition   = z
        addChild(n)
        return n
    }
}

// MARK: - CGPoint arithmetic
private func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}
