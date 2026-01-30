-- ThreatSense: DisplayPreview.lua
-- Preview system for ThreatBar + ThreatList (ThreatEngine 2.0 aware)

local ADDON_NAME, TS = ...

TS.DisplayPreview = TS.DisplayPreview or {}
local Preview = TS.DisplayPreview

Preview.active   = false
Preview.timer    = 0
Preview.interval = 1.0 -- update fake data every second

Preview._saved = {
    threatEngineEnabled = nil,
}

------------------------------------------------------------
-- Fake threat generator (ThreatEngine 2.0 payload shape)
------------------------------------------------------------
local function GenerateFakePayload()
    local list = {
        { unit = "player", name = "You",     class = "WARRIOR", threatPct = math.random(40, 95), isTanking = true  },
        { unit = "party1", name = "Mage",    class = "MAGE",    threatPct = math.random(20, 80), isTanking = false },
        { unit = "party2", name = "Rogue",   class = "ROGUE",   threatPct = math.random(10, 70), isTanking = false },
        { unit = "party3", name = "Hunter",  class = "HUNTER",  threatPct = math.random(10, 60), isTanking = false },
    }

    local playerEntry = list[1]
    local targetName  = "Training Dummy"

    return {
        threatPct = playerEntry.threatPct,
        isTanking = playerEntry.isTanking,
        role      = TS.RoleManager and TS.RoleManager:GetRole() or "TANK",
        list      = list,
        target    = targetName,
        tankThreat = 100,
        topThreat  = 100,
    }
end

------------------------------------------------------------
-- Push fake events into the system
------------------------------------------------------------
local function PushFakeThreat()
    local payload = GenerateFakePayload()

    -- Player threat update
    TS.EventBus:Send("PLAYER_THREAT_UPDATED", payload)

    -- Threat list update
    TS.EventBus:Send("THREAT_LIST_UPDATED", { list = payload.list })

    -- Target update
    TS.EventBus:Send("THREAT_TARGET_UPDATED", {
        name = payload.target,
    })
end

------------------------------------------------------------
-- Start preview mode
------------------------------------------------------------
function Preview:Start()
    if self.active then return end
    self.active = true
    self.timer  = 0

    TS.Utils:Debug("DisplayPreview: START")

    -- Disable real ThreatEngine updates (if it exposes a toggle)
    if TS.ThreatEngine and TS.ThreatEngine.SetEnabled then
        self._saved.threatEngineEnabled = TS.ThreatEngine:IsEnabled()
        TS.ThreatEngine:SetEnabled(false)
    end

    -- Immediately push fake data
    PushFakeThreat()
end

------------------------------------------------------------
-- Stop preview mode
------------------------------------------------------------
function Preview:Stop()
    if not self.active then return end
    self.active = false

    TS.Utils:Debug("DisplayPreview: STOP")

    -- Re-enable ThreatEngine if we disabled it
    if TS.ThreatEngine and TS.ThreatEngine.SetEnabled and self._saved.threatEngineEnabled ~= nil then
        TS.ThreatEngine:SetEnabled(self._saved.threatEngineEnabled)
        self._saved.threatEngineEnabled = nil
    end

    -- Emit a reset so UI can clear or resume real data
    TS.EventBus:Send("THREAT_RESET")
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
local frame = CreateFrame("Frame", "ThreatSense_DisplayPreviewFrame", UIParent)
frame:SetScript("OnUpdate", function(_, elapsed)
    if not Preview.active then return end

    Preview.timer = Preview.timer + elapsed
    if Preview.timer >= Preview.interval then
        Preview.timer = 0
        PushFakeThreat()
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

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        StopPreviewIfActive()
    end
end)

TS.EventBus:Register("TARGET_CHANGED", StopPreviewIfActive, {
    namespace = "DisplayPreview",
    source    = "DisplayPreview",
})

TS.EventBus:Register("TEST_MODE_STARTED", StopPreviewIfActive, {
    namespace = "DisplayPreview",
    source    = "DisplayPreview",
})

TS.EventBus:Register("DEVMODE_OVERRIDE", StopPreviewIfActive, {
    namespace = "DisplayPreview",
    source    = "DisplayPreview",
})

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Preview:Initialize()
    TS.Utils:Debug("DisplayPreview 2.0 initialized")
end

return Preview