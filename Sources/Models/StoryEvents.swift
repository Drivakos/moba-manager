import Foundation

// MARK: - Story Line
struct StoryLine {
    let speaker: String
    let text: String
}

// MARK: - Story Event
struct StoryEvent {
    let id: String
    let lines: [StoryLine]
}

// MARK: - All Story Content
enum Story {

    // MARK: - Intro (first time playing)
    static let intro: [StoryLine] = [
        StoryLine(speaker: "REEVES", text: "Hey. You must be the new hire."),
        StoryLine(speaker: "REEVES", text: "I'm Coach Reeves. I ran this org for 12 years before my knees gave out."),
        StoryLine(speaker: "REEVES", text: "The org is broke. We got nothing. No players, no funding, no reputation."),
        StoryLine(speaker: "REEVES", text: "But this city is full of young talent. Kids grinding in cafes, training grounds..."),
        StoryLine(speaker: "REEVES", text: "Your job? Scout them. Build a team of five. Then beat everyone in the Arena."),
        StoryLine(speaker: "REEVES", text: "Oh — and watch out for AXIOM. They're the top org. They don't play nice."),
        StoryLine(speaker: "REEVES", text: "Walk into the ~~~ training patches or CAFE zones to find recruits. Good luck, coach."),
    ]

    // MARK: - Rival intro (first time talking to AXIOM rep)
    static let rivalIntro: [StoryLine] = [
        StoryLine(speaker: "AXIOM", text: "Oh. You're the new manager everyone's laughing about."),
        StoryLine(speaker: "AXIOM", text: "Reeves really scraped the bottom of the barrel this time."),
        StoryLine(speaker: "AXIOM", text: "Our roster has four international players. What do you have?"),
        StoryLine(speaker: "AXIOM", text: "Go back to scouting amateurs. You'll never reach the Grand Finals."),
    ]

    // MARK: - Post chapter dialogues
    static func postChapterDialogue(chapter: Int, won: Bool) -> [StoryLine] {
        if won {
            switch chapter {
            case 1:
                return [
                    StoryLine(speaker: "REEVES", text: "Not bad! People are starting to notice this team."),
                    StoryLine(speaker: "REEVES", text: "AXIOM has been watching. Step it up — the real matches are coming."),
                ]
            case 2:
                return [
                    StoryLine(speaker: "REEVES", text: "You're for real. I didn't think you'd get this far."),
                    StoryLine(speaker: "AXIOM",  text: "Enjoy it. The Grand Finals are a different beast entirely."),
                ]
            case 3:
                return [
                    StoryLine(speaker: "REEVES", text: "CHAMPIONS. I've waited 12 years for this moment."),
                    StoryLine(speaker: "REEVES", text: "The kids did it. YOU did it. This city won't forget this team."),
                ]
            default:
                return [StoryLine(speaker: "REEVES", text: "Keep pushing. More tournaments ahead.")]
            }
        } else {
            return [
                StoryLine(speaker: "REEVES", text: "Tough loss. Review the phases — figure out where it fell apart."),
                StoryLine(speaker: "REEVES", text: "Your team needs more practice. Keep scouting, keep training."),
            ]
        }
    }

    // MARK: - NPC locations
    static let npcs: [NPCData] = [
        NPCData(
            id: "reeves",
            col: 2, row: 4,
            color: "mentor",
            defaultDialogue: [
                StoryLine(speaker: "REEVES", text: "Get out there and scout. Training grounds and cafes."),
                StoryLine(speaker: "REEVES", text: "Once you have five players, hit the Arena."),
            ]
        ),
        NPCData(
            id: "rival",
            col: 13, row: 9,
            color: "rival",
            defaultDialogue: [
                StoryLine(speaker: "AXIOM", text: "Still here? Surprising."),
                StoryLine(speaker: "AXIOM", text: "Our org's win rate is 84%. You're wasting your time."),
            ]
        ),
    ]
}

// MARK: - NPC Data
struct NPCData {
    let id: String
    let col: Int
    let row: Int
    let color: String  // "mentor" or "rival"
    let defaultDialogue: [StoryLine]
}
