import Foundation
import CoreGraphics

// MARK: - Coordinate space
// All positions are normalized 0.0-1.0 so the renderer can scale cleanly to
// any Canvas size. Origin (0,0) is top-left; (0.5, 1.0) is bottom-center —
// where the avatar's planted foot sits by convention.

struct NormPoint: Codable, Equatable, Hashable {
    var x: Double
    var y: Double

    static let zero = NormPoint(x: 0, y: 0)

    func lerp(to other: NormPoint, t: Double) -> NormPoint {
        NormPoint(x: x + (other.x - x) * t, y: y + (other.y - y) * t)
    }
}

// MARK: - Discrete state fields (snap at keyframe boundaries)

enum ViewAngle: String, Codable {
    case topDown
    case profile
}

enum AvatarPose: String, Codable {
    case neutral
    case crouched
    case leanLeft
    case leanRight
    case plantLeft
    case plantRight
    case explodeLeft
    case explodeRight
}

enum FootSurface: String, Codable {
    case none
    case inside
    case outside
    case laces
    case sole
    case heel
}

enum FootSide: String, Codable {
    case left
    case right
}

enum Easing: String, Codable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case spring

    /// Apply this curve to a linear parameter u in [0, 1].
    func apply(_ u: Double) -> Double {
        let clamped = max(0.0, min(1.0, u))
        switch self {
        case .linear:     return clamped
        case .easeIn:     return clamped * clamped
        case .easeOut:    return 1 - pow(1 - clamped, 2)
        case .easeInOut:  return clamped < 0.5
            ? 2 * clamped * clamped
            : 1 - pow(-2 * clamped + 2, 2) / 2
        case .spring:
            // Critically-ish damped spring approximation: overshoots slightly
            // then settles. Matches SwiftUI's default .spring() response feel.
            let c4 = (2 * Double.pi) / 3
            if clamped == 0 || clamped == 1 { return clamped }
            return pow(2, -10 * clamped) * sin((clamped * 10 - 0.75) * c4) + 1
        }
    }
}

// MARK: - Kinematic avatar
// Joint angles drive a SwiftUI-rendered figure. Each AvatarPose maps to a
// preset; the renderer interpolates angles between the preset for kA and
// the preset for kB so the figure sweeps naturally rather than snapping.

struct AvatarKinematics: Equatable {
    var torsoTilt: Double       // radians; negative = lean left, positive = lean right
    var shoulderTilt: Double    // radians; follows torso with slight lag on leans
    var leftHipAngle: Double    // radians; 0 = leg straight down, positive = leg swings forward
    var rightHipAngle: Double
    var leftKneeBend: Double    // radians; 0 = straight, positive = bent
    var rightKneeBend: Double
    var centerOfMass: NormPoint // where the figure's hips sit

    static let neutral = AvatarKinematics(
        torsoTilt: 0,
        shoulderTilt: 0,
        leftHipAngle: 0,
        rightHipAngle: 0,
        leftKneeBend: 0.08,
        rightKneeBend: 0.08,
        centerOfMass: NormPoint(x: 0.50, y: 0.78)
    )

    func lerp(to other: AvatarKinematics, t: Double) -> AvatarKinematics {
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * t }
        return AvatarKinematics(
            torsoTilt:    mix(torsoTilt, other.torsoTilt),
            shoulderTilt: mix(shoulderTilt, other.shoulderTilt),
            leftHipAngle:  mix(leftHipAngle, other.leftHipAngle),
            rightHipAngle: mix(rightHipAngle, other.rightHipAngle),
            leftKneeBend:  mix(leftKneeBend, other.leftKneeBend),
            rightKneeBend: mix(rightKneeBend, other.rightKneeBend),
            centerOfMass:  centerOfMass.lerp(to: other.centerOfMass, t: t)
        )
    }
}

extension AvatarPose {
    /// Preset joint angles for each pose. Authored once; interpolated
    /// between at render time.
    var kinematics: AvatarKinematics {
        switch self {
        case .neutral:
            return .neutral
        case .crouched:
            return AvatarKinematics(
                torsoTilt: 0, shoulderTilt: 0,
                leftHipAngle: 0.15, rightHipAngle: 0.15,
                leftKneeBend: 0.55, rightKneeBend: 0.55,
                centerOfMass: NormPoint(x: 0.50, y: 0.82)
            )
        case .leanLeft:
            return AvatarKinematics(
                torsoTilt: -0.28, shoulderTilt: -0.22,
                leftHipAngle: 0.05, rightHipAngle: 0.45,
                leftKneeBend: 0.18, rightKneeBend: 0.30,
                centerOfMass: NormPoint(x: 0.47, y: 0.78)
            )
        case .leanRight:
            return AvatarKinematics(
                torsoTilt: 0.28, shoulderTilt: 0.22,
                leftHipAngle: 0.45, rightHipAngle: 0.05,
                leftKneeBend: 0.30, rightKneeBend: 0.18,
                centerOfMass: NormPoint(x: 0.53, y: 0.78)
            )
        case .plantLeft:
            return AvatarKinematics(
                torsoTilt: -0.10, shoulderTilt: -0.06,
                leftHipAngle: 0, rightHipAngle: 0.20,
                leftKneeBend: 0.25, rightKneeBend: 0.12,
                centerOfMass: NormPoint(x: 0.46, y: 0.80)
            )
        case .plantRight:
            return AvatarKinematics(
                torsoTilt: 0.10, shoulderTilt: 0.06,
                leftHipAngle: 0.20, rightHipAngle: 0,
                leftKneeBend: 0.12, rightKneeBend: 0.25,
                centerOfMass: NormPoint(x: 0.54, y: 0.80)
            )
        case .explodeLeft:
            return AvatarKinematics(
                torsoTilt: -0.34, shoulderTilt: -0.40,
                leftHipAngle: -0.25, rightHipAngle: 0.55,
                leftKneeBend: 0.10, rightKneeBend: 0.45,
                centerOfMass: NormPoint(x: 0.38, y: 0.74)
            )
        case .explodeRight:
            return AvatarKinematics(
                torsoTilt: 0.34, shoulderTilt: 0.40,
                leftHipAngle: 0.55, rightHipAngle: -0.25,
                leftKneeBend: 0.45, rightKneeBend: 0.10,
                centerOfMass: NormPoint(x: 0.62, y: 0.74)
            )
        }
    }
}

