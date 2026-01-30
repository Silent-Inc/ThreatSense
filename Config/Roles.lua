-- ThreatSense: Roles.lua
-- Modern role-based profile settings (AceDB, ProfileManager 2.0)

local ADDON_NAME, TS = ...
local Roles = {}
TS.Roles = Roles

local PM = TS.ProfileManager

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function Header(layout, text)
    local h = layout:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    h:SetText(text)
    h:SetPoint("TOPLEFT", 0, -12)
    return h
end

local function FireProfileChanged()
    TS.EventBus:Send("PROFILE_CHANGED")

    if TS.DisplayPreview and TS.DisplayPreview:IsActive() then
        TS.DisplayPreview:Stop()
    end
    if TS.WarningPreview and TS.WarningPreview:IsActive() then
        TS.WarningPreview:Stop()
    end
end

local function BuildProfileOptions()
    local opts = {}
    for name in pairs(TS.db.profiles) do
        table.insert(opts, { text = name, value = name })
    end
    return opts
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Roles:Initialize()
    local categoryName = TS.Categories.ROLES
    local category, layout = Settings.RegisterVerticalLayoutCategory(categoryName)
    self.category = category

    local roleDB = TS.db.profile.roles

    ------------------------------------------------------------
    -- AUTO-SWITCH
    ------------------------------------------------------------
    Header(layout, "Automatic Role Switching")

    local autoSetting = Settings.RegisterAddOnSetting(
        category,
        "AutoSwitchProfiles",
        nil,
        Settings.VarType.Boolean,
        roleDB.autoSwitch
    )

    Settings.CreateCheckbox(
        layout,
        autoSetting,
        "Enable Auto-Switch Profiles",
        "Automatically switch profiles when your role changes."
    )

    autoSetting:SetValueChangedCallback(function(value)
        roleDB.autoSwitch = value
        FireProfileChanged()
    end)

    ------------------------------------------------------------
    -- ROLE → PROFILE MAPPING
    ------------------------------------------------------------
    Header(layout, "Role-Based Profile Mapping")

    local roles = { "TANK", "HEALER", "DPS" }

    for _, role in ipairs(roles) do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "ProfileFor" .. role,
            nil,
            Settings.VarType.String,
            roleDB[role]
        )

        Settings.CreateDropdown(
            layout,
            setting,
            BuildProfileOptions(),
            role .. " Profile",
            "Profile to use when your role is " .. role .. "."
        )

        setting:SetValueChangedCallback(function(value)
            roleDB[role] = value
            FireProfileChanged()
        end)
    end

    ------------------------------------------------------------
    -- ROLE DETECTION PREVIEW
    ------------------------------------------------------------
    Header(layout, "Role Detection")

    Settings.CreateControlButton(
        layout,
        "Detect Current Role",
        "Show what role ThreatSense currently detects.",
        function()
            local role = TS.RoleManager:GetCurrentRole() or "UNKNOWN"
            print("|cff00ff00ThreatSense|r detected role: " .. role)
        end
    )

    ------------------------------------------------------------
    -- REGISTER
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end

return Roles