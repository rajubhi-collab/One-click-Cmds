#!/bin/bash

# ==============================================================================
#                               CONFIG & COLORS
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# ==============================================================================
#                               HELPER FUNCTIONS
# ==============================================================================

# Function to pause and wait for user input
pause() {
    echo -e ""
    read -n 1 -s -r -p "Press any key to continue..."
    echo -e ""
}

# Function to display a banner (Header)
banner() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}█${NC}             ${WHITE}SERVER PANEL MANAGER${NC}               ${CYAN}█${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
}

# ==============================================================================
#                               PANEL MENU
# ==============================================================================
panel_menu() {
    while true; do
        banner
        
        # UI Header
        echo -e "${CYAN} ┌────────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN} │${NC}              ${YELLOW}SELECT AN OPTION${NC}                  ${CYAN}│${NC}"
        echo -e "${CYAN} ├──────────────────────┬─────────────────────────┤${NC}"
        
        # Menu Rows (Left Column | Right Column)
        echo -e "${CYAN} │${NC} ${GREEN}1)${NC} FeatherPanel      ${CYAN}│${NC} ${GREEN} 7)${NC} Payment Gateway     ${CYAN}│${NC}"
        echo -e "${CYAN} │${NC} ${GREEN}2)${NC} Pterodactyl       ${CYAN}│${NC} ${GREEN} 8)${NC} CtrlPanel           ${CYAN}│${NC}"
        echo -e "${CYAN} │${NC} ${GREEN}3)${NC} Jexactyl          ${CYAN}│${NC} ${GREEN} 9)${NC} Reviactyl           ${CYAN}│${NC}"
        echo -e "${CYAN} │${NC} ${GREEN}4)${NC} Jexpanel          ${CYAN}│${NC} ${GREEN}10)${NC} Tools (Ext)         ${CYAN}│${NC}"
        echo -e "${CYAN} │${NC} ${GREEN}5)${NC} Mythicaldash      ${CYAN}│${NC}                         ${CYAN}│${NC}"
        echo -e "${CYAN} │${NC} ${GREEN}6)${NC} Mythicaldash v3   ${CYAN}│${NC} ${RED}11) Back                ${CYAN}│${NC}"
        
        # UI Footer
        echo -e "${CYAN} └──────────────────────┴─────────────────────────┘${NC}"
        echo -e ""
        
        # Input Prompt
        echo -e "${WHITE}Enter your choice [1-11]:${NC}"
        read -p "➔ " p

        # Logic
        case $p in
            1)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/panel/FeatherPanel/install.sh)
                pause ;;
            2)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/panel/pterodactyl/run.sh)
                pause ;;
            3)
                bash <(curl -fsSL https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/panel/Jexactyl/run.sh)
                pause ;;
            4)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/panel/Jexactyl/install.sh)
                pause ;;
            5)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/panel/dash/os.sh)
                pause ;;
            6)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/panel/dashv3/os.sh)
                pause ;;
            7)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/panel/Payment/run.sh)
                pause ;;
            8)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/Hub-of-raj/refs/heads/main/srv/panel/ctrlpanel.sh)
                pause ;;
            9)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/panel/reviactyl/run.sh)
                pause ;;
            10)
                bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/tools/run.sh)
                pause ;;
            11)
                break ;;
            *)
                echo -e "${RED}Invalid Option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Run the menu
panel_menu
