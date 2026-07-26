#!/bin/bash

# -----------------------------------------------------
#  Blueprint Addon Installer & Uninstaller
#  By RAJBHAI — Clean UI • Animations • ASCII Art
# -----------------------------------------------------

# Colors
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
YELLOW="\e[33m"
MAGENTA="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

# ASCII Art Banner
banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"

           _____  _____   ____  _   _     _____ _   _  _____ _______       _      _       ______ _____  
     /\   |  __ \|  __ \ / __ \| \ | |   |_   _| \ | |/ ____|__   __|/\   | |    | |    |  ____|  __ \ 
    /  \  | |  | | |  | | |  | |  \| |     | | |  \| | (___    | |  /  \  | |    | |    | |__  | |__) |
   / /\ \ | |  | | |  | | |  | | . ` |     | | | . ` |\___ \   | | / /\ \ | |    | |    |  __| |  _  / 
  / ____ \| |__| | |__| | |__| | |\  |    _| |_| |\  |____) |  | |/ ____ \| |____| |____| |____| | \ \ 
 /_/    \_\_____/|_____/ \____/|_| \_|   |_____|_| \_|_____/   |_/_/    \_\______|______|______|_|  \_\
                                                                                                        
EOF
    echo -e "${RESET}"
}

# Spinner Animation
spinner() {
    local pid=$1
    local delay=0.1
    local spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    while kill -0 "$pid" 2>/dev/null; do
        for frame in "${spin[@]}"; do
            printf "\r${MAGENTA}Processing... ${frame}${RESET}"
            sleep $delay
        done
    done
    printf "\r${GREEN}✓ Done!${RESET}        \n"
}

