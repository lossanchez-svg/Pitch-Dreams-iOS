-- scissor_hero_driver.luau
-- Node script for scissor_hero.riv. Single source of truth for the Still-Ball
-- Scissor motion; mirrors `scissorStillBall` in
-- PitchDreams/Core/Animation/TechniqueAnimationRegistry.swift.
--
-- Protocol: Node script (per rive.app/docs/scripting/protocols/node-scripts).
-- Lifecycle: init → advance(dt) each frame → update() on input change.
-- This script does NOT draw. All visible motion flows through the
-- `pose` ViewModel input; shapes/bones bind to ScissorPose fields in the editor.
--
-- To wire up in Rive editor:
--   1. Create Data > ViewModel "ScissorPose" with the fields listed in spec §6.
--   2. Attach this script to `driver_node` (empty node in the SVG skeleton).
--   3. Bind the `pose` input to an instance of ScissorPose.
--   4. Bind bone rotations, ball.x/y, etc. to ScissorPose fields.
--
-- DRAFT: exact API spellings (math.clamp, Data.ScissorPose field names) may
-- need small tweaks to match the installed runtime. The shape, lifecycle, and
-- math are correct.

--==============================================================================
-- Types
--==============================================================================

type Pose = {
    torsoTilt: number,       -- radians
    shoulderTilt: number,
    leftHipAngle: number,
    rightHipAngle: number,
    leftKneeBend: number,
    rightKneeBend: number,
    comX: number,            -- artboard-space, 0..1000
    comY: number,            -- artboard-space, 0..1500
}

type FootState = {
    x: number,               -- artboard-space
    y: number,
    surface: number,         -- 0=none, 1=inside, 2=outside, 3=laces, 4=sole, 5=heel
    active: boolean,
}

type Keyframe = {
    t: number,               -- seconds from cycle start
    ballX: number,
    ballY: number,
    leftFoot: FootState,
    rightFoot: FootState,
    pose: Pose,
    caption: number,         -- 0..3
    easeIn: number,          -- 0=linear 1=easeIn 2=easeOut 3=easeInOut 4=spring
}

type ScissorDriver = {
    pose: Input<Data.ScissorPose>,
    time: number,
    duration: number,
    loopPause: number,
    keyframes: {Keyframe},
}

--==============================================================================
-- Constants — ARTBOARD-SPACE values. Normalized × (1000, 1500).
-- Keep in lockstep with scissorStillBall.keyframes (registry §2.0).
--==============================================================================

local AW, AH = 1000, 1500

-- Pose presets — duplicate of AvatarPose.kinematics in TechniqueAnimation.swift.
-- If the Swift side changes, update here too.
local POSE_NEUTRAL: Pose = {
    torsoTilt = 0, shoulderTilt = 0,
    leftHipAngle = 0, rightHipAngle = 0,
    leftKneeBend = 0.08, rightKneeBend = 0.08,
    comX = 0.50 * AW, comY = 0.78 * AH,
}
local POSE_LEAN_LEFT: Pose = {
    torsoTilt = -0.28, shoulderTilt = -0.22,
    leftHipAngle = 0.05, rightHipAngle = 0.45,
    leftKneeBend = 0.18, rightKneeBend = 0.30,
    comX = 0.47 * AW, comY = 0.78 * AH,
}
local POSE_PLANT_LEFT: Pose = {
    torsoTilt = -0.10, shoulderTilt = -0.06,
    leftHipAngle = 0.0, rightHipAngle = 0.20,
    leftKneeBend = 0.25, rightKneeBend = 0.12,
    comX = 0.46 * AW, comY = 0.80 * AH,
}
local POSE_EXPLODE_LEFT: Pose = {
    torsoTilt = -0.34, shoulderTilt = -0.40,
    leftHipAngle = -0.25, rightHipAngle = 0.55,
    leftKneeBend = 0.10, rightKneeBend = 0.45,
    comX = 0.38 * AW, comY = 0.74 * AH,
}

-- Easing enum tags. Matches Easing in TechniqueAnimation.swift.
local EASE_LINEAR, EASE_IN, EASE_OUT, EASE_IN_OUT, EASE_SPRING = 0, 1, 2, 3, 4

-- Footsurface enum — matches FootSurface.swift ordering.
local SURF_NONE, SURF_INSIDE, SURF_OUTSIDE = 0, 1, 2

local KEYFRAMES: {Keyframe} = {
    {
        t = 0.0,
        ballX = 0.50 * AW, ballY = 0.78 * AH,
        leftFoot  = { x = 0.42 * AW, y = 0.92 * AH, surface = SURF_NONE, active = false },
        rightFoot = { x = 0.58 * AW, y = 0.92 * AH, surface = SURF_NONE, active = false },
        pose = POSE_NEUTRAL,
        caption = 0,
        easeIn = EASE_LINEAR,
    },
    {
        t = 0.7,
        ballX = 0.50 * AW, ballY = 0.78 * AH,
        leftFoot  = { x = 0.40 * AW, y = 0.92 * AH, surface = SURF_NONE,    active = false },
        rightFoot = { x = 0.78 * AW, y = 0.60 * AH, surface = SURF_OUTSIDE, active = true  },
        pose = POSE_LEAN_LEFT,
        caption = 1,
        easeIn = EASE_OUT,
    },
    {
        t = 1.3,
        ballX = 0.50 * AW, ballY = 0.78 * AH,
        leftFoot  = { x = 0.40 * AW, y = 0.92 * AH, surface = SURF_NONE,   active = false },
        rightFoot = { x = 0.62 * AW, y = 0.90 * AH, surface = SURF_INSIDE, active = true  },
        pose = POSE_PLANT_LEFT,
        caption = 2,
        easeIn = EASE_OUT,
    },
    {
        t = 2.0,
        ballX = 0.22 * AW, ballY = 0.80 * AH,
        leftFoot  = { x = 0.30 * AW, y = 0.84 * AH, surface = SURF_INSIDE, active = true  },
        rightFoot = { x = 0.58 * AW, y = 0.88 * AH, surface = SURF_NONE,   active = false },
        pose = POSE_EXPLODE_LEFT,
        caption = 3,
        easeIn = EASE_SPRING,
    },
}

