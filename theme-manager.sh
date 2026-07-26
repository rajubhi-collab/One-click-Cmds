#!/bin/bash

# ==========================================
#  RAJBHAI — PTERODACTYL THEME MANAGER
#  Themes • Extensions • Uninstall
# ==========================================

# --- Colors ---
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
CYAN="\e[1;36m"
MAGENTA="\e[1;35m"
BLUE="\e[1;34m"
WHITE="\e[1;37m"
GRAY="\e[1;90m"
RESET="\e[0m"
BOLD="\e[1m"

# --- Base URL for blueprint files ---
BASE="https://raw.githubusercontent.com/rajbhai-collab/One-click-Cmds/refs/heads/main/extensions"

# --- Argument ---
START_MODE="${1:-}"   # --themes | --extensions | (empty = main menu)

# --- Root Check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}  ✖ Please run as root!${RESET}"
    exit 1
fi

# --- Panel Check ---
if [ ! -d "/var/www/pterodactyl" ]; then
    echo -e "${RED}  ✖ Pterodactyl panel not found at /var/www/pterodactyl${RESET}"
    echo -e "${YELLOW}  Install the panel first before managing themes.${RESET}"
    exit 1
fi

# --- UI Helpers ---
header() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAGENTA}║${RESET}  ${BOLD}${CYAN}🎨 PTERODACTYL THEME MANAGER${RESET}                  ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}  ${GRAY}Made By - RAJBHAI${RESET}                              ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}╠══════════════════════════════════════════════════╣${RESET}"
    echo -e "${MAGENTA}║${RESET}  ${BLUE}User:${RESET} $(whoami)   ${BLUE}Host:${RESET} $(hostname)   ${BLUE}Time:${RESET} $(date +'%H:%M')  ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════╝${RESET}"
    echo ""
}

pause() {
    echo ""
    echo -e "${GRAY}─────────────────────────────────────────────────────${RESET}"
    read -rp " ↩  Press Enter to return to menu..."
}

ok()   { echo -e "  ${GREEN}✔ $1${RESET}"; }
fail() { echo -e "  ${RED}✖ $1${RESET}"; }
info() { echo -e "  ${CYAN}➜ $1${RESET}"; }
warn() { echo -e "  ${YELLOW}⚠ $1${RESET}"; }

# ==========================================
# GENERIC INSTALL HELPER
# Usage: bp_install "Display Name" "blueprint_id"
# ==========================================
bp_install() {
    local name="$1" id="$2"
    cd /var/www/pterodactyl || { fail "Panel path not found!"; pause; return; }
    info "Downloading ${name}..."
    wget -q "${BASE}/${id}.blueprint" -O "${id}.blueprint"
    if [ ! -f "${id}.blueprint" ]; then
        fail "Download failed for ${name}!"
        pause; return
    fi
    info "Installing ${name} via Blueprint..."
    yes "" | blueprint -i "${id}"
    rm -f "${id}.blueprint"
    ok "${name} installed successfully!"
    pause
}

# ==========================================
# THEMES
# ==========================================
install_nebula() {
    header
    echo -e "${GREEN}  ╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}  ║${RESET}  ${BOLD}🚀 Installing Nebula Theme${RESET}                ${GREEN}║${RESET}"
    echo -e "${GREEN}  ╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    bp_install "Nebula" "nebula"
}

install_euphoria() {
    header
    echo -e "${CYAN}  ╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}  ║${RESET}  ${BOLD}🌈 Installing Euphoria Theme${RESET}              ${CYAN}║${RESET}"
    echo -e "${CYAN}  ╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    bp_install "Euphoria" "euphoriatheme"
}

install_refreshtheme() {
    header
    echo -e "${BLUE}  ╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}  ║${RESET}  ${BOLD}🔄 Installing Refresh Theme${RESET}               ${BLUE}║${RESET}"
    echo -e "${BLUE}  ╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    bp_install "Refresh Theme" "refreshtheme"
}

# ==========================================
# EXTENSIONS SUBMENU
# ==========================================

