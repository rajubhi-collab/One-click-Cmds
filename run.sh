#!/bin/bash

# ====================================================
#       PTERODACTYL CONTROL CENTER v2.1
#             By - RAJ
# ====================================================

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
GRAY='\033[1;90m'
BOLD='\033[1m'
NC='\033[0m'

# --- UI HELPER FUNCTIONS ---

show_header() {
    clear
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}║${NC}         ${BOLD}${WHITE}PTERODACTYL SERVER MANAGEMENT SYSTEM${NC}             ${PURPLE}║${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Current Module: ${YELLOW}$1${NC}"
    echo -e "${PURPLE}────────────────────────────────────────────────────────────${NC}"
    echo ""
}

status_msg() {
    case $1 in
        "OK")   echo -e "  [${GREEN} ✔ ${NC}] $2" ;;
        "ERR")  echo -e "  [${RED} ✘ ${NC}] $2" ;;
        "INFO") echo -e "  [${CYAN} ➜ ${NC}] $2" ;;
        "WAIT") echo -e "  [${YELLOW} ⏳ ${NC}] $2" ;;
    esac
}

pause() {
    echo ""
    read -p "  Press [Enter] to return to main menu..."
}

# ================== INSTALL FUNCTION ==================
install_ptero() {
    show_header "PANEL INSTALLATION"

    status_msg "INFO" "Initiating installation script..."
    sleep 1

    bash <(curl -fsSL https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/install.sh)

    echo ""
    status_msg "OK" "Installation Sequence Complete."
    pause
}

# ================== CREATE USER ==================
create_user() {
    show_header "USER MANAGEMENT"

    if [ ! -d /var/www/pterodactyl ]; then
        status_msg "ERR" "Panel directory not found (/var/www/pterodactyl)."
        status_msg "ERR" "Please install the panel first."
        pause
        return
    fi

    status_msg "WAIT" "Launching Artisan User Maker..."
    echo ""
    cd /var/www/pterodactyl || exit
    php artisan p:user:make

    echo ""
    status_msg "OK" "User created successfully."
    pause
}

# ================= PANEL UNINSTALL =================
uninstall_logic() {
    status_msg "WAIT" "Stopping Panel services..."
    systemctl stop pteroq.service 2>/dev/null || true
    systemctl disable pteroq.service 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    systemctl daemon-reload

    status_msg "WAIT" "Removing cronjobs..."
    crontab -l 2>/dev/null | grep -v 'php /var/www/pterodactyl/artisan schedule:run' | crontab - || true

    status_msg "WAIT" "Deleting panel files..."
    rm -rf /var/www/pterodactyl

    status_msg "WAIT" "Dropping database and users..."
    mariadb -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || \
        mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
    mariadb -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || \
        mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || true
    mariadb -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || \
        mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true

    status_msg "WAIT" "Cleaning Nginx configs..."
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    systemctl reload nginx 2>/dev/null || true
}

uninstall_ptero() {
    show_header "UNINSTALLATION"

    echo -e "${RED}  WARNING: This will delete all panel data and databases!${NC}"
    read -p "  Are you sure you want to proceed? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        status_msg "INFO" "Uninstallation cancelled."
        pause
        return
    fi

    echo ""
    uninstall_logic

    echo ""
    status_msg "OK" "Panel removed successfully (Wings untouched)."
    pause
}

# ================= UPDATE FUNCTION =================
update_panel() {
    show_header "SYSTEM UPDATE"

    if [ ! -d /var/www/pterodactyl ]; then
        status_msg "ERR" "Panel not found in /var/www/pterodactyl"
        pause
        return
    fi

    cd /var/www/pterodactyl || exit

    status_msg "INFO" "Putting panel into Maintenance Mode..."
    php artisan down

    status_msg "INFO" "Downloading latest release..."
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzf panel.tar.gz
    rm -f panel.tar.gz

    status_msg "INFO" "Setting permissions..."
    chmod -R 755 storage/* bootstrap/cache

    status_msg "INFO" "Updating Composer dependencies..."
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

    status_msg "INFO" "Clearing cache..."
    php artisan view:clear
    php artisan config:clear

    status_msg "INFO" "Running database migrations..."
    php artisan migrate --seed --force

    status_msg "INFO" "Fixing file ownership..."
    chown -R www-data:www-data /var/www/pterodactyl/*

    status_msg "INFO" "Restarting Queue Workers..."
    php artisan queue:restart
    php artisan up

    echo ""
    status_msg "OK" "Panel Updated Successfully."
    pause
}

# ================= DOMAIN / SSL =================
domain_ssl() {
    show_header "DOMAIN / SSL"
    bash <(curl -fsSL https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ssl.sh)
    pause
}

# ===================== MAIN MENU =====================
while true; do
    clear

    echo -e "${PURPLE}  ____  _                     _            _         _ ${NC}"
    echo -e "${PURPLE} |  _ \| |_ ___ _ __ ___   __| | __ _  ___| |_ _   _| |${NC}"
    echo -e "${PURPLE} | |_) | __/ _ \ '__/ _ \ / _\` |/ _\` |/ __| __| | | | |${NC}"
    echo -e "${PURPLE} |  __/| ||  __/ | | (_) | (_| | (_| | (__| |_| |_| | |${NC}"
    echo -e "${PURPLE} |_|    \__\___|_|  \___/ \__,_|\__,_|\___|\__|\__, |_|${NC}"
    echo -e "${PURPLE}                                               |___/   ${NC}"
    echo -e ""

    echo -e "${CYAN} ┌───────────────────────────────────────────────────────┐${NC}"

    if [ -d "/var/www/pterodactyl" ]; then
        echo -e "${CYAN} │${NC} ${BOLD}${WHITE}PANEL STATUS:${NC} ${GREEN}INSTALLED ✔${NC}                                 ${CYAN}│${NC}"
    else
        echo -e "${CYAN} │${NC} ${BOLD}${WHITE}PANEL STATUS:${NC} ${RED}NOT INSTALLED ✘${NC}                             ${CYAN}│${NC}"
    fi

    echo -e "${CYAN} ├───────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN} │${NC}                                                       ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${GREEN}[1]${NC} Install Panel     ${GRAY}:: (Fresh Install)${NC}              ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${GREEN}[2]${NC} Create User       ${GRAY}:: (Add Admin/User)${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${YELLOW}[3]${NC} Update Panel      ${GRAY}:: (Latest Release)${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${CYAN}[4]${NC}  Domain / SSL      ${GRAY}:: (Change Domain/SSL)${NC}         ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${RED}[5]${NC} Uninstall Panel   ${GRAY}:: (Remove Data)${NC}               ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}                                                       ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${WHITE}[6] Exit System${NC}                                   ${CYAN}│${NC}"
    echo -e "${CYAN} └───────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -ne "${BOLD}${WHITE}  root@ptero:~# ${NC}"
    read choice

    case $choice in
        1) install_ptero ;;
        2) create_user ;;
        3) update_panel ;;
        4) domain_ssl ;;
        5) uninstall_ptero ;;
        6) clear; exit 0 ;;
        *) echo -e "${RED}  Invalid option selected...${NC}"; sleep 1 ;;
    esac
done
