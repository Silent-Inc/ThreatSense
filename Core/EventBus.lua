-- ThreatSense: EventBus.lua
-- Advanced pub/sub system with namespaces, metadata, and queued events

local ADDON_NAME, TS = ...

TS.EventBus = TS.EventBus or {}
local Bus = TS.EventBus

------------------------------------------------------------
-- Internal storage
------------------------------------------------------------
Bus.listeners = {}          -- listeners[event] = { entries... }
Bus.namespaces = {}         -- namespaces[ns] = { entries... }
Bus.wildcards = {}          -- listeners for "*"
Bus.queue = {}              -- queued events
Bus.queueEnabled = false    -- optional queued mode

------------------------------------------------------------
-- Utility: Create listener entry
------------------------------------------------------------
local function CreateEntry(event, callback, once, source, namespace)
    return {
        event = event,
        callback = callback,
        once = once or false,
        source = source or "Unknown",
        namespace = namespace or nil,
    }
end

------------------------------------------------------------
-- Register a listener
-- @param event (string)
-- @param callback (function)
-- @param opts { once = bool, source = string, namespace = string }
------------------------------------------------------------
function Bus:Register(event, callback, opts)
    if not event or type(callback) ~= "function" then return end

    opts = opts or {}

    -- Wildcard listener
    if event == "*" then
        table.insert(Bus.wildcards, CreateEntry("*", callback, opts.once, opts.source, opts.namespace))
        return
    end

    Bus.listeners[event] = Bus.listeners[event] or {}
    local entry = CreateEntry(event, callback, opts.once, opts.source, opts.namespace)
    table.insert(Bus.listeners[event], entry)

    -- Namespace tracking
    if opts.namespace then
        Bus.namespaces[opts.namespace] = Bus.namespaces[opts.namespace] or {}
        table.insert(Bus.namespaces[opts.namespace], entry)
    end
end

------------------------------------------------------------
-- Register a one-time listener
------------------------------------------------------------
function Bus:RegisterOnce(event, callback, opts)
    opts = opts or {}
    opts.once = true
    self:Register(event, callback, opts)
end

------------------------------------------------------------
-- Unregister a specific callback
------------------------------------------------------------
function Bus:Unregister(event, callback)
    local list = Bus.listeners[event]
    if not list then return end

    for i = #list, 1, -1 do
        if list[i].callback == callback then
            table.remove(list, i)
        end
    end
end

------------------------------------------------------------
-- Unregister all listeners for an event
------------------------------------------------------------
function Bus:UnregisterAll(event)
    Bus.listeners[event] = nil
end

------------------------------------------------------------
-- Unregister all listeners in a namespace
------------------------------------------------------------
function Bus:UnregisterNamespace(namespace)
    local entries = Bus.namespaces[namespace]
    if not entries then return end

    for _, entry in ipairs(entries) do
        local list = Bus.listeners[entry.event]
        if list then
            for i = #list, 1, -1 do
                if list[i] == entry then
                    table.remove(list, i)
                end
            end
        end
    end

    Bus.namespaces[namespace] = nil
end

------------------------------------------------------------
-- Queue an event (processed later)
------------------------------------------------------------
function Bus:SendQueued(event, ...)
    table.insert(Bus.queue, { event = event, args = { ... } })
end

------------------------------------------------------------
-- Flush queued events
------------------------------------------------------------
function Bus:FlushQueue()
    for _, item in ipairs(Bus.queue) do
        Bus:Send(item.event, unpack(item.args))
    end
    Bus.queue = {}
end

------------------------------------------------------------
-- Send an event immediately
------------------------------------------------------------
function Bus:Send(event, ...)
    local debug = TS.db and TS.db.profile and TS.db.profile.debug

    -- Debug logging
    if debug then
        print("|cff00ff00[EventBus]|r", "Event:", event)
    end

    -- Wildcard listeners
    for i = #Bus.wildcards, 1, -1 do
        local entry = Bus.wildcards[i]
        local ok, err = pcall(entry.callback, event, ...)
        if not ok then
            print("|cffff0000[EventBus Error]|r", "Wildcard:", entry.source, err)
        end
        if entry.once then
            table.remove(Bus.wildcards, i)
        end
    end

    -- Normal listeners
    local list = Bus.listeners[event]
    if not list then return end

    for i = #list, 1, -1 do
        local entry = list[i]

        local ok, err = pcall(entry.callback, ...)
        if not ok then
            print("|cffff0000[EventBus Error]|r",
                "Event:", event,
                "Source:", entry.source,
                "Namespace:", entry.namespace or "none",
                err)
        end

        if entry.once then
            table.remove(list, i)
        end
    end
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function Bus:Initialize()
    TS.Utils:Debug("EventBus 2.0 initialized")
end

return Bus