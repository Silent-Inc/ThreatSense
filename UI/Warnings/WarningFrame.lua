-- ThreatSense: WarningFrame.lua
-- Modern, profile-driven warning UI with animations and sounds

local ADDON_NAME, TS = ...

TS.WarningFrame = TS.WarningFrame or {}
local WF = TS.WarningFrame

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
WF.frame = nil
WF.activeWarning = nil

------------------------------------------------------------
-- Apply profile settings
------------------------------------------------------------
function WF:ApplyProfile()
    if not self.frame then return end

    local profile = TS.db.profile.warnings

    -- Size
    self.frame:SetSize(profile.iconSize, profile.iconSize)

    -- Position
    local pos = profile.position
    self.frame:ClearAllPoints()
    self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)

    -- Font
    local font = TS.Media:Font(profile.font)
    self.frame.text:SetFont(font, profile.fontSize, "OUTLINE")
end

------------------------------------------------------------
-- Create the warning frame
------------------------------------------------------------
function WF:Initialize()
    if self.frame then return end

    local profile = TS.db.profile.warnings

    local f = CreateFrame("Frame", "ThreatSense_WarningFrame", UIParent)
    f:SetSize(profile.iconSize, profile.iconSize)
    f:SetPoint(profile.position.point, UIParent, profile.position.relativePoint, profile.position.x, profile.position.y)
    f:Hide()

    self.frame = f

    -- Icon
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()

    -- Text
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFont(TS.Media:Font(profile.font), profile.fontSize, "OUTLINE")
    f.text:SetPoint("TOP", f, "BOTTOM", 0, -4)

    ------------------------------------------------------------
    -- Event listeners
    ------------------------------------------------------------

    -- Warning triggered
    TS.EventBus:Register("WARNING_TRIGGERED", function(data)
        self:ShowWarning(data)
    end, {
        namespace = "WarningFrame",
        source = "WarningFrame",
    })

    -- Warning cleared
    TS.EventBus:Register("WARNING_CLEARED", function()
        self:ClearWarning()
    end, {
        namespace = "WarningFrame",
        source = "WarningFrame",
    })

    -- Profile changed
    TS.EventBus:Register("PROFILE_CHANGED", function()
        self:ApplyProfile()
    end, {
        namespace = "WarningFrame",
        source = "WarningFrame",
    })

    -- Threat reset
    TS.EventBus:Register("THREAT_RESET", function()
        self:ClearWarning()
    end, {
        namespace = "WarningFrame",
        source = "WarningFrame",
    })

    TS.Utils:Debug("WarningFrame 2.0 initialized")
end

------------------------------------------------------------
-- Show a warning
------------------------------------------------------------
function WF:ShowWarning(data)
    local f = self.frame
    if not f then return end

    local profile = TS.db.profile.warnings

    -- Priority handling
    if self.activeWarning and data.priority < self.activeWarning.priority then
        return -- ignore lower priority warnings
    end
    self.activeWarning = data

    -- Icon
    local icon = profile.icons[data.type] or TS.WarningDefaults.icons[data.type]
    if not icon then return end
    f.icon:SetTexture(icon)

    -- Text
    if profile.showText then
        f.text:SetText(data.text or data.type:gsub("_", " "))
    else
        f.text:SetText("")
    end

    -- Sound
    if profile.sounds[data.type] and profile.sounds[data.type].enabled then
        local sound = TS.Media:Sound(profile.sounds[data.type].mediaKey)
        if sound then PlaySoundFile(sound, "Master") end
    end

    -- Animation
    TS.WarningAnimations:Stop(f)
    TS.WarningAnimations:Play(f, profile.animation)

    f:Show()
end

------------------------------------------------------------
-- Clear warning
------------------------------------------------------------
function WF:ClearWarning()
    local f = self.frame
    if not f then return end

    TS.WarningAnimations:Stop(f)
    f:Hide()
    self.activeWarning = nil
end

return WF