install_ext() {
    local label="$1" id="$2"
    header
    echo -e "${YELLOW}  ╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}  ║${RESET}  ${BOLD}🧩 Installing: ${label}${RESET}"
    echo -e "${YELLOW}  ╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    bp_install "${label}" "${id}"
}

install_all_extensions() {
    header
    echo -e "${MAGENTA}  ╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${MAGENTA}  ║${RESET}  ${BOLD}📦 Installing ALL Extensions...${RESET}           ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}  ╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    cd /var/www/pterodactyl || { fail "Panel path not found!"; pause; return; }

    declare -A EXTS=(
        ["MC Logs"]="mclogs"
        ["MC Plugins"]="mcplugins"
        ["MC Tools"]="mctools"
        ["MC Player Manager"]="minecraftplayermanager"
        ["Saga MC Player Manager"]="sagaminecraftplayermanager"
        ["Version Changer"]="versionchanger"
        ["Hux Register"]="huxregister"
        ["Simple Favicons"]="simplefavicons"
        ["Subdomains"]="subdomains"
        ["Vanilla Tweaks"]="vanillatweaks"
        ["Panel Statistics"]="pstatistics"
    )

    local ORDER=(
        "mclogs" "mcplugins" "mctools"
        "minecraftplayermanager" "sagaminecraftplayermanager"
        "versionchanger" "huxregister" "simplefavicons"
        "subdomains" "vanillatweaks" "pstatistics"
    )
    local NAMES=(
        "MC Logs" "MC Plugins" "MC Tools"
        "MC Player Manager" "Saga MC Player Manager"
        "Version Changer" "Hux Register" "Simple Favicons"
        "Subdomains" "Vanilla Tweaks" "Panel Statistics"
    )

    info "Downloading all extension blueprints..."
    for id in "${ORDER[@]}"; do
        wget -q "${BASE}/${id}.blueprint" -O "${id}.blueprint" && ok "Downloaded ${id}" || warn "Failed to download ${id}"
    done

    echo ""
    info "Installing all extensions via Blueprint..."
    for i in "${!ORDER[@]}"; do
        local id="${ORDER[$i]}" lbl="${NAMES[$i]}"
        if [ -f "${id}.blueprint" ]; then
            yes "" | blueprint -i "${id}" &>/dev/null \
                && ok "${lbl} installed" \
                || warn "${lbl} failed"
            rm -f "${id}.blueprint"
        else
            warn "Skipping ${lbl} (download failed)"
        fi
    done

    ok "All extensions processed!"
    pause
}

extensions_menu() {
    while true; do
        header
        echo -e "  ${YELLOW}╔══════════════════════════════════════════════╗${RESET}"
        echo -e "  ${YELLOW}║${RESET}          ${BOLD}${WHITE}🧩 EXTENSIONS MENU${RESET}                  ${YELLOW}║${RESET}"
        echo -e "  ${YELLOW}╠══════════════════════════════════════════════╣${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[1]${RESET}  MC Logs               ${GRAY}:: mclogs${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[2]${RESET}  MC Plugins            ${GRAY}:: mcplugins${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[3]${RESET}  MC Tools              ${GRAY}:: mctools${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[4]${RESET}  MC Player Manager     ${GRAY}:: minecraftplayermanager${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[5]${RESET}  Saga MC Player Mgr    ${GRAY}:: sagaminecraftplayermanager${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[6]${RESET}  Version Changer       ${GRAY}:: versionchanger${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[7]${RESET}  Hux Register          ${GRAY}:: huxregister${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[8]${RESET}  Simple Favicons       ${GRAY}:: simplefavicons${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[9]${RESET}  Subdomains            ${GRAY}:: subdomains${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[10]${RESET} Vanilla Tweaks        ${GRAY}:: vanillatweaks${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${GREEN}[11]${RESET} Panel Statistics      ${GRAY}:: pstatistics${RESET}"
        echo -e "  ${YELLOW}║${RESET}"
        echo -e "  ${YELLOW}║${RESET}  ${MAGENTA}[12]${RESET} 📦 Install ALL Extensions"
        echo -e "  ${YELLOW}║${RESET}  ${WHITE}[0]${RESET}  Back"
        echo -e "  ${YELLOW}╚══════════════════════════════════════════════╝${RESET}"
        echo ""
        read -p "  Choose → " eopt

        case "$eopt" in
            1)  install_ext "MC Logs"             "mclogs" ;;
            2)  install_ext "MC Plugins"          "mcplugins" ;;
            3)  install_ext "MC Tools"            "mctools" ;;
            4)  install_ext "MC Player Manager"   "minecraftplayermanager" ;;
            5)  install_ext "Saga MC Player Mgr"  "sagaminecraftplayermanager" ;;
            6)  install_ext "Version Changer"     "versionchanger" ;;
            7)  install_ext "Hux Register"        "huxregister" ;;
            8)  install_ext "Simple Favicons"     "simplefavicons" ;;
            9)  install_ext "Subdomains"          "subdomains" ;;
            10) install_ext "Vanilla Tweaks"      "vanillatweaks" ;;
            11) install_ext "Panel Statistics"    "pstatistics" ;;
            12) install_all_extensions ;;
            0)  break ;;
            *)  warn "Invalid option"; sleep 1 ;;
        esac
    done
}

