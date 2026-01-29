-- ThreatSense: ConfigDisplay.lua
-- Settings panel for display options (bar, list, both)

local ADDON_NAME, TS = ...
local ConfigDisplay = {}
TS.ConfigDisplay = ConfigDisplay

------------------------------------------------------------
-- Initialize the Display Settings Panel
------------------------------------------------------------
function ConfigDisplay:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory("ThreatSense - Display")
    self.category = category

    ------------------------------------------------------------
    -- 1. Register the underlying saved variable
    ------------------------------------------------------------
    local variable = Settings.RegisterAddOnSetting(
        category,
        "Display Mode",
        "ThreatSenseDB_DisplayMode",
        Settings.VarType.String,
        "BAR_ONLY" -- default
    )

    ------------------------------------------------------------
    -- 2. Create dropdown options
    ------------------------------------------------------------
    local options = {
        { text = "Bar Only",     value = "BAR_ONLY" },
        { text = "List Only",    value = "LIST_ONLY" },
        { text = "Bar + List",   value = "BAR_AND_LIST" },
    }

    local dropdown = Settings.CreateDropdown(
        layout,
        variable,
        options,
        "Display Mode",
        "Choose how ThreatSense displays threat information."
    )

    ------------------------------------------------------------
    -- 3. React to user changes
    ------------------------------------------------------------
    variable:SetValueChangedCallback(function(newValue)
        TS.DisplayMode:Set(newValue)

        -- If preview is active, update immediately
        if TS.DisplayPreview and TS.DisplayPreview:IsActive() then
            TS.DisplayPreview:Start()
        end
    end)

    ------------------------------------------------------------
    -- 4. Register the category with the Blizzard Settings UI
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end