-- ThreatSense: WarningEngine.lua
-- Modern, snapshot-driven, role-aware threat warning system

local ADDON_NAME, TS = ...

TS.WarningEngine = TS.WarningEngine or {}
local Engine = TS.WarningEngine

local Math = TS.ThreatMath

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
    return t, role == "TANK" and "tank"
             or role == "HEALER" and "healer"
             or "dps"
end

local function GetSoundsProfile()
    if TS.db and TS.db.profile and TS.db.profile.sounds then
        return TS.db.profile.sounds
    end
    return nil
end

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

    if role == "TANK" or role == "HEALER" then
        if self.lastWarning and self.lastWarning ~= type then
            self:Emit("WARNING_CLEARED", { type = self.lastWarning })
        end
        self.lastWarning = type
    end

    StartCooldown(type)

    self:Emit("WARNING_TRIGGERED", payload)

    local sounds = GetSoundsProfile()
    if sounds and sounds[type] and sounds[type].enabled then
        self:Emit("WARNING_SOUND", {
            type = type,
            sound = sounds[type].mediaKey,
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
-- Core evaluation logic (snapshot-driven)
------------------------------------------------------------
function Engine:EvaluateFromSnapshot(s)
    local role = GetRole()
    local thresholds, key = GetThresholdsForRole(role)

    local player = s.player or {}
    local list   = s.list or {}

    local playerThreat    = player.threat or 0
    local playerThreatPct = player.threatPct or 0
    local playerIsTanking = player.isTanking or false
    local relToTank       = player.relToTank or 0

    local topThreat   = s.topThreat or 0
    local tankThreat  = s.tankThreat or topThreat
    local secondThreat = s.secondThreat or 0

    if not s.targetName or #list == 0 then
        self:ClearAll()
        return
    end

    --------------------------------------------------------
    -- TANK LOGIC
    --------------------------------------------------------
    if role == "TANK" then
        local t = thresholds[key]

        if not playerIsTanking then
            self:Trigger("AGGRO_LOST", {
                threatPct = playerThreatPct,
                target    = s.targetName,
            })
            return
        end

        if secondThreat > 0 then
            local losing, rel = Math:IsLosingAggro(playerThreat, secondThreat, t.losingAggro or 80)
            if losing then
                local second = list[2]
                self:Trigger("LOSING_AGGRO", {
                    unit      = second and second.unit or nil,
                    name      = second and second.name or nil,
                    threatPct = second and second.threatPct or 0,
                    relative  = rel,
                })
                return
            end
        end

        local top = list[1]
        if top and not top.isTanking and top.unit ~= "player" then
            self:Trigger("TAUNT", {
                unit      = top.unit,
                name      = top.name,
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
        local pullingThreshold = t.pulling or 90
        local dropThreshold    = t.drop or 95

        if relToTank >= pullingThreshold then
            self:Trigger("PULLING_AGGRO", {
                threatPct = playerThreatPct,
                relative  = relToTank,
                target    = s.targetName,
            })
        end

        if playerIsTanking then
            self:Trigger("AGGRO_PULLED", {
                threatPct = playerThreatPct,
                relative  = relToTank,
                target    = s.targetName,
            })
        end

        if relToTank >= dropThreshold then
            self:Trigger("DROP_THREAT", {
                threatPct = playerThreatPct,
                relative  = relToTank,
                target    = s.targetName,
            })
        end

        return
    end

    --------------------------------------------------------
    -- HEALER LOGIC
    --------------------------------------------------------
    if role == "HEALER" then
        local t = thresholds[key]
        local pullingThreshold = t.pulling or 90

        if relToTank >= pullingThreshold then
            self:Trigger("PULLING_AGGRO", {
                threatPct = playerThreatPct,
                relative  = relToTank,
                target    = s.targetName,
            })
        else
            self:ClearAll()
        end

        return
    end
end

------------------------------------------------------------
-- Event wiring to ThreatEngine 2.0
------------------------------------------------------------
function Engine:OnThreatSnapshotUpdated(snapshot)
    self:EvaluateFromSnapshot(snapshot)
end

function Engine:OnThreatReset()
    self:ClearAll()
end

------------------------------------------------------------
-- Preview support
------------------------------------------------------------
function Engine:Preview(type)
    self:Trigger(type, { preview = true })
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Engine:Initialize()
    TS.Utils:Debug("WarningEngine 2.0 (snapshot-driven) initialized")

    if TS.EventBus and TS.EventBus.Register then
        TS.EventBus:Register("THREAT_SNAPSHOT_UPDATED", function(payload)
            self:OnThreatSnapshotUpdated(payload)
        end)

        TS.EventBus:Register("THREAT_RESET", function()
            self:OnThreatReset()
        end)
    end
end

return Engine