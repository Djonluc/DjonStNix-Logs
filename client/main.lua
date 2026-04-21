-- ==============================================================================
-- client/main.lua
-- Client-side detection loops: Shooting, Damage, Death.
-- All data sent to server for logging — NO direct client webhook calls.
-- ==============================================================================

-- ==============================================================================
-- SHOOTING DETECTION
-- ==============================================================================
CreateThread(function()
    Wait(2000) -- Wait for config to load

    if not Config.WeaponLog then return end

    local fireWeapon = nil
    local fireCount  = 0
    local timeout    = 0

    while true do
        Wait(0)
        local playerPed = PlayerPedId()

        if IsPedShooting(playerPed) then
            fireWeapon = GetSelectedPedWeapon(playerPed)
            fireCount  = fireCount + 1
            timeout    = 1000 -- Active cooldown before sending log
        elseif fireCount ~= 0 and timeout ~= 0 then
            if timeout > 0 then
                timeout = timeout - 1
            end

            -- If weapon changed, flush immediately
            if fireWeapon ~= GetSelectedPedWeapon(playerPed) then
                timeout = 0
            end

            if fireCount > 0 and timeout == 0 then
                local weaponName = LogTables.WeaponNames[tostring(fireWeapon)]

                if not weaponName then
                    weaponName = "Unknown Weapon"
                end

                -- Check if this weapon is excluded
                local isExcluded = false
                for _, v in pairs(Config.WeaponsNotLogged) do
                    if fireWeapon == GetHashKey(v) then
                        isExcluded = true
                        break
                    end
                end

                if not isExcluded then
                    TriggerServerEvent('DjonStNix-Logs:server:playerShotWeapon', weaponName, fireCount)
                end

                fireCount = 0
            end
        end
    end
end)

-- ==============================================================================
-- DAMAGE DETECTION
-- ==============================================================================
CreateThread(function()
    Wait(2000)

    if not Config.DamageLog then return end

    local lastHealth = nil

    while true do
        Wait(1000)
        local currentHealth = GetEntityHealth(PlayerPedId())

        if lastHealth == nil then
            lastHealth = currentHealth
        end

        -- Health increased (healed) — just update tracker
        if currentHealth > lastHealth then
            lastHealth = currentHealth
        end

        -- Health decreased — damage taken
        if lastHealth > currentHealth then
            local damageAmount = math.floor((lastHealth - currentHealth) / 2)

            if damageAmount > 0 then
                TriggerServerEvent('DjonStNix-Logs:server:playerDamaged', damageAmount)
            end

            lastHealth = currentHealth
        end
    end
end)

