-- ThreatSense: WarningAnimations.lua
-- Reusable animation system for warning UI

local ADDON_NAME, TS = ...

TS.WarningAnimations = TS.WarningAnimations or {}
local Anim = TS.WarningAnimations

------------------------------------------------------------
-- Internal: Create animation group for a frame
------------------------------------------------------------
local function EnsureAnimGroup(frame)
    if frame._tsAnimGroup then
        return frame._tsAnimGroup
    end

    local ag = frame:CreateAnimationGroup()
    ag:SetLooping("NONE")
    frame._tsAnimGroup = ag
    return ag
end

------------------------------------------------------------
-- Stop any running animation
------------------------------------------------------------
function Anim:Stop(frame)
    if frame and frame._tsAnimGroup then
        frame._tsAnimGroup:Stop()
        frame:SetAlpha(1)
        frame:SetScale(1)
        frame:SetPoint(frame._tsOriginalPoint or "CENTER")
    end
end

------------------------------------------------------------
-- FLASH animation
-- Quick alpha pulse
------------------------------------------------------------
local function PlayFlash(frame)
    local ag = EnsureAnimGroup(frame)
    ag:Stop()
    ag:ReleaseAnimations()

    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.2)
    fadeOut:SetDuration(0.2)
    fadeOut:SetOrder(1)

    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.2)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.2)
    fadeIn:SetOrder(2)

    ag:SetLooping("REPEAT")
    ag:Play()
end

------------------------------------------------------------
-- PULSE animation
-- Smooth scale up/down
------------------------------------------------------------
local function PlayPulse(frame)
    local ag = EnsureAnimGroup(frame)
    ag:Stop()
    ag:ReleaseAnimations()

    local grow = ag:CreateAnimation("Scale")
    grow:SetScale(1.2, 1.2)
    grow:SetDuration(0.25)
    grow:SetOrder(1)

    local shrink = ag:CreateAnimation("Scale")
    shrink:SetScale(1/1.2, 1/1.2)
    shrink:SetDuration(0.25)
    shrink:SetOrder(2)

    ag:SetLooping("REPEAT")
    ag:Play()
end

------------------------------------------------------------
-- SHAKE animation
-- Horizontal shake effect
------------------------------------------------------------
local function PlayShake(frame)
    local ag = EnsureAnimGroup(frame)
    ag:Stop()
    ag:ReleaseAnimations()

    -- Save original point
    if not frame._tsOriginalPoint then
        local point, rel, relPoint, x, y = frame:GetPoint()
        frame._tsOriginalPoint = { point, rel, relPoint, x, y }
    end

    local left = ag:CreateAnimation("Translation")
    left:SetOffset(-10, 0)
    left:SetDuration(0.05)
    left:SetOrder(1)

    local right = ag:CreateAnimation("Translation")
    right:SetOffset(20, 0)
    right:SetDuration(0.1)
    right:SetOrder(2)

    local center = ag:CreateAnimation("Translation")
    center:SetOffset(-10, 0)
    center:SetDuration(0.05)
    center:SetOrder(3)

    ag:SetLooping("REPEAT")
    ag:Play()
end

------------------------------------------------------------
-- FADE animation
-- Slow fade in/out
------------------------------------------------------------
local function PlayFade(frame)
    local ag = EnsureAnimGroup(frame)
    ag:Stop()
    ag:ReleaseAnimations()

    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.3)
    fadeOut:SetDuration(0.5)
    fadeOut:SetOrder(1)

    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.3)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.5)
    fadeIn:SetOrder(2)

    ag:SetLooping("REPEAT")
    ag:Play()
end

------------------------------------------------------------
-- Animation registry
------------------------------------------------------------
Anim.animations = {
    FLASH = PlayFlash,
    PULSE = PlayPulse,
    SHAKE = PlayShake,
    FADE  = PlayFade,
}

------------------------------------------------------------
-- Play animation based on profile
------------------------------------------------------------
function Anim:Play(frame, animType)
    if not frame then return end
    self:Stop(frame)

    local fn = self.animations[animType]
    if fn then
        fn(frame)
    else
        -- Fallback to FLASH
        PlayFlash(frame)
    end
end

return Anim