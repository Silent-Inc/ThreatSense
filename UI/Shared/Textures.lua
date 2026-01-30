-- ThreatSense: Textures.lua
-- Centralized texture registration + helpers (profile-aware)

local ADDON_NAME, TS = ...

TS.Textures = TS.Textures or {}
local T = TS.Textures

------------------------------------------------------------
-- Default texture fallbacks
------------------------------------------------------------
T.DEFAULTS = {
    STATUSBAR = "Interface\\TARGETINGFRAME\\UI-StatusBar",
    BACKDROP  = "Interface\\DialogFrame\\UI-DialogBox-Background",
    BORDER    = "Interface\\Tooltips\\UI-Tooltip-Border",
}

------------------------------------------------------------
-- Resolve a texture from SharedMedia or fallback
------------------------------------------------------------
function T:GetTexture(key)
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if not LSM then
        return T.DEFAULTS.STATUSBAR
    end

    local profile = TS.db.profile.textures
    local mediaKey = profile[key]

    if not mediaKey then
        return T.DEFAULTS.STATUSBAR
    end

    local tex = LSM:Fetch("statusbar", mediaKey, true)
    if tex then
        return tex
    end

    return T.DEFAULTS.STATUSBAR
end

------------------------------------------------------------
-- Apply a texture to a StatusBar
------------------------------------------------------------
function T:ApplyStatusBar(bar, key)
    if not bar then return end
    bar:SetStatusBarTexture(self:GetTexture(key))
end

------------------------------------------------------------
-- Apply a texture to a background
------------------------------------------------------------
function T:ApplyBackground(frame, key)
    if not frame then return end

    local LSM = LibStub("LibSharedMedia-3.0", true)
    local profile = TS.db.profile.textures
    local mediaKey = profile[key]

    local tex = nil
    if LSM then
        tex = LSM:Fetch("background", mediaKey, true)
    end

    frame:SetBackdrop({
        bgFile   = tex or T.DEFAULTS.BACKDROP,
        edgeFile = T.DEFAULTS.BORDER,
        tile     = false,
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
end

------------------------------------------------------------
-- Convenience wrappers
------------------------------------------------------------
function T:StatusBar(key)
    return self:GetTexture(key)
end

function T:Backdrop()
    return T.DEFAULTS.BACKDROP
end

function T:Border()
    return T.DEFAULTS.BORDER
end

------------------------------------------------------------
-- Initialize (future-proof)
------------------------------------------------------------
function T:Initialize()
    TS.Utils:Debug("Textures 2.0 initialized")
end

return T