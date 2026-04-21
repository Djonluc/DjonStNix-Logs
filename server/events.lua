-- ==============================================================================
-- server/events.lua
-- General game event handlers: join, leave, chat, resource, explosion,
-- name change, txAdmin, shooting, damage, death.
-- ==============================================================================

-- ==============================================================================
-- PLAYER: Join / Leave
-- ==============================================================================

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    SendLog("join", "📥 Player Connecting",
        ("**%s** (%s) is joining the server."):format(SanitizeString(name), GetDiscordMention(src)),
        { source = src }
    )
end)

AddEventHandler('playerDropped', function(reason)
    local src  = source
    local name = GetPlayerName(src) or "Unknown"

    SendLog("leave", "📤 Player Disconnected",
        ("**%s** (%s) left the server.\n**Reason:** %s"):format(
            SanitizeString(name),
            GetDiscordMention(src),
            SanitizeString(reason or "Unknown")
        ),
        { source = src }
    )
end)

-- ==============================================================================
-- CHAT: Capture public chat messages (skip commands)
-- ==============================================================================

AddEventHandler('chatMessage', function(src, authorName, msg)
    if not msg or msg:sub(1, 1) == "/" then return end

    SendLog("chat", "💬 Chat Message",
        ("**%s** (%s)**:** %s"):format(
            SanitizeString(authorName or GetPlayerName(src) or "Unknown"),
            GetDiscordMention(src),
            SanitizeString(msg)
        ),
        { source = src }
    )
end)

-- ==============================================================================
-- RESOURCES: Start / Stop
-- ==============================================================================

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then return end
    SendLog("resource", "⚙️ Resource Started",
        ("`%s` has started."):format(SanitizeString(resourceName))
    )
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then return end
    SendLog("resource", "⛔ Resource Stopped",
        ("`%s` has stopped."):format(SanitizeString(resourceName))
    )
end)

-- ==============================================================================
-- EXPLOSIONS
-- ==============================================================================

AddEventHandler('explosionEvent', function(src, ev)
    local explosionKey = LogTables.ExplosionTypes[ev.explosionType + 1]
    if not explosionKey then return end

    -- Check if this explosion type is excluded
    for _, excluded in ipairs(Config.ExplosionsNotLogged) do
        if explosionKey == excluded then return end
    end

    local friendlyName = LogTables.ExplosionNames[explosionKey] or explosionKey

    SendLog("explosion", "💥 Explosion",
        ("**%s** (%s) caused an explosion: **%s**"):format(
            SanitizeString(GetPlayerName(src) or "Unknown"),
            GetDiscordMention(src),
            friendlyName
        ),
        { source = src }
    )
end)

-- ==============================================================================
-- NAME CHANGES (using KVP to track previous names)
-- ==============================================================================

AddEventHandler('playerJoining', function(newID, oldID)
    local ids = ExtractIdentifiers(newID)
    local kvpKey  = "DjonStNix-Logs:name:" .. ids.license
    local oldName = GetResourceKvpString(kvpKey)

    if oldName == nil then
        -- First time seeing this player — store their name
        SetResourceKvp(kvpKey, GetPlayerName(newID) or "Unknown")
    else
        local currentName = GetPlayerName(newID) or "Unknown"
        if oldName ~= currentName then
            SendLog("nameChange", "💠 Name Changed",
                ("Player %s changed their name.\n**Old:** %s\n**New:** %s"):format(
                    GetDiscordMention(newID),
                    SanitizeString(oldName),
                    SanitizeString(currentName)
                ),
                { source = newID }
            )
            SetResourceKvp(kvpKey, currentName)
        end
    end
end)

-- ==============================================================================
-- TXADMIN EVENTS
-- ==============================================================================

-- Cache player names since they may disconnect before the event fires
local _playerNames = {}
CreateThread(function()
    while true do
        Wait(2000)
        for _, v in pairs(GetPlayers()) do
            _playerNames[v] = GetPlayerName(v)
        end
    end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(data)
    local function SecsToClock(sec)
        local m = math.floor(sec / 60)
        local s = sec - m * 60
        if m == 0 then return ("%d seconds"):format(s) end
        return ("%d minutes, %d seconds"):format(m, s)
    end
    SendLog("txAdmin", "🔄 Scheduled Restart",
        ("The server will restart in **%s**"):format(SecsToClock(data.secondsRemaining))
    )
end)

AddEventHandler('txAdmin:events:playerKicked', function(data)
    SendLog("txAdmin", "👢 Player Kicked",
        ("**%s** kicked **%s**\n**Reason:** `%s`"):format(
            SanitizeString(data.author or "txAdmin"),
            SanitizeString(_playerNames[tostring(data.target)] or "Unknown"),
            SanitizeString(data.reason or "No reason")
        )
    )
end)

