import Foundation

/// All daily tips shipped with the app. The home view rotates through these
/// deterministically so every kid sees the same tip on the same calendar day.
///
/// Tip curation principles:
/// - Short (under 140 chars ideally)
/// - Concrete and actionable, not motivational fluff
/// - Age-appropriate for 8–18; avoid jargon the youngest half won't know
/// - Real coaching insight, not generic advice
enum DailyTipRegistry {

    /// Full tip catalog. Add new entries at the end — the rotation index is
    /// stable across releases so you don't accidentally reshuffle yesterday's
    /// tip into today's slot.
    static let all: [DailyTip] = technical + mental + recovery + tactical

    /// Returns today's tip based on the calendar day-of-year, so the same
    /// tip shows everywhere for the whole day and rotates through the list
    /// across the year.
    static func todaysTip(date: Date = Date(), calendar: Calendar = .current) -> DailyTip {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let count = max(1, all.count)
        return all[(dayOfYear - 1) % count]
    }

    // MARK: - Technical

    private static let technical: [DailyTip] = [
        DailyTip(id: "t-001", category: .technical, text: "Touch the ball with the inside of your foot on every pass under 15 yards. More control than laces."),
        DailyTip(id: "t-002", category: .technical, text: "Your first touch decides the whole play. Cushion the ball away from pressure, not into it."),
        DailyTip(id: "t-003", category: .technical, text: "Juggle 10 times with your weak foot only. Today. Not tomorrow. Today."),
        DailyTip(id: "t-004", category: .technical, text: "When you shoot low and hard, aim for the side netting. Goalkeepers can't reach that."),
        DailyTip(id: "t-005", category: .technical, text: "Keep your head up for half a second longer on every touch. That's where vision starts."),
        DailyTip(id: "t-006", category: .technical, text: "Dribble with the outside of your foot when you need speed. Inside-foot dribbling is for tight spaces."),
        DailyTip(id: "t-007", category: .technical, text: "Chest trap: relax the shoulders on impact. A stiff chest rebounds the ball away from you."),
        DailyTip(id: "t-008", category: .technical, text: "Shoot through the ball, not AT it. Your follow-through should point where you want the ball to go."),
        DailyTip(id: "t-009", category: .technical, text: "Sole rolls aren't flashy. They ARE the foundation of every skill move. Do them every day."),
        DailyTip(id: "t-010", category: .technical, text: "Receive the ball with the foot furthest from pressure. This buys you an extra second."),
        DailyTip(id: "t-011", category: .technical, text: "Wall ball builds first touch faster than anything else. 5 minutes beats 20 minutes of drills."),
        DailyTip(id: "t-012", category: .technical, text: "If your weak foot feels weird, you're doing it right. Discomfort is how skill grows."),
    ]

    // MARK: - Mental

    private static let mental: [DailyTip] = [
        DailyTip(id: "m-001", category: .mental, text: "Mistakes aren't your enemy — not learning from them is. One lesson per mistake is the rule."),
        DailyTip(id: "m-002", category: .mental, text: "Before you get the ball, you should already know where it's going. Scan. Then scan again."),
        DailyTip(id: "m-003", category: .mental, text: "The player who runs when tired is the player who wins. Fatigue is almost always mental."),
        DailyTip(id: "m-004", category: .mental, text: "Big moments feel smaller when you've rehearsed them. Visualize the play before you take it."),
        DailyTip(id: "m-005", category: .mental, text: "Don't compare your start to someone else's middle. Every pro was average once."),
        DailyTip(id: "m-006", category: .mental, text: "After a bad touch, reset in 3 seconds. Holding on to it costs you the next 30."),
        DailyTip(id: "m-007", category: .mental, text: "Confidence is a habit, not a mood. Show up when you don't feel like it — that's how you build it."),
        DailyTip(id: "m-008", category: .mental, text: "Coachable > talented. Be the player coaches want to keep teaching."),
        DailyTip(id: "m-009", category: .mental, text: "Compete with yesterday's you, not today's teammate. Your real opponent is in the mirror."),
        DailyTip(id: "m-010", category: .mental, text: "Pressure is a privilege. Only players that matter feel it. Enjoy the moment."),
        DailyTip(id: "m-011", category: .mental, text: "Being tired is information, not a command. Ask: am I hurt, or just uncomfortable?"),
        DailyTip(id: "m-012", category: .mental, text: "Write down one thing you did well today. Tomorrow you'll remember your growth, not your mistakes."),
    ]

