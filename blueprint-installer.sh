#!/bin/bash

# ==========================================
#  RAJBHAI — BLUEPRINT CONTROL HUB
# ==========================================

# --- Colors (matching MainMenu style) ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
GRAY='\033[38;5;245m'

COLORS=(
'\033[1;31m' '\033[1;32m' '\033[1;33m' '\033[1;34m'
'\033[1;35m' '\033[1;36m'
'\033[38;5;208m' '\033[38;5;205m' '\033[38;5;51m'
)
rand_color(){ echo -e "${COLORS[$RANDOM % ${#COLORS[@]}]}"; }
pause(){ echo -e "${GRAY}"; read -rp "  Press Enter to continue..." x; echo -e "${NC}"; }

# --- Trap Ctrl+C ---
trap 'echo -e "\n${RED}  [!] Force exit detected.${NC}"; exit 1' SIGINT

# --- Root Check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}  ✖ Please run as root!${NC}"
    exit 1
fi

# ==========================================
# BANNER (matches MainMenu style)
# ==========================================
banner() {
    clear
    C1=$(rand_color); C2=$(rand_color); C3=$(rand_color)
    echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${C2}██████╗  █████╗      ██╗██████╗ ██╗  ██╗ █████╗ ██╗${NC}"
    echo -e "${C2}██╔══██╗██╔══██╗     ██║██╔══██╗██║  ██║██╔══██╗██║${NC}"
    echo -e "${C2}██████╔╝███████║     ██║██████╔╝███████║███████║██║${NC}"
    echo -e "${C2}██╔══██╗██╔══██║██   ██║██╔══██╗██╔══██║██╔══██║██║${NC}"
    echo -e "${C2}██║  ██║██║  ██║╚█████╔╝██████╔╝██║  ██║██║  ██║██║${NC}"
    echo -e "${C2}╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝${NC}"
    echo
    echo -e "${C3}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "                 ${BOLD}Made By - RAJBHAI${NC}"
    echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# ==========================================
# INSTALL HELPERS
# ==========================================
ok()   { echo -e "  ${GREEN}✔ $1${NC}"; }
fail() { echo -e "  ${RED}✖ $1${NC}"; echo -e "${YELLOW}  Continuing in 3s...${NC}"; sleep 3; }
info() { echo -e "  ${CYAN}➜ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠ $1${NC}"; }

spinner() {
    local pid=$1 delay=0.1 spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    while kill -0 "$pid" 2>/dev/null; do
        local tmp=${spinstr#?}
        printf " [%c] " "$spinstr"
        spinstr=$tmp${spinstr%"$tmp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

panel_check() {
    if [ ! -d "/var/www/pterodactyl" ]; then
        echo -e "${RED}  ✖ Pterodactyl panel not found at /var/www/pterodactyl${NC}"
        echo -e "${YELLOW}  Install the panel first before managing Blueprint.${NC}"
        pause; return 1
    fi
    return 0
}

# ==========================================
# ACTION 1 — FRESH INSTALL
# ==========================================
install_blueprint() {
    banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}🚀 FRESH INSTALL BLUEPRINT${NC}                ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    panel_check || return

    info "Installing base packages..."
    apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1 &
    spinner $!; ok "Base packages ready"

    info "Setting up Node.js 20.x repository..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list

    info "Installing Node.js..."
    apt-get update > /dev/null 2>&1 && apt-get install -y nodejs > /dev/null 2>&1 &
    spinner $!; ok "Node.js installed"

    info "Installing Yarn & extras..."
    npm i -g yarn > /dev/null 2>&1 &
    spinner $!
    apt install -y zip unzip git curl wget > /dev/null 2>&1 &
    spinner $!
    cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; return; }
    yarn > /dev/null 2>&1 &
    spinner $!; ok "Yarn & dependencies ready"

    info "Fetching latest Blueprint release from GitHub..."
    PT_DIR="/var/www/pterodactyl"
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
        | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)
    if [[ -z "$DOWNLOAD_URL" ]]; then
        fail "Could not fetch download URL"; pause; return
    fi
    wget -q "$DOWNLOAD_URL" -O "$PT_DIR/release.zip" &
    spinner $!; ok "Downloaded"

    info "Extracting files..."
    unzip -o "$PT_DIR/release.zip" -d "$PT_DIR" > /dev/null 2>&1 &
    spinner $!; ok "Extracted"

    info "Generating configuration..."
    cat <<EOF > "$PT_DIR/.blueprintrc"
WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";
EOF
    chmod +x "$PT_DIR/blueprint.sh"
    chown -R www-data:www-data "$PT_DIR"
    ok "Config ready"

    info "Running Blueprint installer..."
    bash "$PT_DIR/blueprint.sh"
    echo ""
    echo -e "${GREEN}  ✔ Blueprint installation complete!${NC}"
    pause
}

# ==========================================
# ACTION 2 — FRESH REBUILD
# ==========================================
install_blueprint2() {
    banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}⚡ FRESH REBUILD (BLUEPRINT 2)${NC}             ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    panel_check || return

    PT_DIR="/var/www/pterodactyl"

    info "Installing system dependencies..."
    apt update -y -q && apt install -y curl wget unzip ca-certificates git gnupg zip -q
    ok "Dependencies installed"

    info "Setting up Node.js & Yarn..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
    apt update -y -q && apt install -y nodejs -q
    npm i -g yarn
    ok "Node.js & Yarn ready"

    info "Downloading latest Blueprint..."
    cd "$PT_DIR" || { fail "Panel directory not found!"; pause; return; }
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
        | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)
    wget -q "$DOWNLOAD_URL" -O "$PT_DIR/release.zip"
    unzip -o -q release.zip
    ok "Downloaded & extracted"

    info "Writing configuration..."
    cat <<EOF > "$PT_DIR/.blueprintrc"
WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";
EOF
    chmod +x "$PT_DIR/blueprint.sh"
    chown -R www-data:www-data "$PT_DIR"
    ok "Config ready"

    info "Running Blueprint installer..."
    bash "$PT_DIR/blueprint.sh"
    echo ""
    echo -e "${GREEN}  ✔ Blueprint rebuild complete!${NC}"
    pause
}

# ==========================================
# ACTION 3 — AUTO FIX
# ==========================================
autofix() {
    banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}🛠  AUTO FIX / REPAIR${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    panel_check || return

    cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; return; }

    info "Running blueprint -rerun-install..."
    blueprint -rerun-install
    ok "Rerun complete"

    info "Resetting file ownership..."
    chown -R www-data:www-data /var/www/pterodactyl/*
    ok "Ownership reset"

    info "Clearing Laravel caches..."
    php artisan view:clear
    php artisan config:clear
    php artisan cache:clear
    ok "Caches cleared"

    info "Restarting queue worker..."
    php artisan queue:restart
    ok "Queue restarted"

    echo ""
    echo -e "${GREEN}  ✔ Auto fix complete!${NC}"
    pause
}

# ==========================================
# ACTION 4 — HYPERV1
# ==========================================
install_hyperv1() {
    banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}🔧 HYPERV1 INSTALLER${NC}                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    info "Downloading HyperV1 installer..."
    wget -O /tmp/hyperv1_installer.sh https://r2.rolexdev.tech/hyperv1/installer.sh
    if [ ! -f /tmp/hyperv1_installer.sh ]; then
        fail "Failed to download HyperV1 installer"; pause; return
    fi
    chmod +x /tmp/hyperv1_installer.sh
    bash /tmp/hyperv1_installer.sh
    rm -f /tmp/hyperv1_installer.sh
    pause
}

# ==========================================
# ACTION 5 — REINSTALL (RERUN ONLY)
# ==========================================
reinstall_blueprint() {
    banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}🔄 REINSTALL BLUEPRINT${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    panel_check || return
    cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; return; }

    info "Running blueprint -rerun-install..."
    blueprint -rerun-install &
    spinner $!
    ok "Reinstall complete"
    pause
}

# ==========================================
# ACTION 6 — UPDATE
# ==========================================
update_blueprint() {
    banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}⬆  UPDATE BLUEPRINT FRAMEWORK${NC}             ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    panel_check || return
    cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; return; }

    info "Running blueprint -upgrade..."
    blueprint -upgrade &
    spinner $!
    ok "Update complete"
    pause
}

# ==========================================
# ACTION 7 — UNINSTALL BLUEPRINT
# ==========================================
uninstall_blueprint() {
    while true; do
        banner
        echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}      ${BOLD}${RED}🗑  UNINSTALL BLUEPRINT${NC}                    ${CYAN}║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}[1]${NC} Remove a Specific Extension"
        echo -e "${CYAN}║${NC}  ${YELLOW}[2]${NC} Remove ALL Extensions"
        echo -e "${CYAN}║${NC}  ${RED}[3]${NC} Remove Blueprint Framework Entirely"
        echo -e "${CYAN}║${NC}  ${WHITE}[0]${NC} Back"
        echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "  Select → " sub

        case $sub in
            # ── Remove one extension ─────────────────────────────
            1)
                banner
                echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}🗑  REMOVE EXTENSION${NC}                       ${CYAN}║${NC}"
                echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
                echo ""
                panel_check || { pause; continue; }

                EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
                if [ ! -d "$EXT_DIR" ] || [ -z "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
                    warn "No Blueprint extensions are currently installed."
                    pause; continue
                fi

                echo -e "  ${CYAN}Installed extensions:${NC}"
                echo ""
                mapfile -t EXTS < <(ls "$EXT_DIR")
                for i in "${!EXTS[@]}"; do
                    echo -e "  ${GREEN}[$((i+1))]${NC} ${EXTS[$i]}"
                done
                echo ""
                read -p "  Enter extension number to remove: " EXT_NUM

                if ! [[ "$EXT_NUM" =~ ^[0-9]+$ ]] || \
                   [ "$EXT_NUM" -lt 1 ] || [ "$EXT_NUM" -gt "${#EXTS[@]}" ]; then
                    fail "Invalid selection."
                    pause; continue
                fi

                EXT_NAME="${EXTS[$((EXT_NUM-1))]}"
                echo ""
                echo -e "  ${RED}⚠ About to remove extension: ${BOLD}${EXT_NAME}${NC}"
                read -p "  Confirm? (y/N): " CONFIRM
                if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
                    info "Cancelled."; pause; continue
                fi

                echo ""
                info "Removing extension ${EXT_NAME}..."
                cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; continue; }
                blueprint -remove "$EXT_NAME" &
                spinner $!

                if [ $? -eq 0 ]; then
                    ok "Extension '${EXT_NAME}' removed successfully!"
                else
                    fail "Removal may have encountered issues. Check output above."
                fi
                pause
                ;;

            # ── Remove ALL extensions ────────────────────────────
            2)
                banner
                echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}🗑  REMOVE ALL EXTENSIONS${NC}                  ${CYAN}║${NC}"
                echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
                echo ""
                panel_check || { pause; continue; }

                EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
                if [ ! -d "$EXT_DIR" ] || [ -z "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
                    warn "No Blueprint extensions are currently installed."
                    pause; continue
                fi

                mapfile -t ALL_EXTS < <(ls "$EXT_DIR")
                echo -e "  ${YELLOW}⚠ This will remove ALL ${#ALL_EXTS[@]} extension(s):${NC}"
                for ext in "${ALL_EXTS[@]}"; do
                    echo -e "    ${RED}•${NC} $ext"
                done
                echo ""
                read -p "  Are you sure? (y/N): " CONFIRM
                if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
                    info "Cancelled."; pause; continue
                fi

                echo ""
                cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; continue; }
                FAILED=0
                for ext in "${ALL_EXTS[@]}"; do
                    info "Removing: $ext"
                    blueprint -remove "$ext" &
                    spinner $!
                    if [ $? -eq 0 ]; then
                        ok "Removed: $ext"
                    else
                        warn "Issue removing: $ext"
                        FAILED=$((FAILED+1))
                    fi
                done

                echo ""
                if [ "$FAILED" -eq 0 ]; then
                    ok "All extensions removed successfully!"
                else
                    warn "$FAILED extension(s) had issues. Check output above."
                fi
                pause
                ;;

            # ── Remove Blueprint framework entirely ──────────────
            3)
                banner
                echo -e "${RED}╔══════════════════════════════════════════════════╗${NC}"
                echo -e "${RED}║${NC}   ${BOLD}${RED}⛔  REMOVE BLUEPRINT FRAMEWORK${NC}              ${RED}║${NC}"
                echo -e "${RED}║${NC}   ${YELLOW}This will remove Blueprint completely!${NC}         ${RED}║${NC}"
                echo -e "${RED}║${NC}   ${YELLOW}Extensions and custom code will be lost.${NC}       ${RED}║${NC}"
                echo -e "${RED}╚══════════════════════════════════════════════════╝${NC}"
                echo ""
                read -p "  Type 'CONFIRM' to proceed: " CONFIRM
                if [[ "$CONFIRM" != "CONFIRM" ]]; then
                    info "Cancelled."; pause; continue
                fi

                panel_check || { pause; continue; }
                cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; continue; }

                # Step 1: Remove all extensions first
                EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
                if [ -d "$EXT_DIR" ] && [ -n "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
                    info "Removing all installed extensions first..."
                    for ext in $(ls "$EXT_DIR"); do
                        blueprint -remove "$ext" > /dev/null 2>&1 &
                        spinner $!
                        ok "Removed extension: $ext"
                    done
                fi

                # Step 2: Remove Blueprint files
                info "Removing Blueprint files..."
                rm -f /usr/local/bin/blueprint
                rm -f /var/www/pterodactyl/blueprint.sh
                rm -f /var/www/pterodactyl/.blueprintrc
                rm -f /var/www/pterodactyl/release.zip
                rm -rf /var/www/pterodactyl/.blueprint
                ok "Blueprint files removed"

                # Step 3: Rebuild panel assets
                info "Rebuilding panel assets..."
                php artisan view:clear > /dev/null 2>&1
                php artisan config:clear > /dev/null 2>&1
                php artisan cache:clear > /dev/null 2>&1
                yarn build:production > /dev/null 2>&1 &
                spinner $!
                ok "Panel assets rebuilt"

                # Step 4: Fix ownership
                info "Resetting file ownership..."
                chown -R www-data:www-data /var/www/pterodactyl
                ok "Ownership reset"

                echo ""
                echo -e "${GREEN}  ✔ Blueprint framework removed successfully!${NC}"
                echo -e "${CYAN}  Panel has been restored to its original state.${NC}"
                pause
                ;;

            0) return ;;
            *) echo -e "${RED}  Invalid Option!${NC}"; sleep 1 ;;
        esac
    done
}

# ==========================================
# MAIN MENU
# ==========================================
while true; do
    banner

    # Live Blueprint status
    if [ -f "/usr/local/bin/blueprint" ] || [ -f "/var/www/pterodactyl/blueprint.sh" ]; then
        BP_STATUS="${GREEN}INSTALLED ✔${NC}"
    else
        BP_STATUS="${RED}NOT INSTALLED ✘${NC}"
    fi
    if [ -d "/var/www/pterodactyl" ]; then
        PANEL_STATUS="${GREEN}FOUND ✔${NC}"
    else
        PANEL_STATUS="${RED}NOT FOUND ✘${NC}"
    fi

    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}      ${BOLD}${WHITE}⚡ BLUEPRINT CONTROL HUB${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  Panel     : $(echo -e $PANEL_STATUS)"
    echo -e "${CYAN}║${NC}  Blueprint : $(echo -e $BP_STATUS)"
    echo -e "${CYAN}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[1]${NC} Fresh Install      ${GRAY}:: Full Auto Setup${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}[2]${NC} Fresh Rebuild      ${GRAY}:: Blueprint 2${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}[3]${NC} Auto Fix / Repair  ${GRAY}:: Fix Broken Install${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}[4]${NC} HyperV1 Installer  ${GRAY}:: HyperV1 Setup${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}[5]${NC} Reinstall          ${GRAY}:: Rerun Only${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}[6]${NC} Update Framework   ${GRAY}:: Latest Release${NC}"
    echo -e "${CYAN}║${NC}  ${RED}[7]${NC} Uninstall          ${GRAY}:: Remove Extension / Framework${NC}"
    echo -e "${CYAN}║${NC}  ${WHITE}[0]${NC} Exit"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "  Select → " choice

    case $choice in
        1) install_blueprint ;;
        2) install_blueprint2 ;;
        3) autofix ;;
        4) install_hyperv1 ;;
        5) reinstall_blueprint ;;
        6) update_blueprint ;;
        7) uninstall_blueprint ;;
        0)
            echo -e "${GREEN}  Exiting — RAJBHAI Blueprint Hub${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}  Invalid Option!${NC}"
            sleep 1.5
            ;;
    esac
done
