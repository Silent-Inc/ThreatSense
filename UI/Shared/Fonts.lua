-- ThreatSense: Fonts.lua
-- Centralized font registration + helpers (profile-aware)

local ADDON_NAME, TS = ...

TS.Fonts = TS.Fonts or {}
local F = TS.Fonts

------------------------------------------------------------
-- Default font definitions (fallbacks)
------------------------------------------------------------
F.DEFAULTS = {
    NORMAL = "Fonts\\FRIZQT__.TTF",
    BOLD   = "Fonts\\FRIZQT__.TTF",
    DAMAGE = "Fonts\\FRIZQT__.TTF",
}

------------------------------------------------------------
-- Resolve a font from SharedMedia or fallback
------------------------------------------------------------
function F:GetFont(key)
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if not LSM then
        return F.DEFAULTS.NORMAL
    end

    local profile = TS.db.profile.fonts
    local mediaKey = profile[key]

    -- If profile key missing, fallback to default
    if not mediaKey then
        return F.DEFAULTS.NORMAL
    end

    -- Try SharedMedia
    local font = LSM:Fetch("font", mediaKey, true)
    if font then
        return font
    end

    -- Fallback
    return F.DEFAULTS.NORMAL
end

------------------------------------------------------------
-- Apply a font to a FontString
------------------------------------------------------------
function F:Apply(fontString, key, size, outline)
    if not fontString then return end

    local font = self:GetFont(key)
    local profile = TS.db.profile.fonts

    local finalSize = size or profile.defaultSize or 12
    local finalOutline = outline or profile.defaultOutline or "OUTLINE"

    fontString:SetFont(font, finalSize, finalOutline)
end

------------------------------------------------------------
-- Convenience wrappers
------------------------------------------------------------
function F:Normal(fontString, size, outline)
    self:Apply(fontString, "normal", size, outline)
end

function F:Bold(fontString, size, outline)
    self:Apply(fontString, "bold", size, outline)
end

function F:Damage(fontString, size, outline)
    self:Apply(fontString, "damage", size, outline)
end

------------------------------------------------------------
-- Initialize (future-proof)
------------------------------------------------------------
function F:Initialize()
    TS.Utils:Debug("Fonts 2.0 initialized")
end

return F