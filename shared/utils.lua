-- ==============================================================================
-- shared/utils.lua
-- Shared utility functions used across DjonStNix-Logs.
-- ==============================================================================

--- Sanitize a string: strip null bytes, control characters, truncate to 1000 chars.
--- @param str any
--- @return string
function SanitizeString(str)
    if type(str) ~= "string" then return tostring(str or "N/A") end
    return str:gsub("%z", ""):gsub("[\1-\31]", ""):sub(1, 1000)
end

--- Returns current ISO 8601 timestamp string for Discord embeds.
--- @return string
function GetTimestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

--- Convert hex color string (e.g., "#FF0000") to decimal integer.
--- @param col string|number
--- @return number
function ConvertColor(col)
    if col == nil then return 0 end
    if type(col) == "number" then return col end
    if type(col) == "string" and col:find("#") then
        return tonumber(col:gsub("#", ""), 16) or 0
    end
    return tonumber(col) or 0
end

--- Extract all identifiers from a player source.
--- @param src number
--- @return table
function ExtractIdentifiers(src)
    local identifiers = {
        steam    = "N/A",
        ip       = "N/A",
        discord  = "N/A",
        license  = "N/A",
        license2 = "N/A",
        xbl      = "N/A",
        live     = "N/A",
        fivem    = "N/A",
    }
    if not src then return identifiers end

    local numIds = GetNumPlayerIdentifiers(src)
    for i = 0, numIds - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id then
            if id:find("steam:")    then identifiers.steam    = id
            elseif id:find("ip:")      then identifiers.ip       = id
            elseif id:find("discord:") then identifiers.discord  = id
            elseif id:find("license2:") then identifiers.license2 = id
            elseif id:find("license:") then identifiers.license  = id
            elseif id:find("xbl:")     then identifiers.xbl      = id
            elseif id:find("live:")    then identifiers.live     = id
            elseif id:find("fivem:")   then identifiers.fivem    = id
            end
        end
    end
    return identifiers
end

--- Get Discord mention string for a player.
--- @param src number
--- @return string
function GetDiscordMention(src)
    if not src or src == 0 then return "N/A" end
    local ids = ExtractIdentifiers(src)
    if ids.discord ~= "N/A" then
        return "<@" .. ids.discord:gsub("discord:", "") .. ">"
    end
    return "N/A"
end

--- Get the nearest postal code for a player.
--- @param src number
--- @return string
function GetPlayerPostal(src)
    if not src then return "N/A" end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return "N/A" end

    local coords = GetEntityCoords(ped)
    if not coords then return "N/A" end

    -- Lazy-load postal data
    if not _postalsData then
        local raw = LoadResourceFile(GetCurrentResourceName(), "json/postals.json")
        if raw then
            _postalsData = json.decode(raw)
        end
    end

    if not _postalsData then return "N/A" end

    local x, y = coords.x, coords.y
    local nearestDist = -1
    local nearestIdx  = -1

    for i, p in ipairs(_postalsData) do
        local dm = (x - p.x) ^ 2 + (y - p.y) ^ 2
        if nearestDist == -1 or dm < nearestDist then
            nearestIdx  = i
            nearestDist = dm
        end
    end

    if nearestIdx ~= -1 and _postalsData[nearestIdx] then
        return tostring(_postalsData[nearestIdx].code or "N/A")
    end
    return "N/A"
end

--- Build a rich player details string for Discord embed fields.
--- Respects Config.PlayerDetails toggles.
--- @param src number
--- @return string
function GetPlayerDetailsString(src)
    if not src or src == 0 then return "No player info available." end

    local ids = ExtractIdentifiers(src)
    local value = ""
    local cfg = Config.PlayerDetails

    if cfg.showServerId then
        value = value .. "\n`🔢` **Server ID:** `" .. tostring(src) .. "`"
    end

    if cfg.showPostal then
        value = value .. "\n`🗺️` **Nearest Postal:** `" .. GetPlayerPostal(src) .. "`"
    end

    if cfg.showHealth then
        local ped = GetPlayerPed(src)
        local health = ped and ped ~= 0 and math.floor(GetEntityHealth(ped) / 2) or 0
        value = value .. "\n`❤️` **Health:** `" .. health .. "/100`"
    end

    if cfg.showArmor then
        local ped = GetPlayerPed(src)
        local armor = ped and ped ~= 0 and math.floor(GetPedArmour(ped)) or 0
        value = value .. "\n`🛡️` **Armor:** `" .. armor .. "/100`"
    end

    if cfg.showPing then
        value = value .. "\n`📶` **Ping:** `" .. GetPlayerPing(src) .. "ms`"
    end

    if cfg.showDiscord and cfg.showDiscord.enabled then
        local discordId = ids.discord:gsub("discord:", "")
        if cfg.showDiscord.spoiler then
            value = value .. "\n`💬` **Discord:** <@" .. discordId .. "> (||" .. discordId .. "||)"
        else
            value = value .. "\n`💬` **Discord:** <@" .. discordId .. "> (`" .. discordId .. "`)"
        end
    end

    if cfg.showIp then
        value = value .. "\n`🔗` **IP:** ||" .. ids.ip:gsub("ip:", "") .. "||"
    end

    if cfg.showSteam and cfg.showSteam.enabled then
        if cfg.showSteam.spoiler then
            value = value .. "\n`🎮` **Steam Hex:** ||" .. ids.steam .. "||"
        else
            value = value .. "\n`🎮` **Steam Hex:** `" .. ids.steam .. "`"
        end
    end

    if cfg.showSteamUrl then
        if ids.steam and ids.steam ~= "N/A" then
            local steamDec = tonumber(ids.steam:gsub("steam:", ""), 16)
            if steamDec then
                value = value .. " [`🔗` Steam Profile](https://steamcommunity.com/profiles/" .. steamDec .. ")"
            end
        end
    end

    if cfg.showLicense and cfg.showLicense.enabled then
        if cfg.showLicense.spoiler then
            value = value .. "\n`💿` **License:** ||" .. ids.license .. "||"
            if ids.license2 ~= "N/A" then
                value = value .. "\n`📀` **License 2:** ||" .. ids.license2 .. "||"
            end
        else
            value = value .. "\n`💿` **License:** `" .. ids.license .. "`"
            if ids.license2 ~= "N/A" then
                value = value .. "\n`📀` **License 2:** `" .. ids.license2 .. "`"
            end
        end
    end

    if value == "" then
        return "No info available."
    end
    return value
end

--- Debug print helper
--- @param msg string
function DebugPrint(msg)
    if Config.EnableDebug then
        print("^3[DjonStNix-Logs]^7 " .. tostring(msg))
    end
end
