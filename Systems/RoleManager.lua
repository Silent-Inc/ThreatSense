-- ThreatSense: RoleManager.lua
-- Robust, override-capable role detection with event-driven updates

local ADDON_NAME, TS = ...

TS.RoleManager = TS.RoleManager or {}
local RM = TS.RoleManager

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
RM.currentRole = nil
RM.forcedRole = nil
RM.lastUpdate = 0
RM.UPDATE_DEBOUNCE = 0.2 -- seconds

------------------------------------------------------------
-- Internal: Determine role using Blizzard API
------------------------------------------------------------
local function DetectRoleFromGame()
    -- Retail: specialization-based
    if GetSpecialization then
        local spec = GetSpecialization()
        if spec then
            local role = GetSpecializationRole(spec)
            if role then
                return role -- "TANK", "HEALER", "DAMAGER"
            end
        end
    end

    -- Classic fallback: group role assignment
    local assigned = UnitGroupRolesAssigned("player")
    if assigned and assigned ~= "NONE" then
        return assigned
    end

    -- Last fallback: DPS
    return "DAMAGER"
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function RM:GetRole()
    return self.forcedRole or self.currentRole or "DAMAGER"
end

function RM:IsTank()
    return self:GetRole() == "TANK"
end

function RM:IsHealer()
    return self:GetRole() == "HEALER"
end

function RM:IsDPS()
    return self:GetRole() == "DAMAGER"
end

------------------------------------------------------------
-- Forced role override
------------------------------------------------------------
function RM:SetForcedRole(role)
    if role ~= "TANK" and role ~= "HEALER" and role ~= "DAMAGER" and role ~= nil then
        return -- invalid
    end

    self.forcedRole = role
    self:UpdateRole(true) -- force update
end

------------------------------------------------------------
-- Update role and emit events
------------------------------------------------------------
function RM:UpdateRole(force)
    local now = GetTime()
    if not force and (now - self.lastUpdate) < self.UPDATE_DEBOUNCE then
        return
    end
    self.lastUpdate = now

    local detected = DetectRoleFromGame()
    local newRole = self.forcedRole or detected

    if newRole ~= self.currentRole then
        self.currentRole = newRole

        TS.Utils:Debug("RoleManager: Role changed to " .. newRole)

        -- Notify systems
        TS.EventBus:Send("ROLE_CHANGED", newRole)
    end
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
function RM:Initialize()
    -- Initial detection
    self:UpdateRole(true)

    -- Emit initial event
    TS.EventBus:Send("ROLE_INITIALIZED", self.currentRole)

    -- Retail: spec changes
    if C_EventUtils and C_EventUtils.IsEventValid("PLAYER_SPECIALIZATION_CHANGED") then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        f:SetScript("OnEvent", function()
            self:UpdateRole()
        end)
    end

    -- Classic: group role assignment changes
    local f2 = CreateFrame("Frame")
    f2:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    f2:SetScript("OnEvent", function()
        self:UpdateRole()
    end)

    TS.Utils:Debug("RoleManager 2.0 initialized")
end

return RM