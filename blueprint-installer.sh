#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Function to print status messages
print_status() {
    echo -e "${YELLOW}⏳ $1...${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to animate progress
animate_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Welcome animation with RAJBHAI Branding
welcome_animation() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}"
    echo "██████╗  █████╗      ██╗██████╗ ██╗  ██╗ █████╗ ██╗"
    echo "██╔══██╗██╔══██╗     ██║██╔══██╗██║  ██║██╔══██╗██║"
    echo "██████╔╝███████║     ██║██████╔╝███████║███████║██║"
    echo "██╔══██╗██╔══██║██   ██║██╔══██╗██╔══██║██╔══██║██║"
    echo "██║  ██║██║  ██║╚██████╔╝██████╔╝██║  ██║██║  ██║██║"
    echo "╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝"
    echo -e "${NC}"
    echo -e "${CYAN}              Blueprint Installer${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 2
}

# Function: Install (Fresh Setup)
install_blueprint() {
    print_header "FRESH INSTALLATION"
    
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script as root or with sudo"
        return 1
    fi

    print_status "Starting Fresh Install for Blueprint"

    # --- Step 1: Install Node.js 20.x ---
    print_header "INSTALLING NODE.JS 20.x"
    print_status "Installing required packages"
    sudo apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1 &
    animate_progress $! "Installing dependencies"
    
    print_status "Setting up Node.js repository"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
      sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg > /dev/null 2>&1
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | \
      sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null 2>&1
      
    print_status "Updating package lists"
    sudo apt-get update > /dev/null 2>&1 &
    animate_progress $! "Updating package lists"
    
    print_status "Installing Node.js"
    sudo apt-get install -y nodejs > /dev/null 2>&1 &
    animate_progress $! "Installing Node.js"

    # --- Step 2: Install Yarn & Dependencies ---
    print_header "INSTALLING DEPENDENCIES"
    print_status "Installing Yarn"
    npm i -g yarn > /dev/null 2>&1 &
    animate_progress $! "Installing Yarn"

    print_status "Changing to panel directory"
    cd /var/www/pterodactyl || { print_error "Panel directory not found!"; return 1; }
    
    print_status "Installing Yarn dependencies"
    yarn > /dev/null 2>&1 &
    animate_progress $! "Installing Yarn dependencies"

    print_status "Installing additional packages"
    sudo apt install -y zip unzip git curl wget > /dev/null 2>&1 &
    animate_progress $! "Installing additional packages"

    # --- Step 3: Download and Extract Release ---
    print_header "DOWNLOADING BLUEPRINT FRAMEWORK"
    print_status "Downloading latest release"
    # Ensure PTERODACTYL_DIRECTORY is set or default to current
    PDIR=${PTERODACTYL_DIRECTORY:-"/var/www/pterodactyl"}
    wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)" -O "$PDIR/release.zip"
    
    print_status "Extracting release files"
    unzip -o release.zip > /dev/null 2>&1 &
    animate_progress $! "Extracting files"

    # --- Step 4: Run Blueprint Installer ---
    print_header "RUNNING BLUEPRINT INSTALLER"
    if [ ! -f "blueprint.sh" ]; then
        print_error "blueprint.sh not found"
        return 1
    fi

    print_status "Making blueprint.sh executable"
    chmod +x blueprint.sh
    bash blueprint.sh
}

# Function: Reinstall
reinstall_blueprint() {
    print_header "REINSTALLING BLUEPRINT"
    print_status "Starting reinstallation"
    blueprint -rerun-install > /dev/null 2>&1 &
    animate_progress $! "Reinstalling"
}

# Function: Update
update_blueprint() {
    print_header "UPDATING BLUEPRINT"
    print_status "Starting update"
    blueprint -upgrade > /dev/null 2>&1 &
    animate_progress $! "Updating"
}

# Function to display the main menu
show_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}           🔧 BLUEPRINT INSTALLER               ${NC}"
    echo -e "${CYAN}                BY RAJBHAI                      ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                📋 MAIN MENU                   ║${NC}"
    echo -e "${WHITE}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║   ${GREEN}1)${NC} ${CYAN}Fresh Install Blueprint${NC}               ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}2)${NC} ${CYAN}Reinstall (Rerun Only)${NC}                ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}3)${NC} ${CYAN}Update Blueprint Framework${NC}            ${WHITE}║${NC}"
    echo -e "${WHITE}║   ${GREEN}0)${NC} ${RED}Exit${NC}                               ${WHITE}║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📝 Select an option [0-3]: ${NC}"
}

# Main execution
welcome_animation

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) install_blueprint ;;
        2) reinstall_blueprint ;;
        3) update_blueprint ;;
        0) 
            echo -e "${GREEN}Exiting Installer...${NC}"
            exit 0 
            ;;
        *) 
            print_error "Invalid option!"
            sleep 2
            ;;
    esac
    
    echo -e ""
    read -p "$(echo -e "${YELLOW}Press Enter to continue...${NC}")" -n 1
done
