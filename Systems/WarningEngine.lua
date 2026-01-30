-- ThreatSense: WarningEngine.lua
-- Modern, role-aware, profile-driven threat warning system

local ADDON_NAME, TS = ...

TS.WarningEngine = TS.WarningEngine or {}
local Engine = TS.WarningEngine

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
Engine.lastWarning = nil
Engine.cooldowns = {}      -- [type] = expiresAt
Engine.cooldownDefaults = {
    AGGRO_LOST     = 2,
    LOSING_AGGRO   = 2,
    TAUNT          = 2,
    PULLING_AGGRO  = 1.5,
    AGGRO_PULLED   = 1.5,
    DROP_THREAT    = 2,
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function Now()
    return GetTime()
end

local function IsOnCooldown(type)
    local expires = Engine.cooldowns[type]
    return expires and expires > Now()
end

local function StartCooldown(type)
    local cd = Engine.cooldownDefaults[type]
    if not cd or cd <= 0 then return end
    Engine.cooldowns[type] = Now() + cd
end

local function GetRole()
    if TS.RoleManager and TS.RoleManager.GetRole then
        return TS.RoleManager:GetRole()
    end
    return "DAMAGER"
end

local function GetWarningProfile()
    if TS.db and TS.db.profile and TS.db.profile.warnings then
        return TS.db.profile.warnings
    end
    return nil
end

local function GetThresholdsForRole(role)
    local profile = GetWarningProfile()
    if not profile or not profile.thresholds then
        -- Fallback defaults if profile not yet configured
        return {
            tank = {
                losingAggro = 80,
                taunt = 0,
            },
            dps = {
                pulling = 90,
                drop = 95,
            },
            healer = {
                pulling = 90,
            },
        }, role == "TANK" and "tank"
           or role == "HEALER" and "healer"
           or "dps"
    end

    local t = profile.thresholds
    return profile.thresholds, role == "TANK" and "tank"
                              or role == "HEALER" and "healer"
                              or "dps"
end

local function GetSoundsProfile()
    if TS.db and TS.db.profile and TS.db.profile.sounds then
        return TS.db.profile.sounds
    end
    return nil
end

------------------------------------------------------------
-- Event emission helpers
------------------------------------------------------------

function Engine:Emit(event, payload)
    if TS.EventBus and TS.EventBus.Send then
        TS.EventBus:Send(event, payload)
    end
end

------------------------------------------------------------
-- Warning triggering
------------------------------------------------------------

function Engine:Trigger(type, payload)
    payload = payload or {}
    payload.type = type

    if IsOnCooldown(type) then
        return
    end

    local role = GetRole()

    -- Tanks/Healers: only one active warning at a time
    if role == "TANK" or role == "HEALER" then
        if self.lastWarning and self.lastWarning ~= type then
            self:Emit("WARNING_CLEARED", { type = self.lastWarning })
        end
        self.lastWarning = type
    end

    StartCooldown(type)

    -- Emit generic warning event
    self:Emit("WARNING_TRIGGERED", payload)

    -- Emit sound event (UI or sound system can handle it)
    local sounds = GetSoundsProfile()
    if sounds and sounds[type] and sounds[type].enabled then
        self:Emit("WARNING_SOUND", {
            type = type,
            sound = sounds[type].mediaKey, -- LibSharedMedia key
        })
    end
end

function Engine:ClearAll()
    if self.lastWarning then
        self:Emit("WARNING_CLEARED", { type = self.lastWarning })
        self.lastWarning = nil
    end
end

------------------------------------------------------------
-- Core evaluation logic
-- Called when threat updates
------------------------------------------------------------

function Engine:EvaluateFromThreatState(threatState)
    local role = GetRole()
    local thresholds, key = GetThresholdsForRole(role)

    local playerThreat = threatState.playerThreat or 0
    local playerThreatPct = threatState.playerThreatPct or 0
    local playerIsTanking = threatState.playerIsTanking or false
    local topThreat = threatState.topThreat or 0
    local tankThreat = threatState.tankThreat or topThreat
    local list = threatState.threatList or {}

    if not threatState.targetName or #list == 0 then
        self:ClearAll()
        return
    end

    --------------------------------------------------------
    -- TANK LOGIC
    --------------------------------------------------------
    if role == "TANK" then
        local t = thresholds[key]

        -- 1. Aggro lost
        if not playerIsTanking then
            self:Trigger("AGGRO_LOST", {
                threatPct = playerThreatPct,
                target = threatState.targetName,
            })
            return
        end

        -- 2. Losing aggro (second highest close behind)
        local second = list[2]
        if second and second.threat > 0 then
            local rel = TS.ThreatMath:GetTankRelativeThreat(playerThreat, second.threat)
            if rel <= (t.losingAggro or 80) then
                self:Trigger("LOSING_AGGRO", {
                    unit = second.unit,
                    name = second.name,
                    threatPct = second.threatPct,
                    relative = rel,
                })
                return
            end
        end

        -- 3. Taunt suggestion (someone else tanking)
        local top = list[1]
        if top and not top.isTanking and top.unit ~= "player" then
            self:Trigger("TAUNT", {
                unit = top.unit,
                name = top.name,
                threatPct = top.threatPct,
            })
            return
        end

        self:ClearAll()
        return
    end

    --------------------------------------------------------
    -- DPS LOGIC
    --------------------------------------------------------
    if role == "DAMAGER" then
        local t = thresholds[key]
        local refThreat = tankThreat > 0 and tankThreat or topThreat
        local rel = TS.ThreatMath:GetRelativeThreat(playerThreat, refThreat)

        -- Pulling aggro
        if rel >= (t.pulling or 90) then
            self:Trigger("PULLING_AGGRO", {
                threatPct = playerThreatPct,
                relative = rel,
                target = threatState.targetName,
            })
        end

        -- Aggro pulled
        if playerIsTanking then
            self:Trigger("AGGRO_PULLED", {
                threatPct = playerThreatPct,
                relative = rel,
                target = threatState.targetName,
            })
        end

        -- Drop threat suggestion
        if rel >= (t.drop or 95) then
            self:Trigger("DROP_THREAT", {
                threatPct = playerThreatPct,
                relative = rel,
                target = threatState.targetName,
            })
        end

        return
    end

    --------------------------------------------------------
    -- HEALER LOGIC
    --------------------------------------------------------
    if role == "HEALER" then
        local t = thresholds[key]
        local refThreat = tankThreat > 0 and tankThreat or topThreat
        local rel = TS.ThreatMath:GetRelativeThreat(playerThreat, refThreat)

        if rel >= (t.pulling or 90) then
            self:Trigger("PULLING_AGGRO", {
                threatPct = playerThreatPct,
                relative = rel,
                target = threatState.targetName,
            })
        else
            self:ClearAll()
        end

        return
    end
end

------------------------------------------------------------
-- Event wiring to ThreatEngine
------------------------------------------------------------

function Engine:OnThreatListUpdated(payload)
    -- payload: { list, topThreat, tankThreat }
    local targetUnit, targetName = TS.ThreatEngine:GetCurrentTarget()
    local playerThreat, playerThreatPct, playerIsTanking = TS.ThreatEngine:GetPlayerThreat()

    local state = {
        targetUnit       = targetUnit,
        targetName       = targetName,
        threatList       = payload.list,
        topThreat        = payload.topThreat,
        tankThreat       = payload.tankThreat,
        playerThreat     = playerThreat,
        playerThreatPct  = playerThreatPct,
        playerIsTanking  = playerIsTanking,
    }

    self:EvaluateFromThreatState(state)
end

function Engine:OnThreatReset()
    self:ClearAll()
end

------------------------------------------------------------
-- Preview support
------------------------------------------------------------

function Engine:Preview(type)
    -- For config panels: simulate a warning
    self:Trigger(type, { preview = true })
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------

function Engine:Initialize()
    TS.Utils:Debug("WarningEngine 2.0 initialized")

    if TS.EventBus and TS.EventBus.Register then
        TS.EventBus:Register("THREAT_LIST_UPDATED", function(payload)
            self:OnThreatListUpdated(payload)
        end)

        TS.EventBus:Register("THREAT_RESET", function()
            self:OnThreatReset()
        end)
    end
end