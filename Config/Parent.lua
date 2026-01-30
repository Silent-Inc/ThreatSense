-- ThreatSense: Parent.lua
-- Root settings panel for the addon (modernized)

local ADDON_NAME, TS = ...
local Parent = {}
TS.Parent = Parent

local VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unknown"
local AUTHOR  = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Author") or "Unknown"

------------------------------------------------------------
-- Central category registry (used by all config modules)
------------------------------------------------------------
TS.ConfigCategories = {
    ROOT            = "ThreatSense",
    DISPLAY         = "ThreatSense - Display",
    DISPLAY_ADV     = "ThreatSense - Display (Advanced)",
    WARNINGS        = "ThreatSense - Warnings",
    WARNINGS_ADV    = "ThreatSense - Warnings (Advanced)",
    ROLES           = "ThreatSense - Roles",
    PROFILES        = "ThreatSense - Profiles",
    MEDIA           = "ThreatSense - Media",
    COLORS          = "ThreatSense - Colors",
    FONTS           = "ThreatSense - Fonts",
    TEXTURES        = "ThreatSense - Textures",
    DEVELOPER       = "ThreatSense - Developer",
}

------------------------------------------------------------
-- Helper: Create a navigation button
------------------------------------------------------------
local function CreateNavButton(layout, text, description, callback)
    Settings.CreateControlButton(layout, text, description, callback)
end

------------------------------------------------------------
-- Initialize the Parent Settings Panel
------------------------------------------------------------
function Parent:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory(TS.ConfigCategories.ROOT)
    self.category = category

    ------------------------------------------------------------
    -- Header: Addon Info
    ------------------------------------------------------------
    local header = layout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetText("ThreatSense")
    header:SetPoint("TOPLEFT", 0, -4)

    local info = layout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    info:SetText("Version: " .. VERSION .. "\nAuthor: " .. AUTHOR)
    info:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)

    ------------------------------------------------------------
    -- Navigation Buttons
    ------------------------------------------------------------
    CreateNavButton(layout,
        "Display Settings",
        "Configure threat bars, list, textures, fonts, and layout.",
        function() Settings.OpenToCategory(TS.ConfigCategories.DISPLAY) end
    )

    CreateNavButton(layout,
        "Advanced Display Settings",
        "Configure textures, fonts, colors, layout, and behavior.",
        function() Settings.OpenToCategory(TS.ConfigCategories.DISPLAY_ADV) end
    )

    CreateNavButton(layout,
        "Warning Settings",
        "Configure warning types, thresholds, visuals, and sounds.",
        function() Settings.OpenToCategory(TS.ConfigCategories.WARNINGS) end
    )

    CreateNavButton(layout,
        "Advanced Warning Settings",
        "Configure advanced warning visuals, thresholds, and audio.",
        function() Settings.OpenToCategory(TS.ConfigCategories.WARNINGS_ADV) end
    )

    CreateNavButton(layout,
        "Role Settings",
        "Configure role detection and optional auto-switch profiles.",
        function() Settings.OpenToCategory(TS.ConfigCategories.ROLES) end
    )

    CreateNavButton(layout,
        "Profile Settings",
        "Manage profiles: create, copy, delete, and switch.",
        function() Settings.OpenToCategory(TS.ConfigCategories.PROFILES) end
    )

    CreateNavButton(layout,
        "Media Settings",
        "Configure fonts, textures, and shared media.",
        function() Settings.OpenToCategory(TS.ConfigCategories.MEDIA) end
    )

    CreateNavButton(layout,
        "Color Settings",
        "Configure threat colors, role colors, and warning colors.",
        function() Settings.OpenToCategory(TS.ConfigCategories.COLORS) end
    )

    CreateNavButton(layout,
        "Font Settings",
        "Configure fonts for all UI elements.",
        function() Settings.OpenToCategory(TS.ConfigCategories.FONTS) end
    )

    CreateNavButton(layout,
        "Texture Settings",
        "Configure textures for bars and backgrounds.",
        function() Settings.OpenToCategory(TS.ConfigCategories.TEXTURES) end
    )

    CreateNavButton(layout,
        "Developer Tools",
        "Debug tools, raw data views, and event logs.",
        function() Settings.OpenToCategory(TS.ConfigCategories.DEVELOPER) end
    )

    ------------------------------------------------------------
    -- Preview Buttons
    ------------------------------------------------------------
    CreateNavButton(layout,
        "Preview Display",
        "Show a live preview of the threat display.",
        function()
            if TS.DisplayPreview:IsActive() then
                TS.DisplayPreview:Stop()
            else
                TS.DisplayPreview:Start()
            end
        end
    )

    CreateNavButton(layout,
        "Preview Warnings",
        "Show a live preview of warning alerts.",
        function()
            if TS.WarningPreview:IsActive() then
                TS.WarningPreview:Stop()
            else
                TS.WarningPreview:StartRandom()
            end
        end
    )

    ------------------------------------------------------------
    -- Test Mode Button
    ------------------------------------------------------------
    CreateNavButton(layout,
        "Start Test Mode",
        "Simulate combat, threat, and warnings for full UI testing.",
        function()
            TS.EventBus:Send("TEST_MODE_STARTED")
        end
    )

    ------------------------------------------------------------
    -- Register Category
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end

return Parent