AddEventHandler('txAdmin:events:playerWarned', function(data)
    SendLog("txAdmin", "⚠️ Player Warned",
        ("**%s** warned **%s** (%s)\n**Action ID:** `%s`\n**Reason:** `%s`"):format(
            SanitizeString(data.author or "txAdmin"),
            SanitizeString(GetPlayerName(data.target) or "Unknown"),
            GetDiscordMention(data.target),
            SanitizeString(data.actionId or "N/A"),
            SanitizeString(data.reason or "No reason")
        ),
        { source = data.target }
    )
end)

AddEventHandler('txAdmin:events:playerBanned', function(data)
    local expireStr = data.expiration == false and "Permanent" or tostring(data.expiration)
    SendLog("txAdmin", "🔨 Player Banned",
        ("**%s** banned **%s**\n**Action ID:** `%s`\n**Reason:** `%s`\n**Expires:** `%s`"):format(
            SanitizeString(data.author or "txAdmin"),
            SanitizeString(_playerNames[tostring(data.target)] or "Unknown"),
            SanitizeString(data.actionId or "N/A"),
            SanitizeString(data.reason or "No reason"),
            SanitizeString(expireStr)
        ),
        { priority = true }
    )
end)

AddEventHandler('txAdmin:events:playerWhitelisted', function(data)
    SendLog("txAdmin", "✅ Player Whitelisted",
        ("**%s** whitelisted `%s`\n**Action ID:** `%s`"):format(
            SanitizeString(data.author or "txAdmin"),
            SanitizeString(tostring(data.target)),
            SanitizeString(data.actionId or "N/A")
        )
    )
end)

AddEventHandler('txAdmin:events:healedPlayer', function(data)
    if data.id == -1 then
        SendLog("txAdmin", "💚 Server Healed", "The whole server was healed.")
    else
        SendLog("txAdmin", "💚 Player Healed",
            ("**%s** (%s) was healed."):format(
                SanitizeString(GetPlayerName(data.id) or "Unknown"),
                GetDiscordMention(data.id)
            ),
            { source = data.id }
        )
    end
end)

AddEventHandler('txAdmin:events:announcement', function(data)
    SendLog("txAdmin", "📢 Announcement",
        ("**%s** created an announcement:\n`%s`"):format(
            SanitizeString(data.author or "txAdmin"),
            SanitizeString(data.message or "")
        )
    )
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function(data)
    local function SecsToClock(sec)
        local m = math.floor(sec / 60)
        local s = sec - m * 60
        if m == 0 then return ("%d seconds"):format(s) end
        return ("%d minutes, %d seconds"):format(m, s)
    end
    SendLog("txAdmin", "🛑 Server Shutting Down",
        ("Server will shut down in **%s**\n**Requested by:** `%s`\n**Message:** `%s`"):format(
            SecsToClock((data.delay or 0) / 1000),
            SanitizeString(data.author or "txAdmin"),
            SanitizeString(data.message or "No message")
        ),
        { priority = true }
    )
end)

-- ==============================================================================
-- CLIENT EVENT RECEIVERS: Shooting, Damage, Death
-- ==============================================================================

RegisterNetEvent('DjonStNix-Logs:server:playerShotWeapon')
AddEventHandler('DjonStNix-Logs:server:playerShotWeapon', function(weaponName, count)
    local src = source
    SendLog("shooting", "🔫 Weapon Fired",
        ("**%s** (%s) fired **%s** (%d shots)"):format(
            SanitizeString(GetPlayerName(src) or "Unknown"),
            GetDiscordMention(src),
            SanitizeString(weaponName or "Unknown"),
            count or 1
        ),
        { source = src }
    )
end)

RegisterNetEvent('DjonStNix-Logs:server:playerDamaged')
AddEventHandler('DjonStNix-Logs:server:playerDamaged', function(damageAmount)
    local src = source
    SendLog("damage", "🩸 Player Damaged",
        ("**%s** (%s) took **%d** damage"):format(
            SanitizeString(GetPlayerName(src) or "Unknown"),
            GetDiscordMention(src),
            damageAmount or 0
        ),
        { source = src }
    )
end)

RegisterNetEvent('DjonStNix-Logs:server:playerDied')
AddEventHandler('DjonStNix-Logs:server:playerDied', function(args)
    local src = source
    if not args then return end

    local opts = { source = src }

    if args.killerId and args.killerId > 0 then
        opts.source2 = args.killerId
    end

    SendLog("death", "💀 Player Death",
        args.reason or ("**%s** (%s) died."):format(
            SanitizeString(GetPlayerName(src) or "Unknown"),
            GetDiscordMention(src)
        ),
        opts
    )
end)
