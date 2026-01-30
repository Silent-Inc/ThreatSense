-- ThreatSense: SharedMedia.lua
-- Unified media API with ThreatSense namespace and LSM integration

local ADDON_NAME, TS = ...

TS.Media = TS.Media or {}
local Media = TS.Media

local LSM = LibStub("LibSharedMedia-3.0")

------------------------------------------------------------
-- Internal cache (optional but improves performance)
------------------------------------------------------------
Media.cache = {
    statusbar = {},
    background = {},
    font = {},
    sound = {},
}

------------------------------------------------------------
-- Register ThreatSense media namespace
-- Even without bundled assets, we provide branded aliases
------------------------------------------------------------
function Media:RegisterDefaults()
    -- Statusbars
    LSM:Register("statusbar", "ThreatSense - Default", "Interface\\TARGETINGFRAME\\UI-StatusBar")
    LSM:Register("statusbar", "ThreatSense - Smooth",  "Interface\\TARGETINGFRAME\\UI-StatusBar")
    LSM:Register("statusbar", "ThreatSense - Flat",    "Interface\\Buttons\\WHITE8x8")

    -- Backgrounds
    LSM:Register("background", "ThreatSense - Default", "Interface\\Buttons\\WHITE8x8")

    -- Fonts
    LSM:Register("font", "ThreatSense - Default", "Fonts\\FRIZQT__.TTF")

    -- Sounds (aliases to Blizzard sounds)
    LSM:Register("sound", "ThreatSense - Warning", 567482)  -- RaidWarning
    LSM:Register("sound", "ThreatSense - Alarm",   567399)  -- Alarm
    LSM:Register("sound", "ThreatSense - Horn",    567275)  -- Horn
    LSM:Register("sound", "ThreatSense - Bell",    567404)  -- Bell
end

------------------------------------------------------------
-- Unified fetch API
------------------------------------------------------------
function Media:Fetch(kind, name)
    if not kind then return nil end

    -- Cache hit
    if name and self.cache[kind] and self.cache[kind][name] then
        return self.cache[kind][name]
    end

    -- Try to fetch from LSM
    local result = nil
    if name and name ~= "" then
        result = LSM:Fetch(kind, name, true)
    end

    -- Fallbacks
    if not result then
        if kind == "statusbar" then
            result = LSM:Fetch("statusbar", "ThreatSense - Default")
        elseif kind == "background" then
            result = LSM:Fetch("background", "ThreatSense - Default")
        elseif kind == "font" then
            result = LSM:Fetch("font", "ThreatSense - Default")
        elseif kind == "sound" then
            result = LSM:Fetch("sound", "ThreatSense - Warning")
        end
    end

    -- Cache result
    if name and result then
        self.cache[kind][name] = result
    end

    return result
end

------------------------------------------------------------
-- Convenience wrappers
------------------------------------------------------------
function Media:Statusbar(name)
    return self:Fetch("statusbar", name)
end

function Media:Background(name)
    return self:Fetch("background", name)
end

function Media:Font(name)
    return self:Fetch("font", name)
end

function Media:Sound(name)
    return self:Fetch("sound", name)
end

------------------------------------------------------------
-- LSM callback → notify UI to refresh
------------------------------------------------------------
local function OnMediaUpdated(event, mediaType, key)
    if TS.EventBus and TS.EventBus.Send then
        TS.EventBus:Send("MEDIA_UPDATED", {
            kind = mediaType,
            key = key,
        })
    end
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Media:Initialize()
    self:RegisterDefaults()

    -- Listen for new media being registered
    LSM:RegisterCallback("LibSharedMedia_Registered", OnMediaUpdated)
    LSM:RegisterCallback("LibSharedMedia_SetGlobal", OnMediaUpdated)

    TS.Utils:Debug("SharedMedia 2.0 initialized")
end

return Media