# ==========================================
# UNINSTALL SUBMENU
# ==========================================
uninstall_menu() {
    while true; do
        header
        echo -e "  ${RED}╔══════════════════════════════════════════════╗${RESET}"
        echo -e "  ${RED}║${RESET}       ${BOLD}${WHITE}🗑  UNINSTALL MENU${RESET}                    ${RED}║${RESET}"
        echo -e "  ${RED}╠══════════════════════════════════════════════╣${RESET}"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[1]${RESET}  Remove Nebula"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[2]${RESET}  Remove Euphoria"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[3]${RESET}  Remove Refresh Theme"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[4]${RESET}  Remove MC Logs"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[5]${RESET}  Remove MC Plugins"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[6]${RESET}  Remove MC Tools"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[7]${RESET}  Remove MC Player Manager"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[8]${RESET}  Remove Saga MC Player Manager"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[9]${RESET}  Remove Version Changer"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[10]${RESET} Remove Hux Register"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[11]${RESET} Remove Simple Favicons"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[12]${RESET} Remove Subdomains"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[13]${RESET} Remove Vanilla Tweaks"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[14]${RESET} Remove Panel Statistics"
        echo -e "  ${RED}║${RESET}"
        echo -e "  ${RED}║${RESET}  ${RED}[15]${RESET} 🗑  Remove ALL"
        echo -e "  ${RED}║${RESET}  ${WHITE}[0]${RESET}  Back"
        echo -e "  ${RED}╚══════════════════════════════════════════════╝${RESET}"
        echo ""
        read -p "  Choose → " uopt

        bp_remove() {
            local lbl="$1" id="$2"
            cd /var/www/pterodactyl || { fail "Panel path not found!"; return; }
            info "Removing ${lbl}..."
            blueprint -r "${id}" && ok "${lbl} removed!" || fail "Failed to remove ${lbl}"
        }

        case "$uopt" in
            1)  bp_remove "Nebula"                "nebula";                     pause ;;
            2)  bp_remove "Euphoria"              "euphoriatheme";              pause ;;
            3)  bp_remove "Refresh Theme"         "refreshtheme";               pause ;;
            4)  bp_remove "MC Logs"               "mclogs";                     pause ;;
            5)  bp_remove "MC Plugins"            "mcplugins";                  pause ;;
            6)  bp_remove "MC Tools"              "mctools";                    pause ;;
            7)  bp_remove "MC Player Manager"     "minecraftplayermanager";     pause ;;
            8)  bp_remove "Saga MC Player Mgr"    "sagaminecraftplayermanager"; pause ;;
            9)  bp_remove "Version Changer"       "versionchanger";             pause ;;
            10) bp_remove "Hux Register"          "huxregister";                pause ;;
            11) bp_remove "Simple Favicons"       "simplefavicons";             pause ;;
            12) bp_remove "Subdomains"            "subdomains";                 pause ;;
            13) bp_remove "Vanilla Tweaks"        "vanillatweaks";              pause ;;
            14) bp_remove "Panel Statistics"      "pstatistics";                pause ;;
            15)
                echo -e "${RED}  ⚠  This will remove ALL themes and extensions!${RESET}"
                read -p "  Type 'yes' to confirm: " confirm
                if [[ "$confirm" == "yes" ]]; then
                    cd /var/www/pterodactyl || { fail "Panel path not found!"; pause; continue; }
                    for id in nebula euphoriatheme refreshtheme mclogs mcplugins mctools \
                               minecraftplayermanager sagaminecraftplayermanager versionchanger \
                               huxregister simplefavicons subdomains vanillatweaks pstatistics; do
                        blueprint -r "$id" &>/dev/null && ok "Removed $id" || warn "Skipped $id (not installed)"
                    done
                    ok "All removed!"
                else
                    warn "Cancelled."
                fi
                pause
                ;;
            0) break ;;
            *) warn "Invalid option"; sleep 1 ;;
        esac
    done
}