    // MARK: - Recovery

    private static let recovery: [DailyTip] = [
        DailyTip(id: "r-001", category: .recovery, text: "Sleep is where you get better. Missed drills you can make up; missed sleep you can't."),
        DailyTip(id: "r-002", category: .recovery, text: "Drink water before you feel thirsty. By the time you're thirsty, you're already slow."),
        DailyTip(id: "r-003", category: .recovery, text: "Stretch for 5 minutes after training, not before. Muscles are ready to lengthen when warm."),
        DailyTip(id: "r-004", category: .recovery, text: "Eat protein within an hour after hard training. Your muscles rebuild during this window."),
        DailyTip(id: "r-005", category: .recovery, text: "Rest days are training days. Growth happens when you're not running."),
        DailyTip(id: "r-006", category: .recovery, text: "Foam roll your hamstrings after soccer. Tight hamstrings steal sprint speed."),
        DailyTip(id: "r-007", category: .recovery, text: "If something hurts sharply, stop. Pain is your body's text message saying 'stop it.'"),
        DailyTip(id: "r-008", category: .recovery, text: "Soreness after a new movement is fine. Soreness in joints — knees, ankles — is a warning sign."),
        DailyTip(id: "r-009", category: .recovery, text: "No phone for 30 minutes before bed. Blue light wrecks deep sleep, and deep sleep builds muscle."),
        DailyTip(id: "r-010", category: .recovery, text: "Warm up for 10 minutes before every session. Cold muscles are injured muscles."),
        DailyTip(id: "r-011", category: .recovery, text: "One lazy day won't ruin your streak. Pushing through a real injury will end your season."),
        DailyTip(id: "r-012", category: .recovery, text: "Eat something small 30 minutes before training. Empty-tank sessions don't build anything."),
    ]

    // MARK: - Tactical

    private static let tactical: [DailyTip] = [
        DailyTip(id: "x-001", category: .tactical, text: "Create space BEFORE you ask for the ball. Run away, then cut back — that's when passes arrive."),
        DailyTip(id: "x-002", category: .tactical, text: "Defenders follow eyes. Look left, pass right — the slowest defender is the one you fooled."),
        DailyTip(id: "x-003", category: .tactical, text: "Don't chase the ball. Chase the space the ball is going to."),
        DailyTip(id: "x-004", category: .tactical, text: "Width wins games. If everyone piles in the middle, you're making it easier to defend."),
        DailyTip(id: "x-005", category: .tactical, text: "Pass and move. Standing still after a pass is how possession dies."),
        DailyTip(id: "x-006", category: .tactical, text: "When you have the ball, think: forward first, sideways second, backward only if forced."),
        DailyTip(id: "x-007", category: .tactical, text: "Defenders tell you where to pass. The covered teammate is telling you where NOT to go."),
        DailyTip(id: "x-008", category: .tactical, text: "One-twos break defenses. Pass and burst past your defender — receive on the other side."),
        DailyTip(id: "x-009", category: .tactical, text: "Corner kicks: near post, back post, or top of the box. Pick one before you run in."),
        DailyTip(id: "x-010", category: .tactical, text: "Press as a unit or don't press at all. One lonely presser is just giving the ball away."),
        DailyTip(id: "x-011", category: .tactical, text: "The best first touch takes you past a defender. That's a touch with intent, not just control."),
        DailyTip(id: "x-012", category: .tactical, text: "If you can't shoot, look for the cutback. The ball moving across the box beats shots from tight angles."),
    ]
}
