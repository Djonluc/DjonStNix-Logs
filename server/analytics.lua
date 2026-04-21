-- ==============================================================================
-- server/analytics.lua
-- Automated periodic analytics engine.
-- Aggregates data from inventory.lua trackers and sends summary reports.
-- ==============================================================================

-- ==============================================================================
-- HELPER: Sort table by value and return top N
-- ==============================================================================
local function GetTopN(tbl, n)
    local sorted = {}
    for k, v in pairs(tbl) do
        table.insert(sorted, { name = k, count = v })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)

    local result = {}
    for i = 1, math.min(n, #sorted) do
        table.insert(result, sorted[i])
    end
    return result
end

-- ==============================================================================
-- HELPER: Sort police data by total actions
-- ==============================================================================
local function GetTopOfficers(tbl, n)
    local sorted = {}
    for k, v in pairs(tbl) do
        table.insert(sorted, {
            name  = k,
            total = (v.searches or 0) + (v.confiscations or 0),
            searches = v.searches or 0,
            confiscations = v.confiscations or 0
        })
    end
    table.sort(sorted, function(a, b) return a.total > b.total end)

    local result = {}
    for i = 1, math.min(n, #sorted) do
        table.insert(result, sorted[i])
    end
    return result
end

-- ==============================================================================
-- HELPER: Format a leaderboard list for embeds
-- ==============================================================================
local function FormatLeaderboard(items, valueLabel)
    if #items == 0 then return "No data collected this period." end
    local lines = {}
    for i, item in ipairs(items) do
        local medal = ""
        if i == 1 then medal = "🥇"
        elseif i == 2 then medal = "🥈"
        elseif i == 3 then medal = "🥉"
        else medal = "▫️"
        end
        table.insert(lines, ("%s **%s** — %d %s"):format(medal, SanitizeString(item.name), item.count or item.total, valueLabel))
    end
    return table.concat(lines, "\n")
end

-- ==============================================================================
-- ANALYTICS REPORT LOOP
-- ==============================================================================
CreateThread(function()
    Wait(10000) -- Wait for everything to initialize

    local intervalMs = (Config.AnalyticsInterval or 120) * 60 * 1000

    while true do
        Wait(intervalMs)

        -- Skip if no analytics webhook is configured
        if not Config.Webhooks.analytics or Config.Webhooks.analytics == "" then
            DebugPrint("Analytics webhook not configured — skipping report cycle.")
            goto continue
        end

        DebugPrint("Generating periodic analytics report...")

        -- ══════════════════════════════════════════════
        -- 📊 TOP PURCHASED ITEMS
        -- ══════════════════════════════════════════════
        local topPurchases = GetTopN(AnalyticsData.purchases, 5)
        if #topPurchases > 0 then
            SendLog("analytics", "📊 Top Purchased Items",
                FormatLeaderboard(topPurchases, "bought"),
                {
                    icon = "📊",
                    fields = {
                        { name = "📅 Report Period", value = (Config.AnalyticsInterval or 120) .. " minutes", inline = true },
                        { name = "📦 Unique Items", value = tostring(#topPurchases), inline = true }
                    }
                }
            )
        end

        -- ══════════════════════════════════════════════
        -- 🔨 TOP CRAFTED ITEMS
        -- ══════════════════════════════════════════════
        local topCrafts = GetTopN(AnalyticsData.crafts, 5)
        if #topCrafts > 0 then
            SendLog("analytics", "🔨 Top Crafted Items",
                FormatLeaderboard(topCrafts, "crafted"),
                {
                    icon = "🔨",
                    fields = {
                        { name = "📅 Report Period", value = (Config.AnalyticsInterval or 120) .. " minutes", inline = true }
                    }
                }
            )
        end

        -- ══════════════════════════════════════════════
        -- 👮 POLICE ACTIVITY REPORT
        -- ══════════════════════════════════════════════
        local topOfficers = GetTopOfficers(AnalyticsData.police, 5)
        if #topOfficers > 0 then
            local policeLines = {}
            for i, officer in ipairs(topOfficers) do
                local medal = ""
                if i == 1 then medal = "🥇"
                elseif i == 2 then medal = "🥈"
                elseif i == 3 then medal = "🥉"
                else medal = "▫️"
                end
                table.insert(policeLines, ("%s **%s** — %d searches, %d confiscations"):format(
                    medal, SanitizeString(officer.name), officer.searches, officer.confiscations
                ))
            end

            SendLog("analytics", "👮 Police Activity Report",
                table.concat(policeLines, "\n"),
                {
                    icon = "👮",
                    fields = {
                        { name = "📅 Report Period", value = (Config.AnalyticsInterval or 120) .. " minutes", inline = true },
                        { name = "👮 Active Officers", value = tostring(#topOfficers), inline = true }
                    }
                }
            )
        end

        -- ══════════════════════════════════════════════
        -- 🚨 ILLEGAL ACTIVITY REPORT
        -- ══════════════════════════════════════════════
        local topIllegalItems   = GetTopN(AnalyticsData.illegal.items, 5)
        local topIllegalPlayers = GetTopN(AnalyticsData.illegal.players, 5)

        if #topIllegalItems > 0 or #topIllegalPlayers > 0 then
            local illegalMsg = ""

            if #topIllegalItems > 0 then
                illegalMsg = illegalMsg .. "**🧪 Most Traded Illegal Items:**\n"
                illegalMsg = illegalMsg .. FormatLeaderboard(topIllegalItems, "trades") .. "\n\n"
            end

            if #topIllegalPlayers > 0 then
                illegalMsg = illegalMsg .. "**👤 Most Active Players:**\n"
                illegalMsg = illegalMsg .. FormatLeaderboard(topIllegalPlayers, "interactions")
            end

            SendLog("analytics", "🚨 Illegal Activity Report",
                illegalMsg,
                {
                    icon = "🚨",
                    fields = {
                        { name = "📅 Report Period", value = (Config.AnalyticsInterval or 120) .. " minutes", inline = true }
                    }
                }
            )
        end

        -- ══════════════════════════════════════════════
        -- RESET AGGREGATION TABLES
        -- ══════════════════════════════════════════════
        AnalyticsData.purchases = {}
        AnalyticsData.crafts    = {}
        AnalyticsData.police    = {}
        AnalyticsData.illegal   = { items = {}, players = {} }

        DebugPrint("Analytics report sent. Trackers reset.")

        ::continue::
    end
end)
