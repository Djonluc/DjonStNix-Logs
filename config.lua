Config = {}

-- ==============================================================================
-- 👑 DJONSTNIX-LOGS — MASTER CONFIGURATION
-- ==============================================================================
-- Comprehensive logging, analytics & anti-abuse system for ox_inventory.
-- Supports QBCore & ESX via DjonStNix-Bridge.
-- ==============================================================================

Config.ServerName = "Your Server Name"
Config.EnableDebug = false

-- ==============================================================================
-- 📡 WEBHOOK URLS
-- ==============================================================================
-- Leave "" to disable that log category entirely.
-- You can use the same webhook for multiple categories if desired.
Config.Webhooks = {
    -- ── General Events ──────────────────────────────────────────────────
    join        = "",    -- Player connections
    leave       = "",    -- Player disconnections
    chat        = "",    -- Chat messages
    death       = "",    -- Deaths/kills (with weapon detail)
    shooting    = "",    -- Weapon firing logs
    damage      = "",    -- Player damage received
    explosion   = "",    -- Explosion events
    nameChange  = "",    -- Steam name changes
    resource    = "",    -- Resource start/stop
    screenshot  = "",    -- Screenshot captures
    txAdmin     = "",    -- txAdmin actions (kick, ban, warn, heal, etc.)

    -- ── Inventory & Economy (ox_inventory) ──────────────────────────────
    items       = "",    -- Item give/take/drop/pickup
    money       = "",    -- Cash transfers & large-value alerts
    weapons     = "",    -- Weapon tracking with serial numbers
    stashes     = "",    -- Stash/trunk/glovebox/evidence activity
    police      = "",    -- Police searches & confiscations
    admin       = "",    -- Admin command usage
    suspicious  = "",    -- Suspicious activity alerts (distance, exploits)
    analytics   = "",    -- Periodic analytics reports

    -- ── Special ─────────────────────────────────────────────────────────
    all         = "",    -- Mirror ALL logs to one master channel
}

-- ==============================================================================
-- 🎨 EMBED COLORS (Decimal format)
-- ==============================================================================
-- Use https://www.birdflop.com/resources/rgb/ to pick colors
Config.Colors = {
    join        = 3066993,   -- Green
    leave       = 15158332,  -- Red
    chat        = 3447003,   -- Blurple
    death       = 1,         -- Black
    shooting    = 3066993,   -- Blue
    damage      = 16711680,  -- Red
    explosion   = 16753920,  -- Orange
    nameChange  = 3145727,   -- Teal
    resource    = 15844367,  -- Yellow
    screenshot  = 10070709,  -- Grey
    txAdmin     = 16777215,  -- White

    items       = 5793266,   -- Cyan
    money       = 15844367,  -- Gold
    weapons     = 10038562,  -- Dark Grey
    stashes     = 3447003,   -- Blurple
    police      = 255,       -- Pure Blue
    admin       = 16776960,  -- Yellow
    suspicious  = 16711680,  -- Bright Red
    analytics   = 10181046,  -- Purple
}

-- ==============================================================================
-- 📋 PLAYER DETAIL SETTINGS (Shown in embed fields)
-- ==============================================================================
-- Toggle what player info is displayed in log embeds.
Config.PlayerDetails = {
    showServerId    = true,
    showPostal      = true,
    showHealth      = true,
    showArmor       = true,
    showPing        = true,
    showDiscord     = { enabled = true,  spoiler = true },
    showSteam       = { enabled = true,  spoiler = true },
    showSteamUrl    = true,
    showIp          = true,   -- Sensitive data, OFF by default
    showLicense     = { enabled = true,  spoiler = true },
}

-- ==============================================================================
-- 🔀 FEATURE TOGGLES
-- ==============================================================================
Config.WeaponLog            = true       -- Log weapon firing
Config.DamageLog            = true       -- Log player damage
Config.DeathLog             = true       -- Log player deaths
Config.LogAdminCommands     = true       -- Log admin command usage
Config.LogConnectDisconnect = true       -- Log connect/disconnect + inventory snapshot

-- ==============================================================================
-- 💰 ECONOMY / INVENTORY SETTINGS
-- ==============================================================================
Config.MoneyThreshold       = 50000      -- Amount that triggers a high-alert ping
Config.SuspiciousDistance   = 100.0      -- Max distance (units) for valid player transfer
Config.AnalyticsInterval    = 120        -- Minutes between automated analytics reports

-- Items to SKIP logging (too common / spammy)
Config.IgnoredItems = {
    "water",
    "bread",
    "bandage",
}

-- Items classified as ILLEGAL for analytics tracking
Config.IllegalItems = {
    "weed_brick",
    "weed_bag",
    "coke_brick",
    "coke_bag",
    "crack_baggy",
    "meth",
    "meth_bag",
    "oxy",
    "xtcbaggy",
    "joint",
    "rolling_paper",
}

-- Weapons to NOT log when fired (too common / intended)
Config.WeaponsNotLogged = {
    "WEAPON_SNOWBALL",
    "WEAPON_FIREEXTINGUISHER",
    "WEAPON_PETROLCAN",
}

-- Explosion types to NOT log
Config.ExplosionsNotLogged = {}

-- ==============================================================================
-- 🔔 ALERT SETTINGS
-- ==============================================================================
-- Discord Role IDs to ping on critical alerts (suspicious activity, large money)
-- Example: { "123456789012345678", "987654321098765432" }
Config.AlertRoles = {}

-- ==============================================================================
-- 📸 SCREENSHOT SETTINGS
-- ==============================================================================
-- Requires 'screenshot-basic' resource to be running.
-- Set to false to disable the /screenshot command entirely.
Config.ScreenshotEnabled = true
