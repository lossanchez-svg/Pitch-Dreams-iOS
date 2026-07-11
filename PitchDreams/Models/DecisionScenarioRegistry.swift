import Foundation

/// Authored Game Moments, each tied to the animated lesson that teaches its
/// concept. Diagram coordinates use the same 0–100 pitch space as lessons
/// (attack toward the top: low y = their goal).
enum DecisionScenarioRegistry {

    static let all: [DecisionScenario] = [
        scanTouchAwayFromPressure,
        scanShoulderCheckEarly,
        rdePickTheFreeMan,
        rdeReDecideWhenLaneCloses,
        pressHeavyTouchTrigger,
        pressNoTriggerStayHome,
        switchAwayFromTheCrowd,
        patienceRecycleAndMove,
    ]

    static func scenario(for id: String) -> DecisionScenario? {
        all.first { $0.id == id }
    }

    static func scenarios(forLesson lessonId: String) -> [DecisionScenario] {
        all.filter { $0.lessonId == lessonId }
    }

    // MARK: - Three-Point Scan

    static let scanTouchAwayFromPressure = DecisionScenario(
        id: "gm-scan-touch-away",
        lessonId: "3point-scan",
        situation: "The ball is rolling to you. Your scan showed a defender closing from your right.",
        situationYoung: "The ball is coming! You peeked — a defender is running at your right side.",
        diagram: TacticalDiagramState(
            players: [
                TacticalPlayer(id: "you", x: 50, y: 60, type: .self_, label: "You", highlight: true),
                TacticalPlayer(id: "def1", x: 68, y: 52, type: .opponent, label: "D"),
                TacticalPlayer(id: "mate1", x: 30, y: 40, type: .teammate, label: "T"),
            ],
            arrows: [
                TacticalArrow(id: "pass-in", fromX: 50, fromY: 85, toX: 50, toY: 62, type: .pass),
            ],
            zones: [
                TacticalZone(id: "space-left", x: 22, y: 45, w: 18, h: 18, type: .space, label: "Space"),
            ],
            ball: BallPosition(x: 50, y: 78)
        ),
        options: [
            DecisionOption(
                id: "touch-left",
                label: "First touch left, into space",
                isBest: true,
                rationale: "Your scan already found the space — take your first touch into it, away from the pressure.",
                rationaleYoung: "You peeked and found the empty grass. Take the ball there — away from the defender!"
            ),
            DecisionOption(
                id: "touch-right",
                label: "First touch right",
                rationale: "That's straight into the defender your scan warned you about. The scan only helps if you use it.",
                rationaleYoung: "That's right where the defender is running! Your peek told you — go the other way."
            ),
            DecisionOption(
                id: "stop-dead",
                label: "Stop the ball and hold it",
                rationale: "Stopping invites the pressure to arrive. A moving first touch keeps you ahead of the defender.",
                rationaleYoung: "If you stand still, the defender catches you. Keep the ball moving!"
            ),
        ]
    )

    static let scanShoulderCheckEarly = DecisionScenario(
        id: "gm-scan-shoulder-early",
        lessonId: "check-your-shoulder",
        situation: "A pass is on its way to you. Your back is to their goal — and you haven't looked yet.",
        situationYoung: "A pass is coming and your back is turned. You haven't peeked yet!",
        diagram: TacticalDiagramState(
            players: [
                TacticalPlayer(id: "you", x: 50, y: 45, type: .self_, label: "You", highlight: true),
                TacticalPlayer(id: "def1", x: 54, y: 32, type: .opponent, label: "D"),
                TacticalPlayer(id: "passer", x: 50, y: 80, type: .teammate, label: "T"),
            ],
            arrows: [
                TacticalArrow(id: "pass-in", fromX: 50, fromY: 77, toX: 50, toY: 48, type: .pass),
            ],
            ball: BallPosition(x: 50, y: 70)
        ),
        options: [
            DecisionOption(
                id: "check-now",
                label: "Shoulder check while the ball travels",
                isBest: true,
                rationale: "The ball's travel time is free — use it to look. You'll know whether to turn before it arrives.",
                rationaleYoung: "Peek while the ball is still rolling! Then you already know what to do when it gets to you."
            ),
            DecisionOption(
                id: "turn-blind",
                label: "Turn with the ball right away",
                rationale: "Turning blind is how the ball gets stolen — there's a defender on your back you haven't seen.",
                rationaleYoung: "Spinning without peeking is how the sneaky defender steals it!"
            ),
            DecisionOption(
                id: "wait-then-look",
                label: "Control it first, then look around",
                rationale: "By then the defender has arrived. Looking after you receive is a beat too late.",
                rationaleYoung: "Too slow — the defender gets there while you're still looking."
            ),
        ]
    )

