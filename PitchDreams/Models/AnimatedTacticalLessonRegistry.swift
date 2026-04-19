import Foundation

// MARK: - Animated Tactical Lesson Registry

/// Step-based animated versions of tactical lessons with per-step diagram states.
/// Ported from web `lib/tactical-lessons/registry.ts`.
enum AnimatedTacticalLessonRegistry {

    static let all: [AnimatedTacticalLesson] = [
        threePointScan,
        receiveDecideExecute,
        patienceInPossession,
        checkYourShoulder,
        pressTriggers,
        thirdManRun,
        switchingThePlay,
        blindSideMovement,
        controllingTheTempo,
        breathingUnderPressure,
    ]

    static func lesson(for id: String) -> AnimatedTacticalLesson? {
        all.first { $0.id == id }
    }

    static func lessons(for track: String) -> [AnimatedTacticalLesson] {
        all.filter { $0.track == track }
    }

    // MARK: - 1. 3-Point Scan (Scanning / Beginner)

    static let threePointScan = AnimatedTacticalLesson(
        id: "3point-scan",
        title: "3-Point Scan",
        track: "scanning",
        description: "Learn to scan left, right, and behind before the ball arrives. Elite players scan 3+ times before every touch.",
        difficulty: "beginner",
        steps: [
            TacticalStep(
                narration: "You're a central midfielder about to receive a pass. Two center-backs hold the line ahead, and a midfielder screens in front of them. Before the ball arrives — scan.",
                narrationYoung: "You're in the middle. A teammate is about to pass you the ball. Before it gets there — look around!",
                spotlightElementId: "self",
                spotlightCaption: "Watch yourself — the ball's on its way",
                spotlightCaptionYoung: "The ball is coming to YOU!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-left", x: 15, y: 48, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-forward", x: 56, y: 33, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-passer", x: 45, y: 82, type: .teammate, label: "CB"),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 32, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb-r", x: 62, y: 32, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-mid", x: 46, y: 44, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "incoming-pass", fromX: 45, fromY: 82, toX: 50, toY: 58, type: .pass, label: "Pass coming", delay: 0.5),
                    ],
                    ball: BallPosition(x: 45, y: 78)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "First scan: LEFT shoulder. Your left winger is unmarked with acres of space on the flank. Safe option noted.",
                narrationYoung: "First look: LEFT. Your teammate on the left has lots of space. That's a safe pass.",
                spotlightElementId: "tm-left",
                spotlightCaption: "Check your left winger",
                spotlightCaptionYoung: "Look LEFT — who's open?",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-left", x: 15, y: 48, type: .teammate, label: "LW", highlight: true),
                        TacticalPlayer(id: "tm-forward", x: 56, y: 33, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-passer", x: 45, y: 82, type: .teammate),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 32, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 62, y: 32, type: .opponent),
                        TacticalPlayer(id: "opp-mid", x: 46, y: 44, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "scan-left", fromX: 48, fromY: 53, toX: 22, toY: 46, type: .scan, label: "Scan 1"),
                    ],
                    zones: [
                        TacticalZone(id: "space-left", x: 3, y: 35, w: 22, h: 22, type: .space, label: "Space"),
                    ],
                    ball: BallPosition(x: 46, y: 72)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "Second scan: RIGHT shoulder. The right center-back is stepping forward to press you — that's danger. But notice: he's leaving a gap in the defensive line.",
                narrationYoung: "Second look: RIGHT. A defender is charging at you — watch out! But see, they're leaving a hole behind them.",
                spotlightElementId: "opp-cb-r",
                spotlightCaption: "Watch the defender stepping up",
                spotlightCaptionYoung: "A defender is running at you!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-left", x: 15, y: 48, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-forward", x: 56, y: 33, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-passer", x: 45, y: 82, type: .teammate),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 32, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 58, y: 42, type: .opponent, highlight: true),
                        TacticalPlayer(id: "opp-mid", x: 46, y: 44, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "scan-right", fromX: 52, fromY: 53, toX: 64, toY: 42, type: .scan, label: "Scan 2"),
                        TacticalArrow(id: "cb-pressing", fromX: 62, fromY: 32, toX: 58, toY: 42, type: .run, delay: 0.3),
                    ],
                    zones: [
                        TacticalZone(id: "danger-right", x: 54, y: 40, w: 16, h: 16, type: .danger, label: "Pressure"),
                    ],
                    ball: BallPosition(x: 48, y: 65)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "Third scan: Glance BEHIND. Your striker is level with the last defender — onside. And the gap left by the pressing CB? That's the channel for a through ball.",
                narrationYoung: "Third look: BEHIND. Your striker is ready to sprint. That hole the defender left is an open road now.",
                spotlightElementId: "tm-forward",
                spotlightCaption: "Check your striker — is a run on?",
                spotlightCaptionYoung: "Your striker is ready to RUN!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-left", x: 15, y: 48, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-forward", x: 56, y: 32, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "tm-passer", x: 45, y: 82, type: .teammate),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 32, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 58, y: 42, type: .opponent),
                        TacticalPlayer(id: "opp-mid", x: 46, y: 44, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "scan-behind", fromX: 50, fromY: 52, toX: 52, toY: 35, type: .scan, label: "Scan 3"),
                        TacticalArrow(id: "st-run", fromX: 56, fromY: 32, toX: 58, toY: 20, type: .run, label: "Timed run", delay: 0.5),
                    ],
                    zones: [
                        TacticalZone(id: "gap-channel", x: 44, y: 15, w: 22, h: 20, type: .opportunity, label: "Gap"),
                    ],
                    ball: BallPosition(x: 49, y: 60)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "3 scans done. You KNOW the picture. The right CB pressed, leaving a gap. Your ST times the run. Receive, turn left, thread it through the channel. That's how scanning wins games.",
                narrationYoung: "3 looks done. You know where everyone is. Get the ball, turn, and slide it through the gap to your striker!",
                spotlightElementId: "through-ball",
                spotlightCaption: "The payoff — through-ball",
                spotlightCaptionYoung: "Send the ball through the gap!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-left", x: 15, y: 48, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-forward", x: 57, y: 18, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "tm-passer", x: 45, y: 82, type: .teammate),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 32, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 56, y: 44, type: .opponent),
                        TacticalPlayer(id: "opp-mid", x: 46, y: 44, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "scan-left-ghost", fromX: 48, fromY: 53, toX: 22, toY: 46, type: .scan),
                        TacticalArrow(id: "scan-right-ghost", fromX: 52, fromY: 53, toX: 64, toY: 42, type: .scan, delay: 0.1),
                        TacticalArrow(id: "scan-behind-ghost", fromX: 50, fromY: 52, toX: 52, toY: 35, type: .scan, delay: 0.2),
                        TacticalArrow(id: "through-ball", fromX: 50, fromY: 54, toX: 55, toY: 20, type: .pass, label: "Through ball!", delay: 0.8),
                    ],
                    zones: [
                        TacticalZone(id: "gap-channel", x: 44, y: 12, w: 22, h: 18, type: .opportunity),
                    ],
                    ball: BallPosition(x: 50, y: 55)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "scanning.3point_scan"
    )

    // MARK: - 2. Receive-Decide-Execute (Decision Chain / Intermediate)

    static let receiveDecideExecute = AnimatedTacticalLesson(
        id: "receive-decide-execute",
        title: "Receive\u{2013}Decide\u{2013}Execute",
        track: "decision_chain",
        description: "The best players decide BEFORE the ball arrives. Learn the RDE chain: pre-scan, pick your option, then execute in one touch.",
        difficulty: "intermediate",
        steps: [
            TacticalStep(
                narration: "You're a central midfielder. The ball is coming from your right-back. Two opponents are closing you down. Most players panic here — but you've already scanned. You know your three options BEFORE the ball arrives.",
                narrationYoung: "You're about to get the ball. Two players are running to take it. Don't panic — you already looked around and know what to do.",
                spotlightElementId: "self",
                spotlightCaption: "Pressure's coming — you've already scanned",
                spotlightCaptionYoung: "Stay calm — you know what to do!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-rb", x: 78, y: 70, type: .teammate, label: "RB"),
                        TacticalPlayer(id: "tm-lw", x: 12, y: 45, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 32, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-cm2", x: 55, y: 68, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "opp-press1", x: 52, y: 50, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-press2", x: 38, y: 52, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-cb-l", x: 35, y: 30, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb-r", x: 58, y: 30, type: .opponent, label: "CB"),
                    ],
                    arrows: [
                        TacticalArrow(id: "incoming", fromX: 78, fromY: 70, toX: 48, toY: 58, type: .pass, label: "Pass coming", delay: 0.5),
                    ],
                    ball: BallPosition(x: 75, y: 68)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "DECIDE phase. The ball is still traveling. You've already scanned and identified three options: A) Switch to the open left winger. B) Through ball to the striker's run. C) Safe lay-off to your CM partner.",
                narrationYoung: "DECIDE. The ball is still flying. You have 3 choices: A) Pass far left. B) Pass forward to the striker. C) Easy pass sideways.",
                spotlightElementId: "tm-lw",
                spotlightCaption: "Three options — pick the best one",
                spotlightCaptionYoung: "You have 3 choices — which is best?",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-rb", x: 78, y: 70, type: .teammate),
                        TacticalPlayer(id: "tm-lw", x: 12, y: 45, type: .teammate, label: "LW", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 50, y: 32, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "tm-cm2", x: 55, y: 68, type: .teammate, label: "CM", highlight: true),
                        TacticalPlayer(id: "opp-press1", x: 50, y: 52, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 40, y: 53, type: .opponent),
                        TacticalPlayer(id: "opp-cb-l", x: 35, y: 30, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 58, y: 30, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "option-a", fromX: 44, fromY: 54, toX: 16, toY: 45, type: .scan, label: "A: Switch"),
                        TacticalArrow(id: "option-b", fromX: 46, fromY: 53, toX: 52, toY: 34, type: .scan, label: "B: Through", delay: 0.3),
                        TacticalArrow(id: "option-c", fromX: 47, fromY: 57, toX: 55, toY: 66, type: .scan, label: "C: Safe", delay: 0.6),
                    ],
                    zones: [
                        TacticalZone(id: "space-left", x: 2, y: 35, w: 20, h: 18, type: .space, label: "Open"),
                        TacticalZone(id: "pressure", x: 36, y: 48, w: 20, h: 12, type: .danger, label: "Pressure"),
                    ],
                    ball: BallPosition(x: 62, y: 63)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "Look at the back line. The right CB has drifted wide, creating a gap between the two center-backs. Your striker is level with the left CB — he's ONSIDE and about to burst into that gap. Option B is the killer ball.",
                narrationYoung: "Look at the defenders. One moved out wide and left a big hole in the middle. Your striker can run right through it!",
                spotlightElementId: "gap",
                spotlightCaption: "There's the killer gap",
                spotlightCaptionYoung: "A huge hole opened up!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-rb", x: 78, y: 70, type: .teammate),
                        TacticalPlayer(id: "tm-lw", x: 12, y: 45, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 48, y: 30, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "tm-cm2", x: 55, y: 68, type: .teammate),
                        TacticalPlayer(id: "opp-press1", x: 48, y: 52, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 40, y: 53, type: .opponent),
                        TacticalPlayer(id: "opp-cb-l", x: 35, y: 30, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb-r", x: 65, y: 28, type: .opponent, label: "CB", highlight: true),
                    ],
                    arrows: [
                        TacticalArrow(id: "cb-drift", fromX: 58, fromY: 30, toX: 65, toY: 28, type: .run),
                        TacticalArrow(id: "st-run", fromX: 48, fromY: 30, toX: 46, toY: 18, type: .run, label: "Run!", delay: 0.4),
                    ],
                    zones: [
                        TacticalZone(id: "gap", x: 38, y: 15, w: 24, h: 18, type: .opportunity, label: "Gap"),
                    ],
                    ball: BallPosition(x: 52, y: 60)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "RECEIVE phase. The ball arrives. Because you already decided, your first touch isn't random — it's deliberate. You let it run across your body to the left, opening your hips toward the target.",
                narrationYoung: "The ball is here. Your first touch pushes it to the left. Now your body is pointing where you want to pass.",
                spotlightElementId: "first-touch",
                spotlightCaption: "First touch — on purpose, not random",
                spotlightCaptionYoung: "First touch — put it where you want!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 44, y: 54, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-rb", x: 78, y: 70, type: .teammate),
                        TacticalPlayer(id: "tm-lw", x: 12, y: 45, type: .teammate),
                        TacticalPlayer(id: "tm-st", x: 47, y: 24, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "tm-cm2", x: 55, y: 68, type: .teammate),
                        TacticalPlayer(id: "opp-press1", x: 47, y: 52, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 41, y: 54, type: .opponent),
                        TacticalPlayer(id: "opp-cb-l", x: 35, y: 30, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 65, y: 28, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "first-touch", fromX: 48, fromY: 57, toX: 43, toY: 55, type: .pass, label: "1st touch"),
                    ],
                    zones: [
                        TacticalZone(id: "pressure-close", x: 38, y: 50, w: 14, h: 10, type: .danger),
                        TacticalZone(id: "gap", x: 38, y: 15, w: 24, h: 18, type: .opportunity, label: "Gap"),
                    ],
                    ball: BallPosition(x: 44, y: 55)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "EXECUTE. Second touch: the through ball. Weighted perfectly into the gap between the center-backs. Your striker is through on goal. The whole sequence took 2 seconds because you thought BEFORE the ball arrived.",
                narrationYoung: "GO! Second touch: slide the ball through the hole. Your striker is clear — one-on-one with the goalie!",
                spotlightElementId: "through-ball",
                spotlightCaption: "Two touches, two seconds, goal set up",
                spotlightCaptionYoung: "Slide it through — striker is IN!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 44, y: 54, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-rb", x: 78, y: 70, type: .teammate),
                        TacticalPlayer(id: "tm-lw", x: 12, y: 45, type: .teammate),
                        TacticalPlayer(id: "tm-st", x: 46, y: 14, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "tm-cm2", x: 55, y: 68, type: .teammate),
                        TacticalPlayer(id: "opp-press1", x: 46, y: 53, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 42, y: 55, type: .opponent),
                        TacticalPlayer(id: "opp-cb-l", x: 34, y: 28, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 65, y: 26, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "through-ball", fromX: 44, fromY: 53, toX: 46, toY: 16, type: .pass, label: "Through ball!"),
                        TacticalArrow(id: "ghost-a", fromX: 44, fromY: 54, toX: 16, toY: 45, type: .scan, delay: 0.5),
                        TacticalArrow(id: "ghost-b", fromX: 46, fromY: 53, toX: 52, toY: 34, type: .scan, delay: 0.6),
                        TacticalArrow(id: "ghost-c", fromX: 47, fromY: 57, toX: 55, toY: 66, type: .scan, delay: 0.7),
                    ],
                    zones: [
                        TacticalZone(id: "gap-split", x: 38, y: 8, w: 24, h: 22, type: .opportunity),
                    ],
                    ball: BallPosition(x: 45, y: 30)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "decision_chain.receive_decide_execute"
    )

    // MARK: - 3. Patience in Possession (Tempo / Intermediate)

    static let patienceInPossession = AnimatedTacticalLesson(
        id: "patience-in-possession",
        title: "Patience in Possession",
        track: "tempo",
        description: "Rushing leads to turnovers. Learn when to hold, shield, and wait for the right moment to release the ball.",
        difficulty: "intermediate",
        steps: [
            TacticalStep(
                narration: "You're a midfielder who just received the ball. Two opponents are pressing you immediately. Every forward option is covered. Rushing now means a turnover. This is where patience wins.",
                narrationYoung: "You have the ball. Two players are crashing in. Every forward pass is blocked. If you rush, you'll lose it.",
                spotlightElementId: "pressure-zone",
                spotlightCaption: "Every forward option is blocked",
                spotlightCaptionYoung: "Too many defenders — don't rush!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 50, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-press1", x: 52, y: 47, type: .opponent, label: "CM", highlight: true),
                        TacticalPlayer(id: "opp-press2", x: 38, y: 48, type: .opponent, label: "CM", highlight: true),
                        TacticalPlayer(id: "tm-lw", x: 18, y: 38, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 28, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-rw", x: 80, y: 35, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 36, type: .opponent, label: "LB"),
                        TacticalPlayer(id: "opp-cb", x: 48, y: 26, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-rb", x: 75, y: 33, type: .opponent, label: "RB"),
                        TacticalPlayer(id: "tm-cb", x: 42, y: 75, type: .teammate, label: "CB"),
                    ],
                    zones: [
                        TacticalZone(id: "pressure-zone", x: 34, y: 44, w: 24, h: 14, type: .danger, label: "Pressure"),
                    ],
                    ball: BallPosition(x: 45, y: 50)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "SHIELD. Put your body between the ball and the nearest opponent. Drop your shoulder, keep the ball on your far foot. You've just bought yourself 2 seconds. That's an eternity in football.",
                narrationYoung: "SHIELD. Use your body to protect the ball. Keep it on the foot furthest from the defender. You just bought 2 seconds — a long time!",
                spotlightElementId: "self",
                spotlightCaption: "Shield the ball with your body",
                spotlightCaptionYoung: "Protect the ball!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 43, y: 50, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-press1", x: 48, y: 48, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-press2", x: 36, y: 49, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 18, y: 38, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 28, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-rw", x: 80, y: 35, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 36, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 48, y: 26, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 75, y: 33, type: .opponent),
                        TacticalPlayer(id: "tm-cb", x: 42, y: 75, type: .teammate, label: "CB"),
                    ],
                    zones: [
                        TacticalZone(id: "shield-zone", x: 40, y: 47, w: 12, h: 8, type: .space, label: "Shield"),
                    ],
                    ball: BallPosition(x: 41, y: 51)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "While you hold, your teammates MOVE. The left winger drops deep. The striker drifts wide. The right winger makes a run in behind. Patience creates options that didn't exist 2 seconds ago.",
                narrationYoung: "While you hold, your friends move. New passing options pop up that weren't there before. Waiting made them happen!",
                spotlightElementId: "tm-rw",
                spotlightCaption: "Teammates make new options appear",
                spotlightCaptionYoung: "New passes are opening up!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 43, y: 50, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-press1", x: 48, y: 48, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 37, y: 50, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 22, y: 46, type: .teammate, label: "LW", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 62, y: 30, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-rw", x: 72, y: 22, type: .teammate, label: "RW", highlight: true),
                        TacticalPlayer(id: "opp-lb", x: 24, y: 40, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 60, y: 28, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-rb", x: 70, y: 30, type: .opponent, label: "RB"),
                        TacticalPlayer(id: "tm-cb", x: 42, y: 75, type: .teammate),
                    ],
                    arrows: [
                        TacticalArrow(id: "lw-drop", fromX: 18, fromY: 38, toX: 22, toY: 46, type: .run, label: "Drops"),
                        TacticalArrow(id: "st-drift", fromX: 50, fromY: 28, toX: 62, toY: 30, type: .run, delay: 0.3),
                        TacticalArrow(id: "rw-run", fromX: 80, fromY: 35, toX: 72, toY: 22, type: .run, label: "Run!", delay: 0.5),
                    ],
                    zones: [
                        TacticalZone(id: "new-lane", x: 25, y: 43, w: 16, h: 10, type: .space, label: "New lane"),
                        TacticalZone(id: "space-behind", x: 66, y: 16, w: 18, h: 14, type: .opportunity, label: "Space"),
                    ],
                    ball: BallPosition(x: 41, y: 51)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "NOW. The RB is caught between covering the ST and tracking the RW's run — he can't do both. That hesitation is your TRIGGER. The moment you see it, release the ball.",
                narrationYoung: "NOW. The defender is stuck. They can't guard both your players. The second they freeze — that's your moment. GO.",
                spotlightElementId: "opp-rb",
                spotlightCaption: "Defender frozen — your trigger",
                spotlightCaptionYoung: "Defender is stuck — release it!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 43, y: 50, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-press1", x: 48, y: 49, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 38, y: 51, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 22, y: 46, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 62, y: 30, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-rw", x: 68, y: 18, type: .teammate, label: "RW", highlight: true),
                        TacticalPlayer(id: "opp-lb", x: 24, y: 42, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 60, y: 28, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 68, y: 28, type: .opponent, label: "RB", highlight: true),
                        TacticalPlayer(id: "tm-cb", x: 42, y: 75, type: .teammate),
                    ],
                    zones: [
                        TacticalZone(id: "rb-dilemma", x: 62, y: 24, w: 14, h: 12, type: .danger, label: "Stuck!"),
                        TacticalZone(id: "space-behind", x: 62, y: 10, w: 18, h: 14, type: .opportunity, label: "Space"),
                    ],
                    ball: BallPosition(x: 41, y: 51)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "The pass. Played into the space behind the RB, perfectly weighted for the RW's run. If you'd rushed 3 seconds ago, this option didn't exist. Patience in possession isn't slow — it's SMART.",
                narrationYoung: "THE PASS. Right into the space behind the defender. 3 seconds ago this pass wasn't open. Patience isn't slow — it's smart!",
                spotlightElementId: "release-pass",
                spotlightCaption: "Release — perfect weight, perfect timing",
                spotlightCaptionYoung: "Perfect pass into the space!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 43, y: 50, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-press1", x: 47, y: 49, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 39, y: 51, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 22, y: 46, type: .teammate),
                        TacticalPlayer(id: "tm-st", x: 62, y: 30, type: .teammate),
                        TacticalPlayer(id: "tm-rw", x: 66, y: 12, type: .teammate, label: "RW", highlight: true),
                        TacticalPlayer(id: "opp-lb", x: 24, y: 42, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 60, y: 28, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 68, y: 26, type: .opponent),
                        TacticalPlayer(id: "tm-cb", x: 42, y: 75, type: .teammate),
                    ],
                    arrows: [
                        TacticalArrow(id: "release-pass", fromX: 43, fromY: 49, toX: 65, toY: 14, type: .pass, label: "Release!"),
                    ],
                    zones: [
                        TacticalZone(id: "space-exploited", x: 60, y: 6, w: 18, h: 14, type: .opportunity),
                    ],
                    ball: BallPosition(x: 58, y: 28)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "tempo.patience_in_possession"
    )

    // MARK: - 4. Check Your Shoulder (Scanning / Intermediate)

    static let checkYourShoulder = AnimatedTacticalLesson(
        id: "check-your-shoulder",
        title: "Check Your Shoulder",
        track: "scanning",
        description: "The best midfielders check their shoulder every 4-6 seconds. Learn the habit that separates good from elite.",
        difficulty: "intermediate",
        steps: [
            TacticalStep(
                narration: "You're a central midfielder with your back to the opponent's goal. The ball is coming. Most players just wait and receive — then panic because they don't know what's behind them.",
                narrationYoung: "Your back is to the goal. The ball is coming. Most kids just wait — then panic because they don't know what's behind them.",
                spotlightElementId: "blind-spot",
                spotlightCaption: "What's behind you? You need to know",
                spotlightCaptionYoung: "Danger behind — you can't see!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 52, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-passer", x: 55, y: 75, type: .teammate, label: "RB"),
                        TacticalPlayer(id: "opp-press", x: 48, y: 44, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-press2", x: 56, y: 46, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 40, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 25, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 24, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 60, y: 24, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "incoming", fromX: 55, fromY: 75, toX: 50, toY: 55, type: .pass, label: "Incoming", delay: 0.5),
                    ],
                    zones: [
                        TacticalZone(id: "blind-spot", x: 40, y: 38, w: 22, h: 14, type: .danger, label: "Blind spot"),
                    ],
                    ball: BallPosition(x: 55, y: 72)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "FIRST CHECK: 3 seconds before the ball arrives, glance over your LEFT shoulder. You spot the CM closing from behind-left. Now you know: don't turn left.",
                narrationYoung: "FIRST CHECK. Look over your LEFT shoulder. A defender is coming from behind — don't turn that way!",
                spotlightElementId: "opp-press",
                spotlightCaption: "Spotted — CM pressing from behind-left",
                spotlightCaptionYoung: "Watch left — someone's chasing!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 52, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-passer", x: 55, y: 75, type: .teammate, label: "RB"),
                        TacticalPlayer(id: "opp-press", x: 48, y: 44, type: .opponent, label: "CM", highlight: true),
                        TacticalPlayer(id: "opp-press2", x: 56, y: 46, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 40, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 25, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 24, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 60, y: 24, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "check-left", fromX: 48, fromY: 50, toX: 42, toY: 44, type: .scan, label: "Check 1"),
                    ],
                    zones: [
                        TacticalZone(id: "danger-left", x: 42, y: 40, w: 12, h: 10, type: .danger, label: "Danger"),
                    ],
                    ball: BallPosition(x: 54, y: 68)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "SECOND CHECK: 1 second before the ball arrives, quick glance RIGHT. The other CM is closing too, but there's a gap between them. That gap is your escape route.",
                narrationYoung: "SECOND CHECK. Look RIGHT. Another defender is coming — but look, there's a small gap between them. That's your way out!",
                spotlightElementId: "gap",
                spotlightCaption: "Gap between defenders — your escape",
                spotlightCaptionYoung: "See the gap? That's your exit!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 52, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-passer", x: 55, y: 75, type: .teammate),
                        TacticalPlayer(id: "opp-press", x: 47, y: 44, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-press2", x: 55, y: 45, type: .opponent, label: "CM", highlight: true),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 40, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 25, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 24, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 60, y: 24, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "check-right", fromX: 52, fromY: 50, toX: 58, toY: 44, type: .scan, label: "Check 2"),
                    ],
                    zones: [
                        TacticalZone(id: "gap", x: 48, y: 41, w: 8, h: 10, type: .opportunity, label: "Gap"),
                    ],
                    ball: BallPosition(x: 52, y: 60)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "Ball arrives. Because you checked TWICE, you know exactly where the gap is. First touch goes FORWARD through the gap between the two midfielders.",
                narrationYoung: "The ball is here. Because you checked twice, you know the gap is there. First touch goes FORWARD — right through the middle!",
                spotlightElementId: "touch-through",
                spotlightCaption: "First touch forward through the gap",
                spotlightCaptionYoung: "First touch — forward!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 48, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-passer", x: 55, y: 75, type: .teammate),
                        TacticalPlayer(id: "opp-press", x: 46, y: 44, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 54, y: 44, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 40, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 25, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 24, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 60, y: 24, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "touch-through", fromX: 50, fromY: 52, toX: 50, toY: 48, type: .pass, label: "Touch!"),
                    ],
                    ball: BallPosition(x: 50, y: 48)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "Two shoulder checks. One smart touch. Now you're facing forward with the ball, past two midfielders. Check your shoulder every 4-6 seconds — it's the cheapest way to gain an advantage.",
                narrationYoung: "Two looks. One smart touch. Now you're facing the right way, past two defenders. Look behind you every few seconds — it's free info!",
                spotlightElementId: "to-st",
                spotlightCaption: "Two checks, one smart touch, forward!",
                spotlightCaptionYoung: "You did it — pass forward!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 46, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-passer", x: 55, y: 75, type: .teammate),
                        TacticalPlayer(id: "opp-press", x: 46, y: 48, type: .opponent),
                        TacticalPlayer(id: "opp-press2", x: 54, y: 48, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 25, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "opp-cb-l", x: 38, y: 24, type: .opponent),
                        TacticalPlayer(id: "opp-cb-r", x: 60, y: 24, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "ghost-l", fromX: 48, fromY: 50, toX: 42, toY: 44, type: .scan),
                        TacticalArrow(id: "ghost-r", fromX: 52, fromY: 50, toX: 58, toY: 44, type: .scan, delay: 0.1),
                        TacticalArrow(id: "to-st", fromX: 50, fromY: 45, toX: 50, toY: 27, type: .pass, label: "Forward!", delay: 0.5),
                        TacticalArrow(id: "to-lw", fromX: 48, fromY: 45, toX: 18, toY: 38, type: .scan, delay: 0.7),
                    ],
                    ball: BallPosition(x: 50, y: 46)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "scanning.shoulder_check"
    )

    // MARK: - 5. Press Triggers (Decision Chain / Beginner)

    static let pressTriggers = AnimatedTacticalLesson(
        id: "press-triggers",
        title: "Press Triggers",
        track: "decision_chain",
        description: "Know WHEN to press and when to hold. Read the 3 triggers that tell you it's time to win the ball back.",
        difficulty: "beginner",
        steps: [
            TacticalStep(
                narration: "The opponent has the ball. Your instinct says: CHASE! But pressing randomly wastes energy and opens gaps. Smart teams wait for a TRIGGER — a signal that tells you now is the time to press.",
                narrationYoung: "They have the ball. You want to CHASE! But chasing too soon wastes your energy. Smart teams wait for a SIGNAL that says 'go now'.",
                spotlightElementId: "self",
                spotlightCaption: "Wait for the signal, don't chase blindly",
                spotlightCaptionYoung: "Wait — don't chase yet!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 48, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-partner", x: 42, y: 46, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "tm-lw", x: 20, y: 40, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-rw", x: 78, y: 40, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "opp-cb", x: 50, y: 30, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb2", x: 35, y: 28, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cm", x: 45, y: 38, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-rb", x: 70, y: 25, type: .opponent, label: "RB"),
                    ],
                    ball: BallPosition(x: 50, y: 30)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "TRIGGER 1: Bad touch. The CB takes a heavy first touch and the ball bounces away. That's your signal! A bad touch means the opponent needs an extra second to control — that's your window to press.",
                narrationYoung: "SIGNAL 1: Bad touch. The defender kicks it too hard and the ball bounces away. That's your moment — SPRINT at them!",
                spotlightElementId: "bad-touch",
                spotlightCaption: "Bad touch = trigger — press NOW",
                spotlightCaptionYoung: "Bad touch — GO!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 48, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-partner", x: 42, y: 46, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "tm-lw", x: 20, y: 40, type: .teammate),
                        TacticalPlayer(id: "tm-rw", x: 78, y: 40, type: .teammate),
                        TacticalPlayer(id: "opp-cb", x: 50, y: 30, type: .opponent, label: "CB", highlight: true),
                        TacticalPlayer(id: "opp-cb2", x: 35, y: 28, type: .opponent),
                        TacticalPlayer(id: "opp-cm", x: 45, y: 38, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 70, y: 25, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "press-now", fromX: 50, fromY: 48, toX: 50, toY: 34, type: .run, label: "PRESS!", delay: 0.3),
                    ],
                    zones: [
                        TacticalZone(id: "bad-touch", x: 47, y: 26, w: 12, h: 10, type: .opportunity, label: "Bad touch!"),
                    ],
                    ball: BallPosition(x: 54, y: 27)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "TRIGGER 2: Backward pass. When an opponent passes BACKWARD to their CB, the ball is traveling, the receiver isn't set — press the receiver WHILE the ball is moving.",
                narrationYoung: "SIGNAL 2: Backward pass. When they pass BACK toward their own goal, the ball is moving and the catcher isn't ready. Chase the catcher!",
                spotlightElementId: "back-pass",
                spotlightCaption: "Backward pass = trigger — chase the receiver",
                spotlightCaptionYoung: "Backward pass — GO chase it!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 44, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-partner", x: 42, y: 42, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "tm-lw", x: 20, y: 38, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-rw", x: 78, y: 38, type: .teammate),
                        TacticalPlayer(id: "opp-cm", x: 45, y: 36, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-cb", x: 42, y: 26, type: .opponent, label: "CB", highlight: true),
                        TacticalPlayer(id: "opp-cb2", x: 58, y: 26, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 70, y: 25, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "back-pass", fromX: 45, fromY: 36, toX: 42, toY: 28, type: .pass, label: "Back pass"),
                        TacticalArrow(id: "press-cb", fromX: 50, fromY: 44, toX: 44, toY: 30, type: .run, label: "PRESS!", delay: 0.4),
                    ],
                    zones: [
                        TacticalZone(id: "intercept", x: 38, y: 26, w: 12, h: 8, type: .opportunity, label: "Arrive together"),
                    ],
                    ball: BallPosition(x: 44, y: 34)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "TRIGGER 3: Receiver facing their own goal. When an opponent receives with their back to you, they can't see what's coming. Press hard! Cut off the turn and you win the ball.",
                narrationYoung: "SIGNAL 3: Back turned. When a defender catches the ball facing their own goal, they can't see you. Press hard — don't let them turn!",
                spotlightElementId: "opp-cm",
                spotlightCaption: "Back to you = blind — press the turn",
                spotlightCaptionYoung: "They can't see you — CHARGE!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 48, y: 46, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-partner", x: 40, y: 44, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "tm-lw", x: 20, y: 38, type: .teammate),
                        TacticalPlayer(id: "tm-rw", x: 78, y: 38, type: .teammate),
                        TacticalPlayer(id: "opp-cm", x: 46, y: 38, type: .opponent, label: "CM", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 42, y: 26, type: .opponent),
                        TacticalPlayer(id: "opp-cb2", x: 58, y: 26, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 70, y: 28, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "pass-to-cm", fromX: 42, fromY: 26, toX: 46, toY: 36, type: .pass),
                        TacticalArrow(id: "press-behind", fromX: 48, fromY: 46, toX: 46, toY: 40, type: .run, label: "PRESS!", delay: 0.3),
                    ],
                    zones: [
                        TacticalZone(id: "back-to-goal", x: 42, y: 35, w: 12, h: 8, type: .opportunity, label: "Back to you"),
                    ],
                    ball: BallPosition(x: 44, y: 30)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "Key rule: never press ALONE. When you go, your CM partner covers the space behind you. Press as a pair — one hunts the ball, one cuts the passing lane.",
                narrationYoung: "Never press alone! When you charge, a friend covers behind you. Press as a PAIR — one hunts the ball, one blocks the pass.",
                spotlightElementId: "tm-partner",
                spotlightCaption: "Press in pairs — never alone",
                spotlightCaptionYoung: "Bring a friend — press as 2!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 48, y: 36, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-partner", x: 44, y: 42, type: .teammate, label: "CM", highlight: true),
                        TacticalPlayer(id: "tm-lw", x: 22, y: 36, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-rw", x: 76, y: 36, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "opp-cm", x: 46, y: 34, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-cb", x: 42, y: 24, type: .opponent),
                        TacticalPlayer(id: "opp-cb2", x: 58, y: 24, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 70, y: 26, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "you-press", fromX: 48, fromY: 40, toX: 47, toY: 36, type: .run, label: "Hunt"),
                        TacticalArrow(id: "partner-cover", fromX: 42, fromY: 44, toX: 44, toY: 42, type: .run, label: "Cover", delay: 0.2),
                        TacticalArrow(id: "cut-lane", fromX: 44, fromY: 42, toX: 44, toY: 38, type: .scan, label: "Lane cut", delay: 0.5),
                    ],
                    zones: [
                        TacticalZone(id: "trap-zone", x: 40, y: 32, w: 14, h: 14, type: .danger, label: "Trapped!"),
                    ],
                    ball: BallPosition(x: 46, y: 34)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "decision_chain.press_triggers"
    )

    // MARK: - 6. Third Man Run (Decision Chain / Advanced)

    static let thirdManRun = AnimatedTacticalLesson(
        id: "third-man-run",
        title: "Third Man Run",
        track: "decision_chain",
        description: "The most dangerous runs come from the player nobody is watching. Learn to use a third player to unlock defenses.",
        difficulty: "advanced",
        steps: [
            TacticalStep(
                narration: "You have the ball in midfield. Your striker is making a run, but the CB is reading it perfectly. A direct pass? Intercepted. You need a THIRD MAN.",
                narrationYoung: "You have the ball. Your striker is running, but the defender sees it coming. A direct pass? Stolen. You need a helper — a THIRD player.",
                spotlightElementId: "opp-cb",
                spotlightCaption: "Direct pass is covered — you need a helper",
                spotlightCaptionYoung: "The defender is ready — need a helper!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 50, y: 28, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "opp-cb", x: 48, y: 26, type: .opponent, label: "CB", highlight: true),
                        TacticalPlayer(id: "tm-am", x: 55, y: 42, type: .teammate, label: "AM"),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "opp-cb2", x: 62, y: 26, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cm", x: 50, y: 44, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 28, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "direct", fromX: 45, fromY: 54, toX: 50, toY: 30, type: .scan, label: "Covered"),
                    ],
                    zones: [
                        TacticalZone(id: "interception", x: 44, y: 26, w: 14, h: 10, type: .danger, label: "Intercepted"),
                    ],
                    ball: BallPosition(x: 45, y: 55)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "Instead, play a short pass to the attacking midfielder — the SECOND man. This pass is easy and safe. He's the link.",
                narrationYoung: "Instead, pass short to your midfielder — they're the LINK. This pass is easy and safe.",
                spotlightElementId: "tm-am",
                spotlightCaption: "Safe pass to the link player",
                spotlightCaptionYoung: "Pass to the helper first!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 50, y: 28, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "opp-cb", x: 48, y: 26, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "tm-am", x: 52, y: 44, type: .teammate, label: "AM", highlight: true),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "opp-cb2", x: 62, y: 26, type: .opponent),
                        TacticalPlayer(id: "opp-cm", x: 52, y: 46, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 28, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "to-am", fromX: 45, fromY: 54, toX: 52, toY: 45, type: .pass, label: "1st pass"),
                    ],
                    ball: BallPosition(x: 48, y: 50)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "While the ball travels to the AM, the striker changes direction. He PEELS behind the CB into the channel. The CB was watching the ball, not the runner. That's the third man principle.",
                narrationYoung: "As the ball travels, the striker sneaks behind the defender. The defender was watching the ball — not the runner. Classic trick!",
                spotlightElementId: "st-peel",
                spotlightCaption: "Striker peels behind while CB watches ball",
                spotlightCaptionYoung: "Sneaky — striker runs behind!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 55, type: .self_),
                        TacticalPlayer(id: "tm-st", x: 55, y: 24, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 50, y: 28, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "tm-am", x: 52, y: 44, type: .teammate, label: "AM", highlight: true),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate),
                        TacticalPlayer(id: "opp-cb2", x: 62, y: 26, type: .opponent),
                        TacticalPlayer(id: "opp-cm", x: 52, y: 46, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 28, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "st-peel", fromX: 50, fromY: 28, toX: 58, toY: 18, type: .run, label: "Third man!"),
                    ],
                    zones: [
                        TacticalZone(id: "channel", x: 52, y: 12, w: 18, h: 16, type: .opportunity, label: "Channel"),
                    ],
                    ball: BallPosition(x: 52, y: 44)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "The AM plays FIRST TIME into the channel. One touch — that's all. The CB is still turned toward the AM when the ball is already past him. Two passes, three players, defense broken.",
                narrationYoung: "The midfielder passes FIRST TIME — one touch! The defender is still watching them when the ball flies past. 2 passes, 3 players, defense beat!",
                spotlightElementId: "through",
                spotlightCaption: "One touch — defense broken",
                spotlightCaptionYoung: "One touch — defense busted!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 55, type: .self_),
                        TacticalPlayer(id: "tm-st", x: 58, y: 16, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 50, y: 28, type: .opponent),
                        TacticalPlayer(id: "tm-am", x: 52, y: 44, type: .teammate, label: "AM", highlight: true),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate),
                        TacticalPlayer(id: "opp-cb2", x: 62, y: 26, type: .opponent),
                        TacticalPlayer(id: "opp-cm", x: 52, y: 46, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 28, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "through", fromX: 52, fromY: 43, toX: 58, toY: 18, type: .pass, label: "First time!"),
                    ],
                    zones: [
                        TacticalZone(id: "space-behind", x: 52, y: 8, w: 18, h: 14, type: .opportunity),
                    ],
                    ball: BallPosition(x: 56, y: 28)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "The Third Man: A passes to B, B plays to C's run. The magic is that C starts moving BEFORE the first pass. Defenders track the ball; the third man attacks the space they've abandoned.",
                narrationYoung: "The trick: A passes to B, B passes to C. The magic? C starts running BEFORE the first pass. Defenders watch the ball — the third player attacks the empty space!",
                spotlightElementId: "tm-st",
                spotlightCaption: "A → B → C — third man wins",
                spotlightCaptionYoung: "The third player is YOU... wait, they are!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 45, y: 55, type: .self_, label: "A"),
                        TacticalPlayer(id: "tm-st", x: 58, y: 10, type: .teammate, label: "C", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 50, y: 28, type: .opponent),
                        TacticalPlayer(id: "tm-am", x: 52, y: 44, type: .teammate, label: "B"),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate),
                        TacticalPlayer(id: "opp-cb2", x: 62, y: 26, type: .opponent),
                        TacticalPlayer(id: "opp-cm", x: 52, y: 46, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 28, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "a-to-b", fromX: 45, fromY: 54, toX: 52, toY: 45, type: .pass, label: "A\u{2192}B"),
                        TacticalArrow(id: "b-to-c", fromX: 52, fromY: 43, toX: 58, toY: 12, type: .pass, label: "B\u{2192}C", delay: 0.4),
                        TacticalArrow(id: "c-run", fromX: 50, fromY: 28, toX: 58, toY: 10, type: .run, delay: 0.2),
                    ],
                    ball: BallPosition(x: 58, y: 10)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "decision_chain.third_man_awareness"
    )

    // MARK: - 7. Switching the Play (Tempo / Beginner)

    static let switchingThePlay = AnimatedTacticalLesson(
        id: "switching-the-play",
        title: "Switching the Play",
        track: "tempo",
        description: "When one side is overloaded, the space is on the OTHER side. Learn to recognize when to switch and change the point of attack.",
        difficulty: "beginner",
        steps: [
            TacticalStep(
                narration: "Your team has been attacking down the right side. Three of your players are on the right, but so are FOUR of their defenders. The right side is crowded and locked. Time to look the other way.",
                narrationYoung: "Your team keeps attacking on the right. But look — their defenders are all there too. That side is crowded. Time to look the OTHER way.",
                spotlightElementId: "crowded",
                spotlightCaption: "Right side is locked — too many defenders",
                spotlightCaptionYoung: "Too crowded on the right!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 55, y: 52, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-rw", x: 82, y: 38, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "tm-rb", x: 78, y: 55, type: .teammate, label: "RB"),
                        TacticalPlayer(id: "tm-lw", x: 12, y: 36, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-lb", x: 18, y: 55, type: .teammate, label: "LB"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 26, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "opp-lb", x: 75, y: 36, type: .opponent, label: "LB"),
                        TacticalPlayer(id: "opp-lcm", x: 65, y: 44, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 55, y: 28, type: .opponent),
                        TacticalPlayer(id: "opp-cb2", x: 42, y: 28, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 22, y: 32, type: .opponent, label: "RB"),
                    ],
                    zones: [
                        TacticalZone(id: "crowded", x: 58, y: 32, w: 30, h: 26, type: .danger, label: "Crowded"),
                    ],
                    ball: BallPosition(x: 55, y: 52)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "Look left. Your left winger is 1v1 against their right-back. Your left-back is completely free. That's where the space is — the WEAK SIDE.",
                narrationYoung: "Look LEFT. Your winger is 1-on-1. Your left-back is totally open. THAT'S where the space is!",
                spotlightElementId: "space-left",
                spotlightCaption: "Weak side — huge space waiting",
                spotlightCaptionYoung: "Empty space on the LEFT!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 55, y: 52, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-rw", x: 82, y: 38, type: .teammate),
                        TacticalPlayer(id: "tm-rb", x: 78, y: 55, type: .teammate),
                        TacticalPlayer(id: "tm-lw", x: 12, y: 36, type: .teammate, label: "LW", highlight: true),
                        TacticalPlayer(id: "tm-lb", x: 18, y: 55, type: .teammate, label: "LB", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 50, y: 26, type: .teammate),
                        TacticalPlayer(id: "opp-lb", x: 75, y: 36, type: .opponent),
                        TacticalPlayer(id: "opp-lcm", x: 65, y: 44, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 55, y: 28, type: .opponent),
                        TacticalPlayer(id: "opp-cb2", x: 42, y: 28, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 22, y: 32, type: .opponent, label: "RB"),
                    ],
                    arrows: [
                        TacticalArrow(id: "scan-left", fromX: 52, fromY: 50, toX: 20, toY: 45, type: .scan, label: "Weak side"),
                    ],
                    zones: [
                        TacticalZone(id: "space-left", x: 2, y: 30, w: 28, h: 30, type: .space, label: "Space!"),
                    ],
                    ball: BallPosition(x: 55, y: 52)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "SWITCH IT. A long diagonal ball to the left-back. The ball travels faster than defenders can shift across. By the time they reorganize, your LB has the ball in acres of space.",
                narrationYoung: "SWITCH IT. A long pass across to the other side. The ball flies faster than defenders can run. Your teammate gets it with tons of space!",
                spotlightElementId: "switch",
                spotlightCaption: "Long diagonal — faster than defenders can shift",
                spotlightCaptionYoung: "Long pass — ZOOM!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 55, y: 52, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-rw", x: 82, y: 38, type: .teammate),
                        TacticalPlayer(id: "tm-rb", x: 78, y: 55, type: .teammate),
                        TacticalPlayer(id: "tm-lw", x: 12, y: 36, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-lb", x: 18, y: 55, type: .teammate, label: "LB", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 50, y: 26, type: .teammate),
                        TacticalPlayer(id: "opp-lb", x: 72, y: 38, type: .opponent),
                        TacticalPlayer(id: "opp-lcm", x: 60, y: 46, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 52, y: 30, type: .opponent),
                        TacticalPlayer(id: "opp-cb2", x: 42, y: 30, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 22, y: 34, type: .opponent, label: "RB"),
                    ],
                    arrows: [
                        TacticalArrow(id: "switch", fromX: 55, fromY: 51, toX: 20, toY: 54, type: .pass, label: "Switch!"),
                    ],
                    ball: BallPosition(x: 38, y: 52)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "Your LB receives with time and space. He drives forward. Now it's 2v1 — your LW and LB against their lone RB. Switching the play creates overloads on the OTHER side.",
                narrationYoung: "Your teammate gets the ball with lots of space. Now it's 2 of yours against 1 of theirs. Switching creates MORE of you than them!",
                spotlightElementId: "two-v-one",
                spotlightCaption: "2v1 on the weak side",
                spotlightCaptionYoung: "2 versus 1 — easy win!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 52, type: .self_),
                        TacticalPlayer(id: "tm-rw", x: 80, y: 40, type: .teammate),
                        TacticalPlayer(id: "tm-rb", x: 75, y: 55, type: .teammate),
                        TacticalPlayer(id: "tm-lb", x: 18, y: 42, type: .teammate, label: "LB", highlight: true),
                        TacticalPlayer(id: "tm-lw", x: 14, y: 30, type: .teammate, label: "LW", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 48, y: 24, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "opp-lb", x: 65, y: 40, type: .opponent),
                        TacticalPlayer(id: "opp-lcm", x: 52, y: 46, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 46, y: 30, type: .opponent),
                        TacticalPlayer(id: "opp-cb2", x: 34, y: 30, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 20, y: 32, type: .opponent, label: "RB"),
                    ],
                    arrows: [
                        TacticalArrow(id: "lb-drive", fromX: 18, fromY: 50, toX: 18, toY: 42, type: .run, label: "Drive"),
                    ],
                    zones: [
                        TacticalZone(id: "two-v-one", x: 6, y: 26, w: 22, h: 20, type: .opportunity, label: "2v1"),
                    ],
                    ball: BallPosition(x: 18, y: 42)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "The LB plays the LW in behind the RB. Cross into the box. One switch of play turned a dead attack into a goal-scoring chance. When you're stuck: don't force it. Switch it.",
                narrationYoung: "Pass to the winger, cross to the striker — GOAL chance! One switch turned a stuck attack into a shot. Stuck? Don't force it — SWITCH it!",
                spotlightElementId: "cross",
                spotlightCaption: "Cross into the box — chance created",
                spotlightCaptionYoung: "Cross the ball — SHOT!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 48, y: 48, type: .self_),
                        TacticalPlayer(id: "tm-rw", x: 68, y: 28, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "tm-rb", x: 70, y: 50, type: .teammate),
                        TacticalPlayer(id: "tm-lb", x: 18, y: 38, type: .teammate, label: "LB"),
                        TacticalPlayer(id: "tm-lw", x: 10, y: 20, type: .teammate, label: "LW", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 52, y: 16, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "opp-lb", x: 58, y: 38, type: .opponent),
                        TacticalPlayer(id: "opp-lcm", x: 46, y: 42, type: .opponent),
                        TacticalPlayer(id: "opp-cb", x: 44, y: 22, type: .opponent),
                        TacticalPlayer(id: "opp-cb2", x: 34, y: 22, type: .opponent),
                        TacticalPlayer(id: "opp-rb", x: 16, y: 24, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "cross", fromX: 12, fromY: 20, toX: 50, toY: 16, type: .pass, label: "Cross!"),
                        TacticalArrow(id: "st-arrive", fromX: 48, fromY: 24, toX: 52, toY: 16, type: .run, delay: 0.3),
                        TacticalArrow(id: "rw-arrive", fromX: 68, fromY: 28, toX: 60, toY: 18, type: .run, delay: 0.4),
                    ],
                    zones: [
                        TacticalZone(id: "danger-area", x: 36, y: 10, w: 28, h: 14, type: .opportunity, label: "Danger zone"),
                    ],
                    ball: BallPosition(x: 30, y: 18)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "tempo.switch_play"
    )

    // MARK: - 8. Blind Side Movement (Scanning / Advanced)

    static let blindSideMovement = AnimatedTacticalLesson(
        id: "blind-side-movement",
        title: "Blind Side Movement",
        track: "scanning",
        description: "The best attackers make runs where defenders can't see them. Learn to exploit the blind side and arrive unseen.",
        difficulty: "advanced",
        steps: [
            TacticalStep(
                narration: "Every defender has a BLIND SIDE. They have to choose: watch the ball or watch their runner. The blind side is the area BEHIND the defender, on the opposite side from the ball.",
                narrationYoung: "Every defender has a BLIND SIDE — a spot they can't see. They have to choose: watch the ball or watch YOU. The blind side is behind them.",
                spotlightElementId: "blind",
                spotlightCaption: "Blind side — where they can't see",
                spotlightCaptionYoung: "That's the blind spot!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "tm-rw", x: 78, y: 40, type: .teammate, label: "RW", highlight: true),
                        TacticalPlayer(id: "self", x: 50, y: 30, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 52, y: 28, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb2", x: 38, y: 28, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-cm", x: 50, y: 52, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "opp-rb", x: 72, y: 32, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 20, y: 30, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "cb-sight", fromX: 52, fromY: 28, toX: 72, toY: 36, type: .scan, label: "Watching ball"),
                    ],
                    zones: [
                        TacticalZone(id: "blind", x: 36, y: 18, w: 16, h: 14, type: .opportunity, label: "Blind side"),
                    ],
                    ball: BallPosition(x: 78, y: 40)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "Start where the CB can see you. Stand still, right next to him. He checks you, then turns back to watch the ball. The moment his head turns... you move.",
                narrationYoung: "Stand where the defender CAN see you. Stay still. They look at you, then look away at the ball. The SECOND their head turns... you MOVE.",
                spotlightElementId: "opp-cb",
                spotlightCaption: "Wait for their head to turn",
                spotlightCaptionYoung: "Wait for them to look away!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "tm-rw", x: 78, y: 40, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "self", x: 50, y: 30, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 52, y: 28, type: .opponent, label: "CB", highlight: true),
                        TacticalPlayer(id: "opp-cb2", x: 38, y: 28, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate),
                        TacticalPlayer(id: "tm-cm", x: 50, y: 52, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "opp-rb", x: 72, y: 32, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 20, y: 30, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "cb-looks-ball", fromX: 52, fromY: 28, toX: 68, toY: 36, type: .scan, label: "Looks away", delay: 0.5),
                    ],
                    ball: BallPosition(x: 78, y: 40)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "NOW. His head turns to track the ball carrier. You DART across his blind side. Move BEHIND him, toward the far post. By the time he looks back, you're gone.",
                narrationYoung: "NOW! Their head turned away. You DART across where they can't see. Run BEHIND them toward the far post. When they look back — you're gone!",
                spotlightElementId: "blind-run",
                spotlightCaption: "Dart across the blind side — NOW",
                spotlightCaptionYoung: "GO — sneak behind them!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "tm-rw", x: 78, y: 38, type: .teammate, label: "RW", highlight: true),
                        TacticalPlayer(id: "self", x: 42, y: 22, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 52, y: 28, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb2", x: 38, y: 28, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 38, type: .teammate),
                        TacticalPlayer(id: "tm-cm", x: 50, y: 52, type: .teammate),
                        TacticalPlayer(id: "opp-rb", x: 72, y: 34, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 20, y: 30, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "blind-run", fromX: 50, fromY: 30, toX: 42, toY: 22, type: .run, label: "Blind side!"),
                    ],
                    zones: [
                        TacticalZone(id: "behind-cb", x: 36, y: 16, w: 14, h: 14, type: .opportunity, label: "Unseen"),
                    ],
                    ball: BallPosition(x: 78, y: 38)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "The RW crosses. The CB turns — you're not where he left you. You're arriving at the FAR POST, completely unmarked. You've created a free header.",
                narrationYoung: "Your teammate crosses. The defender turns — but YOU'RE NOT THERE. You're at the far post, totally alone. Free header coming!",
                spotlightElementId: "free-space",
                spotlightCaption: "Far post — totally unmarked",
                spotlightCaptionYoung: "Wide open at the far post!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "tm-rw", x: 82, y: 28, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "self", x: 35, y: 14, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 50, y: 24, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb2", x: 42, y: 20, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 36, type: .teammate),
                        TacticalPlayer(id: "tm-cm", x: 48, y: 48, type: .teammate),
                        TacticalPlayer(id: "opp-rb", x: 74, y: 30, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 24, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "cross", fromX: 80, fromY: 28, toX: 37, toY: 14, type: .pass, label: "Cross!"),
                    ],
                    zones: [
                        TacticalZone(id: "free-space", x: 28, y: 8, w: 16, h: 14, type: .opportunity, label: "Free!"),
                    ],
                    ball: BallPosition(x: 58, y: 20)
                ),
                duration: 4
            ),
            TacticalStep(
                narration: "Blind side rule: the ball goes one way, you go the OTHER. Defenders watch the ball — exploit it. Start visible, wait for the head to turn, dart behind. Be the player they never saw coming.",
                narrationYoung: "BLIND SIDE RULE: ball goes one way, you go the OTHER. Defenders watch the ball — use it! Start where they see you, wait, then sneak behind them.",
                spotlightElementId: "your-run",
                spotlightCaption: "Ball one way, you the other — stay unseen",
                spotlightCaptionYoung: "Be the one they never see coming!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "tm-rw", x: 82, y: 28, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "self", x: 35, y: 12, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp-cb", x: 50, y: 22, type: .opponent),
                        TacticalPlayer(id: "opp-cb2", x: 42, y: 18, type: .opponent),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 36, type: .teammate),
                        TacticalPlayer(id: "tm-cm", x: 48, y: 48, type: .teammate),
                        TacticalPlayer(id: "opp-rb", x: 74, y: 30, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 22, y: 22, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "ball-path", fromX: 80, fromY: 28, toX: 36, toY: 13, type: .pass),
                        TacticalArrow(id: "your-run", fromX: 50, fromY: 30, toX: 35, toY: 12, type: .run, label: "Blind side!", delay: 0.3),
                    ],
                    ball: BallPosition(x: 36, y: 13)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "scanning.blind_side"
    )

    // MARK: - 9. Controlling the Tempo (Tempo / Intermediate)

    static let controllingTheTempo = AnimatedTacticalLesson(
        id: "controlling-the-tempo",
        title: "Controlling the Tempo",
        track: "tempo",
        description: "The best players dictate the speed of the game. Learn when to slow down, when to explode, and how to control the rhythm of play.",
        difficulty: "intermediate",
        steps: [
            TacticalStep(
                narration: "Your centre-back has the ball deep in your own half. The opponents have set up a mid-block. There's no space in behind, no urgency. This is a WAIT moment. Smart teams slow down here.",
                narrationYoung: "Your defender has the ball at the back. The other team is in a wall. There's no space to run into — no rush. This is a WAIT moment. Slow down.",
                spotlightElementId: "mid-block",
                spotlightCaption: "No space yet — this is a slow moment",
                spotlightCaptionYoung: "No rush — slow it down!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self-cb", x: 40, y: 75, type: .self_, label: "CB", highlight: true),
                        TacticalPlayer(id: "tm-cb2", x: 60, y: 73, type: .teammate, label: "CB"),
                        TacticalPlayer(id: "tm-lb", x: 15, y: 65, type: .teammate, label: "LB"),
                        TacticalPlayer(id: "tm-rb", x: 85, y: 65, type: .teammate, label: "RB"),
                        TacticalPlayer(id: "tm-cm1", x: 35, y: 55, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "tm-cm2", x: 58, y: 53, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "opp-st", x: 48, y: 45, type: .opponent, label: "ST"),
                        TacticalPlayer(id: "opp-cm1", x: 35, y: 40, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-cm2", x: 62, y: 40, type: .opponent, label: "CM"),
                        TacticalPlayer(id: "opp-lw", x: 20, y: 38, type: .opponent, label: "LW"),
                        TacticalPlayer(id: "opp-rw", x: 78, y: 38, type: .opponent, label: "RW"),
                    ],
                    arrows: [
                        TacticalArrow(id: "side-pass", fromX: 40, fromY: 75, toX: 60, toY: 73, type: .pass),
                        TacticalArrow(id: "switch-back", fromX: 60, fromY: 73, toX: 85, toY: 65, type: .pass, delay: 0.5),
                    ],
                    zones: [
                        TacticalZone(id: "mid-block", x: 18, y: 34, w: 64, h: 18, type: .danger, label: "Mid-block"),
                    ],
                    ball: BallPosition(x: 40, y: 75)
                ),
                duration: 6
            ),
            TacticalStep(
                narration: "Patient passing has forced a reaction. Their left winger charges out to press your right-back. That's the TRIGGER. The moment a defender breaks their line, space opens behind them.",
                narrationYoung: "Patient passing worked. Their winger charges at you — they broke the wall! That's the SIGNAL. When a defender leaves their spot, space opens up behind them.",
                spotlightElementId: "gap",
                spotlightCaption: "Defender broke the line — gap opens",
                spotlightCaptionYoung: "They moved — a GAP opened!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self-rb", x: 85, y: 63, type: .self_, label: "RB", highlight: true),
                        TacticalPlayer(id: "tm-cb", x: 55, y: 72, type: .teammate, label: "CB"),
                        TacticalPlayer(id: "tm-cm", x: 60, y: 50, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "tm-rw", x: 82, y: 38, type: .teammate, label: "RW", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 50, y: 30, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-lb", x: 15, y: 65, type: .teammate, label: "LB"),
                        TacticalPlayer(id: "opp-lw", x: 80, y: 55, type: .opponent, label: "LW", highlight: true),
                        TacticalPlayer(id: "opp-cm1", x: 55, y: 40, type: .opponent),
                        TacticalPlayer(id: "opp-lb", x: 75, y: 30, type: .opponent, label: "LB"),
                        TacticalPlayer(id: "opp-cb1", x: 50, y: 25, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb2", x: 40, y: 27, type: .opponent, label: "CB"),
                    ],
                    arrows: [
                        TacticalArrow(id: "lw-press", fromX: 20, fromY: 38, toX: 80, toY: 55, type: .run, label: "Presses"),
                    ],
                    zones: [
                        TacticalZone(id: "gap", x: 74, y: 34, w: 18, h: 18, type: .opportunity, label: "Gap!"),
                    ],
                    ball: BallPosition(x: 85, y: 63)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "ACCELERATE. One touch to your winger, he lays it back first time, and you're driving forward into the space their winger left behind. Two passes in 3 seconds — that's the tempo shift.",
                narrationYoung: "SPEED UP! One pass to your winger, they bounce it back first time, you blast into the open space. 2 passes in 3 seconds — BOOM, tempo shift!",
                spotlightElementId: "rb-drive",
                spotlightCaption: "Accelerate — two passes in 3 seconds",
                spotlightCaptionYoung: "GO FAST — BLAST into the space!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self-rb", x: 80, y: 45, type: .self_, label: "RB", highlight: true),
                        TacticalPlayer(id: "tm-rw", x: 85, y: 35, type: .teammate, label: "RW", highlight: true),
                        TacticalPlayer(id: "tm-cm", x: 65, y: 42, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 28, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-lb", x: 18, y: 55, type: .teammate, label: "LB"),
                        TacticalPlayer(id: "tm-cb", x: 55, y: 70, type: .teammate, label: "CB"),
                        TacticalPlayer(id: "opp-lw", x: 82, y: 58, type: .opponent, label: "LW"),
                        TacticalPlayer(id: "opp-lb", x: 72, y: 28, type: .opponent, label: "LB"),
                        TacticalPlayer(id: "opp-cb1", x: 50, y: 22, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cm1", x: 58, y: 38, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "pass-rw", fromX: 85, fromY: 63, toX: 85, toY: 35, type: .pass),
                        TacticalArrow(id: "layoff", fromX: 85, fromY: 35, toX: 80, toY: 45, type: .pass, label: "Lay off", delay: 0.3),
                        TacticalArrow(id: "rb-drive", fromX: 80, fromY: 45, toX: 78, toY: 32, type: .run, label: "Drive!", delay: 0.6),
                    ],
                    zones: [
                        TacticalZone(id: "attack-space", x: 70, y: 22, w: 22, h: 20, type: .space, label: "Space to attack"),
                    ],
                    ball: BallPosition(x: 80, y: 45)
                ),
                duration: 5
            ),
            TacticalStep(
                narration: "Not every attack ends in a goal. The opponents recover. Instead of forcing a cross into a packed box, the smart play is to SLOW DOWN again. Recycle possession and wait for the next trigger.",
                narrationYoung: "Not every attack scores. The defenders caught up. Don't force a bad pass into the crowd — SLOW DOWN again. Pass it back and wait for the next opening.",
                spotlightElementId: "packed-box",
                spotlightCaption: "Packed box — reset and wait",
                spotlightCaptionYoung: "Crowded — pass it back!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self-rb", x: 78, y: 30, type: .self_, label: "RB", highlight: true),
                        TacticalPlayer(id: "tm-rw", x: 88, y: 22, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "tm-st", x: 48, y: 18, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-cm", x: 55, y: 40, type: .teammate, label: "CM", highlight: true),
                        TacticalPlayer(id: "tm-lb", x: 18, y: 45, type: .teammate, label: "LB"),
                        TacticalPlayer(id: "tm-cb", x: 50, y: 65, type: .teammate, label: "CB"),
                        TacticalPlayer(id: "opp-lb", x: 82, y: 18, type: .opponent, label: "LB"),
                        TacticalPlayer(id: "opp-cb1", x: 55, y: 16, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb2", x: 42, y: 17, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cm1", x: 60, y: 32, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "recycle", fromX: 78, fromY: 30, toX: 55, toY: 40, type: .pass, label: "Recycle"),
                    ],
                    zones: [
                        TacticalZone(id: "packed-box", x: 35, y: 10, w: 30, h: 14, type: .danger, label: "Packed box"),
                    ],
                    ball: BallPosition(x: 78, y: 30)
                ),
                duration: 6
            ),
            TacticalStep(
                narration: "Your team resets and builds again. The centre-back steps up to intercept but MISSES. Your striker is one-on-one. THIS is a NOW moment — no hesitation. That is controlling the tempo.",
                narrationYoung: "Your team resets and tries again. A defender lunges — and MISSES! Your striker is 1-on-1 with the keeper. THIS is a GO moment — no waiting. That's controlling the tempo.",
                spotlightElementId: "through-ball",
                spotlightCaption: "GO moment — no hesitation",
                spotlightCaptionYoung: "NOW — strike!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self-cm", x: 50, y: 42, type: .self_, label: "CM", highlight: true),
                        TacticalPlayer(id: "tm-st", x: 48, y: 22, type: .teammate, label: "ST", highlight: true),
                        TacticalPlayer(id: "tm-rw", x: 80, y: 30, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "tm-lb", x: 18, y: 45, type: .teammate, label: "LB"),
                        TacticalPlayer(id: "tm-cb", x: 45, y: 65, type: .teammate, label: "CB"),
                        TacticalPlayer(id: "opp-cb1", x: 50, y: 35, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-cb2", x: 38, y: 18, type: .opponent, label: "CB"),
                        TacticalPlayer(id: "opp-gk", x: 50, y: 5, type: .opponent, label: "GK"),
                        TacticalPlayer(id: "opp-rb", x: 72, y: 22, type: .opponent),
                    ],
                    arrows: [
                        TacticalArrow(id: "through-ball", fromX: 50, fromY: 42, toX: 48, toY: 15, type: .pass, label: "NOW!"),
                        TacticalArrow(id: "st-run", fromX: 48, fromY: 22, toX: 48, toY: 12, type: .run, delay: 0.3),
                    ],
                    zones: [
                        TacticalZone(id: "behind-line", x: 35, y: 8, w: 30, h: 14, type: .opportunity, label: "1-on-1!"),
                    ],
                    ball: BallPosition(x: 50, y: 42)
                ),
                duration: 5
            ),
        ],
        relatedDrillKey: "tempo.urgency_recognition"
    )

    // MARK: - 10. Breathing Under Pressure (Tempo / Beginner)

    static let breathingUnderPressure = AnimatedTacticalLesson(
        id: "breathing-under-pressure",
        title: "Breathing Under Pressure",
        track: "tempo",
        description: "The best players breathe slow when the game speeds up. Learn how controlled breathing keeps you calm, focused, and one step ahead.",
        difficulty: "beginner",
        steps: [
            TacticalStep(
                narration: "It's the 89th minute. Your team just won a free kick on the edge of the box. The score is level. Your coach points at you — you're taking it. Your heart is pounding. This is where breathing changes EVERYTHING.",
                narrationYoung: "It's the last minute. Your team has a free kick. The game is tied. The coach points at YOU — you're taking it. Heart racing? That's where breathing helps.",
                spotlightElementId: "pressure-zone",
                spotlightCaption: "Heart pounding — here's where breathing matters",
                spotlightCaptionYoung: "Big moment — deep breath!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 40, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm1", x: 40, y: 35, type: .teammate),
                        TacticalPlayer(id: "tm2", x: 55, y: 35, type: .teammate),
                        TacticalPlayer(id: "tm3", x: 60, y: 42, type: .teammate),
                        TacticalPlayer(id: "opp1", x: 44, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp2", x: 48, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp3", x: 52, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp4", x: 56, y: 25, type: .opponent),
                        TacticalPlayer(id: "gk", x: 50, y: 5, type: .opponent, label: "GK"),
                    ],
                    zones: [
                        TacticalZone(id: "pressure-zone", x: 42, y: 36, w: 16, h: 10, type: .danger, label: "Pressure"),
                    ],
                    ball: BallPosition(x: 50, y: 42)
                ),
                duration: 6
            ),
            TacticalStep(
                narration: "Before you step up, BREATHE. In through your nose for 4 counts. Hold for 4 counts. Out through your mouth for 4 counts. This is called box breathing. The best footballers in the world use it before every big moment.",
                narrationYoung: "Before you step up, BREATHE. In your nose — 1, 2, 3, 4. Hold — 1, 2, 3, 4. Out your mouth — 1, 2, 3, 4. Pro players use this before every big moment!",
                spotlightElementId: "calm-zone",
                spotlightCaption: "Box breathing — 4 in, 4 hold, 4 out",
                spotlightCaptionYoung: "In 4, hold 4, out 4!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 40, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp1", x: 44, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp2", x: 48, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp3", x: 52, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp4", x: 56, y: 25, type: .opponent),
                        TacticalPlayer(id: "gk", x: 50, y: 5, type: .opponent, label: "GK"),
                    ],
                    zones: [
                        TacticalZone(id: "calm-zone", x: 42, y: 36, w: 16, h: 10, type: .space, label: "Calm zone"),
                    ],
                    ball: BallPosition(x: 50, y: 42)
                ),
                duration: 7
            ),
            TacticalStep(
                narration: "When you panic, your body floods with adrenaline. Your vision narrows. Your muscles tighten. But 3 deep breaths REVERSE all of that. Your heart rate drops. Your vision widens. Breathing is a superpower.",
                narrationYoung: "When you panic, you can only see what's right in front of you. Your muscles get tight. But 3 deep breaths fix all that — your heart slows, you see the whole field. Breathing is a SUPERPOWER.",
                spotlightElementId: "wide-vision",
                spotlightCaption: "Breathing widens your vision",
                spotlightCaptionYoung: "Breathe — see EVERYTHING!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 50, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-lw", x: 15, y: 35, type: .teammate, label: "LW"),
                        TacticalPlayer(id: "tm-st", x: 50, y: 25, type: .teammate, label: "ST"),
                        TacticalPlayer(id: "tm-rw", x: 85, y: 35, type: .teammate, label: "RW"),
                        TacticalPlayer(id: "tm-cm", x: 35, y: 50, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "tm-rb", x: 80, y: 55, type: .teammate, label: "RB"),
                    ],
                    arrows: [
                        TacticalArrow(id: "scan-left", fromX: 50, fromY: 50, toX: 15, toY: 35, type: .scan),
                        TacticalArrow(id: "scan-center", fromX: 50, fromY: 50, toX: 50, toY: 25, type: .scan, delay: 0.3),
                        TacticalArrow(id: "scan-right", fromX: 50, fromY: 50, toX: 85, toY: 35, type: .scan, delay: 0.6),
                    ],
                    zones: [
                        TacticalZone(id: "wide-vision", x: 10, y: 25, w: 80, h: 35, type: .space, label: "Full vision"),
                    ],
                    ball: BallPosition(x: 50, y: 50)
                ),
                duration: 7
            ),
            TacticalStep(
                narration: "It's not just for set pieces. In open play, whenever the ball goes out or there's a break, take one deep breath. Before a goal kick — breathe. Between sprints — breathe.",
                narrationYoung: "It's not just for free kicks. Any time the ball goes out or there's a break — take one deep breath. Before a goal kick, between sprints. Breathe often!",
                spotlightElementId: "recovery",
                spotlightCaption: "Every break — one breath",
                spotlightCaptionYoung: "Every break — breathe!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 55, y: 55, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "tm-lb", x: 15, y: 70, type: .teammate, label: "LB"),
                        TacticalPlayer(id: "tm-cb", x: 40, y: 72, type: .teammate, label: "CB"),
                        TacticalPlayer(id: "tm-cm", x: 45, y: 48, type: .teammate, label: "CM"),
                        TacticalPlayer(id: "opp-st", x: 48, y: 42, type: .opponent, label: "ST"),
                        TacticalPlayer(id: "opp-rw", x: 70, y: 45, type: .opponent, label: "RW"),
                    ],
                    zones: [
                        TacticalZone(id: "recovery", x: 48, y: 50, w: 14, h: 12, type: .space, label: "Recover here"),
                    ],
                    ball: BallPosition(x: 15, y: 68)
                ),
                duration: 6
            ),
            TacticalStep(
                narration: "Back to the free kick. You've taken three deep breaths. Your heart is steady. You can see the gap between the wall and the post. Calm mind, calm body, clinical execution.",
                narrationYoung: "Back to the free kick. 3 deep breaths. Heart steady. You can see the gap between the wall and the post. Calm mind, calm body — GOAL!",
                spotlightElementId: "target",
                spotlightCaption: "Calm mind — see the gap — strike",
                spotlightCaptionYoung: "Calm — aim — SCORE!",
                diagram: TacticalDiagramState(
                    players: [
                        TacticalPlayer(id: "self", x: 50, y: 40, type: .self_, label: "You", highlight: true),
                        TacticalPlayer(id: "opp1", x: 44, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp2", x: 48, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp3", x: 52, y: 25, type: .opponent),
                        TacticalPlayer(id: "opp4", x: 56, y: 25, type: .opponent),
                        TacticalPlayer(id: "gk", x: 50, y: 5, type: .opponent, label: "GK"),
                    ],
                    arrows: [
                        TacticalArrow(id: "shot", fromX: 50, fromY: 42, toX: 40, toY: 4, type: .pass, label: "GOAL!"),
                    ],
                    zones: [
                        TacticalZone(id: "target", x: 35, y: 2, w: 10, h: 6, type: .opportunity, label: "Target"),
                    ],
                    ball: BallPosition(x: 50, y: 42)
                ),
                duration: 6
            ),
        ],
        relatedDrillKey: "tempo.breathing_rhythm"
    )
}
