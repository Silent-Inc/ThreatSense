-- ThreatSense: DisplayAdvanced.lua
-- Advanced display configuration (profile-aware, DisplayMode 2.0)

local ADDON_NAME, TS = ...
local DisplayAdvanced = {}
TS.DisplayAdvanced = DisplayAdvanced

local LSM = LibStub("LibSharedMedia-3.0", true)

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function Header(layout, text)
    local h = layout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    h:SetText(text)
    h:SetPoint("TOPLEFT", 0, -12)
    return h
end

local function RefreshPreview()
    if TS.DisplayPreview and TS.DisplayPreview:IsActive() then
        TS.DisplayPreview:Start() -- restart = refresh
    end
end

local function FireProfileChanged()
    TS.EventBus:Send("PROFILE_CHANGED")
    RefreshPreview()
end

------------------------------------------------------------
-- Slider helper (writes to profile)
------------------------------------------------------------
local function Slider(layout, label, key, min, max, step, description)
    local db = TS.db.profile.display

    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        nil,
        Settings.VarType.Number,
        db[key]
    )

    Settings.CreateSlider(
        layout,
        setting,
        label,
        description,
        min,
        max,
        step
    )

    setting:SetValueChangedCallback(function(value)
        db[key] = value
        FireProfileChanged()
    end)
end

------------------------------------------------------------
-- Checkbox helper (writes to profile)
------------------------------------------------------------
local function Checkbox(layout, label, key, description)
    local db = TS.db.profile.display

    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        nil,
        Settings.VarType.Boolean,
        db[key]
    )

    Settings.CreateCheckbox(layout, setting, label, description)

    setting:SetValueChangedCallback(function(value)
        db[key] = value
        FireProfileChanged()
    end)
end

------------------------------------------------------------
-- Color picker helper (writes to profile.colors)
------------------------------------------------------------
local function ColorPicker(layout, label, key, default)
    local db = TS.db.profile.colors

    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        nil,
        Settings.VarType.Color,
        db[key] or default
    )

    Settings.CreateColorPicker(layout, setting, label, "Adjust this color.")

    setting:SetValueChangedCallback(function(value)
        db[key] = value
        FireProfileChanged()
    end)
end

------------------------------------------------------------
-- LSM dropdown helper (writes to profile.display)
------------------------------------------------------------
local function LSMDropdown(layout, label, key, mediaType, description)
    local db = TS.db.profile.display

    local setting = Settings.RegisterAddOnSetting(
        layout:GetCategory(),
        label,
        nil,
        Settings.VarType.String,
        db[key]
    )

    local function BuildOptions()
        local opts = {}
        if LSM then
            for _, name in ipairs(LSM:List(mediaType)) do
                table.insert(opts, { text = name, value = name })
            end
        end
        return opts
    end

    Settings.CreateDropdown(layout, setting, BuildOptions(), label, description)

    setting:SetValueChangedCallback(function(value)
        db[key] = value
        FireProfileChanged()
    end)
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function DisplayAdvanced:Initialize()
    local categoryName = TS.Categories.DISPLAY_ADV
    local category, layout = Settings.RegisterVerticalLayoutCategory(categoryName)
    self.category = category

    local db = TS.db.profile.display

    ------------------------------------------------------------
    -- TEXTURES
    ------------------------------------------------------------
    Header(layout, "Textures")

    LSMDropdown(layout, "Bar Texture", "barTexture", "statusbar",
        "Texture used for threat bars.")

    LSMDropdown(layout, "Background Texture", "backgroundTexture", "background",
        "Background texture for the display.")

    ------------------------------------------------------------
    -- FONTS
    ------------------------------------------------------------
    Header(layout, "Fonts")

    LSMDropdown(layout, "Font", "font", "font",
        "Font used for text in the display.")

    Slider(layout, "Font Size", "fontSize", 8, 32, 1,
        "Adjust the size of display text.")

    ------------------------------------------------------------
    -- COLORS
    ------------------------------------------------------------
    Header(layout, "Colors")

    ColorPicker(layout, "Bar Color", "barColor",
        { r = 0.8, g = 0.1, b = 0.1, a = 1 })

    Checkbox(layout, "Enable Threat Gradient", "threatGradient",
        "Automatically adjust bar color based on threat percentage.")

    ------------------------------------------------------------
    -- LAYOUT
    ------------------------------------------------------------
    Header(layout, "Layout")

    Slider(layout, "Bar Height", "barHeight", 8, 40, 1,
        "Height of each threat bar.")

    Slider(layout, "Bar Spacing", "barSpacing", 0, 10, 1,
        "Spacing between bars.")

    Slider(layout, "List Row Height", "rowHeight", 10, 40, 1,
        "Height of each row in the threat list.")

    Slider(layout, "List Row Spacing", "rowSpacing", 0, 10, 1,
        "Spacing between rows in the threat list.")

    ------------------------------------------------------------
    -- BEHAVIOR
    ------------------------------------------------------------
    Header(layout, "Behavior")

    Slider(layout, "Smooth Animation Speed", "smoothSpeed", 0, 1, 0.05,
        "Speed of bar smoothing animations.")

    Checkbox(layout, "Combat Fade", "combatFade",
        "Fade the display when out of combat.")

    Slider(layout, "Combat Fade Opacity", "combatFadeOpacity", 0, 1, 0.05,
        "Opacity of the display when faded.")

    ------------------------------------------------------------
    -- PREVIEW
    ------------------------------------------------------------
    Header(layout, "Preview")

    Settings.CreateControlButton(
        layout,
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

    ------------------------------------------------------------
    -- Register
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end

return DisplayAdvanced