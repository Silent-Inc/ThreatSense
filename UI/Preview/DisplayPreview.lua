-- ThreatSense: DisplayPreview.lua
-- Preview system for ThreatBar + ThreatList

local ADDON_NAME, TS = ...
local Preview = {}
TS.DisplayPreview = Preview

Preview.active = false
Preview.timer = 0
Preview.interval = 1.0 -- update fake data every second

------------------------------------------------------------
-- Fake threat generator
------------------------------------------------------------
local function GenerateFakeThreat()
    return {
        target = "Training Dummy",
        playerThreat = math.random(10, 90),
        playerThreatPct = math.random(10, 90),
        isTanking = false,
        tankThreat = 100,
        topThreat = 100,
        relativePct = math.random(10, 90),

        threatList = {
            { name = "Warrior", class = "WARRIOR", threat = 92, threatPct = 92, isTanking = true },
            { name = "Mage",    class = "MAGE",    threat = 68, threatPct = 68 },
            { name = "Rogue",   class = "ROGUE",   threat = 55, threatPct = 55 },
            { name = "Hunter",  class = "HUNTER",  threat = 43, threatPct = 43 },
        }
    }
end

------------------------------------------------------------
-- Start preview mode
------------------------------------------------------------
function Preview:Start()
    if self.active then return end
    self.active = true
    self.timer = 0

    TS.Utils:Debug("DisplayPreview: START")

    -- Stop real threat updates
    self._oldUpdate = TS.ThreatEngine.Update
    TS.ThreatEngine.Update = function() end

    -- Immediately push fake data
    TS.EventBus:Emit("THREAT_UPDATED", GenerateFakeThreat())
end

------------------------------------------------------------
-- Stop preview mode
------------------------------------------------------------
function Preview:Stop()
    if not self.active then return end
    self.active = false

    TS.Utils:Debug("DisplayPreview: STOP")

    -- Restore real ThreatEngine
    if self._oldUpdate then
        TS.ThreatEngine.Update = self._oldUpdate
        self._oldUpdate = nil
    end

    -- Force UI to refresh with real data
    TS.ThreatEngine:Update()
end

------------------------------------------------------------
-- Is preview active?
------------------------------------------------------------
function Preview:IsActive()
    return self.active
end

------------------------------------------------------------
-- Update loop (fake threat pulses)
------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(_, elapsed)
    if not Preview.active then return end

    Preview.timer = Preview.timer + elapsed
    if Preview.timer >= Preview.interval then
        Preview.timer = 0
        TS.EventBus:Emit("THREAT_UPDATED", GenerateFakeThreat())
    end
end)

------------------------------------------------------------
-- Auto-stop conditions
------------------------------------------------------------
local function StopPreviewIfActive()
    if Preview.active then
        Preview:Stop()
    end
end

-- Stop preview on combat
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", StopPreviewIfActive)

-- Stop preview when target changes
TS.EventBus:Register("TARGET_CHANGED", StopPreviewIfActive)

-- Stop preview when TestMode starts
TS.EventBus:Register("TEST_MODE_STARTED", StopPreviewIfActive)

-- Stop preview when DevMode overrides data
TS.EventBus:Register("DEVMODE_OVERRIDE", StopPreviewIfActive)

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Preview:Initialize()
    TS.Utils:Debug("DisplayPreview initialized")
end