-- ==============================================================================
-- server/inventory.lua
-- ox_inventory deep integration: items, money, weapons, stashes,
-- suspicious activity detection.
-- Uses ox_inventory registerHook('swapItems') with payload.fromType/toType.
-- ==============================================================================

-- ==============================================================================
-- IN-MEMORY ANALYTICS TRACKERS (fed to analytics.lua)
-- ==============================================================================
AnalyticsData = {
    purchases = {},   -- { [itemName] = count }
    crafts    = {},   -- { [itemName] = count }
    police    = {},   -- { [officerName] = { searches = n, confiscations = n } }
    illegal   = {     -- { items = { [itemName] = count }, players = { [name] = count } }
        items   = {},
        players = {}
    }
}

-- ==============================================================================
-- HELPER: Get action label from fromType → toType
-- ==============================================================================
local function GetActionLabel(fromType, toType)
    if fromType == "player" and toType == "player" then return "Gave"
    elseif fromType == "player" and toType == "drop" then return "Dropped"
    elseif fromType == "drop" and toType == "player" then return "Picked Up"
    elseif fromType == "player" and toType == "stash" then return "Stashed"
    elseif fromType == "stash" and toType == "player" then return "Retrieved from Stash"
    elseif fromType == "player" and toType == "trunk" then return "Added to Trunk"
    elseif fromType == "trunk" and toType == "player" then return "Removed from Trunk"
    elseif fromType == "player" and toType == "glovebox" then return "Added to Glovebox"
    elseif fromType == "glovebox" and toType == "player" then return "Removed from Glovebox"
    elseif fromType == "player" and toType == "evidence" then return "Added to Evidence"
    elseif fromType == "evidence" and toType == "player" then return "Retrieved from Evidence"
    elseif fromType == "player" and toType == "dumpster" then return "Dumped"
    elseif fromType == "dumpster" and toType == "player" then return "Scavenged from Dumpster"
    else return "Moved"
    end
end

local function GetStorageIcon(invType)
    if invType == "trunk" then return "🚗"
    elseif invType == "glovebox" then return "📦"
    elseif invType == "evidence" then return "🔒"
    elseif invType == "stash" then return "🗄️"
    elseif invType == "dumpster" then return "🗑️"
    elseif invType == "drop" then return "📍"
    elseif invType == "player" then return "👤"
    else return "📦"
    end
end

local function GetStorageLabel(invType)
    if invType == "trunk" then return "Vehicle Trunk"
    elseif invType == "glovebox" then return "Glovebox"
    elseif invType == "evidence" then return "Evidence Locker"
    elseif invType == "stash" then return "Stash"
    elseif invType == "dumpster" then return "Dumpster"
    elseif invType == "drop" then return "Ground"
    elseif invType == "player" then return "Player"
    else return "Storage"
    end
end

-- ==============================================================================
-- HELPER: Get player coordinates as formatted string
-- ==============================================================================
local function GetCoordsString(src)
    if not src then return "N/A" end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return "N/A" end
    local coords = GetEntityCoords(ped)
    if not coords then return "N/A" end
    return ("%.1f, %.1f, %.1f"):format(coords.x, coords.y, coords.z)
end

-- ==============================================================================
-- HELPER: Get Discord ID from source
-- ==============================================================================
local function GetDiscordId(src)
    if not src then return "N/A" end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find("discord:") then
            return id:gsub("discord:", "")
        end
    end
    return "N/A"
end

-- ==============================================================================
-- HELPER: Check if item is a weapon
-- ==============================================================================
local function IsWeapon(itemName)
    if not itemName then return false end
    local name = itemName:lower()
    return name:find("^weapon_") ~= nil
end

-- ==============================================================================
-- HELPER: Check if item is ignored
-- ==============================================================================
local function IsIgnored(itemName)
    if not itemName then return false end
    for _, ignored in ipairs(Config.IgnoredItems) do
        if itemName:lower() == ignored:lower() then
            return true
        end
    end
    return false
end

