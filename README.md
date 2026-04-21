<div align="center">
  <img src="djonstnix_logs_banner_1776727512535.png" alt="DjonStNix Logs Banner" width="100%">

  # 👑 DjonStNix-Logs
  ### The Gold Standard in FiveM Server Analytics & Asset Tracking

  [![Framework](https://img.shields.io/badge/Framework-Framework--Agnostic-blue?style=for-the-badge&logo=fivem)](https://github.com/Djonluc/DjonStNix-Bridge)
  [![Inventory](https://img.shields.io/badge/Inventory-ox__inventory-green?style=for-the-badge&logo=github)](https://github.com/overextended/ox_inventory)
  [![Version](https://img.shields.io/badge/Version-1.1.0-orange?style=for-the-badge)](https://github.com/Djonluc)
  [![License](https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge)](https://opensource.org/licenses/MIT)

  ---
  
  **DjonStNix-Logs** is a high-performance, event-driven logging and analytics powerhouse designed exclusively for the modern FiveM ecosystem. Moving far beyond "text in a channel," this system acts as your server's black box—recording, analyzing, and alerting on every critical transaction with surgical precision.
</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Bot & Ecosystem Integration](#-bot--ecosystem-integration)
- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Webhook Setup](#-webhook-setup)
- [Export API](#-export-api)
- [Log Categories](#-log-categories)
- [Analytics Reports](#-analytics-reports)
- [Commands](#-commands)
- [Performance](#-performance)
- [FAQ](#-faq)

---

## 🌟 Overview

**DjonStNix-Logs** is not just another logging script. It is a comprehensive server management and analytics tool designed for the DjonStNix ecosystem. It combines deep ox_inventory integration with general game event logging, automated analytics, and proactive anti-abuse detection.

### What makes it different?

| Feature              | Other Loggers | DjonStNix-Logs                                         |
| -------------------- | ------------- | ------------------------------------------------------ |
| Item logging         | Basic         | ✅ Differentiates give/take/drop/pickup/stash/retrieve |
| Weapon tracking      | ❌            | ✅ With serial numbers                                 |
| Money alerts         | ❌            | ✅ High-value threshold alerts with role pings         |
| Suspicious activity  | ❌            | ✅ Distance-based transfer detection                   |
| Analytics reports    | ❌            | ✅ Automated periodic economy reports                  |
| Death detail         | Basic         | ✅ Weapon, killer type, cause of death                 |
| Framework support    | Single        | ✅ QBCore + ESX via Bridge                             |
| Combat log detection | ❌            | ✅ Inventory snapshot on disconnect                    |
| Police oversight     | ❌            | ✅ Evidence locker monitoring                          |

---

## 🤖 Bot & Ecosystem Integration

DjonStNix-Logs is designed to work in perfect harmony with the **[DjonStNix-DiscordBot](https://github.com/Djonluc/DjonStNix-DiscordBot)** and the wider ecosystem.

### 🔔 Staff Alert Pings (Role Sync)
While the Logger uses Webhooks for performance, it is designed to ping the **Staff Roles** defined in your Discord Bot.
*   **How to setup:** Copy the **Role IDs** for your `Owner`, `Developer`, and `Staff` roles from Discord and paste them into `Config.AlertRoles`.
*   **Result:** When a critical alert (like a suspicious transfer) is logged, the Logger will **ping** those roles, alerting your staff team immediately.

### 🆔 Unified Player Identity
Both the Bot (for Queue Priority) and the Logger (for tracking) use the **DjonStNix-Bridge**.
*   This ensures that a player's **Discord ID** is consistent across your entire server.
*   The Logger automatically **tags** players (`<@ID>`) in logs, allowing you to instantly click their profile to take administrative action through your bot.

### 🛡️ Shared Security Layer
*   **Staff Verification:** The logger verifies admin permissions using the same logic your bot uses for whitelisting and priority.
*   **Forensic Evidence:** Inventory snapshots on disconnect provide the "missing link" for your staff to enforce rules when players attempt to combat-log.

### 🚀 Automated Infrastructure Sync
DjonStNix-Logs now features **Zero-Config Infrastructure Setup** powered by the bot.
*   **How it works:** On startup, the bot automatically creates the `🔴 DJONSTNIX LOGS` category, all required channels, and generates secure Webhooks.
*   **Zero-Config:** The Logger automatically reads these webhooks from `webhooks.json` — **no manual setup required!**

---

## ✨ Features

### 📦 Inventory Management (ox_inventory)

- **Items**: Every give, take, drop, pickup, stash, and retrieve is logged
- **Money**: All cash transfers tracked with high-alert notifications for large values
- **Weapons**: Every weapon transfer logged with serial number
- **Storage**: Vehicle trunks, gloveboxes, stashes, and evidence lockers monitored

### 🕵️ Player & Staff Oversight

- **Connect/Disconnect**: Full inventory snapshot on disconnect (combat-log evidence)
- **Police Activity**: Automatic logging of evidence locker access and confiscations
- **Admin Commands**: Command usage logged for accountability
- **Name Changes**: Steam name change detection with history

### 💀 Game Event Logging

- **Deaths**: Detailed death logs with weapon, killer, and cause
- **Shooting**: Weapon firing detection with shot count
- **Damage**: Damage received with source identification
- **Explosions**: Typed explosion logging (grenade, RPG, vehicle, etc.)
- **Chat**: All chat messages logged (commands excluded)
- **Resources**: Resource start/stop monitoring
- **txAdmin**: Kick, ban, warn, heal, restart, shutdown, announcements

### 📊 Automated Analytics Reports

- **Top Purchased Items**: Most popular shop items
- **Top Crafted Items**: Most crafted recipes
- **Police Activity**: Most active officers
- **Illegal Activity**: Most traded illegal items and active players

### ⚡ Anti-Abuse Detection

- **Distance Check**: Flags item transfers over impossible distances
- **High-Value Alerts**: Role pings for large money transactions
- **Combat Log Evidence**: Full inventory saved on disconnect

### 📸 Screenshot System

- `/screenshot <id>` — Capture any player's screen

---

## 📋 Requirements

| Dependency                                                        | Required | Notes                              |
| ----------------------------------------------------------------- | -------- | ---------------------------------- |
| [DjonStNix-Bridge](https://github.com/Djonluc/DjonStNix-Bridge)   | ✅       | Framework detection & unified APIs |
| [ox_inventory](https://github.com/overextended/ox_inventory)      | ✅       | Inventory system                   |
| [ox_lib](https://github.com/overextended/ox_lib)                  | ✅       | Utility library                    |
| [screenshot-basic](https://github.com/citizenfx/screenshot-basic) | Optional | For `/screenshot` command          |

### Supported Frameworks

- ✅ **QBCore**
- ✅ **QBox**
- ✅ **ESX**

---

## 📥 Installation

### Step 1: Download

Place the `DjonStNix-Logs` folder in your server's resources directory.

### Step 2: Configure

Open `config.lua` and add your Discord webhook URLs (see [Webhook Setup](#-webhook-setup)).

### Step 3: Add to server.cfg

```cfg
# Make sure dependencies start BEFORE DjonStNix-Logs
ensure DjonStNix-Bridge
ensure ox_lib
ensure ox_inventory

# Start DjonStNix-Logs
ensure DjonStNix-Logs
```

### Step 4: Restart

Restart your server. You should see the DjonStNix startup banner in the console.

---

## ⚙️ Configuration

All settings are in `config.lua`. Here's what you can customize:

### Server Identity

```lua
Config.ServerName = "Your Server Name"  -- Shown in all embed footers
Config.EnableDebug = false              -- Set to true for console debug output
```

### Feature Toggles

```lua
Config.WeaponLog            = true    -- Log weapon firing
Config.DamageLog            = true    -- Log damage taken
Config.DeathLog             = true    -- Log deaths
Config.LogAdminCommands     = true    -- Log admin command usage
Config.LogConnectDisconnect = true    -- Log join/leave + inventory snapshots
Config.ScreenshotEnabled   = true    -- Enable /screenshot command
```

### Economy Settings

```lua
Config.MoneyThreshold     = 50000    -- $ amount that triggers high-alert ping
Config.SuspiciousDistance  = 100.0   -- Max units for valid player transfer
Config.AnalyticsInterval  = 120     -- Minutes between analytics reports
```

### Ignored Items

Items that won't generate log entries (too common/spammy):

```lua
Config.IgnoredItems = {
    "water", "bread", "bandage",
}
```

### Illegal Items

Items tracked for the Illegal Activity analytics report:

```lua
Config.IllegalItems = {
    "weed_brick", "coke_brick", "meth",
}
```

### Alert Roles

Discord Role IDs to ping on critical alerts:

```lua
Config.AlertRoles = {
    "123456789012345678",  -- @Admin role
}
```

### Player Detail Settings

Control what info shows in embed fields:

```lua
Config.PlayerDetails = {
    showServerId = true,
    showPostal   = true,
    showHealth   = true,
    showArmor    = true,
    showPing     = true,
    showDiscord  = { enabled = true, spoiler = true },
    showSteam    = { enabled = true, spoiler = true },
    showSteamUrl = true,
    showIp       = false,  -- OFF by default (sensitive)
    showLicense  = { enabled = true, spoiler = true },
}
```

---

## 🔗 Webhook Setup

### Creating Discord Webhooks

1. Open your Discord server settings
2. Go to **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Name it (e.g., "Server Logs - Items")
5. Select the target channel
6. Copy the webhook URL
7. Paste it into the corresponding field in `config.lua`

### Webhook Categories

```lua
Config.Webhooks = {
    -- General Events
    join        = "https://discord.com/api/webhooks/...",
    leave       = "https://discord.com/api/webhooks/...",
    chat        = "https://discord.com/api/webhooks/...",
    death       = "https://discord.com/api/webhooks/...",
    shooting    = "https://discord.com/api/webhooks/...",
    damage      = "https://discord.com/api/webhooks/...",
    explosion   = "https://discord.com/api/webhooks/...",
    nameChange  = "https://discord.com/api/webhooks/...",
    resource    = "https://discord.com/api/webhooks/...",
    screenshot  = "https://discord.com/api/webhooks/...",
    txAdmin     = "https://discord.com/api/webhooks/...",

    -- Inventory & Economy
    items       = "https://discord.com/api/webhooks/...",
    money       = "https://discord.com/api/webhooks/...",
    weapons     = "https://discord.com/api/webhooks/...",
    stashes     = "https://discord.com/api/webhooks/...",
    police      = "https://discord.com/api/webhooks/...",
    admin       = "https://discord.com/api/webhooks/...",
    suspicious  = "https://discord.com/api/webhooks/...",
    analytics   = "https://discord.com/api/webhooks/...",

    -- Master Channel (mirrors ALL logs)
    all         = "https://discord.com/api/webhooks/...",
}
```

> **Tip:** Leave a webhook as `""` to disable that category entirely. You can also use the same webhook URL for multiple categories.

---

## 📡 Export API

DjonStNix-Logs provides a universal export API for other resources to send logs.

### `createLog` (Recommended)

```lua
exports['DjonStNix-Logs']:createLog({
    EmbedMessage = "Player bought a house for $500,000",
    player_id    = source,           -- Optional: first player
    player_2_id  = targetSource,     -- Optional: second player
    channel      = "items",          -- Webhook key or direct URL
    title        = "House Purchase", -- Optional: custom title
    color        = "#00FF00",        -- Optional: hex or decimal color
    icon         = "🏠",             -- Optional: emoji icon
    fields       = {                 -- Optional: extra embed fields
        { name = "Price", value = "$500,000", inline = true },
        { name = "Location", value = "Vinewood Hills", inline = true },
    },
    screenshot   = false,            -- Optional: capture screenshot
    priority     = false,            -- Optional: skip queue (alerts)
})
```

### `SendLog` (Simple)

```lua
exports['DjonStNix-Logs']:SendLog(
    "items",                         -- Category
    "Item Bought",                   -- Title
    "Player bought a sandwich",      -- Message
    { source = source }              -- Options
)
```

### `discord` (Legacy JD_logsV3 Compatible)

```lua
exports['DjonStNix-Logs']:discord(
    "Player did something",          -- Message
    source,                          -- Player 1 (0 for none)
    targetId,                        -- Player 2 (0 for none)
    "#FF0000",                       -- Color
    "items"                          -- Channel
)
```

---

## 📂 Log Categories

| Key          | Icon | Description                                |
| ------------ | ---- | ------------------------------------------ |
| `join`       | 📥   | Player connections                         |
| `leave`      | 📤   | Player disconnections + inventory snapshot |
| `chat`       | 💬   | Chat messages                              |
| `death`      | 💀   | Deaths with weapon/cause detail            |
| `shooting`   | 🔫   | Weapon firing with shot count              |
| `damage`     | 🩸   | Damage received                            |
| `explosion`  | 💥   | Explosions with type                       |
| `nameChange` | 💠   | Steam name changes                         |
| `resource`   | ⚙️   | Resource start/stop                        |
| `screenshot` | 📸   | Screenshot captures                        |
| `txAdmin`    | 💻   | txAdmin actions                            |
| `items`      | 📦   | Item transfers                             |
| `money`      | 💰   | Money transactions                         |
| `weapons`    | 🔫   | Weapon transfers with serial               |
| `stashes`    | 🗄️   | Storage interactions                       |
| `police`     | 🔒   | Police evidence access                     |
| `admin`      | ⚡   | Admin command usage                        |
| `suspicious` | ⚠️   | Suspicious activity alerts                 |
| `analytics`  | 📊   | Periodic analytics reports                 |
| `all`        | 📺   | Mirror of ALL logs                         |

---

## 📊 Analytics Reports

Automated reports are sent every `Config.AnalyticsInterval` minutes to the `analytics` webhook:

### 📊 Top Purchased Items

Shows the 5 most popular items bought from shops.

### 🔨 Top Crafted Items

Shows the 5 most crafted items.

### 👮 Police Activity Report

Top 5 most active officers ranked by searches + confiscations.

### 🚨 Illegal Activity Report

Top 5 most traded illegal items + top 5 most active players in illegal trades.

---

## 🎮 Commands

| Command            | Permission | Description                                   |
| ------------------ | ---------- | --------------------------------------------- |
| `/screenshot <id>` | Admin      | Capture a player's screen and send to Discord |

---

## ⚡ Performance

DjonStNix-Logs is designed for maximum performance:

- **Webhook Queue**: All non-critical logs go through a FIFO queue processed every 1.5 seconds, preventing Discord rate limits
- **Priority Lane**: Critical alerts (suspicious activity, bans) skip the queue for immediate delivery
- **Rate Limit Recovery**: Automatic re-queue on Discord 429 responses
- **Client Loops**: All client detection loops use proper `Wait()` intervals (minimum 500ms when idle)
- **Memory-Based Analytics**: No database overhead — aggregation uses in-memory tables that reset each cycle

---

## ❓ FAQ

### Can I use DjonStNix-Logs alongside qb-central-logs?

Yes. They are independent resources. `qb-central-logs` handles general QBCore events, while `DjonStNix-Logs` focuses on ox_inventory, analytics, and advanced features. You may experience duplicate logs for join/leave/chat if both are running — disable those webhooks in one of them.

### Does it work with ESX?

Yes. DjonStNix-Logs uses `DjonStNix-Bridge` for framework detection. All player/money/admin APIs are framework-agnostic.

### What ox_inventory version is required?

ox_inventory v2.20+ is recommended for full `registerHook` support (swapItems, buyItem, craftItem). Older versions will fall back to event listeners.

### How do I add my own custom logs from other resources?

Use the `createLog` export. See the [Export API](#-export-api) section.

### Can other resources that used JD_logsV3 switch to DjonStNix-Logs?

Yes. Change `exports.JD_logsV3:createLog(...)` to `exports['DjonStNix-Logs']:createLog(...)` — the API is fully compatible.

---

## 📜 License

MIT License (c) 2026 DjonStNix (DjonLuc)

---

## 👑 DjonStNix Ecosystem

| Resource                                                        | Description                       |
| --------------------------------------------------------------- | --------------------------------- |
| [DjonStNix-Bridge](https://github.com/Djonluc/DjonStNix-Bridge) | Central framework bridge          |
| **DjonStNix-Logs**                                              | Comprehensive logging & analytics |
| [DjonStNix-Banking](https://github.com/Djonluc)                 | Banking system                    |
| [DjonStNix-Shops](https://github.com/Djonluc)                   | Shop management                   |
| [DjonStNix-Government](https://github.com/Djonluc)              | Government & licensing            |

---

<p align="center">
  <b>Stop guessing — start knowing.</b><br>
  Made with ❤️ by DjonStNix
</p>
