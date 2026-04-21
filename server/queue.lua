-- ==============================================================================
-- server/queue.lua
-- Webhook queue engine, embed builder, rate limiting, and dispatch.
-- This is the CORE of DjonStNix-Logs — all logging routes through here.
-- ==============================================================================

local Core = nil

CreateThread(function()
    Wait(500)
    Core = exports['DjonStNix-Bridge']:GetCore()
    if Core then
        DebugPrint("Bridge Core loaded successfully.")
    else
        print("^1[DjonStNix-Logs] CRITICAL: Failed to load DjonStNix-Bridge Core!^7")
    end

    -- Load Automated Webhooks from Discord Bot
    local jsonFile = LoadResourceFile(GetCurrentResourceName(), "webhooks.json")
    if jsonFile then
        local data = json.decode(jsonFile)
        if data then
            for category, url in pairs(data) do
                Config.Webhooks[category] = url
            end
            print("^2[DjonStNix-Logs] Automated webhooks loaded successfully.^0")
        end
    else
        DebugPrint("No automated webhooks file found. Falling back to config.lua.")
    end
end)

--- Get the Bridge Core object (lazy fetch).
function GetBridgeCore()
    if not Core then
        Core = exports['DjonStNix-Bridge']:GetCore()
    end
    return Core
end

-- ==============================================================================
-- WEBHOOK QUEUE SYSTEM
-- ==============================================================================
local WebhookQueue    = {}
local PriorityQueue   = {}
local QUEUE_INTERVAL  = 1500 -- ms between queue processing
local LastSentPerType = {}

--- Add a payload to the webhook queue.
--- @param webhookUrl string
--- @param payload string JSON payload
--- @param priority boolean Whether to skip the queue
local function QueueWebhook(webhookUrl, payload, priority)
    if priority then
        table.insert(PriorityQueue, { url = webhookUrl, payload = payload })
    else
        table.insert(WebhookQueue, { url = webhookUrl, payload = payload })
    end
end

--- HTTP dispatch to Discord webhook.
--- @param webhookUrl string
--- @param payload string JSON body
local function DispatchWebhook(webhookUrl, payload)
    PerformHttpRequest(webhookUrl, function(statusCode, responseText, responseHeaders)
        if statusCode == 429 then
            -- Rate limited by Discord — re-queue with delay
            DebugPrint("Rate limited by Discord (429), re-queuing...")
            SetTimeout(2000, function()
                QueueWebhook(webhookUrl, payload, false)
            end)
        elseif Config.EnableDebug then
            if statusCode == 204 or statusCode == 200 then
                DebugPrint("Webhook sent OK (" .. statusCode .. ")")
            else
                DebugPrint("Webhook failed (" .. tostring(statusCode) .. "): " .. tostring(responseText))
            end
        end
    end, "POST", payload, { ["Content-Type"] = "application/json" })
end

--- Queue processing loop.
CreateThread(function()
    while true do
        Wait(QUEUE_INTERVAL)

        -- Process priority queue first (immediate alerts)
        while #PriorityQueue > 0 do
            local item = table.remove(PriorityQueue, 1)
            DispatchWebhook(item.url, item.payload)
            Wait(500) -- Small delay between priority dispatches
        end

        -- Process normal queue (one at a time per tick)
        if #WebhookQueue > 0 then
            local item = table.remove(WebhookQueue, 1)
            DispatchWebhook(item.url, item.payload)
        end
    end
end)

-- ==============================================================================
-- EMBED BUILDER
-- ==============================================================================