-- ==============================================================================
-- HELPER: Check if item is illegal
-- ==============================================================================
local function IsIllegal(itemName)
    if not itemName then return false end
    for _, illegal in ipairs(Config.IllegalItems) do
        if itemName:lower() == illegal:lower() then
            return true
        end
    end
    return false
end

-- ==============================================================================
-- HELPER: Track illegal activity for analytics
-- ==============================================================================
local function TrackIllegalActivity(itemName, playerName)
    if not IsIllegal(itemName) then return end
    AnalyticsData.illegal.items[itemName] = (AnalyticsData.illegal.items[itemName] or 0) + 1
    if playerName then
        AnalyticsData.illegal.players[playerName] = (AnalyticsData.illegal.players[playerName] or 0) + 1
    end
end

-- ==============================================================================
-- HELPER: Get player distance (for suspicious activity detection)
-- ==============================================================================
local function GetDistance(src1, src2)
    if not src1 or not src2 then return 0 end

    local ped1 = GetPlayerPed(src1)
    local ped2 = GetPlayerPed(src2)
    if not ped1 or ped1 == 0 or not ped2 or ped2 == 0 then return 0 end

    local coords1 = GetEntityCoords(ped1)
    local coords2 = GetEntityCoords(ped2)
    if not coords1 or not coords2 then return 0 end

    return #(coords1 - coords2)
end

-- ==============================================================================
-- WEAPON EQUIP DETECTION
-- ==============================================================================
AddEventHandler('ox_inventory:usedItem', function(playerId, itemName, slotId, metadata)
    if IsIgnored(itemName) then return end

    local playerName = GetPlayerName(playerId) or "Unknown"

    if IsWeapon(itemName) then
        local serial = metadata and metadata.serial or "N/A"
        SendLog("weapons", "🔫 Weapon Equipped",
            ("**%s** equipped **%s**\n**Serial:** `%s`"):format(
                SanitizeString(playerName), SanitizeString(itemName), SanitizeString(serial)
            ),
            { source = playerId }
        )
    end
end)

