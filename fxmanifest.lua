-- ==============================================================================
-- 👑 DJONSTNIX BRANDING
-- ==============================================================================
-- DEVELOPED BY: DjonStNix (DjonLuc)
-- GITHUB: https://github.com/Djonluc
-- DISCORD: https://discord.gg/s7GPUHWrS7
-- YOUTUBE: https://www.youtube.com/@Djonluc
-- EMAIL: djonstnix@gmail.com
-- LICENSE: MIT License (c) 2026 DjonStNix (DjonLuc)
-- ==============================================================================

fx_version 'cerulean'
game 'gta5'

name 'DjonStNix-Logs'
description 'Comprehensive logging, analytics & anti-abuse system for ox_inventory (QBCore & ESX)'
author 'DjonStNix (DjonLuc)'
version '1.0.0'
repository 'https://github.com/Djonluc/DjonStNix-Logs'

dependencies {
    'DjonStNix-Bridge',
    'ox_inventory',
    'ox_lib'
}

shared_scripts {
    'config.lua',
    'shared/utils.lua',
    'shared/tables.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/queue.lua',
    'server/events.lua',
    'server/inventory.lua',
    'server/player.lua',
    'server/analytics.lua',
    'server/screenshot.lua',
    'server/exports.lua'
}

lua54 'yes'