--- Build a Discord embed payload.
--- @param opts table { category, title, message, color, source, source2, fields, icon, priority }
--- @return string JSON payload
local function BuildEmbed(opts)
    local category = opts.category or "items"
    local embedColor = opts.color or Config.Colors[category] or 7506394

    -- Convert hex color if needed
    if type(embedColor) == "string" then
        embedColor = ConvertColor(embedColor)
    end

    local title = opts.title or (category:gsub("^%l", string.upper))
    if opts.icon then
        title = opts.icon .. " " .. title
    end

    local embed = {
        title       = SanitizeString(title),
        description = SanitizeString(opts.message or "No details."),
        color       = embedColor,
        timestamp   = GetTimestamp(),
        footer      = {
            text = Config.ServerName .. " • DjonStNix-Logs v1.0.0"
        },
        fields = {}
    }

    -- Player 1 details
    if opts.source and opts.source > 0 then
        table.insert(embed.fields, {
            name   = "👤 Player: " .. SanitizeString(GetPlayerName(opts.source) or "Unknown"),
            value  = GetPlayerDetailsString(opts.source),
            inline = false
        })
    end

    -- Player 2 details
    if opts.source2 and opts.source2 > 0 then
        table.insert(embed.fields, {
            name   = "👤 Player 2: " .. SanitizeString(GetPlayerName(opts.source2) or "Unknown"),
            value  = GetPlayerDetailsString(opts.source2),
            inline = false
        })
    end

    -- Extra fields
    if opts.fields and type(opts.fields) == "table" then
        for _, field in ipairs(opts.fields) do
            table.insert(embed.fields, {
                name   = SanitizeString(field.name or "Field"),
                value  = SanitizeString(field.value or "N/A"),
                inline = field.inline or false
            })
        end
    end

    -- Screenshot image
    if opts.imageUrl then
        embed.image = { url = opts.imageUrl }
    end

    local payloadTable = {
        username = Config.ServerName,
        embeds   = { embed }
    }

    -- Role pings for critical alerts
    if opts.priority and #Config.AlertRoles > 0 then
        local pings = {}
        for _, roleId in ipairs(Config.AlertRoles) do
            table.insert(pings, "<@&" .. roleId .. ">")
        end
        payloadTable.content = table.concat(pings, " ")
    end

    return json.encode(payloadTable)
end

-- ==============================================================================
-- PUBLIC API: SendLog
-- ==============================================================================
--- The core logging function. ALL logs route through this.
--- @param category string Webhook category key (must match Config.Webhooks)
--- @param title string Embed title
--- @param message string Embed description
--- @param opts table Optional: { color, source, source2, fields, icon, priority, title, imageUrl }
function SendLog(category, title, message, opts)
    opts = opts or {}

    -- Validate category
    if type(category) ~= "string" then
        DebugPrint("Invalid log category: " .. tostring(category))
        return
    end

    -- Get webhook URL
    local webhookUrl = Config.Webhooks[category]
    if not webhookUrl or webhookUrl == "" then
        -- If category doesn't match a configured webhook, check if it's a direct URL
        if category:find("https://") then
            webhookUrl = category
            category = "custom"
        else
            DebugPrint("No webhook for category: " .. category .. " — skipping.")
            return
        end
    end

    -- Set defaults from opts
    opts.category = category
    opts.title    = opts.title or title
    opts.message  = message
    opts.color    = opts.color or Config.Colors[category]
    opts.priority = opts.priority or false

    -- Build and queue
    local payload  = BuildEmbed(opts)
    local priority = opts.priority or false

    QueueWebhook(webhookUrl, payload, priority)

    -- Mirror to "all" channel if configured
    local allUrl = Config.Webhooks.all
    if allUrl and allUrl ~= "" and category ~= "all" then
        QueueWebhook(allUrl, payload, false)
    end
end

-- Expose globally for other server scripts in this resource
_G.SendLog = SendLog
_G.GetBridgeCore = GetBridgeCore

-- Startup banner
CreateThread(function()
    Wait(1000)
    print("^5================================================^0")
    print("^3  👑 DJONSTNIX ECOSYSTEM^0")
    print("^5================================================^0")
    print("^2  Resource : ^7DjonStNix-Logs")
    print("^2  Version  : ^71.0.0")
    print("^2  Author   : ^7DjonLuc (@DjonStNix)")
    print("^2  Framework: ^7" .. (exports['DjonStNix-Bridge']:GetFramework() or "Unknown"))
    print("^5================================================^0")
end)