    // MARK: - Receive-Decide-Execute

    static let rdePickTheFreeMan = DecisionScenario(
        id: "gm-rde-free-man",
        lessonId: "receive-decide-execute",
        situation: "Clean first touch. Two defenders step toward you — and your winger is free on the left.",
        situationYoung: "Nice touch! Two defenders are coming — but look, your teammate is all alone on the left.",
        diagram: TacticalDiagramState(
            players: [
                TacticalPlayer(id: "you", x: 55, y: 55, type: .self_, label: "You", highlight: true),
                TacticalPlayer(id: "def1", x: 50, y: 42, type: .opponent, label: "D"),
                TacticalPlayer(id: "def2", x: 62, y: 44, type: .opponent, label: "D"),
                TacticalPlayer(id: "winger", x: 18, y: 40, type: .teammate, label: "T", highlight: true),
            ],
            zones: [
                TacticalZone(id: "left-wing", x: 8, y: 30, w: 20, h: 22, type: .opportunity, label: "Free"),
            ],
            ball: BallPosition(x: 55, y: 57)
        ),
        options: [
            DecisionOption(
                id: "pass-wing",
                label: "Pass to the free winger",
                isBest: true,
                rationale: "Receive, decide, execute — the free man is the decision, and speed of action beats perfection.",
                rationaleYoung: "Your teammate is all alone! Get them the ball before the defenders block the way."
            ),
            DecisionOption(
                id: "take-them-on",
                label: "Dribble at both defenders",
                rationale: "Two versus one is their maths, not yours. The framework exists so you don't force hero ball.",
                rationaleYoung: "Two defenders against you alone? Pass to your free teammate instead!"
            ),
            DecisionOption(
                id: "turn-back",
                label: "Turn back the way you came",
                rationale: "Safe, but it wastes the free winger. When a better option is on, hesitation is the mistake.",
                rationaleYoung: "Going backward when your friend is wide open wastes the chance!"
            ),
        ]
    )

    static let rdeReDecideWhenLaneCloses = DecisionScenario(
        id: "gm-rde-re-decide",
        lessonId: "receive-decide-execute",
        situation: "You decided to pass — but a defender just slid into the passing lane.",
        situationYoung: "You picked your pass — but a defender jumped into the way!",
        diagram: TacticalDiagramState(
            players: [
                TacticalPlayer(id: "you", x: 50, y: 60, type: .self_, label: "You", highlight: true),
                TacticalPlayer(id: "def-lane", x: 42, y: 48, type: .opponent, label: "D", highlight: true),
                TacticalPlayer(id: "mate-blocked", x: 32, y: 35, type: .teammate, label: "T"),
                TacticalPlayer(id: "mate-open", x: 72, y: 45, type: .teammate, label: "T"),
            ],
            ball: BallPosition(x: 50, y: 62)
        ),
        options: [
            DecisionOption(
                id: "re-decide",
                label: "Shift the ball, pick the next option",
                isBest: true,
                rationale: "Decisions have a shelf life. When the picture changes, run the chain again — there's a man open right.",
                rationaleYoung: "The picture changed, so change your plan! Your other teammate is open."
            ),
            DecisionOption(
                id: "force-it",
                label: "Force the pass anyway",
                rationale: "The lane is gone — that's a giveaway. Committing to a dead decision isn't bravery.",
                rationaleYoung: "The defender will steal that one. Pick a new pass!"
            ),
            DecisionOption(
                id: "freeze",
                label: "Hold the ball and wait",
                rationale: "Freezing lets the press arrive. Re-deciding fast is the skill this moment trains.",
                rationaleYoung: "If you just stand there, more defenders come. Decide again — fast!"
            ),
        ]
    )