-- ==============================================================================
-- REGISTER ox_inventory HOOKS
-- Uses the CORRECT payload structure:
--   payload.source     = player server ID
--   payload.fromType   = 'player' | 'drop' | 'stash' | 'trunk' | 'glovebox' | etc.
--   payload.toType     = 'player' | 'drop' | 'stash' | 'trunk' | 'glovebox' | etc.
--   payload.fromInventory = inventory ID (player ID, drop ID, stash name, etc.)
--   payload.toInventory   = inventory ID
--   payload.fromSlot   = { name, count, metadata, ... }
--   payload.count      = amount transferred
-- ==============================================================================
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if GetResourceState('ox_inventory') ~= 'started' then
        print("^1[DjonStNix-Logs] ox_inventory is not started! Inventory logging disabled.^7")
        return
    end

    -- ══════════════════════════════════════════════
    -- SWAP ITEMS HOOK (All item movements)
    -- ══════════════════════════════════════════════
    exports.ox_inventory:registerHook('swapItems', function(payload)
        local src       = payload.source
        local fromType  = payload.fromType
        local toType    = payload.toType
        local fromInv   = payload.fromInventory
        local toInv     = payload.toInventory
        local itemName  = payload.fromSlot and payload.fromSlot.name or "Unknown"
        local count     = payload.count or payload.amount or (payload.fromSlot and payload.fromSlot.count) or 1
        local metadata  = payload.fromSlot and payload.fromSlot.metadata or {}

        if IsIgnored(itemName) then return end

        local playerName = GetPlayerName(src) or "Unknown"
        local mention    = GetDiscordMention(src)
        local coordsStr  = GetCoordsString(src)
        local action     = GetActionLabel(fromType, toType)
        local metaStr    = json.encode(metadata) or "{}"

        -- ── PLAYER → DROP (Item Dropped) ──
        if fromType == "player" and toType == "drop" then
            if IsWeapon(itemName) then
                local serial = metadata.serial or "N/A"
                SendLog("weapons", "🔫 Weapon Dropped",
                    ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`\n**Serial:** `%s`\n**Metadata:** `%s`\n**Coordinates:** `%s`"):format(
                        SanitizeString(playerName), mention, src,
                        SanitizeString(itemName), count, SanitizeString(serial),
                        SanitizeString(metaStr), coordsStr
                    ),
                    { source = src }
                )
            else
                SendLog("items", "📍 Item Dropped",
                    ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`\n**Metadata:** `%s`\n**Coordinates:** `%s`"):format(
                        SanitizeString(playerName), mention, src,
                        SanitizeString(itemName), count,
                        SanitizeString(metaStr), coordsStr
                    ),
                    { source = src }
                )
            end
            TrackIllegalActivity(itemName, playerName)

        -- ── DROP → PLAYER (Item Picked Up) ──
        elseif fromType == "drop" and toType == "player" then
            if IsWeapon(itemName) then
                local serial = metadata.serial or "N/A"
                SendLog("weapons", "🔫 Weapon Picked Up",
                    ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`\n**Serial:** `%s`\n**Metadata:** `%s`\n**Coordinates:** `%s`"):format(
                        SanitizeString(playerName), mention, src,
                        SanitizeString(itemName), count, SanitizeString(serial),
                        SanitizeString(metaStr), coordsStr
                    ),
                    { source = src }
                )
            else
                SendLog("items", "📦 Item Picked Up",
                    ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`\n**Metadata:** `%s`\n**Coordinates:** `%s`"):format(
                        SanitizeString(playerName), mention, src,
                        SanitizeString(itemName), count,
                        SanitizeString(metaStr), coordsStr
                    ),
                    { source = src }
                )
            end
            TrackIllegalActivity(itemName, playerName)

        -- ── PLAYER → PLAYER (Give / Transfer) ──
        elseif fromType == "player" and toType == "player" then
            -- Skip if moving within own inventory
            if fromInv == toInv then return end

            local targetSource = toInv
            local targetName   = GetPlayerName(targetSource) or "Unknown"
            local targetMention = GetDiscordMention(targetSource)
            local targetCoords = GetCoordsString(targetSource)

            -- Suspicious Distance Check
            local dist = GetDistance(src, targetSource)
            if dist > Config.SuspiciousDistance then
                SendLog("suspicious", "⚠️ Suspicious Transfer",
                    ("**%s** transferred **%s** (x%s) to **%s** over **%.1f** units distance!\n(Threshold: %.1f)"):format(
                        SanitizeString(playerName),
                        SanitizeString(itemName), count,
                        SanitizeString(targetName),
                        dist, Config.SuspiciousDistance
                    ),
                    { source = src, source2 = targetSource, priority = true }
                )
            end

            local category = IsWeapon(itemName) and "weapons" or "items"
            local title = IsWeapon(itemName) and "🔫 Weapon Transfer" or "🤝 Item Transfer"
            local serial = metadata.serial and ("\n**Serial:** `%s`"):format(SanitizeString(metadata.serial)) or ""

            SendLog(category, title,
                ("**From Player:**\n" ..
                "Name: `%s`\nDiscord: %s\nPlayer ID: `%s`\n\n" ..
                "**To Player:**\n" ..
                "Name: `%s`\nDiscord: %s\nPlayer ID: `%s`\n\n" ..
                "**Item Info:**\n" ..
                "Item Name: `%s`\nCount: `x%s`%s\n" ..
                "Metadata: `%s`\n\n" ..
                "**Coordinates:**\n" ..
                "From Player: `%s`\nTo Player: `%s`"):format(
                    SanitizeString(playerName), mention, src,
                    SanitizeString(targetName), targetMention, targetSource,
                    SanitizeString(itemName), count, serial,
                    SanitizeString(metaStr),
                    coordsStr, targetCoords
                ),
                { source = src, source2 = targetSource }
            )
            TrackIllegalActivity(itemName, playerName)

        -- ── PLAYER → TRUNK (Trunk Add) ──
        elseif fromType == "player" and toType == "trunk" then
            local category = IsWeapon(itemName) and "weapons" or "stashes"
            local serial = metadata.serial and ("\n**Serial:** `%s`"):format(SanitizeString(metadata.serial)) or ""
            SendLog(category, "🚗 Trunk Add",
                ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`%s\n**Metadata:** `%s`\n**Trunk ID:** `%s`\n**Coordinates:** `%s`"):format(
                    SanitizeString(playerName), mention, src,
                    SanitizeString(itemName), count, serial,
                    SanitizeString(metaStr),
                    SanitizeString(tostring(toInv)), coordsStr
                ),
                { source = src }
            )

        -- ── TRUNK → PLAYER (Trunk Remove) ──
        elseif fromType == "trunk" and toType == "player" then
            local category = IsWeapon(itemName) and "weapons" or "stashes"
            local serial = metadata.serial and ("\n**Serial:** `%s`"):format(SanitizeString(metadata.serial)) or ""
            SendLog(category, "🚗 Trunk Remove",
                ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`%s\n**Metadata:** `%s`\n**Trunk ID:** `%s`\n**Coordinates:** `%s`"):format(
                    SanitizeString(playerName), mention, src,
                    SanitizeString(itemName), count, serial,
                    SanitizeString(metaStr),
                    SanitizeString(tostring(fromInv)), coordsStr
                ),
                { source = src }
            )

        -- ── PLAYER → GLOVEBOX (Glovebox Add) ──
        elseif fromType == "player" and toType == "glovebox" then
            local category = IsWeapon(itemName) and "weapons" or "stashes"
            local serial = metadata.serial and ("\n**Serial:** `%s`"):format(SanitizeString(metadata.serial)) or ""
            SendLog(category, "📦 Glovebox Add",
                ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`%s\n**Metadata:** `%s`\n**Glovebox ID:** `%s`\n**Coordinates:** `%s`"):format(
                    SanitizeString(playerName), mention, src,
                    SanitizeString(itemName), count, serial,
                    SanitizeString(metaStr),
                    SanitizeString(tostring(toInv)), coordsStr
                ),
                { source = src }
            )

        -- ── GLOVEBOX → PLAYER (Glovebox Remove) ──
        elseif fromType == "glovebox" and toType == "player" then
            local category = IsWeapon(itemName) and "weapons" or "stashes"
            local serial = metadata.serial and ("\n**Serial:** `%s`"):format(SanitizeString(metadata.serial)) or ""
            SendLog(category, "📦 Glovebox Remove",
                ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`%s\n**Metadata:** `%s`\n**Glovebox ID:** `%s`\n**Coordinates:** `%s`"):format(
                    SanitizeString(playerName), mention, src,
                    SanitizeString(itemName), count, serial,
                    SanitizeString(metaStr),
                    SanitizeString(tostring(fromInv)), coordsStr
                ),
                { source = src }
            )

        -- ── PLAYER → STASH (Stash Add) ──
        elseif fromType == "player" and toType == "stash" then
            local isEvidence = tostring(toInv):find("evidence")
            local category = isEvidence and "police" or (IsWeapon(itemName) and "weapons" or "stashes")
            local title = isEvidence and "🔒 Evidence Add" or "🗄️ Stash Add"
            local serial = metadata.serial and ("\n**Serial:** `%s`"):format(SanitizeString(metadata.serial)) or ""

            local msg = ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`%s\n**Metadata:** `%s`\n**Stash ID:** `%s`\n**Coordinates:** `%s`"):format(
                SanitizeString(playerName), mention, src,
                SanitizeString(itemName), count, serial,
                SanitizeString(metaStr),
                SanitizeString(tostring(toInv)), coordsStr
            )

            if isEvidence then
                local BridgeCore = GetBridgeCore()
                local job = BridgeCore and BridgeCore.Player.GetJob(src) or nil
                local jobName = job and job.name or "Unknown"
                msg = msg .. ("\n**Job:** `%s`"):format(SanitizeString(jobName))

                -- Track police analytics
                local officerKey = playerName .. " (" .. jobName .. ")"
                if not AnalyticsData.police[officerKey] then
                    AnalyticsData.police[officerKey] = { searches = 0, confiscations = 0 }
                end
                AnalyticsData.police[officerKey].confiscations = AnalyticsData.police[officerKey].confiscations + 1
            end

            SendLog(category, title, msg, { source = src })

        -- ── STASH → PLAYER (Stash Remove) ──
        elseif fromType == "stash" and toType == "player" then
            local isEvidence = tostring(fromInv):find("evidence")
            local category = isEvidence and "police" or (IsWeapon(itemName) and "weapons" or "stashes")
            local title = isEvidence and "🔒 Evidence Remove" or "🗄️ Stash Remove"
            local serial = metadata.serial and ("\n**Serial:** `%s`"):format(SanitizeString(metadata.serial)) or ""

            local msg = ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`%s\n**Metadata:** `%s`\n**Stash ID:** `%s`\n**Coordinates:** `%s`"):format(
                SanitizeString(playerName), mention, src,
                SanitizeString(itemName), count, serial,
                SanitizeString(metaStr),
                SanitizeString(tostring(fromInv)), coordsStr
            )

            if isEvidence then
                local BridgeCore = GetBridgeCore()
                local job = BridgeCore and BridgeCore.Player.GetJob(src) or nil
                local jobName = job and job.name or "Unknown"
                msg = msg .. ("\n**Job:** `%s`"):format(SanitizeString(jobName))

                local officerKey = playerName .. " (" .. jobName .. ")"
                if not AnalyticsData.police[officerKey] then
                    AnalyticsData.police[officerKey] = { searches = 0, confiscations = 0 }
                end
                AnalyticsData.police[officerKey].searches = AnalyticsData.police[officerKey].searches + 1
            end

            SendLog(category, title, msg, { source = src })

        -- ── PLAYER → DUMPSTER ──
        elseif fromType == "player" and toType == "dumpster" then
            SendLog("stashes", "🗑️ Dumpster Add",
                ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`\n**Metadata:** `%s`\n**Coordinates:** `%s`"):format(
                    SanitizeString(playerName), mention, src,
                    SanitizeString(itemName), count,
                    SanitizeString(metaStr), coordsStr
                ),
                { source = src }
            )

        -- ── DUMPSTER → PLAYER ──
        elseif fromType == "dumpster" and toType == "player" then
            SendLog("stashes", "🗑️ Dumpster Remove",
                ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`\n**Metadata:** `%s`\n**Coordinates:** `%s`"):format(
                    SanitizeString(playerName), mention, src,
                    SanitizeString(itemName), count,
                    SanitizeString(metaStr), coordsStr
                ),
                { source = src }
            )

        -- ── CATCH-ALL for any other transfer types ──
        else
            local fromLabel = GetStorageIcon(fromType) .. " " .. GetStorageLabel(fromType)
            local toLabel   = GetStorageIcon(toType) .. " " .. GetStorageLabel(toType)

            SendLog("items", "🔄 Item " .. action,
                ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`\n**Metadata:** `%s`\n**From:** %s (`%s`)\n**To:** %s (`%s`)\n**Coordinates:** `%s`"):format(
                    SanitizeString(playerName), mention, src,
                    SanitizeString(itemName), count,
                    SanitizeString(metaStr),
                    fromLabel, SanitizeString(tostring(fromInv)),
                    toLabel, SanitizeString(tostring(toInv)),
                    coordsStr
                ),
                { source = src }
            )
        end

        -- Do NOT block the transfer
        return
    end, {})

    -- ══════════════════════════════════════════════
    -- BUY ITEM HOOK (Purchase Analytics)
    -- ══════════════════════════════════════════════
    local buyHookSuccess = pcall(function()
        exports.ox_inventory:registerHook('buyItem', function(payload)
            local itemName = payload.itemName or (payload.slot and payload.slot.name) or "Unknown"
            AnalyticsData.purchases[itemName] = (AnalyticsData.purchases[itemName] or 0) + (payload.count or 1)

            local playerName = GetPlayerName(payload.source) or "Unknown"
            local mention = GetDiscordMention(payload.source)

            if not IsIgnored(itemName) then
                SendLog("items", "🛒 Item Purchased",
                    ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`"):format(
                        SanitizeString(playerName), mention, payload.source,
                        SanitizeString(itemName), payload.count or 1
                    ),
                    { source = payload.source }
                )
            end
        end, {})
    end)

    -- ══════════════════════════════════════════════
    -- CRAFT ITEM HOOK (Crafting Analytics)
    -- ══════════════════════════════════════════════
    local craftHookSuccess = pcall(function()
        exports.ox_inventory:registerHook('craftItem', function(payload)
            local itemName = payload.itemName or (payload.slot and payload.slot.name) or "Unknown"
            AnalyticsData.crafts[itemName] = (AnalyticsData.crafts[itemName] or 0) + (payload.count or 1)

            local playerName = GetPlayerName(payload.source) or "Unknown"
            local mention = GetDiscordMention(payload.source)
            TrackIllegalActivity(itemName, playerName)

            if not IsIgnored(itemName) then
                SendLog("items", "🔨 Item Crafted",
                    ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Item Name:** `%s`\n**Count:** `x%s`"):format(
                        SanitizeString(playerName), mention, payload.source,
                        SanitizeString(itemName), payload.count or 1
                    ),
                    { source = payload.source }
                )
            end
        end, {})
    end)

    DebugPrint("ox_inventory hooks registered (swapItems" ..
        (buyHookSuccess and ", buyItem" or "") ..
        (craftHookSuccess and ", craftItem" or "") .. ")")
