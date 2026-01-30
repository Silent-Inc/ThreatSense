-- ThreatSense: ThreatBar.lua
-- Snapshot-driven, profile-based single-bar threat display

local ADDON_NAME, TS = ...

TS.ThreatBar = TS.ThreatBar or {}
local Bar = TS.ThreatBar

------------------------------------------------------------
-- Internal state
------------------------------------------------------------
Bar.frame = nil

------------------------------------------------------------
-- Color mapping by threat category
------------------------------------------------------------
local CATEGORY_COLORS = {
    SAFE     = { r = 0.20, g = 0.80, b = 0.20 },
    WARNING  = { r = 0.90, g = 0.80, b = 0.20 },
    DANGER   = { r = 0.95, g = 0.50, b = 0.10 },
    CRITICAL = { r = 0.95, g = 0.20, b = 0.20 },
}

local function GetColorForCategory(category)
    return CATEGORY_COLORS[category] or CATEGORY_COLORS.SAFE
end

------------------------------------------------------------
-- Apply profile settings to the bar
------------------------------------------------------------
function Bar:ApplyProfile()
    if not self.frame then return end
    local profile = TS.db.profile.display
    if not profile then return end

    -- Size & scale
    self.frame:SetWidth(profile.width or 200)
    self.frame:SetHeight(profile.height or 18)
    self.frame:SetScale(profile.scale or 1)

    -- Texture
    local texture = TS.Media:Statusbar(profile.barTexture)
    self.frame:SetStatusBarTexture(texture)

    -- Font
    local font = TS.Media:Font(profile.font)
    self.frame.text:SetFont(font, profile.fontSize or 12, "OUTLINE")

    -- Position
    local pos = profile.position
    if pos then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
end

------------------------------------------------------------
-- Create the ThreatBar frame
------------------------------------------------------------
function Bar:Create()
    if self.frame then return end

    local f = CreateFrame("StatusBar", "ThreatSense_ThreatBar", UIParent)
    f:SetMinMaxValues(0, 100)
    f:Hide()

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.4)
    f.bg = bg

    -- Text
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER")
    f.text = text

    self.frame = f
    self:ApplyProfile()

    --------------------------------------------------------
    -- Event listeners
    --------------------------------------------------------
    TS.EventBus:Register("THREAT_SNAPSHOT_UPDATED", function(snapshot)
        self:OnSnapshot(snapshot)
    end, {
        namespace = "ThreatBar",
        source    = "ThreatBar",
    })

    TS.EventBus:Register("THREAT_RESET", function()
        self:Hide()
    end, {
        namespace = "ThreatBar",
        source    = "ThreatBar",
    })

    TS.EventBus:Register("DISPLAY_MODE_CHANGED", function(mode)
        self:OnDisplayModeChanged(mode)
    end, {
        namespace = "ThreatBar",
        source    = "ThreatBar",
    })

    TS.EventBus:Register("PROFILE_CHANGED", function()
        self:ApplyProfile()
    end, {
        namespace = "ThreatBar",
        source    = "ThreatBar",
    })

    TS.Utils:Debug("ThreatBar 2.0 (snapshot-driven) initialized")
end

------------------------------------------------------------
-- Display mode logic
------------------------------------------------------------
function Bar:OnDisplayModeChanged(mode)
    if mode == "BAR_ONLY" or mode == "BAR_AND_LIST" then
        self:Show()
    else
        self:Hide()
    end
end

------------------------------------------------------------
-- Snapshot handler
------------------------------------------------------------
function Bar:OnSnapshot(s)
    if not self.frame then return end

    local profile = TS.db.profile.display
    if not profile then return end

    local player = s.player or {}
    local pct    = player.threatPct or 0
    local category = player.category or "SAFE"
    local targetName = s.targetName or "No Target"

    -- Smooth animation
    TS.Smoothing:Start(self.frame, pct)

    -- Text
    if profile.showText then
        self.frame.text:SetText(string.format("%s - %d%%", targetName, pct))
    else
        self.frame.text:SetText("")
    end

    -- Color by category
    local c = GetColorForCategory(category)
    self.frame:SetStatusBarColor(c.r, c.g, c.b)

    self:Show()
end

------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------
function Bar:Show()
    if self.frame then self.frame:Show() end
end

function Bar:Hide()
    if self.frame then self.frame:Hide() end
end

return Bar