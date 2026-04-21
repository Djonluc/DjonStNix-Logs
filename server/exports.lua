-- ==============================================================================
-- server/exports.lua
-- Universal logging API for 3rd-party resources.
-- Drop-in replacement for legacy logging systems.
-- ==============================================================================

-- ==============================================================================
-- MODERN EXPORT: createLog
-- ==============================================================================
-- Usage from any server-side script:
--
--   exports['DjonStNix-Logs']:createLog({
--       EmbedMessage = "Player bought a house",
--       player_id    = source,          -- Optional: player 1
--       player_2_id  = targetSource,    -- Optional: player 2
--       channel      = "items",         -- Webhook key OR direct webhook URL
--       title        = "House Purchase",-- Optional: custom embed title
--       color        = "#00FF00",       -- Optional: hex or decimal color
--       icon         = "🏠",            -- Optional: custom icon
--       fields       = {},              -- Optional: extra embed fields
--       screenshot   = false,           -- Optional: attach screenshot
--       priority     = false,           -- Optional: skip queue for alerts
--   })
--
exports('createLog', function(args)
    if not args then return end

    local category = args.channel or "items"
    local title    = args.title or nil
    local message  = args.EmbedMessage or args.message or "No details."
    local color    = args.color or nil

    -- Convert hex color
    if color and type(color) == "string" then
        color = ConvertColor(color)
    end

    local opts = {
        color    = color,
        source   = args.player_id or nil,
        source2  = args.player_2_id or nil,
        fields   = args.fields or nil,
        icon     = args.icon or nil,
        title    = title,
        priority = args.priority or false,
        imageUrl = args.imageUrl or nil,
    }

    -- If channel is a direct webhook URL, pass it as the category
    -- The SendLog function will detect "https://" and use it directly
    SendLog(category, title or category:gsub("^%l", string.upper), message, opts)

    -- Screenshot support
    if args.screenshot and args.player_id then
        if GetResourceState('screenshot-basic') == 'started' then
            local webhookUrl = Config.Webhooks.screenshot
            if webhookUrl and webhookUrl ~= "" then
                exports['screenshot-basic']:requestClientScreenshot(args.player_id, {
                    url   = webhookUrl,
                    field = 'files[]',
                }, function(err, data) end)
            end
        end
    end

    if args.screenshot_2 and args.player_2_id then
        if GetResourceState('screenshot-basic') == 'started' then
            local webhookUrl = Config.Webhooks.screenshot
            if webhookUrl and webhookUrl ~= "" then
                exports['screenshot-basic']:requestClientScreenshot(args.player_2_id, {
                    url   = webhookUrl,
                    field = 'files[]',
                }, function(err, data) end)
            end
        end
    end
end)

-- ==============================================================================
-- LEGACY EXPORT: discord (Legacy Compatibility)
-- ==============================================================================
-- Usage: exports['DjonStNix-Logs']:discord(msg, player_1, player_2, color, channel)
--
exports('discord', function(msg, player_1, player_2, color, channel)
    local args = {
        EmbedMessage = msg,
        color        = color,
        channel      = channel or "items"
    }
    if player_1 and player_1 ~= 0 then
        args.player_id = player_1
    end
    if player_2 and player_2 ~= 0 then
        args.player_2_id = player_2
    end
    exports['DjonStNix-Logs']:createLog(args)
end)

-- ==============================================================================
-- SIMPLE EXPORT: SendLog (direct API)
-- ==============================================================================
-- Usage: exports['DjonStNix-Logs']:SendLog("items", "Title", "Message", { source = src })
--
exports('SendLog', function(category, title, message, opts)
    SendLog(category, title, message, opts)
end)
