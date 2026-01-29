-- ThreatSense: Smoothing.lua
-- Smooth bar animations using lerp

local ADDON_NAME, TS = ...

TS.Smoothing = {
    active = {},   -- bars currently being smoothed
    speed = 10,    -- higher = faster smoothing
}

------------------------------------------------------------
-- Lerp helper
------------------------------------------------------------
function TS.Smoothing:Lerp(a, b, t)
    return a + (b - a) * t
end

------------------------------------------------------------
-- Start smoothing a bar toward a target value
------------------------------------------------------------
function TS.Smoothing:Start(bar, target)
    self.active[bar] = {
        bar = bar,
        target = target,
    }
end

------------------------------------------------------------
-- Update loop (runs every frame)
------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(_, elapsed)
    local self = TS.Smoothing
    local speed = self.speed

    for bar, data in pairs(self.active) do
        local current = bar:GetValue()
        local target = data.target

        -- Lerp toward target
        local newValue = self:Lerp(current, target, elapsed * speed)
        bar:SetValue(newValue)

        -- Stop when close enough
        if math.abs(newValue - target) < 0.5 then
            bar:SetValue(target)
            self.active[bar] = nil
        end
    end
end)