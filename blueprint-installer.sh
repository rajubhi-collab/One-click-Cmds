#!/bin/bash

# ==========================================
#  RAJBHAI — BLUEPRINT CONTROL HUB
#  Fresh Install • Rebuild • Fix • HyperV1
#  Reinstall • Update
# ==========================================

# --- Colors ---
R="\e[31m";  G="\e[32m";  Y="\e[33m"
B="\e[34m";  M="\e[35m";  C="\e[36m"
W="\e[97m";  N="\e[0m"
BR="\e[1;31m"; BG="\e[1;32m"; BY="\e[1;33m"
BB="\e[1;34m"; BM="\e[1;35m"; BC="\e[1;36m"
BW="\e[1;97m"
BOLD="\e[1m"; DIM="\e[2m"

# --- Trap Ctrl+C ---
trap 'echo -e "\n${BR} [!] Force exit detected.${N}"; exit 1' SIGINT

# --- Root Check ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${BR}  ✖ Please run as root!${N}"
    exit 1
fi

# ==========================================
# UI HELPERS
# ==========================================
print_center() {
    local text="$1" width=60
    local pad=$(( (width - ${#text}) / 2 ))
    printf "%*s%s%*s\n" $pad "" "$text" $pad ""
}

header() {
    clear
    echo -e "${BC}${BOLD}"
    echo " ╔══════════════════════════════════════════════════════════╗"
    echo " ║                                                          ║"
    printf " ║${BW}%-58s${BC}║\n" "$(print_center "⚡ BLUEPRINT CONTROL HUB ⚡")"
    echo " ║                                                          ║"
    printf " ║${B}%-58s${BC}║\n" "$(print_center "Made By - RAJBHAI")"
    echo " ║                                                          ║"
    echo " ╚══════════════════════════════════════════════════════════╝"
    echo -e "${N}"
    echo -e " ${B}User:${N} $(whoami)   ${B}Host:${N} $(hostname)   ${B}Time:${N} $(date +'%H:%M')"
    echo -e "${C} ──────────────────────────────────────────────────────────${N}"
}

pause() {
    echo ""
    echo -e "${B} ──────────────────────────────────────────────────────────${N}"
    read -rp " ↩  Press Enter to return to main menu..."
}

step()   { echo -e "\n${BC}${BOLD}▶${N} ${BW}$1${N}"; echo -e "  ${DIM}╰─ ${W}$2${N}"; }
ok()     { echo -e "  ${G}✓${N} ${G}$1${N}"; }
warn()   { echo -e "  ${Y}⚠${N} ${Y}$1${N}"; }
fail()   { echo -e "  ${R}✗${N} ${R}$1${N}"; echo -e "${Y}  Continuing in 3 seconds...${N}"; sleep 3; }
info()   { echo -e "  ${B}ℹ${N} ${B}$1${N}"; }
divider(){ echo -e "${M}${DIM}  ────────────────────────────────────────────────${N}"; }

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
        fail "Pterodactyl panel not found at /var/www/pterodactyl"
        exit 1
    fi
    ok "Pterodactyl panel found"
}

# ==========================================
# ACTION 1 — FRESH INSTALL BLUEPRINT
# ==========================================
install_blueprint() {
    header
    echo -e " ${BG}[ FRESH INSTALL ]${N} ${BW}Blueprint Framework — Full Auto Setup${N}\n"
    divider

    step "System Check" "Verifying prerequisites"
    panel_check
    ok "Running as root"
    divider

    # Node.js 20.x
    step "Node.js 20.x" "Installing Node.js runtime"
    info "Installing base packages"
    apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1 &
    spinner $!

    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list

    info "Updating package lists"
    apt-get update > /dev/null 2>&1 &
    spinner $!

    info "Installing Node.js"
    apt-get install -y nodejs > /dev/null 2>&1 &
    spinner $!
    ok "Node.js installed"
    divider

    # Yarn & extras
    step "Dependencies" "Yarn, zip, git, wget"
    npm i -g yarn > /dev/null 2>&1 &
    spinner $!
    apt install -y zip unzip git curl wget > /dev/null 2>&1 &
    spinner $!

    cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; return; }
    yarn > /dev/null 2>&1 &
    spinner $!
    ok "Dependencies ready"
    divider

    # Download Blueprint
    step "Blueprint Framework" "Fetching latest release from GitHub"
    PT_DIR="/var/www/pterodactyl"
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
        | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)

    if [[ -z "$DOWNLOAD_URL" ]]; then
        fail "Could not fetch download URL from GitHub API"
        pause; return
    fi

    info "Downloading release..."
    wget -q "$DOWNLOAD_URL" -O "$PT_DIR/release.zip" &
    spinner $!
    ok "Downloaded"

    info "Extracting files"
    unzip -o "$PT_DIR/release.zip" -d "$PT_DIR" > /dev/null 2>&1 &
    spinner $!
    ok "Extracted"
    divider

    # Configure
    step "Configuration" "Generating .blueprintrc"
    cat <<EOF > "$PT_DIR/.blueprintrc"
WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";
EOF
    chmod +x "$PT_DIR/blueprint.sh"
    chown -R www-data:www-data "$PT_DIR"
    ok "Config generated"
    divider

    # Install
    step "Installer" "Running Blueprint internal installer"
    if [ ! -f "$PT_DIR/blueprint.sh" ]; then
        fail "blueprint.sh not found after extraction"
        pause; return
    fi
    bash "$PT_DIR/blueprint.sh"

    echo ""
    echo -e "${BG}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║         🎉 BLUEPRINT INSTALL COMPLETE!           ║"
    echo "  ║   Blueprint Framework is now active on panel.    ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${N}"
    pause
}

# ==========================================
# ACTION 2 — FRESH REBUILD (Blueprint 2)
# ==========================================
install_blueprint2() {
    header
    echo -e " ${BY}[ FRESH REBUILD ]${N} ${BW}Blueprint 2 — Clean Rebuild Process${N}\n"
    divider

    step "System Check" "Verifying prerequisites"
    panel_check
    divider

    PT_DIR="/var/www/pterodactyl"

    step "Dependencies" "Installing system packages"
    apt update -y -q
    apt install -y curl wget unzip ca-certificates git gnupg zip -q
    ok "Dependencies installed"

    step "Node.js & Yarn" "Configuring runtime environment"
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
    apt update -y -q
    apt install -y nodejs -q
    npm i -g yarn
    ok "Node.js & Yarn ready"

    step "Blueprint Framework" "Fetching latest release"
    cd "$PT_DIR" || { fail "Panel directory not found!"; pause; return; }
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
        | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)
    wget -q "$DOWNLOAD_URL" -O "$PT_DIR/release.zip"
    unzip -o -q release.zip
    ok "Files extracted"

    step "Configuration" "Generating .blueprintrc"
    cat <<EOF > "$PT_DIR/.blueprintrc"
WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";
EOF
    chmod +x "$PT_DIR/blueprint.sh"
    chown -R www-data:www-data "$PT_DIR"
    ok "Config generated"

    step "Installer" "Running Blueprint installer"
    bash "$PT_DIR/blueprint.sh"

    echo ""
    echo -e "${BG}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║       🎉 BLUEPRINT REBUILD COMPLETE!             ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${N}"
    pause
}

