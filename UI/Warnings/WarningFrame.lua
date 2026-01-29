-- ThreatSense: WarningFrame.lua
-- UI for displaying threat warnings

local ADDON_NAME, TS = ...
local Frame = {}
TS.WarningFrame = Frame

local ICONS = {
    TAUNT = "Interface\\Icons\\Ability_Warrior_Taunt",
    LOSING_AGGRO = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    AGGRO_LOST = "Interface\\Icons\\Ability_Warrior_Challange",
    PULLING_AGGRO = "Interface\\Icons\\Ability_Rogue_Feint",
    AGGRO_PULLED = "Interface\\Icons\\Ability_Rogue_Sprint",
    DROP_THREAT = "Interface\\Icons\\Ability_Rogue_Vanish",
}

------------------------------------------------------------
-- Create the warning frame
------------------------------------------------------------
function Frame:Initialize()
    local f = CreateFrame("Frame", ADDON_NAME.."WarningFrame", UIParent)
    f:SetSize(64, 64)
    f:SetPoint("CENTER", 0, 200)
    f:Hide()

    self.frame = f

    -- Icon
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()

    -- Text
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.text:SetPoint("TOP", f, "BOTTOM", 0, -4)

    ------------------------------------------------------------
    -- Listen for warnings
    ------------------------------------------------------------
    TS.EventBus:Register("WARNING_TRIGGERED", function(data)
        self:ShowWarning(data)
    end)

    TS.EventBus:Register("WARNING_CLEARED", function(data)
        self:ClearWarning(data)
    end)
end

------------------------------------------------------------
-- Show a warning
------------------------------------------------------------
function Frame:ShowWarning(data)
    local f = self.frame
    if not f then return end

    local type = data.type
    local icon = ICONS[type]

    if not icon then return end

    f.icon:SetTexture(icon)
    f.text:SetText(type:gsub("_", " "))

    f:Show()

    -- Animation
    TS.WarningAnimations:Stop(f)
    TS.WarningAnimations:Flash(f)
end

------------------------------------------------------------
-- Clear warning
------------------------------------------------------------
function Frame:ClearWarning()
    local f = self.frame
    if not f then return end

    TS.WarningAnimations:Stop(f)
    f:Hide()
end