# ==========================================
# THEMES SUBMENU (called via --themes)
# ==========================================
themes_menu() {
    while true; do
        header
        echo -e "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
        echo -e "  ${CYAN}║${RESET}          ${BOLD}${WHITE}🎨 THEMES${RESET}                           ${CYAN}║${RESET}"
        echo -e "  ${CYAN}╠══════════════════════════════════════════════╣${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${GREEN}[1]${RESET} 🚀 Nebula          ${GRAY}:: Auto Install${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${GREEN}[2]${RESET} 🌈 Euphoria        ${GRAY}:: Auto Install${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${GREEN}[3]${RESET} 🔄 Refresh Theme   ${GRAY}:: Auto Install${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${RED}[4]${RESET} 🗑  Uninstall       ${GRAY}:: Remove Themes${RESET}"
        echo -e "  ${CYAN}║${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${WHITE}[0]${RESET} Back"
        echo -e "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
        echo ""
        read -p "  Choose → " opt

        case "$opt" in
            1) install_nebula ;;
            2) install_euphoria ;;
            3) install_refreshtheme ;;
            4) uninstall_menu ;;
            0) exit 0 ;;
            *) warn "Invalid option, try again."; sleep 1 ;;
        esac
    done
}

# ==========================================
# MAIN MENU
# ==========================================
main_theme_menu() {
    while true; do
        header
        echo -e "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
        echo -e "  ${CYAN}║${RESET}          ${BOLD}${WHITE}SELECT A THEME ACTION${RESET}              ${CYAN}║${RESET}"
        echo -e "  ${CYAN}╠══════════════════════════════════════════════╣${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${GREEN}[1]${RESET} 🎨 Theme           ${GRAY}:: Nebula/Euphoria/Refresh${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${YELLOW}[2]${RESET} 🧩 Extensions      ${GRAY}:: 11 Blueprint Extensions${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${RED}[3]${RESET} 🗑  Uninstall       ${GRAY}:: Remove Themes/Extensions${RESET}"
        echo -e "  ${CYAN}║${RESET}"
        echo -e "  ${CYAN}║${RESET}  ${WHITE}[0]${RESET} Exit"
        echo -e "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
        echo ""
        read -p "  Choose → " opt

        case "$opt" in
            1) themes_menu ;;
            2) extensions_menu ;;
            3) uninstall_menu ;;
            0) echo -e "\n${CYAN}  Goodbye! 🚀${RESET}"; exit 0 ;;
            *) warn "Invalid option, try again."; sleep 1 ;;
        esac
    done
}

# ==========================================
# DISPATCH
# ==========================================
case "$START_MODE" in
    --themes)     themes_menu ;;
    --extensions) extensions_menu ;;
    *)            main_theme_menu ;;
esac
