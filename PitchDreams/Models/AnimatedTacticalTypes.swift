import Foundation

// MARK: - Enums

enum PlayerType: String, Codable {
    case self_ = "self"
    case teammate
    case opponent
}

enum ArrowType: String, Codable {
    case pass
    case run
    case scan
    case space
}

enum ZoneType: String, Codable {
    case space
    case danger
    case opportunity
}

// MARK: - Diagram Elements

struct TacticalPlayer: Identifiable, Equatable {
    let id: String
    let x: CGFloat        // 0-100 percentage
    let y: CGFloat        // 0-100 percentage
    let type: PlayerType
    let label: String?
    let highlight: Bool
    let description: String?
    /// F3 — age-adapted tap description (≤11). Falls back to `description`.
    let descriptionYoung: String?

    init(
        id: String,
        x: CGFloat,
        y: CGFloat,
        type: PlayerType,
        label: String? = nil,
        highlight: Bool = false,
        description: String? = nil,
        descriptionYoung: String? = nil
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.type = type
        self.label = label
        self.highlight = highlight
        self.description = description
        self.descriptionYoung = descriptionYoung
    }

    /// Resolve the tap description for the given child age.
    func preferredDescription(childAge: Int?) -> String? {
        if let age = childAge, age <= 11, let y = descriptionYoung { return y }
        return description
    }
}

struct TacticalArrow: Identifiable, Equatable {
    let id: String
    let fromX: CGFloat
    let fromY: CGFloat
    let toX: CGFloat
    let toY: CGFloat
    let type: ArrowType
    let label: String?
    let delay: TimeInterval  // stagger within a step
    let description: String?
    /// F3 — age-adapted tap description (≤11). Falls back to `description`.
    let descriptionYoung: String?

    init(
        id: String,
        fromX: CGFloat,
        fromY: CGFloat,
        toX: CGFloat,
        toY: CGFloat,
        type: ArrowType,
        label: String? = nil,
        delay: TimeInterval = 0,
        description: String? = nil,
        descriptionYoung: String? = nil
    ) {
        self.id = id
        self.fromX = fromX
        self.fromY = fromY
        self.toX = toX
        self.toY = toY
        self.type = type
        self.label = label
        self.delay = delay
        self.description = description
        self.descriptionYoung = descriptionYoung
    }

    func preferredDescription(childAge: Int?) -> String? {
        if let age = childAge, age <= 11, let y = descriptionYoung { return y }
        return description
    }
}

struct TacticalZone: Identifiable, Equatable {
    let id: String
    let x: CGFloat       // 0-100 position
    let y: CGFloat
    let w: CGFloat       // 0-100 width
    let h: CGFloat       // 0-100 height
    let type: ZoneType
    let label: String?
    let description: String?
    /// F3 — age-adapted tap description (≤11). Falls back to `description`.
    let descriptionYoung: String?

    init(
        id: String,
        x: CGFloat,
        y: CGFloat,
        w: CGFloat,
        h: CGFloat,
        type: ZoneType,
        label: String? = nil,
        description: String? = nil,
        descriptionYoung: String? = nil
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.type = type
        self.label = label
        self.description = description
        self.descriptionYoung = descriptionYoung
    }

    func preferredDescription(childAge: Int?) -> String? {
        if let age = childAge, age <= 11, let y = descriptionYoung { return y }
        return description
    }
}

struct BallPosition: Equatable {
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Diagram State & Steps

struct TacticalDiagramState: Equatable {
    let players: [TacticalPlayer]
    let arrows: [TacticalArrow]
    let zones: [TacticalZone]
    let ball: BallPosition?

