#!/bin/bash

# ==========================================
#  RAJBHAI — PTERODACTYL THEME MANAGER
#  Nebula • Euphoria • Add Tool • Uninstall
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
line() { echo -e "${MAGENTA}╠══════════════════════════════════════════════════╣${RESET}"; }

header() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAGENTA}║${RESET}  ${BOLD}${CYAN}🎨 PTERODACTYL THEME MANAGER${RESET}                  ${MAGENTA}║${RESET}"
    echo -e "${MAGENTA}║${RESET}  ${GRAY}Made By - RAJBHAI${RESET}                              ${MAGENTA}║${RESET}"
    line
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
# UNINSTALL SUB-MENU
# ==========================================
uninstall_menu() {
    while true; do
        header
        echo -e "  ${RED}╔════════════════════════════════════════╗${RESET}"
        echo -e "  ${RED}║${RESET}       ${BOLD}${WHITE}🗑  UNINSTALL THEMES${RESET}              ${RED}║${RESET}"
        echo -e "  ${RED}╠════════════════════════════════════════╣${RESET}"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[1]${RESET} Remove Nebula"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[2]${RESET} Remove Euphoria"
        echo -e "  ${RED}║${RESET}  ${YELLOW}[3]${RESET} Remove Add Tool Package"
        echo -e "  ${RED}║${RESET}  ${WHITE}[0]${RESET} Back"
        echo -e "  ${RED}╚════════════════════════════════════════╝${RESET}"
        echo ""
        read -p "  Choose → " uopt

        case "$uopt" in
            1)
                info "Removing Nebula theme..."
                cd /var/www/pterodactyl || { fail "Panel path not found!"; sleep 2; continue; }
                blueprint -r nebula && ok "Nebula removed!" || fail "Failed to remove Nebula"
                pause
                ;;
            2)
                info "Removing Euphoria theme..."
                cd /var/www/pterodactyl || { fail "Panel path not found!"; sleep 2; continue; }
                blueprint -r euphoriatheme && ok "Euphoria removed!" || fail "Failed to remove Euphoria"
                pause
                ;;
            3)
                info "Removing Add Tool package..."
                cd /var/www/pterodactyl || { fail "Panel path not found!"; sleep 2; continue; }
                blueprint -r versionchanger
                blueprint -r mcplugins
                blueprint -r sagaminecraftplayermanager
                ok "Add Tool package removed!"
                pause
                ;;
            0) break ;;
            *) warn "Invalid option"; sleep 1 ;;
        esac
    done
}

# ==========================================
# INSTALL ACTIONS
# ==========================================
install_nebula() {
    header
    echo -e "${GREEN}  ╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}  ║${RESET}  ${BOLD}🚀 Installing Nebula Theme...${RESET}             ${GREEN}║${RESET}"
    echo -e "${GREEN}  ╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    cd /var/www/pterodactyl || { fail "Panel path not found!"; pause; return; }
    info "Downloading Nebula blueprint..."
    wget -q https://github.com/ItsKek/nebulatheme/releases/latest/download/nebula.blueprint -O nebula.blueprint \
        || wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/nebula.blueprint
    if [ ! -f nebula.blueprint ]; then fail "Download failed!"; pause; return; fi
    info "Installing with Blueprint..."
    yes "" | blueprint -i nebula
    rm -f nebula.blueprint
    ok "Nebula installed successfully!"
    pause
}

install_euphoria() {
    header
    echo -e "${CYAN}  ╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}  ║${RESET}  ${BOLD}🌈 Installing Euphoria Theme...${RESET}           ${CYAN}║${RESET}"
    echo -e "${CYAN}  ╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    cd /var/www/pterodactyl || { fail "Panel path not found!"; pause; return; }
    info "Downloading Euphoria blueprint..."
    wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/euphoriatheme.blueprint
    if [ ! -f euphoriatheme.blueprint ]; then fail "Download failed!"; pause; return; fi
    info "Installing with Blueprint..."
    blueprint -i euphoriatheme
    rm -f euphoriatheme.blueprint
    ok "Euphoria installed successfully!"
    pause
}

install_addtool() {
    header
    echo -e "${YELLOW}  ╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}  ║${RESET}  ${BOLD}🛠  Installing Add Tool Package...${RESET}        ${YELLOW}║${RESET}"
    echo -e "${YELLOW}  ╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    cd /var/www/pterodactyl || { fail "Panel path not found!"; pause; return; }

    info "Downloading blueprint extensions..."
    wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/versionchanger.blueprint
    wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/mcplugins.blueprint
    wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/sagaminecraftplayermanager.blueprint
    wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/huxregister.blueprint

    info "Installing extensions via Blueprint..."
    blueprint -i versionchanger   && ok "versionchanger installed"   || warn "versionchanger failed"
    blueprint -i mcplugins        && ok "mcplugins installed"        || warn "mcplugins failed"
    blueprint -i sagaminecraftplayermanager && ok "MC Player Manager installed" || warn "MC Player Manager failed"
    blueprint -i huxregister      && ok "huxregister installed"      || warn "huxregister failed"

    rm -f versionchanger.blueprint mcplugins.blueprint sagaminecraftplayermanager.blueprint huxregister.blueprint
    ok "Add Tool package complete!"
    pause
}

# ==========================================
# MAIN MENU LOOP
# ==========================================
while true; do
    header
    echo -e "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "  ${CYAN}║${RESET}          ${BOLD}${WHITE}SELECT A THEME ACTION${RESET}              ${CYAN}║${RESET}"
    echo -e "  ${CYAN}╠══════════════════════════════════════════════╣${RESET}"
    echo -e "  ${CYAN}║${RESET}  ${GREEN}[1]${RESET} 🚀 Nebula         ${GRAY}:: Auto Install${RESET}"
    echo -e "  ${CYAN}║${RESET}  ${GREEN}[2]${RESET} 🌈 Euphoria       ${GRAY}:: Auto Install${RESET}"
    echo -e "  ${CYAN}║${RESET}  ${YELLOW}[3]${RESET} 🛠  Add Tool       ${GRAY}:: Extension Pack${RESET}"
    echo -e "  ${CYAN}║${RESET}  ${RED}[4]${RESET} 🗑  Uninstall      ${GRAY}:: Remove Themes${RESET}"
    echo -e "  ${CYAN}║${RESET}"
    echo -e "  ${CYAN}║${RESET}  ${WHITE}[0]${RESET} Exit"
    echo -e "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    read -p "  Choose → " opt

    case "$opt" in
        1) install_nebula ;;
        2) install_euphoria ;;
        3) install_addtool ;;
        4) uninstall_menu ;;
        0) echo -e "\n${CYAN}  Goodbye! 🚀${RESET}"; exit 0 ;;
        *) warn "Invalid option, try again."; sleep 1 ;;
    esac
done
