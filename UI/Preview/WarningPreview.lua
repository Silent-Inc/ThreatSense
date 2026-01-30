-- ThreatSense: WarningPreview.lua
-- Scenario-based preview for WarningEngine + WarningFrame (built on ThreatEngine-style events)

local ADDON_NAME, TS = ...

TS.WarningPreview = TS.WarningPreview or {}
local WP = TS.WarningPreview

WP.active    = false
WP.timer     = 0
WP.interval  = 1.0
WP.scenario  = nil

WP._saved = {
    threatEngineEnabled = nil,
}

------------------------------------------------------------
-- Scenario generators (ThreatEngine 2.0 payload shape)
------------------------------------------------------------
local function Scenario_TankLosing()
    local list = {
        { unit = "player", name = "You",     class = "WARRIOR", threatPct = 100, isTanking = true  },
        { unit = "party1", name = "Mage",    class = "MAGE",    threatPct = math.random(80, 95), isTanking = false },
    }

    return {
        threatPct = list[1].threatPct,
        isTanking = true,
        role      = "TANK",
        list      = list,
        target    = "Training Dummy",
        tankThreat = 100,
        topThreat  = 100,
    }
end

local function Scenario_TankLost()
    local list = {
        { unit = "party1", name = "Mage",    class = "MAGE",    threatPct = 110, isTanking = true  },
        { unit = "player", name = "You",     class = "WARRIOR", threatPct = 90,  isTanking = false },
    }

    return {
        threatPct = list[2].threatPct,
        isTanking = false,
        role      = "TANK",
        list      = list,
        target    = "Training Dummy",
        tankThreat = 110,
        topThreat  = 110,
    }
end

local function Scenario_DpsPulling()
    local list = {
        { unit = "tank",   name = "Tank",    class = "PALADIN", threatPct = 100, isTanking = true  },
        { unit = "player", name = "You",     class = "MAGE",    threatPct = math.random(85, 99), isTanking = false },
    }

    return {
        threatPct = list[2].threatPct,
        isTanking = false,
        role      = "DAMAGER",
        list      = list,
        target    = "Training Dummy",
        tankThreat = 100,
        topThreat  = 100,
    }
end

local function Scenario_DpsPulled()
    local list = {
        { unit = "player", name = "You",     class = "MAGE",    threatPct = 110, isTanking = true  },
        { unit = "tank",   name = "Tank",    class = "PALADIN", threatPct = 100, isTanking = false },
    }

    return {
        threatPct = list[1].threatPct,
        isTanking = true,
        role      = "DAMAGER",
        list      = list,
        target    = "Training Dummy",
        tankThreat = 100,
        topThreat  = 110,
    }
end

local function Scenario_HealerPulling()
    local list = {
        { unit = "tank",   name = "Tank",    class = "WARRIOR", threatPct = 100, isTanking = true  },
        { unit = "player", name = "You",     class = "PRIEST",  threatPct = math.random(80, 95), isTanking = false },
    }

    return {
        threatPct = list[2].threatPct,
        isTanking = false,
        role      = "HEALER",
        list      = list,
        target    = "Training Dummy",
        tankThreat = 100,
        topThreat  = 100,
    }
end

WP.scenarios = {
    TANK_LOSING   = Scenario_TankLosing,
    TANK_LOST     = Scenario_TankLost,
    DPS_PULLING   = Scenario_DpsPulling,
    DPS_PULLED    = Scenario_DpsPulled,
    HEALER_PULLING= Scenario_HealerPulling,
}

local function PickRandomScenario()
    local keys = {}
    for k in pairs(WP.scenarios) do
        table.insert(keys, k)
    end
    return keys[math.random(#keys)]
end

------------------------------------------------------------
-- Push fake threat into the system
------------------------------------------------------------
local function PushScenario()
    if not WP.scenario then return end
    local fn = WP.scenarios[WP.scenario]
    if not fn then return end

    local payload = fn()

    TS.EventBus:Send("PLAYER_THREAT_UPDATED", payload)
    TS.EventBus:Send("THREAT_LIST_UPDATED", { list = payload.list })
    TS.EventBus:Send("THREAT_TARGET_UPDATED", { name = payload.target })
end

------------------------------------------------------------
-- Start preview with a specific scenario
------------------------------------------------------------
function WP:StartScenario(name)
    if self.active and self.scenario == name then return end

    if not self.scenarios[name] then
        TS.Utils:Debug("WarningPreview: invalid scenario: " .. tostring(name))
        return
    end

    self.active   = true
    self.timer    = 0
    self.scenario = name

    TS.Utils:Debug("WarningPreview: START scenario " .. name)

    if TS.ThreatEngine and TS.ThreatEngine.SetEnabled then
        self._saved.threatEngineEnabled = TS.ThreatEngine:IsEnabled()
        TS.ThreatEngine:SetEnabled(false)
    end

    PushScenario()
end

------------------------------------------------------------
-- Start preview with a random scenario
------------------------------------------------------------
function WP:StartRandom()
    local name = PickRandomScenario()
    self:StartScenario(name)
end

------------------------------------------------------------
-- Stop preview
------------------------------------------------------------
function WP:Stop()
    if not self.active then return end
    self.active   = false
    self.scenario = nil

    TS.Utils:Debug("WarningPreview: STOP")

    if TS.ThreatEngine and TS.ThreatEngine.SetEnabled and self._saved.threatEngineEnabled ~= nil then
        TS.ThreatEngine:SetEnabled(self._saved.threatEngineEnabled)
        self._saved.threatEngineEnabled = nil
    end

    TS.EventBus:Send("THREAT_RESET")
end

function WP:IsActive()
    return self.active
end

------------------------------------------------------------
-- Update loop
------------------------------------------------------------
local frame = CreateFrame("Frame", "ThreatSense_WarningPreviewFrame", UIParent)
frame:SetScript("OnUpdate", function(_, elapsed)
    if not WP.active then return end

    WP.timer = WP.timer + elapsed
    if WP.timer >= WP.interval then
        WP.timer = 0
        PushScenario()
    end
end)

------------------------------------------------------------
-- Auto-stop conditions
------------------------------------------------------------
local function StopIfActive()
    if WP.active then
        WP:Stop()
    end
end

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        StopIfActive()
    end
end)

TS.EventBus:Register("TARGET_CHANGED", StopIfActive, {
    namespace = "WarningPreview",
    source    = "WarningPreview",
})

TS.EventBus:Register("PROFILE_CHANGED", StopIfActive, {
    namespace = "WarningPreview",
    source    = "WarningPreview",
})

TS.EventBus:Register("DISPLAY_MODE_CHANGED", StopIfActive, {
    namespace = "WarningPreview",
    source    = "WarningPreview",
})

TS.EventBus:Register("DEVMODE_OVERRIDE", StopIfActive, {
    namespace = "WarningPreview",
    source    = "WarningPreview",
})

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function WP:Initialize()
    TS.Utils:Debug("WarningPreview 2.0 initialized")
end

return WP