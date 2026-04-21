-- ==============================================================================
-- server/player.lua
-- Player oversight: connect/disconnect with inventory snapshots,
-- police activity monitoring, admin command logging.
-- ==============================================================================

-- ==============================================================================
-- CONNECT / DISCONNECT WITH INVENTORY SNAPSHOT
-- ==============================================================================

if Config.LogConnectDisconnect then

    -- QBCore player loaded
    AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
        if not Player then return end
        local src = Player.PlayerData.source
        SendLog("join", "✅ Player Loaded",
            ("**%s** (%s) (CitizenID: `%s`) has fully loaded."):format(
                SanitizeString(Player.PlayerData.name or "Unknown"),
                GetDiscordMention(src),
                SanitizeString(Player.PlayerData.citizenid or "N/A")
            ),
            { source = src }
        )
    end)

    -- ESX player loaded
    AddEventHandler('esx:playerLoaded', function(src, xPlayer)
        if not xPlayer then return end
        SendLog("join", "✅ Player Loaded",
            ("**%s** (%s) (ID: `%s`) has fully loaded."):format(
                SanitizeString(GetPlayerName(src) or "Unknown"),
                GetDiscordMention(src),
                SanitizeString(xPlayer.identifier or "N/A")
            ),
            { source = src }
        )
    end)

    -- QBox player loaded
    AddEventHandler('qbx_core:server:playerLoaded', function(src)
        local BridgeCore = GetBridgeCore()
        local identifier = BridgeCore and BridgeCore.Player.GetIdentifier(src) or "N/A"
        SendLog("join", "✅ Player Loaded",
            ("**%s** (%s) (ID: `%s`) has fully loaded."):format(
                SanitizeString(GetPlayerName(src) or "Unknown"),
                GetDiscordMention(src),
                SanitizeString(identifier)
            ),
            { source = src }
        )
    end)

    -- QBCore logout
    AddEventHandler('QBCore:Server:PlayerLogout', function(src)
        SendLog("leave", "🚪 Player Logged Out",
            ("**%s** (%s) has logged out."):format(
                SanitizeString(GetPlayerName(src) or "Unknown"),
                GetDiscordMention(src)
            ),
            { source = src }
        )
    end)

    -- ── Inventory Snapshot on Disconnect ──
    AddEventHandler('playerDropped', function(reason)
        local src = source
        if GetResourceState('ox_inventory') ~= 'started' then return end

        -- Attempt to snapshot inventory before player fully disconnects
        local success, inventory = pcall(function()
            return exports.ox_inventory:GetInventoryItems(src)
        end)

        if success and inventory then
            local itemList = {}
            local itemCount = 0

            for _, item in pairs(inventory) do
                if item and item.name then
                    itemCount = itemCount + 1
                    local entry = ("• **%s** x%d"):format(SanitizeString(item.name), item.count or 1)

                    -- Include weapon serial if present
                    if item.metadata and item.metadata.serial then
                        entry = entry .. (" (Serial: `%s`)"):format(SanitizeString(item.metadata.serial))
                    end

                    table.insert(itemList, entry)

                    -- Cap at 25 items to avoid embed size limits
                    if itemCount >= 25 then
                        table.insert(itemList, ("... and %d more items"):format(#inventory - 25))
                        break
                    end
                end
            end

            if #itemList > 0 then
                SendLog("leave", "📋 Disconnect Inventory Snapshot",
                    ("**%s** (%s) disconnected with the following inventory:\n\n%s"):format(
                        SanitizeString(GetPlayerName(src) or "Unknown"),
                        GetDiscordMention(src),
                        table.concat(itemList, "\n")
                    ),
                    { source = src }
                )
            end
        end
    end)
end

-- ==============================================================================
-- POLICE ACTIVITY MONITORING
-- ==============================================================================

-- Track when police access evidence storage (detected via inventory.lua hooks)
-- Additional police search detection for stash opens
AddEventHandler('ox_inventory:openedInventory', function(playerId, inventoryId)
    if not playerId or not inventoryId then return end

    local invType = GetInventoryType(inventoryId)

    if invType == "evidence" then
        local BridgeCore = GetBridgeCore()
        local playerName = GetPlayerName(playerId) or "Unknown"
        local job = BridgeCore and BridgeCore.Player.GetJob(playerId) or nil
        local jobName = job and job.name or "Unknown"

        SendLog("police", "🔍 Evidence Locker Accessed",
            ("**%s** (%s) (%s) opened evidence locker: `%s`"):format(
                SanitizeString(playerName),
                SanitizeString(jobName),
                GetDiscordMention(playerId),
                SanitizeString(tostring(inventoryId))
            ),
            { source = playerId }
        )

        -- Track for analytics
        local officerKey = playerName .. " (" .. jobName .. ")"
        if not AnalyticsData.police[officerKey] then
            AnalyticsData.police[officerKey] = { searches = 0, confiscations = 0 }
        end
        AnalyticsData.police[officerKey].searches = AnalyticsData.police[officerKey].searches + 1
    end
end)

-- ==============================================================================
-- ADMIN COMMAND LOGGING
-- ==============================================================================

if Config.LogAdminCommands then
    AddEventHandler('chatMessage', function(src, authorName, msg)
        if not msg or msg:sub(1, 1) ~= "/" then return end

        -- Only log commands from admin players
        local BridgeCore = GetBridgeCore()
        if not BridgeCore then return end

        local isAdmin = false
        pcall(function()
            isAdmin = BridgeCore.Player.IsAdmin(src)
        end)

        if isAdmin then
            SendLog("admin", "⚡ Admin Command",
                ("**%s** (%s) used command:\n```%s```"):format(
                    SanitizeString(GetPlayerName(src) or "Unknown"),
                    GetDiscordMention(src),
                    SanitizeString(msg)
                ),
                { source = src }
            )
        end
    end)
end
