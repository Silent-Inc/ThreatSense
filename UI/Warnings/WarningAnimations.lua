-- ThreatSense: WarningEngine.lua
-- Modern tank-aware threat warnings

local ADDON_NAME, TS = ...
TS.WarningEngine = {}
local Engine = TS.WarningEngine

-- Internal state
Engine.activeWarnings = {}
Engine.lastWarning = nil

-- Default thresholds (will be configurable later)
local THRESHOLDS = {
    TANK = {
        LOSING_AGGRO = 80,   -- someone at 80% of your threat
        TAUNT = 0,           -- someone else is tanking (isTanking = false)
    },
    DPS = {
        PULLING = 90,        -- 90% of tank threat
        DROP = 95,           -- 95% of tank threat
    },
    HEALER = {
        PULLING = 90,
    }
}

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Engine:Initialize()
    TS.Utils:Debug("WarningEngine initialized")

    TS.EventBus:Register("THREAT_UPDATED", function(data)
        self:EvaluateThreat(data)
    end)
end

------------------------------------------------------------
-- Emit a warning
------------------------------------------------------------
function Engine:Trigger(type, payload)
    payload = payload or {}
    payload.type = type

    -- Hybrid model:
    -- Tanks: only one warning at a time
    -- DPS: allow multiple
    -- Healers: only one
    local role = TS.Utils:GetPlayerRole()

    if role == "TANK" or role == "HEALER" then
        -- Clear previous warning if different
        if self.lastWarning and self.lastWarning ~= type then
            TS.EventBus:Emit("WARNING_CLEARED", { type = self.lastWarning })
        end
        self.lastWarning = type
    end

    -- Emit the new warning
    TS.EventBus:Emit("WARNING_TRIGGERED", payload)
end

------------------------------------------------------------
-- Clear all warnings
------------------------------------------------------------
function Engine:ClearAll()
    if self.lastWarning then
        TS.EventBus:Emit("WARNING_CLEARED", { type = self.lastWarning })
        self.lastWarning = nil
    end
end

------------------------------------------------------------
-- Main logic
------------------------------------------------------------
function Engine:EvaluateThreat(data)
    local role = TS.Utils:GetPlayerRole()
    local playerPct = data.playerThreatPct or 0
    local isTanking = data.isTanking

    -- No target or no threat → clear warnings
    if not data.target or #data.threatList == 0 then
        self:ClearAll()
        return
    end

    ------------------------------------------------------------
    -- TANK LOGIC
    ------------------------------------------------------------
    if role == "TANK" then
        -- 1. Aggro lost
        if not isTanking then
            self:Trigger("AGGRO_LOST", { threatPct = playerPct })
            return
        end

        -- 2. Losing aggro (someone close behind)
        local second = data.threatList[2]
        if second and second.threatPct >= THRESHOLDS.TANK.LOSING_AGGRO then
            self:Trigger("LOSING_AGGRO", {
                unit = second.unit,
                threatPct = second.threatPct
            })
            return
        end

        -- 3. Taunt needed (someone else tanking)
        local top = data.threatList[1]
        if top and not top.isTanking then
            self:Trigger("TAUNT", {
                unit = top.unit,
                threatPct = top.threatPct
            })
            return
        end

        -- No warnings
        self:ClearAll()
        return
    end

    ------------------------------------------------------------
    -- DPS LOGIC
    ------------------------------------------------------------
    if role == "DAMAGER" then
        local tankThreat = data.tankThreat or data.topThreat

        -- Pulling aggro
        if playerPct >= THRESHOLDS.DPS.PULLING then
            self:Trigger("PULLING_AGGRO", { threatPct = playerPct })
        end

        -- Aggro pulled
        if isTanking then
            self:Trigger("AGGRO_PULLED", { threatPct = playerPct })
        end

        -- Drop threat
        if playerPct >= THRESHOLDS.DPS.DROP then
            self:Trigger("DROP_THREAT", { threatPct = playerPct })
        end

        return
    end

    ------------------------------------------------------------
    -- HEALER LOGIC
    ------------------------------------------------------------
    if role == "HEALER" then
        if playerPct >= THRESHOLDS.HEALER.PULLING then
            self:Trigger("PULLING_AGGRO", { threatPct = playerPct })
        else
            self:ClearAll()
        end
        return
    end
end

return Engine