-- ThreatSense: Display.lua
-- Modern display settings panel (profile-aware, DisplayMode 2.0)

local ADDON_NAME, TS = ...
local Display = {}
TS.Display = Display

------------------------------------------------------------
-- Initialize the Display Settings Panel
------------------------------------------------------------
function Display:Initialize()
    local categoryName = TS.Categories.DISPLAY
    local category, layout = Settings.RegisterVerticalLayoutCategory(categoryName)
    self.category = category

    local db = TS.db.profile.display
    local LSM = LibStub("LibSharedMedia-3.0", true)

    ------------------------------------------------------------
    -- Header
    ------------------------------------------------------------
    local header = layout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetText("ThreatSense Display Settings")
    header:SetPoint("TOPLEFT", 0, -4)

    ------------------------------------------------------------
    -- DISPLAY MODE
    ------------------------------------------------------------
    local modeOptions = {
        { text = "Automatic (Role-Based)", value = "AUTO" },
        { text = "Bar Only",               value = "BAR_ONLY" },
        { text = "List Only",              value = "LIST_ONLY" },
        { text = "Bar + List",             value = "BAR_AND_LIST" },
    }

    local modeSetting = Settings.RegisterAddOnSetting(
        category,
        "DisplayMode",
        nil,
        Settings.VarType.String,
        db.mode or "AUTO"
    )

    local modeDropdown = Settings.CreateDropdown(
        layout,
        modeSetting,
        modeOptions,
        "Display Mode",
        "Choose how ThreatSense displays threat information."
    )

    modeSetting:SetValueChangedCallback(function(newValue)
        db.mode = newValue
        TS.DisplayMode:Set(newValue)

        if TS.DisplayPreview:IsActive() then
            TS.DisplayPreview:Start() -- refresh preview
        end
    end)

    ------------------------------------------------------------
    -- BAR SETTINGS
    ------------------------------------------------------------
    layout:CreateDivider()

    local barHeader = layout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    barHeader:SetText("Threat Bar Settings")

    -- Bar Height
    local barHeight = Settings.RegisterAddOnSetting(
        category,
        "BarHeight",
        nil,
        Settings.VarType.Number,
        db.barHeight or 18
    )

    Settings.CreateSlider(
        layout,
        barHeight,
        10, 40, 1,
        "Bar Height",
        "Height of the main threat bar."
    )

    barHeight:SetValueChangedCallback(function(value)
        db.barHeight = value
        TS.EventBus:Send("PROFILE_CHANGED")
    end)

    -- Bar Texture
    if LSM then
        local textures = {}
        for _, key in ipairs(LSM:List("statusbar")) do
            table.insert(textures, { text = key, value = key })
        end

        local barTexture = Settings.RegisterAddOnSetting(
            category,
            "BarTexture",
            nil,
            Settings.VarType.String,
            db.barTexture or "Blizzard"
        )

        Settings.CreateDropdown(
            layout,
            barTexture,
            textures,
            "Bar Texture",
            "Choose the texture used for the threat bar."
        )

        barTexture:SetValueChangedCallback(function(value)
            db.barTexture = value
            TS.EventBus:Send("PROFILE_CHANGED")
        end)
    end

    ------------------------------------------------------------
    -- LIST SETTINGS
    ------------------------------------------------------------
    layout:CreateDivider()

    local listHeader = layout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listHeader:SetText("Threat List Settings")

    -- Max Entries
    local maxEntries = Settings.RegisterAddOnSetting(
        category,
        "MaxEntries",
        nil,
        Settings.VarType.Number,
        db.maxEntries or 5
    )

    Settings.CreateSlider(
        layout,
        maxEntries,
        3, 10, 1,
        "Max List Entries",
        "How many players to show in the threat list."
    )

    maxEntries:SetValueChangedCallback(function(value)
        db.maxEntries = value
        TS.EventBus:Send("PROFILE_CHANGED")
    end)

    -- List Font Size
    local fontSize = Settings.RegisterAddOnSetting(
        category,
        "ListFontSize",
        nil,
        Settings.VarType.Number,
        db.fontSize or 12
    )

    Settings.CreateSlider(
        layout,
        fontSize,
        8, 24, 1,
        "List Font Size",
        "Font size for threat list entries."
    )

    fontSize:SetValueChangedCallback(function(value)
        db.fontSize = value
        TS.EventBus:Send("PROFILE_CHANGED")
    end)

    ------------------------------------------------------------
    -- SMOOTHING SETTINGS
    ------------------------------------------------------------
    layout:CreateDivider()

    local smoothHeader = layout:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    smoothHeader:SetText("Smoothing")

    local smoothing = Settings.RegisterAddOnSetting(
        category,
        "SmoothingEnabled",
        nil,
        Settings.VarType.Boolean,
        db.smoothing or true
    )

    Settings.CreateCheckbox(
        layout,
        smoothing,
        "Enable Smoothing",
        "Smoothly animate threat bar and list changes."
    )

    smoothing:SetValueChangedCallback(function(value)
        db.smoothing = value
        TS.EventBus:Send("PROFILE_CHANGED")
    end)

    ------------------------------------------------------------
    -- Register Category
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end

return Display