-- ThreatSense: WarningPreview.lua
-- Preview system for warning UI

local ADDON_NAME, TS = ...
local Preview = {}
TS.WarningPreview = Preview

Preview.active = false
Preview.timer = 0
Preview.interval = 1.5

------------------------------------------------------------
-- Fake warning generator
------------------------------------------------------------
local fakeWarnings = {
    { type = "TAUNT" },
    { type = "LOSING_AGGRO" },
    { type = "AGGRO_LOST" },
    { type = "PULLING_AGGRO" },
    { type = "AGGRO_PULLED" },
    { type = "DROP_THREAT" },
}

local function RandomWarning()
    return fakeWarnings[math.random(#fakeWarnings)]
end

------------------------------------------------------------
-- Start preview mode
------------------------------------------------------------
function Preview:Start()
    if self.active then return end
    self.active = true
    self.timer = 0

    TS.Utils:Debug("WarningPreview: START")

    -- Override WarningEngine
    self._oldEvaluate = TS.WarningEngine.EvaluateThreat
    TS.WarningEngine.EvaluateThreat = function() end

    -- Immediately show a fake warning
    TS.EventBus:Emit("WARNING_TRIGGERED", RandomWarning())
end

------------------------------------------------------------
-- Stop preview mode
------------------------------------------------------------
function Preview:Stop()
    if not self.active then return end
    self.active = false

    TS.Utils:Debug("WarningPreview: STOP")

    -- Restore WarningEngine
    if self._oldEvaluate then
        TS.WarningEngine.EvaluateThreat = self._oldEvaluate
        self._oldEvaluate = nil
    end

    -- Clear UI
    TS.EventBus:Emit("WARNING_CLEARED", {})
end

------------------------------------------------------------
-- Is preview active?
------------------------------------------------------------
function Preview:IsActive()
    return self.active
end

------------------------------------------------------------
-- Update loop (rotate fake warnings)
------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(_, elapsed)
    if not Preview.active then return end

    Preview.timer = Preview.timer + elapsed
    if Preview.timer >= Preview.interval then
        Preview.timer = 0
        TS.EventBus:Emit("WARNING_TRIGGERED", RandomWarning())
    end
end)

------------------------------------------------------------
-- Auto-stop conditions
------------------------------------------------------------
local function StopIfActive()
    if Preview.active then
        Preview:Stop()
    end
end

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", StopIfActive)

TS.EventBus:Register("TARGET_CHANGED", StopIfActive)
TS.EventBus:Register("TEST_MODE_STARTED", StopIfActive)
TS.EventBus:Register("DEVMODE_OVERRIDE", StopIfActive)

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Preview:Initialize()
    TS.Utils:Debug("WarningPreview initialized")
end