-- ==============================================================================
-- DEATH DETECTION
-- ==============================================================================
CreateThread(function()
    Wait(2000)

    if not Config.DeathLog then return end

    local hasRun = false

    while true do
        Wait(0)
        local iPed = PlayerPedId()

        if IsEntityDead(iPed) then
            if not hasRun then
                hasRun = true

                local kPed      = GetPedSourceOfDeath(iPed)
                local cause     = GetPedCauseOfDeath(iPed)
                local deathInfo = LogTables.DeathCauses[cause]
                local killer    = 0
                local kPlayer   = NetworkGetPlayerIndexFromPed(kPed)

                Wait(500) -- Brief delay to ensure network data is available

                local deathReason = ""

                if kPlayer == PlayerId() then
                    -- Suicide
                    if deathInfo then
                        if deathInfo[2] then
                            deathReason = ("**%s** killed themselves (%s: %s)"):format(
                                GetPlayerName(PlayerId()), deathInfo[1], deathInfo[2]
                            )
                        else
                            deathReason = ("**%s** killed themselves (%s)"):format(
                                GetPlayerName(PlayerId()), deathInfo[1]
                            )
                        end
                    else
                        deathReason = ("**%s** killed themselves"):format(GetPlayerName(PlayerId()))
                    end

                elseif kPlayer == nil or kPlayer == -1 then
                    if kPed == 0 then
                        -- Environment/unknown death
                        if deathInfo then
                            if deathInfo[2] then
                                deathReason = ("**%s** died (%s: %s)"):format(
                                    GetPlayerName(PlayerId()), deathInfo[1], deathInfo[2]
                                )
                            else
                                deathReason = ("**%s** died (%s)"):format(
                                    GetPlayerName(PlayerId()), deathInfo[1]
                                )
                            end
                        else
                            deathReason = ("**%s** died (Unknown cause)"):format(GetPlayerName(PlayerId()))
                        end
                    else
                        if IsEntityAPed(kPed) then
                            -- AI ped killed player
                            if deathInfo and deathInfo[2] then
                                deathReason = ("**%s** was killed by an NPC (%s: %s)"):format(
                                    GetPlayerName(PlayerId()), deathInfo[1], deathInfo[2]
                                )
                            elseif deathInfo then
                                deathReason = ("**%s** was killed by an NPC (%s)"):format(
                                    GetPlayerName(PlayerId()), deathInfo[1]
                                )
                            else
                                deathReason = ("**%s** was killed by an NPC"):format(GetPlayerName(PlayerId()))
                            end
                        elseif IsEntityAVehicle(kPed) then
                            -- Vehicle killed player
                            local driver = GetPedInVehicleSeat(kPed, -1)
                            if IsEntityAPed(driver) and IsPedAPlayer(driver) then
                                killer = NetworkGetPlayerIndexFromPed(driver)
                                if deathInfo and deathInfo[2] then
                                    deathReason = ("**%s** was killed by **%s** (%s: %s)"):format(
                                        GetPlayerName(PlayerId()), GetPlayerName(killer), deathInfo[1], deathInfo[2]
                                    )
                                elseif deathInfo then
                                    deathReason = ("**%s** was killed by **%s** (%s)"):format(
                                        GetPlayerName(PlayerId()), GetPlayerName(killer), deathInfo[1]
                                    )
                                else
                                    deathReason = ("**%s** was run over by **%s**"):format(
                                        GetPlayerName(PlayerId()), GetPlayerName(killer)
                                    )
                                end
                            else
                                -- AI vehicle
                                if deathInfo and deathInfo[2] then
                                    deathReason = ("**%s** was killed by a vehicle (%s: %s)"):format(
                                        GetPlayerName(PlayerId()), deathInfo[1], deathInfo[2]
                                    )
                                else
                                    deathReason = ("**%s** was hit by a vehicle"):format(GetPlayerName(PlayerId()))
                                end
                            end
                        else
                            -- Unknown entity
                            if deathInfo and deathInfo[2] then
                                deathReason = ("**%s** died (%s: %s)"):format(
                                    GetPlayerName(PlayerId()), deathInfo[1], deathInfo[2]
                                )
                            else
                                deathReason = ("**%s** died (Unknown)"):format(GetPlayerName(PlayerId()))
                            end
                        end
                    end
                else
                    -- Player killed player
                    killer = kPlayer
                    if deathInfo and deathInfo[2] then
                        deathReason = ("**%s** was killed by **%s** (%s: %s)"):format(
                            GetPlayerName(PlayerId()), GetPlayerName(killer), deathInfo[1], deathInfo[2]
                        )
                    elseif deathInfo then
                        deathReason = ("**%s** was killed by **%s** (%s)"):format(
                            GetPlayerName(PlayerId()), GetPlayerName(killer), deathInfo[1]
                        )
                    else
                        deathReason = ("**%s** was killed by **%s**"):format(
                            GetPlayerName(PlayerId()), GetPlayerName(killer)
                        )
                    end
                end

                TriggerServerEvent('DjonStNix-Logs:server:playerDied', {
                    reason   = deathReason,
                    killerId = GetPlayerServerId(killer)
                })
            end
        else
            Wait(500)
            hasRun = false
        end
    end
end)

-- ==============================================================================
-- SCREENSHOT SUPPORT (Client-side handler)
-- ==============================================================================
RegisterNetEvent('DjonStNix-Logs:client:takeScreenshot')
AddEventHandler('DjonStNix-Logs:client:takeScreenshot', function(webhookUrl)
    if GetResourceState('screenshot-basic') ~= 'started' then return end

    exports['screenshot-basic']:requestScreenshotUpload(webhookUrl, 'files[]', function(data)
        local resp = json.decode(data)
        if resp and resp.attachments and resp.attachments[1] then
            TriggerServerEvent('DjonStNix-Logs:server:screenshotReady', resp.attachments[1].url)
        end
    end)
end)
