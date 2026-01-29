-- ThreatSense: ConfigProfiles.lua
-- Profile selection and management panel

local ADDON_NAME, TS = ...
local ConfigProfiles = {}
TS.ConfigProfiles = ConfigProfiles

local PM = TS.ProfileManager

------------------------------------------------------------
-- Initialize the Profiles Settings Panel
------------------------------------------------------------
function ConfigProfiles:Initialize()
    local category, layout = Settings.RegisterVerticalLayoutCategory("ThreatSense - Profiles")
    self.category = category

    ------------------------------------------------------------
    -- Profile dropdown
    ------------------------------------------------------------
    local profileVar = Settings.RegisterAddOnSetting(
        category,
        "Active Profile",
        "ThreatSenseDB_ActiveProfileDummy",
        Settings.VarType.String,
        PM:GetActiveProfileName()
    )

    local function BuildProfileOptions()
        local opts = {}
        for name in pairs(ThreatSenseDB.profiles) do
            table.insert(opts, { text = name, value = name })
        end
        return opts
    end

    Settings.CreateDropdown(
        layout,
        profileVar,
        BuildProfileOptions(),
        "Active Profile",
        "Select which profile this character uses."
    )

    profileVar:SetValueChangedCallback(function(newProfile)
        PM:SetActiveProfile(newProfile)
    end)

    ------------------------------------------------------------
    -- Buttons: New, Copy, Delete
    ------------------------------------------------------------
    Settings.CreateControlButton(
        layout,
        "Create New Profile",
        "Create a new empty profile.",
        function()
            local name = "Profile " .. math.random(1000, 9999)
            PM:CreateProfile(name)
            PM:SetActiveProfile(name)
        end
    )

    Settings.CreateControlButton(
        layout,
        "Copy Current Profile",
        "Duplicate the active profile.",
        function()
            local current = PM:GetActiveProfileName()
            local name = current .. " Copy"
            PM:CopyProfile(current, name)
            PM:SetActiveProfile(name)
        end
    )

    Settings.CreateControlButton(
        layout,
        "Delete Profile",
        "Delete the active profile (except Default).",
        function()
            local current = PM:GetActiveProfileName()
            if current ~= "Default" then
                PM:DeleteProfile(current)
                PM:SetActiveProfile("Default")
            end
        end
    )

    ------------------------------------------------------------
    -- Register category
    ------------------------------------------------------------
    Settings.RegisterAddOnCategory(category)
end