end)

-- Clean up hooks on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if GetResourceState('ox_inventory') ~= 'started' then return end
    pcall(function()
        exports.ox_inventory:removeHooks()
    end)
end)

-- ==============================================================================
-- MONEY TRACKING (Framework-specific via Bridge)
-- ==============================================================================
CreateThread(function()
    Wait(3000)

    local framework = exports['DjonStNix-Bridge']:GetFramework()

    if framework == 'qb' or framework == 'qbox' then
        -- QBCore / QBox money change event
        AddEventHandler('QBCore:Server:OnMoneyChange', function(src, moneyType, amount, action, reason)
            if not src or amount == 0 then return end

            local playerName = GetPlayerName(src) or "Unknown"
            local mention = GetDiscordMention(src)
            local icon = action == "add" and "💰" or "💸"
            local actionLabel = action == "add" and "Received" or "Spent"

            local msg = ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Action:** %s\n**Amount:** `$%s`\n**Type:** `%s`\n**Reason:** `%s`"):format(
                SanitizeString(playerName), mention, src,
                actionLabel,
                SanitizeString(tostring(amount)),
                SanitizeString(moneyType),
                SanitizeString(reason or "No reason")
            )

            local opts = { source = src }

            -- High-value alert
            if amount >= Config.MoneyThreshold then
                opts.priority = true
                msg = msg .. ("\n\n⚠️ **HIGH VALUE TRANSACTION** (Threshold: $%d)"):format(Config.MoneyThreshold)
            end

            SendLog("money", icon .. " Money " .. actionLabel, msg, opts)
        end)

        DebugPrint("QBCore money tracking initialized.")

    elseif framework == 'esx' then
        -- ESX money change event
        AddEventHandler('esx:setAccountMoney', function(src, account, money, reason)
            if not src then return end

            local playerName = GetPlayerName(src) or "Unknown"
            local mention = GetDiscordMention(src)

            local msg = ("**Player Name:** `%s`\n**Discord:** %s\n**Player ID:** `%s`\n**Account:** `%s`\n**New Balance:** `$%s`\n**Reason:** `%s`"):format(
                SanitizeString(playerName), mention, src,
                SanitizeString(account or "unknown"),
                SanitizeString(tostring(money or 0)),
                SanitizeString(reason or "No reason")
            )

            SendLog("money", "💰 Account Updated", msg, { source = src })
        end)

        DebugPrint("ESX money tracking initialized.")
    end
end)