    init(
        players: [TacticalPlayer] = [],
        arrows: [TacticalArrow] = [],
        zones: [TacticalZone] = [],
        ball: BallPosition? = nil
    ) {
        self.players = players
        self.arrows = arrows
        self.zones = zones
        self.ball = ball
    }
}

struct TacticalStep: Equatable {
    let narration: String
    /// Age-adapted narration (≤11). Falls back to `narration` when absent.
    let narrationYoung: String?
    let diagram: TacticalDiagramState
    let duration: TimeInterval  // seconds
    /// Optional element to spotlight for ~1.5s before the step animates.
    /// Matches `TacticalPlayer.id`, `TacticalArrow.id`, or `TacticalZone.id`.
    /// When set, `AnimatedTacticalPitchView` dims all other elements and
    /// pulses a ring around the spotlight target.
    let spotlightElementId: String?
    /// Short caption displayed during the spotlight phase.
    /// Falls back to a generic "Watch this…" if nil.
    let spotlightCaption: String?
    /// Age-adapted spotlight caption (≤11). Falls back to `spotlightCaption`.
    let spotlightCaptionYoung: String?
    /// F6 — optional "what NOT to do" precursor played before this step.
    /// When set, the lesson player shows the shadow animation first with a
    /// red "What NOT to do" banner, then transitions to the real step with
    /// a green "Do this instead" banner. Lessons that teach a technique
    /// (~30-40% of the catalog per spec) benefit from shadow contrast;
    /// conceptual lessons leave this nil.
    let shadowStep: ShadowStep?

    init(
        narration: String,
        narrationYoung: String? = nil,
        spotlightElementId: String? = nil,
        spotlightCaption: String? = nil,
        spotlightCaptionYoung: String? = nil,
        shadowStep: ShadowStep? = nil,
        diagram: TacticalDiagramState,
        duration: TimeInterval
    ) {
        self.narration = narration
        self.narrationYoung = narrationYoung
        self.spotlightElementId = spotlightElementId
        self.spotlightCaption = spotlightCaption
        self.spotlightCaptionYoung = spotlightCaptionYoung
        self.shadowStep = shadowStep
        self.diagram = diagram
        self.duration = duration
    }

    /// Resolve the narration variant for a given child age.
    /// Treats ages 11 and below as "young" per the design constraint.
    func preferredNarration(childAge: Int?) -> String {
        if let age = childAge, age <= 11, let y = narrationYoung { return y }
        return narration
    }

    /// Resolve the spotlight caption for a given child age.
    func preferredSpotlightCaption(childAge: Int?) -> String? {
        if let age = childAge, age <= 11, let y = spotlightCaptionYoung { return y }
        return spotlightCaption
    }

    /// Whether this step has spotlight content that should pre-play.
    var hasSpotlight: Bool { spotlightElementId != nil }

    /// Whether this step has a shadow precursor to play first.
    var hasShadow: Bool { shadowStep != nil }
}

/// F6 — the "what NOT to do" precursor for a step. Plays before the real
/// step with a red-tinted banner; the real step then plays with a green
/// confirmation banner. Makes cause-and-effect visceral instead of abstract.
struct ShadowStep: Equatable {
    let narration: String
    let narrationYoung: String?
    let diagram: TacticalDiagramState
    let duration: TimeInterval
    /// Short outcome label shown at the top, e.g. "The ball gets stolen."
    let outcomeLabel: String
    let outcomeLabelYoung: String?
    /// Emoji hint that reinforces the outcome, e.g. "😞".
    let outcomeEmoji: String

    init(
        narration: String,
        narrationYoung: String? = nil,
        diagram: TacticalDiagramState,
        duration: TimeInterval,
        outcomeLabel: String,
        outcomeLabelYoung: String? = nil,
        outcomeEmoji: String = "⚠️"
    ) {
        self.narration = narration
        self.narrationYoung = narrationYoung
        self.diagram = diagram
        self.duration = duration
        self.outcomeLabel = outcomeLabel
        self.outcomeLabelYoung = outcomeLabelYoung
        self.outcomeEmoji = outcomeEmoji
    }

    func preferredNarration(childAge: Int?) -> String {
        if let age = childAge, age <= 11, let y = narrationYoung { return y }
        return narration
    }

    func preferredOutcomeLabel(childAge: Int?) -> String {
        if let age = childAge, age <= 11, let y = outcomeLabelYoung { return y }
        return outcomeLabel
    }
}

// MARK: - Animated Lesson

struct AnimatedTacticalLesson: Identifiable, Equatable {
    let id: String
    let title: String
    let track: String
    let description: String
    let difficulty: String
    let steps: [TacticalStep]
    let relatedDrillKey: String?

    init(
        id: String,
        title: String,
        track: String,
        description: String,
        difficulty: String,
        steps: [TacticalStep],
        relatedDrillKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.track = track
        self.description = description
        self.difficulty = difficulty
        self.steps = steps
        self.relatedDrillKey = relatedDrillKey
    }
}