    // MARK: - Press Triggers

    static let pressHeavyTouchTrigger = DecisionScenario(
        id: "gm-press-heavy-touch",
        lessonId: "press-triggers",
        situation: "Their defender takes a heavy touch — the ball rolls loose off his foot.",
        situationYoung: "Their defender messed up the touch — the ball got away from him!",
        diagram: TacticalDiagramState(
            players: [
                TacticalPlayer(id: "you", x: 45, y: 45, type: .self_, label: "You", highlight: true),
                TacticalPlayer(id: "def-heavy", x: 55, y: 32, type: .opponent, label: "D", highlight: true),
                TacticalPlayer(id: "mate1", x: 30, y: 50, type: .teammate, label: "T"),
            ],
            zones: [
                TacticalZone(id: "loose", x: 52, y: 36, w: 12, h: 10, type: .opportunity, label: "Loose!"),
            ],
            ball: BallPosition(x: 58, y: 40)
        ),
        options: [
            DecisionOption(
                id: "press-now",
                label: "Sprint and press now",
                isBest: true,
                rationale: "A heavy touch is a press trigger — the ball is nobody's for one second. That second is yours.",
                rationaleYoung: "The ball got loose — GO! That's exactly the moment to win it."
            ),
            DecisionOption(
                id: "hold-shape",
                label: "Hold your position",
                rationale: "Holding shape is right when there's no trigger. This IS the trigger — a loose ball begs to be won.",
                rationaleYoung: "Waiting is for when they're in control. The ball is loose — this is your chance!"
            ),
            DecisionOption(
                id: "drop-off",
                label: "Drop back toward your goal",
                rationale: "Dropping off gives him time to recover his mistake. Mistimed caution is still mistimed.",
                rationaleYoung: "If you back away, he gets the ball back. Go win it!"
            ),
        ]
    )

    static let pressNoTriggerStayHome = DecisionScenario(
        id: "gm-press-no-trigger",
        lessonId: "press-triggers",
        situation: "Their keeper has the ball on his foot — calm, head up, passing options everywhere.",
        situationYoung: "Their goalie has the ball, totally calm, with lots of friends to pass to.",
        diagram: TacticalDiagramState(
            players: [
                TacticalPlayer(id: "you", x: 50, y: 55, type: .self_, label: "You", highlight: true),
                TacticalPlayer(id: "keeper", x: 50, y: 12, type: .opponent, label: "GK"),
                TacticalPlayer(id: "cb1", x: 30, y: 22, type: .opponent, label: "D"),
                TacticalPlayer(id: "cb2", x: 70, y: 22, type: .opponent, label: "D"),
                TacticalPlayer(id: "mate1", x: 38, y: 58, type: .teammate, label: "T"),
            ],
            ball: BallPosition(x: 50, y: 15)
        ),
        options: [
            DecisionOption(
                id: "stay-compact",
                label: "Stay compact, wait for a trigger",
                isBest: true,
                rationale: "No trigger, no press. Charge now and he plays around you — a hole opens where you used to be.",
                rationaleYoung: "He's calm and ready — chasing now just tires you out. Wait for a mistake, then pounce."
            ),
            DecisionOption(
                id: "charge-keeper",
                label: "Charge the keeper",
                rationale: "Pressing without a trigger is a sprint for nothing — one pass beats you and your team is a player down.",
                rationaleYoung: "He'll just pass around you and now you're out of the game. Be patient!"
            ),
            DecisionOption(
                id: "push-line-up",
                label: "Push your whole line high",
                rationale: "Same problem at team scale: step up with no trigger and the space behind you is a gift.",
                rationaleYoung: "If everyone runs up with no reason, there's a big empty field behind you for them."
            ),
        ]
    )