# ==========================================
# ACTION 3 — AUTO FIX / REPAIR
# ==========================================
autofix() {
    header
    echo -e " ${BM}[ AUTO FIX ]${N} ${BW}Attempting to repair Blueprint installation...${N}\n"
    divider

    step "System Check" "Verifying prerequisites"
    panel_check
    divider

    step "Repair" "Running blueprint -rerun-install"
    cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; return; }
    blueprint -rerun-install
    ok "Repair complete"

    step "Permissions" "Resetting file ownership"
    chown -R www-data:www-data /var/www/pterodactyl/*
    ok "Ownership reset"

    step "Cache" "Clearing Laravel caches"
    php artisan view:clear
    php artisan config:clear
    php artisan cache:clear
    ok "Caches cleared"

    step "Queue" "Restarting queue worker"
    php artisan queue:restart
    ok "Queue restarted"

    echo ""
    ok "Auto fix completed!"
    pause
}

# ==========================================
# ACTION 4 — HYPERV1
# ==========================================
install_hyperv1() {
    header
    echo -e " ${BM}[ HYPERV1 ]${N} ${BW}HyperV1 Installer${N}\n"
    divider

    step "HyperV1" "Downloading and running installer"
    wget -O /tmp/hyperv1_installer.sh https://r2.rolexdev.tech/hyperv1/installer.sh
    if [ ! -f /tmp/hyperv1_installer.sh ]; then
        fail "Failed to download HyperV1 installer"
        pause; return
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
    header
    echo -e " ${BC}[ REINSTALL ]${N} ${BW}Rerunning Blueprint install script only...${N}\n"
    divider

    step "System Check" "Verifying prerequisites"
    panel_check
    divider

    step "Reinstall" "Running blueprint -rerun-install"
    cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; return; }
    blueprint -rerun-install &
    spinner $!
    ok "Reinstall complete"

    pause
}

# ==========================================
# ACTION 6 — UPDATE BLUEPRINT
# ==========================================
update_blueprint() {
    header
    echo -e " ${BY}[ UPDATE ]${N} ${BW}Upgrading Blueprint Framework to latest...${N}\n"
    divider

    step "System Check" "Verifying prerequisites"
    panel_check
    divider

    step "Update" "Running blueprint -upgrade"
    cd /var/www/pterodactyl || { fail "Panel directory not found!"; pause; return; }
    blueprint -upgrade &
    spinner $!
    ok "Update complete"

    pause
}

# ==========================================
# MAIN MENU
# ==========================================
show_menu() {
    header
    echo -e " ${BW} SELECT AN OPTION:${N}\n"
    echo -e "  ${BG}[ 1 ]${N}  🚀  Fresh Install Blueprint"
    echo -e "  ${BY}[ 2 ]${N}  ⚡  Fresh Rebuild  ${DIM}(Blueprint 2)${N}"
    echo -e "  ${BM}[ 3 ]${N}  🛠  Auto Fix / Repair"
    echo -e "  ${BM}[ 4 ]${N}  🔧  HyperV1 Installer"
    echo -e "  ${BC}[ 5 ]${N}  🔄  Reinstall  ${DIM}(Rerun Only)${N}"
    echo -e "  ${BB}[ 6 ]${N}  ⬆  Update Blueprint Framework"
    echo ""
    echo -e "  ${BR}[ 0 ]${N}  ❌  Exit"
    echo -e "\n${C} ──────────────────────────────────────────────────────────${N}"
}

# ==========================================
# EXECUTION LOOP
# ==========================================
while true; do
    show_menu
    read -rp " 👉 Enter your choice: " opt

    case "$opt" in
        1) install_blueprint ;;
        2) install_blueprint2 ;;
        3) autofix ;;
        4) install_hyperv1 ;;
        5) reinstall_blueprint ;;
        6) update_blueprint ;;
        0)
            echo -e "\n${M}  👋 Goodbye — RAJBHAI Blueprint Hub${N}"
            sleep 0.5
            clear
            exit 0
            ;;
        *)
            echo -e "\n${BR}  ❌ Invalid option, try again.${N}"
            sleep 1
            ;;
    esac
done