// MARK: - Keyframe

struct FootState: Codable, Equatable {
    let side: FootSide
    let position: NormPoint
    let surface: FootSurface
    let isActive: Bool

    func lerp(to other: FootState, t: Double) -> FootState {
        // Snap categorical fields to `self` (kA) during the transition —
        // the active foot / surface reflects the "current" keyframe until
        // the next one is reached.
        FootState(
            side: side,
            position: position.lerp(to: other.position, t: t),
            surface: surface,
            isActive: isActive
        )
    }
}

struct TechniqueKeyframe: Codable, Equatable {
    let time: TimeInterval
    let ball: NormPoint
    let leftFoot: FootState
    let rightFoot: FootState
    let avatarPose: AvatarPose
    let caption: String?
    let voiceover: String?
    let easeIn: Easing
}

// MARK: - Animation

struct TechniqueAnimation: Codable, Equatable {
    let assetId: String
    let viewAngle: ViewAngle
    let keyframes: [TechniqueKeyframe]
    let loops: Bool
    let loopPauseSeconds: TimeInterval
    let riveAssetName: String?

    var duration: TimeInterval {
        keyframes.last?.time ?? 0
    }
}

// MARK: - Interpolation

/// Interpolated state at a single moment in time. Positions tween; categorical
/// state (pose, caption, foot surface, isActive) snaps from the previous
/// keyframe. Pure output — no side effects.
struct InterpolatedFrame: Equatable {
    let ball: NormPoint
    let leftFoot: FootState
    let rightFoot: FootState
    let avatarKinematics: AvatarKinematics
    let caption: String?
    /// Index of the keyframe whose voiceover should fire when the playhead
    /// crosses *into* that keyframe. Renderers compare this across ticks to
    /// decide when to speak (single-fire per boundary crossing).
    let currentKeyframeIndex: Int
}

extension TechniqueAnimation {
    /// Pure interpolation. `t` is seconds since animation start.
    /// If `loops`, t is wrapped modulo (duration + loopPauseSeconds); during
    /// the pause window the animation holds on the final keyframe.
    func frame(at t: TimeInterval) -> InterpolatedFrame {
        guard let first = keyframes.first else {
            return InterpolatedFrame(
                ball: .zero,
                leftFoot: FootState(side: .left,  position: .zero, surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: .zero, surface: .none, isActive: false),
                avatarKinematics: .neutral,
                caption: nil,
                currentKeyframeIndex: 0
            )
        }

        let last = keyframes.last!
        let wrapped: TimeInterval
        if loops && duration > 0 {
            let cycle = duration + loopPauseSeconds
            wrapped = t.truncatingRemainder(dividingBy: cycle)
        } else {
            wrapped = min(t, duration)
        }

        // Hold on last keyframe during the loop pause window.
        if wrapped >= duration {
            return frameFromSingle(last, index: keyframes.count - 1)
        }

        // Before the first keyframe time.
        if wrapped <= first.time {
            return frameFromSingle(first, index: 0)
        }

        // Find surrounding keyframes kA (prev) and kB (next).
        var aIndex = 0
        for i in 0..<(keyframes.count - 1) {
            if wrapped >= keyframes[i].time && wrapped < keyframes[i + 1].time {
                aIndex = i
                break
            }
        }
        let kA = keyframes[aIndex]
        let kB = keyframes[aIndex + 1]

        let span = kB.time - kA.time
        let linearU = span > 0 ? (wrapped - kA.time) / span : 0
        let u = kB.easeIn.apply(linearU)

        let avatarKin = kA.avatarPose.kinematics.lerp(to: kB.avatarPose.kinematics, t: u)

        return InterpolatedFrame(
            ball: kA.ball.lerp(to: kB.ball, t: u),
            leftFoot: kA.leftFoot.lerp(to: kB.leftFoot, t: u),
            rightFoot: kA.rightFoot.lerp(to: kB.rightFoot, t: u),
            avatarKinematics: avatarKin,
            caption: kA.caption,
            currentKeyframeIndex: aIndex
        )
    }

    private func frameFromSingle(_ k: TechniqueKeyframe, index: Int) -> InterpolatedFrame {
        InterpolatedFrame(
            ball: k.ball,
            leftFoot: k.leftFoot,
            rightFoot: k.rightFoot,
            avatarKinematics: k.avatarPose.kinematics,
            caption: k.caption,
            currentKeyframeIndex: index
        )
    }
}