    // MARK: - Switching the Play / Patience

    static let switchAwayFromTheCrowd = DecisionScenario(
        id: "gm-switch-far-side",
        lessonId: "switching-the-play",
        situation: "The whole defense has shifted to your side. Your far winger has the entire wing to himself.",
        situationYoung: "All the defenders came to your side! Your teammate on the other wing is totally alone.",
        diagram: TacticalDiagramState(
            players: [
                TacticalPlayer(id: "you", x: 72, y: 55, type: .self_, label: "You", highlight: true),
                TacticalPlayer(id: "def1", x: 62, y: 45, type: .opponent, label: "D"),
                TacticalPlayer(id: "def2", x: 76, y: 42, type: .opponent, label: "D"),
                TacticalPlayer(id: "def3", x: 68, y: 60, type: .opponent, label: "D"),
                TacticalPlayer(id: "far-wing", x: 15, y: 45, type: .teammate, label: "T", highlight: true),
            ],
            zones: [
                TacticalZone(id: "open-wing", x: 5, y: 30, w: 22, h: 30, type: .space, label: "Open"),
            ],
            ball: BallPosition(x: 72, y: 57)
        ),
        options: [
            DecisionOption(
                id: "switch",
                label: "Switch it to the far side",
                isBest: true,
                rationale: "They shifted — that's the invitation. One switch and your winger attacks an empty wing.",
                rationaleYoung: "Everyone's on your side — send it across! Your teammate has all the room."
            ),
            DecisionOption(
                id: "into-crowd",
                label: "Dribble into the crowd",
                rationale: "Three defenders came to take exactly this away. Playing into the shift is playing their game.",
                rationaleYoung: "Three defenders are right there! Don't run into the crowd."
            ),
            DecisionOption(
                id: "keep-this-side",
                label: "Recycle and stay on this side",
                rationale: "Sometimes right — but with the far wing this open, keeping it here lets them stay shifted.",
                rationaleYoung: "You could — but your friend is SO open. This is the moment to switch!"
            ),
        ]
    )

    static let patienceRecycleAndMove = DecisionScenario(
        id: "gm-patience-recycle",
        lessonId: "patience-in-possession",
        situation: "Everything forward is blocked — no lane, no runner, defenders set.",
        situationYoung: "Every way forward is blocked. The defenders are all set and waiting.",
        diagram: TacticalDiagramState(
            players: [
                TacticalPlayer(id: "you", x: 50, y: 55, type: .self_, label: "You", highlight: true),
                TacticalPlayer(id: "def1", x: 40, y: 42, type: .opponent, label: "D"),
                TacticalPlayer(id: "def2", x: 52, y: 40, type: .opponent, label: "D"),
                TacticalPlayer(id: "def3", x: 64, y: 43, type: .opponent, label: "D"),
                TacticalPlayer(id: "back", x: 50, y: 75, type: .teammate, label: "T"),
            ],
            zones: [
                TacticalZone(id: "congested", x: 35, y: 35, w: 34, h: 14, type: .danger, label: "Blocked"),
            ],
            ball: BallPosition(x: 50, y: 57)
        ),
        options: [
            DecisionOption(
                id: "recycle",
                label: "Play back and move the defense",
                isBest: true,
                rationale: "Backward isn't backward thinking — every recycled pass makes them shift, and shifting opens gaps.",
                rationaleYoung: "Passing back is smart! It makes the defenders move, and moving defenders leave gaps."
            ),
            DecisionOption(
                id: "force-middle",
                label: "Force it through the middle",
                rationale: "Into three set defenders, that's a turnover dressed as ambition. Patience is a decision too.",
                rationaleYoung: "That's right into three defenders — they'll take it. Keep the ball safe instead."
            ),
            DecisionOption(
                id: "boot-long",
                label: "Kick it long and chase",
                rationale: "Giving the ball away to avoid a decision is the one option that can't work. Keep it, move them.",
                rationaleYoung: "A big kick just gives the ball away. Your team has it — keep it!"
            ),
        ]
    )
}