local DURATION = 2.0     -- matches keyframes last.t
local LOOP_PAUSE = 0.5   -- matches scissorHero.loopPauseSeconds

--==============================================================================
-- Easing — mirrors Easing.apply in TechniqueAnimation.swift.
--==============================================================================

local function clamp01(u: number): number
    if u < 0 then return 0 end
    if u > 1 then return 1 end
    return u
end

local function ease(kind: number, u: number): number
    local c = clamp01(u)
    if kind == EASE_LINEAR then
        return c
    elseif kind == EASE_IN then
        return c * c
    elseif kind == EASE_OUT then
        return 1 - (1 - c) * (1 - c)
    elseif kind == EASE_IN_OUT then
        if c < 0.5 then
            return 2 * c * c
        else
            local d = -2 * c + 2
            return 1 - (d * d) / 2
        end
    elseif kind == EASE_SPRING then
        if c == 0 or c == 1 then return c end
        local c4 = (2 * math.pi) / 3
        return math.pow(2, -10 * c) * math.sin((c * 10 - 0.75) * c4) + 1
    end
    return c
end

local function lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

local function lerpPose(a: Pose, b: Pose, t: number): Pose
    return {
        torsoTilt     = lerp(a.torsoTilt,     b.torsoTilt,     t),
        shoulderTilt  = lerp(a.shoulderTilt,  b.shoulderTilt,  t),
        leftHipAngle  = lerp(a.leftHipAngle,  b.leftHipAngle,  t),
        rightHipAngle = lerp(a.rightHipAngle, b.rightHipAngle, t),
        leftKneeBend  = lerp(a.leftKneeBend,  b.leftKneeBend,  t),
        rightKneeBend = lerp(a.rightKneeBend, b.rightKneeBend, t),
        comX          = lerp(a.comX, b.comX, t),
        comY          = lerp(a.comY, b.comY, t),
    }
end

--==============================================================================
-- Write interpolated state to the bound ViewModel.
--==============================================================================

local function writePose(self: ScissorDriver, kA: Keyframe, kB: Keyframe, u: number)
    local vm = self.pose
    if vm == nil then return end

    local p = lerpPose(kA.pose, kB.pose, u)

    -- Positions tween; categorical fields snap to kA (matches Swift lerp behavior).
    vm.ballX = lerp(kA.ballX, kB.ballX, u)
    vm.ballY = lerp(kA.ballY, kB.ballY, u)

    vm.leftFootX = lerp(kA.leftFoot.x, kB.leftFoot.x, u)
    vm.leftFootY = lerp(kA.leftFoot.y, kB.leftFoot.y, u)
    vm.leftFootActive  = kA.leftFoot.active
    vm.leftFootSurface = kA.leftFoot.surface

    vm.rightFootX = lerp(kA.rightFoot.x, kB.rightFoot.x, u)
    vm.rightFootY = lerp(kA.rightFoot.y, kB.rightFoot.y, u)
    vm.rightFootActive  = kA.rightFoot.active
    vm.rightFootSurface = kA.rightFoot.surface

    vm.torsoTilt     = p.torsoTilt
    vm.shoulderTilt  = p.shoulderTilt
    vm.leftHipAngle  = p.leftHipAngle
    vm.rightHipAngle = p.rightHipAngle
    vm.leftKneeBend  = p.leftKneeBend
    vm.rightKneeBend = p.rightKneeBend
    vm.centerOfMassX = p.comX
    vm.centerOfMassY = p.comY

    vm.captionIndex = kA.caption
end

local function writeSingle(self: ScissorDriver, k: Keyframe)
    -- Called when playhead is at (or held on) exactly one keyframe — no blend.
    writePose(self, k, k, 0)
end

--==============================================================================
-- Lifecycle
--==============================================================================

function init(self: ScissorDriver): boolean
    self.time = 0
    self.duration = DURATION
    self.loopPause = LOOP_PAUSE
    self.keyframes = KEYFRAMES
    writeSingle(self, self.keyframes[1])
    return true
end

function advance(self: ScissorDriver, seconds: number): boolean
    local cycle = self.duration + self.loopPause
    self.time = (self.time + seconds) % cycle

    -- Loop-pause window: hold on the final keyframe.
    if self.time >= self.duration then
        writeSingle(self, self.keyframes[#self.keyframes])
        return true
    end

    -- Find surrounding keyframes kA, kB such that kA.t <= time < kB.t.
    local aIndex = 1
    for i = 1, #self.keyframes - 1 do
        if self.time >= self.keyframes[i].t and self.time < self.keyframes[i + 1].t then
            aIndex = i
            break
        end
    end
    local kA = self.keyframes[aIndex]
    local kB = self.keyframes[aIndex + 1]

    local span = kB.t - kA.t
    local linearU = if span > 0 then (self.time - kA.t) / span else 0
    local u = ease(kB.easeIn, linearU)

    writePose(self, kA, kB, u)
    return true
end

function update(self: ScissorDriver)
    -- No input-driven recompute needed; advance() handles everything.
end

--==============================================================================
-- Factory
--==============================================================================

return function(): Node<ScissorDriver>
    return {
        init = init,
        advance = advance,
        update = update,
        pose = late(),
        time = 0,
        duration = DURATION,
        loopPause = LOOP_PAUSE,
        keyframes = KEYFRAMES,
    }
end
