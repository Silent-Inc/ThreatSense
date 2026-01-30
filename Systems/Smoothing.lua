-- ThreatSense: Smoothing.lua
-- Robust, configurable smoothing engine for status bars

local ADDON_NAME, TS = ...

TS.Smoothing = TS.Smoothing or {}
local SM = TS.Smoothing

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
-- Weak-key table ensures bars are garbage-collected
SM.active = setmetatable({}, { __mode = "k" })

-- Default smoothing settings (overridden by profile)
SM.defaults = {
    mode = "linear",   -- "linear", "exp", "instant"
    speed = 10,        -- linear/exponential speed
}

------------------------------------------------------------
-- Utility: Clamp value to bar min/max
------------------------------------------------------------
local function ClampToBar(bar, value)
    local min, max = bar:GetMinMaxValues()
    if value < min then return min end
    if value > max then return max end
    return value
end

------------------------------------------------------------
-- Utility: Validate bar
------------------------------------------------------------
local function IsValidBar(bar)
    return bar
       and bar.GetValue
       and bar.SetValue
       and bar.GetMinMaxValues
end

------------------------------------------------------------
-- Lerp (linear interpolation)
------------------------------------------------------------
local function Lerp(a, b, t)
    return a + (b - a) * t
end

------------------------------------------------------------
-- Exponential smoothing
------------------------------------------------------------
local function ExpSmooth(a, b, t)
    -- Exponential decay toward target
    return b + (a - b) * math.exp(-t)
end

------------------------------------------------------------
-- Start smoothing a bar toward a target value
------------------------------------------------------------
function SM:Start(bar, target)
    if not IsValidBar(bar) then return end

    -- Instant mode bypasses smoothing
    local mode = TS.db and TS.db.profile and TS.db.profile.display.smoothingMode
        or SM.defaults.mode

    if mode == "instant" then
        bar:SetValue(ClampToBar(bar, target))
        SM.active[bar] = nil
        return
    end

    SM.active[bar] = {
        target = target,
    }
end

------------------------------------------------------------
-- Stop smoothing a bar
------------------------------------------------------------
function SM:Stop(bar)
    SM.active[bar] = nil
end

------------------------------------------------------------
-- Update loop (runs every frame)
------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(_, elapsed)
    local profile = TS.db and TS.db.profile and TS.db.profile.display
    local mode = profile and profile.smoothingMode or SM.defaults.mode
    local speed = profile and profile.smoothingSpeed or SM.defaults.speed

    for bar, data in pairs(SM.active) do
        if not IsValidBar(bar) then
            SM.active[bar] = nil
        else
            local current = bar:GetValue()
            local target = data.target

            -- FPS-independent smoothing factor
            local t = elapsed * speed

            local newValue
            if mode == "exp" then
                newValue = ExpSmooth(current, target, t)
            else -- linear
                newValue = Lerp(current, target, t)
            end

            newValue = ClampToBar(bar, newValue)
            bar:SetValue(newValue)

            -- Stop when close enough
            if math.abs(newValue - target) < 0.5 then
                bar:SetValue(target)
                SM.active[bar] = nil
            end
        end
    end
end)

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function SM:Initialize()
    TS.Utils:Debug("Smoothing 2.0 initialized")
end

return SM