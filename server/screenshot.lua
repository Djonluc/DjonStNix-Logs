-- ==============================================================================
-- server/screenshot.lua
-- Screenshot command using screenshot-basic.
-- Captures a target player's screen and sends to the screenshot webhook.
-- ==============================================================================

CreateThread(function()
    Wait(2000)

    if not Config.ScreenshotEnabled then
        DebugPrint("Screenshot feature disabled in config.")
        return
    end

    if GetResourceState('screenshot-basic') ~= 'started' then
        print("^3[DjonStNix-Logs] screenshot-basic is not running. /screenshot command disabled.^7")
        return
    end

    -- ── /screenshot <id> command ──
    RegisterCommand('screenshot', function(src, args, rawCommand)
        -- Permission check: console or admin only
        if src ~= 0 then
            local BridgeCore = GetBridgeCore()
            if not BridgeCore then return end

            local isAdmin = false
            pcall(function()
                isAdmin = BridgeCore.Player.IsAdmin(src)
            end)

            if not isAdmin then
                TriggerClientEvent('chat:addMessage', src, {
                    color = { 255, 0, 0 },
                    args = { "DjonStNix-Logs", "Insufficient permissions." }
                })
                return
            end
        end

        -- Validate target
        local targetId = tonumber(args[1])
        if not targetId then
            local errorMsg = "Usage: /screenshot <player_id>"
            if src == 0 then
                print(errorMsg)
            else
                TriggerClientEvent('chat:addMessage', src, {
                    color = { 255, 0, 0 },
                    args = { "DjonStNix-Logs", errorMsg }
                })
            end
            return
        end

        -- Check if target is online
        if GetPlayerPing(targetId) == 0 then
            local errorMsg = "Player " .. targetId .. " is not online."
            if src == 0 then
                print(errorMsg)
            else
                TriggerClientEvent('chat:addMessage', src, {
                    color = { 255, 0, 0 },
                    args = { "DjonStNix-Logs", errorMsg }
                })
            end
            return
        end

        -- Get the screenshot webhook URL
        local webhookUrl = Config.Webhooks.screenshot
        if not webhookUrl or webhookUrl == "" then
            local errorMsg = "Screenshot webhook not configured."
            if src == 0 then
                print(errorMsg)
            else
                TriggerClientEvent('chat:addMessage', src, {
                    color = { 255, 0, 0 },
                    args = { "DjonStNix-Logs", errorMsg }
                })
            end
            return
        end

        -- Request screenshot from target client
        local requesterName = src == 0 and "Console" or GetPlayerName(src) or "Unknown"

        -- Use screenshot-basic to capture and upload directly to webhook
        exports['screenshot-basic']:requestClientScreenshot(targetId, {
            url      = webhookUrl,
            field    = 'files[]',
            headers  = { ['Content-Type'] = 'multipart/form-data' }
        }, function(err, data)
            if err then
                DebugPrint("Screenshot error: " .. tostring(err))
                return
            end

            -- Also send a log embed about the screenshot request
            local targetMention = GetDiscordMention(targetId)
            local requesterMention = src ~= 0 and (" (%s)"):format(GetDiscordMention(src)) or ""

            SendLog("screenshot", "📸 Screenshot Captured",
                ("**Screenshot of:** `%s` (%s) (ID: %d)\n**Requested by:** `%s`%s"):format(
                    SanitizeString(GetPlayerName(targetId) or "Unknown"),
                    targetMention,
                    targetId,
                    SanitizeString(requesterName),
                    requesterMention
                ),
                { source = targetId }
            )
        end)

        -- Confirm to requester
        local confirmMsg = "Screenshot requested for player " .. targetId
        if src == 0 then
            print(confirmMsg)
        else
            TriggerClientEvent('chat:addMessage', src, {
                color = { 0, 255, 0 },
                args = { "DjonStNix-Logs", confirmMsg }
            })
        end
    end, false)

    DebugPrint("Screenshot command registered. (/screenshot <id>)")
end)