# ─────────────────────────────────────────
#  INSTALL — all .blueprint files found
# ─────────────────────────────────────────
install_blueprints() {
    banner
    echo -e "${YELLOW}🔍 Searching for .blueprint files...${RESET}"
    sleep 1

    mapfile -t FILES < <(ls *.blueprint 2>/dev/null)

    if (( ${#FILES[@]} == 0 )); then
        echo -e "${RED}❌ No .blueprint files found in current directory!${RESET}"
        return
    fi

    echo -e "${GREEN}✓ Found ${#FILES[@]} blueprint file(s):${RESET}"
    echo ""
    i=1
    for file in "${FILES[@]}"; do
        echo -e "  ${CYAN}$i.${RESET} $file"
        ((i++))
    done
    echo ""

    read -rp "$(echo -e ${YELLOW}'Install all? (y/n): '${RESET})" confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "${RED}Cancelled.${RESET}"; return; }

    echo ""
    echo -e "${BLUE}⚡ Starting installation...${RESET}"
    echo ""

    for f in "${FILES[@]}"; do
        echo -e "${CYAN}➡ Installing: ${MAGENTA}$f${RESET}"
        ( blueprint -install "$f" ) &
        spinner $!
        echo ""
    done

    echo -e "${GREEN}🎉 All blueprints installed successfully!${RESET}"
    echo -e "${BLUE}✨ Thank you for using Blueprint Installer — RAJBHAI${RESET}"
    echo ""
}

# ─────────────────────────────────────────
#  UNINSTALL — pick from installed list
# ─────────────────────────────────────────
uninstall_blueprints() {
    while true; do
        banner
        echo -e "${BOLD}${CYAN}  🗑  UNINSTALL BLUEPRINT${RESET}\n"
        echo -e "  ${YELLOW}[1]${RESET} Remove a Specific Extension"
        echo -e "  ${YELLOW}[2]${RESET} Remove ALL Extensions"
        echo -e "  ${RED}[3]${RESET} Remove Blueprint Framework Entirely"
        echo -e "  ${BLUE}[0]${RESET} Back"
        echo ""
        read -rp "  Select → " uopt

        case $uopt in
            # ── Remove one ───────────────────────────────
            1)
                banner
                EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
                if [ ! -d "$EXT_DIR" ] || [ -z "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
                    echo -e "${YELLOW}⚠ No extensions currently installed.${RESET}"
                    sleep 2; continue
                fi
                echo -e "${CYAN}Installed extensions:${RESET}\n"
                mapfile -t EXTS < <(ls "$EXT_DIR")
                for i in "${!EXTS[@]}"; do
                    echo -e "  ${GREEN}[$((i+1))]${RESET} ${EXTS[$i]}"
                done
                echo ""
                read -rp "  Enter number to remove: " num
                if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "${#EXTS[@]}" ]; then
                    echo -e "${RED}❌ Invalid selection.${RESET}"; sleep 1; continue
                fi
                ext="${EXTS[$((num-1))]}"
                read -rp "  Remove '$ext'? (y/N): " ok
                [[ "$ok" != "y" && "$ok" != "Y" ]] && { echo -e "${YELLOW}Cancelled.${RESET}"; sleep 1; continue; }
                echo -e "\n${MAGENTA}Removing $ext...${RESET}"
                cd /var/www/pterodactyl && blueprint -remove "$ext"
                echo -e "${GREEN}✔ Extension removed!${RESET}"
                sleep 2
                ;;

            # ── Remove all ───────────────────────────────
            2)
                banner
                EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
                if [ ! -d "$EXT_DIR" ] || [ -z "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
                    echo -e "${YELLOW}⚠ No extensions currently installed.${RESET}"
                    sleep 2; continue
                fi
                mapfile -t ALL_EXTS < <(ls "$EXT_DIR")
                echo -e "${YELLOW}⚠ Will remove ${#ALL_EXTS[@]} extension(s):${RESET}"
                for e in "${ALL_EXTS[@]}"; do echo -e "  ${RED}•${RESET} $e"; done
                echo ""
                read -rp "  Confirm? (y/N): " ok
                [[ "$ok" != "y" && "$ok" != "Y" ]] && { echo -e "${YELLOW}Cancelled.${RESET}"; sleep 1; continue; }
                cd /var/www/pterodactyl
                for e in "${ALL_EXTS[@]}"; do
                    echo -e "${MAGENTA}Removing: $e${RESET}"
                    ( blueprint -remove "$e" ) &
                    spinner $!
                    echo -e "${GREEN}✔ Removed: $e${RESET}\n"
                done
                echo -e "${GREEN}🎉 All extensions removed!${RESET}"
                sleep 2
                ;;

            # ── Remove framework ─────────────────────────
            3)
                banner
                echo -e "${RED}⛔ WARNING: This removes Blueprint completely from your panel!${RESET}"
                echo -e "${YELLOW}   Extensions and custom code will be permanently deleted.${RESET}\n"
                read -rp "  Type 'CONFIRM' to proceed: " conf
                [[ "$conf" != "CONFIRM" ]] && { echo -e "${YELLOW}Cancelled.${RESET}"; sleep 1; continue; }

                EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
                if [ -d "$EXT_DIR" ] && [ -n "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
                    echo -e "\n${MAGENTA}Removing all extensions first...${RESET}"
                    cd /var/www/pterodactyl
                    for e in $(ls "$EXT_DIR"); do
                        blueprint -remove "$e" > /dev/null 2>&1
                        echo -e "${GREEN}✔ Removed: $e${RESET}"
                    done
                fi

                echo -e "${MAGENTA}Removing Blueprint files...${RESET}"
                rm -f /usr/local/bin/blueprint
                rm -f /var/www/pterodactyl/blueprint.sh
                rm -f /var/www/pterodactyl/.blueprintrc
                rm -f /var/www/pterodactyl/release.zip
                rm -rf /var/www/pterodactyl/.blueprint

                echo -e "${MAGENTA}Rebuilding panel assets...${RESET}"
                cd /var/www/pterodactyl
                php artisan view:clear > /dev/null 2>&1
                php artisan config:clear > /dev/null 2>&1
                php artisan cache:clear > /dev/null 2>&1
                ( yarn build:production > /dev/null 2>&1 ) &
                spinner $!
                chown -R www-data:www-data /var/www/pterodactyl

                echo -e "\n${GREEN}✔ Blueprint removed. Panel restored to original state.${RESET}"
                sleep 2
                ;;

            0) return ;;
            *) echo -e "${RED}❌ Invalid option.${RESET}"; sleep 1 ;;
        esac
    done
}

# ─────────────────────────────────────────
#  MAIN MENU
# ─────────────────────────────────────────
while true; do
    banner
    echo -e "  ${GREEN}[1]${RESET} 🚀 Install Blueprints"
    echo -e "  ${RED}[2]${RESET} 🗑  Uninstall Blueprint"
    echo -e "  ${BLUE}[0]${RESET} ❌ Exit"
    echo ""
    read -rp "  Select → " choice

    case $choice in
        1) install_blueprints ;;
        2) uninstall_blueprints ;;
        0)
            echo -e "${GREEN}Exiting — RAJBHAI Blueprint Hub${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option.${RESET}"
            sleep 1
            ;;
    esac
done
