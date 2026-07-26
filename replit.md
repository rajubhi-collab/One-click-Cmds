# Rajbhai Pterodactyl Control Panel

A collection of bash scripts for installing and managing a [Pterodactyl](https://pterodactyl.io/) game server panel on a Linux VPS (Ubuntu/Debian), along with Blueprint extensions.

## Project Structure

| File / Folder | Purpose |
|---|---|
| `MainMenu` | **Main entry point.** A terminal control hub with menus for Pterodactyl, Proxmox, KVM, themes, blueprints, and tools. |
| `run.sh` | Standalone Pterodactyl panel manager (install, create user, update, domain/SSL, uninstall). |
| `install.sh` | Pterodactyl panel auto-installer with animated UI. |
| `addon-installer.sh` | Interactive installer for `.blueprint` files found in the current directory. |
| `blueprint-installer.sh` | Blueprint Control Hub — browse and install Blueprint extensions. |
| `ssh.sh` | SSH configuration helper. |
| `motd.sh` | Message-of-the-day setup script. |
| `extensions/` | 14 pre-packaged `.blueprint` extension files (themes, Minecraft tools, subdomains, etc.). |
| `attached_assets/` | Uploaded reference files and archives. |
| `003`, `004`, `amd`, `rajbhai` | Additional installer scripts pulled remotely by MainMenu. |

## How to Run

These scripts are **designed to run on a Linux VPS as root**, not inside Replit. To use them on a server:

```bash
# Main control panel (recommended entry point)
bash MainMenu

# Or run individual scripts directly
bash run.sh          # Pterodactyl panel manager
bash install.sh      # Panel installer
bash blueprint-installer.sh  # Blueprint manager
```

> ⚠️ All scripts require `root` access and Ubuntu/Debian. They install system packages (Nginx, PHP 8.3, MariaDB, etc.).

## Blueprint Extensions (in `extensions/`)

- `euphoriatheme.blueprint` — Euphoria UI theme
- `refreshtheme.blueprint` — Refresh UI theme
- `nebula.blueprint` — Nebula theme
- `mclogs.blueprint` — Minecraft logs viewer
- `mcplugins.blueprint` — Minecraft plugin manager
- `mctools.blueprint` — Minecraft tools
- `minecraftplayermanager.blueprint` / `sagaminecraftplayermanager.blueprint` — Player management
- `vanillatweaks.blueprint` — Vanilla Tweaks integration
- `versionchanger.blueprint` — Server version changer
- `subdomains.blueprint` — Subdomain manager
- `huxregister.blueprint` — User registration
- `simplefavicons.blueprint` — Custom favicons
- `pstatistics.blueprint` — Panel statistics

## User Preferences

<!-- Add any preferences or conventions here -->
