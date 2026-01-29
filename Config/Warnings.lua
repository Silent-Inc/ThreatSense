-- ThreatSense: ConfigWarnings.lua
-- Settings panel for warning system

local ADDON_NAME, TS = ...
local ConfigWarnings = {}
TS.ConfigWarnings = ConfigWarnings

------------------------------------------------------------
-- Initialize the Warnings Settings Panel
------------------------------------------------------------
function ConfigWarnings:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory("ThreatSense - Warnings")
    self.category = category

    ------------------------------------------------------------
    -- Enable warnings toggle
    ------------------------------------------------------------
    local enableVar = Settings.RegisterAddOnSetting(
        category,
        "Enable Warnings",
        "ThreatSenseDB_EnableWarnings",
        Settings.VarType.Boolean,
        true
    )

    Settings.CreateCheckbox(
        layout,
        enableVar,
        "Enable Warnings",
        "Turn the warning system on or off."
    )

    ------------------------------------------------------------
    -- Warning style dropdown
    ------------------------------------------------------------
    local styleVar = Settings.RegisterAddOnSetting(
        category,
        "Warning Style",
        "ThreatSenseDB_WarningStyle",
        Settings.VarType.String,
        "ICON"
    )

    local styleOptions = {
        { text = "Icon Only", value = "ICON" },
        { text = "Text Only", value = "TEXT" },
        { text = "Icon + Text", value = "BOTH" },
    }

    Settings.CreateDropdown(
        layout,
        styleVar,
        styleOptions,
        "Warning Style",
        "Choose how warnings are displayed."
    )

    ------------------------------------------------------------
    -- Preview button
    ------------------------------------------------------------
    Settings.CreateControlButton(
        layout,
        "Preview Warnings",
        "Show a preview of warning alerts.",
        function()
            if TS.WarningPreview:IsActive() then
                TS.WarningPreview:Stop()
            else
                TS.WarningPreview:Start()
            end
        end
    )

    ------------------------------------------------------------
    -- Register category
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end