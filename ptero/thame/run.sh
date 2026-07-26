#!/bin/bash

# ==========================================
# 🎨 UI CONFIGURATION & COLORS
# ==========================================
# Regular Colors
R="\e[31m"; G="\e[32m"; Y="\e[33m"
B="\e[34m"; M="\e[35m"; C="\e[36m"
W="\e[97m"; N="\e[0m"

# Bold & Effects
BR="\e[1;31m"; BG="\e[1;32m"; BY="\e[1;33m"
BB="\e[1;34m"; BM="\e[1;35m"; BC="\e[1;36m"
BW="\e[1;97m"
UL="\e[4m"
BLINK="\e[5m"

# Backgrounds
BG_BLUE="\e[44m"
BG_RED="\e[41m"

# ==========================================
# 🛠️ HELPER FUNCTIONS
# ==========================================

# Trap Ctrl+C
trap 'echo -e "\n${R} [!] Force exit detected.${N}"; exit 1' SIGINT

# Centered Text function
print_center() {
    local text="$1"
    local width=60
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

# The Header
header() {
  clear
  echo -e "${BC}"
  echo " ╔══════════════════════════════════════════════════════════╗"
  echo " ║                                                          ║"
  printf " ║${BW}%-58s${BC}║\n" "$(print_center "⚡ BLUEPRINT CONTROL HUB ⚡")"
  echo " ║                                                          ║"
  printf " ║${B}%-58s${BC}║\n" "$(print_center "Minimal • Clean • High Performance")"
  echo " ║                                                          ║"
  echo " ╚══════════════════════════════════════════════════════════╝"
  echo -e "${N}"
  
  # System Info (Optional visual touch)
  echo -e " ${B}User:${N} $(whoami)  ${B}Host:${N} $(hostname)  ${B}Date:${N} $(date +'%H:%M')"
  echo -e "${C} ──────────────────────────────────────────────────────────${N}"
}

# Pause with style
pause() {
  echo
  echo -e "${B} ──────────────────────────────────────────────────────────${N}"
  read -rp " ↩️  Press Enter to return to main menu..."
}

# ==========================================
# 📋 ACTIONS
# ==========================================

blueprint1() {
  header
  echo -e "\n${BG} [ ACTION STARTED ] ${N} ${W}Running Blueprint 1...${N}\n"
  bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/Hub-of-raj/refs/heads/main/srv/thame/blueprint.sh)
  pause
}

blueprint2() {
  header
  echo -e "\n${BY} [ ACTION STARTED ] ${N} ${W}Running Blueprint 2 (Rebuild)...${N}\n"
  bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/Hub-of-raj/refs/heads/main/srv/thame/blueprint-2.sh)
  pause
}

autofix() {
    header
    echo -e "\n${BM} [ DIAGNOSTICS ] ${N} ${W}Attempting Auto-Fix...${N}\n"
    bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/Hub-of-raj/refs/heads/main/srv/thame/fix.sh)
    pause
}

uninstall_menu() {
  while true; do
    header
    echo -e "${BW} UNINSTALL — SELECT AN OPTION:${N}\n"
    echo -e "  ${BY}[ 1 ]${N}  🗑️   Remove a Specific Extension"
    echo -e "  ${BY}[ 2 ]${N}  🗑️   Remove ALL Extensions"
    echo -e "  ${BR}[ 3 ]${N}  ⛔  Remove Blueprint Framework Entirely"
    echo -e "  ${BR}[ 0 ]${N}  ↩️   Back"
    echo -e "\n${C} ──────────────────────────────────────────────────────────${N}"
    read -p " 👉 Enter your choice: " uopt

    case $uopt in
      1)
        header
        EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
        if [ ! -d "$EXT_DIR" ] || [ -z "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
          echo -e "\n${Y} ⚠ No extensions installed.${N}"; sleep 2; continue
        fi
        echo -e "\n${BW} Installed extensions:${N}\n"
        mapfile -t EXTS < <(ls "$EXT_DIR")
        for i in "${!EXTS[@]}"; do
          echo -e "  ${BG}[$((i+1))]${N} ${EXTS[$i]}"
        done
        echo ""
        read -p " 👉 Enter number to remove: " num
        if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt "${#EXTS[@]}" ]; then
          echo -e "${R} ❌ Invalid selection.${N}"; sleep 1; continue
        fi
        ext="${EXTS[$((num-1))]}"
        read -p " Remove '$ext'? (y/N): " ok
        [[ "$ok" != "y" && "$ok" != "Y" ]] && { echo -e "${Y} Cancelled.${N}"; sleep 1; continue; }
        echo -e "\n${BM} Removing $ext...${N}"
        cd /var/www/pterodactyl && blueprint -remove "$ext"
        echo -e "${BG} ✔ Done!${N}"; pause
        ;;
      2)
        header
        EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
        if [ ! -d "$EXT_DIR" ] || [ -z "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
          echo -e "\n${Y} ⚠ No extensions installed.${N}"; sleep 2; continue
        fi
        mapfile -t ALL_EXTS < <(ls "$EXT_DIR")
        echo -e "\n${BY} ⚠ Will remove ${#ALL_EXTS[@]} extension(s):${N}"
        for e in "${ALL_EXTS[@]}"; do echo -e "   ${BR}•${N} $e"; done
        read -p " Confirm? (y/N): " ok
        [[ "$ok" != "y" && "$ok" != "Y" ]] && { echo -e "${Y} Cancelled.${N}"; sleep 1; continue; }
        cd /var/www/pterodactyl
        for e in "${ALL_EXTS[@]}"; do
          echo -e "${BM} Removing: $e${N}"
          blueprint -remove "$e"
          echo -e "${BG} ✔ Removed: $e${N}"
        done
        echo -e "\n${BG} ✔ All extensions removed!${N}"; pause
        ;;
      3)
        header
        echo -e "\n${BR} ⛔ WARNING: This removes Blueprint completely!${N}"
        read -p " Type 'CONFIRM' to proceed: " conf
        [[ "$conf" != "CONFIRM" ]] && { echo -e "${Y} Cancelled.${N}"; sleep 1; continue; }
        EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
        if [ -d "$EXT_DIR" ] && [ -n "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
          echo -e "${BM} Removing extensions first...${N}"
          cd /var/www/pterodactyl
          for e in $(ls "$EXT_DIR"); do blueprint -remove "$e" > /dev/null 2>&1 && echo -e "${BG} ✔ Removed: $e${N}"; done
        fi
        echo -e "${BM} Removing Blueprint files...${N}"
        rm -f /usr/local/bin/blueprint
        rm -f /var/www/pterodactyl/blueprint.sh
        rm -f /var/www/pterodactyl/.blueprintrc
        rm -f /var/www/pterodactyl/release.zip
        rm -rf /var/www/pterodactyl/.blueprint
        echo -e "${BM} Rebuilding panel...${N}"
        cd /var/www/pterodactyl
        php artisan view:clear && php artisan config:clear && php artisan cache:clear
        yarn build:production > /dev/null 2>&1
        chown -R www-data:www-data /var/www/pterodactyl
        echo -e "\n${BG} ✔ Blueprint removed. Panel restored.${N}"; pause
        ;;
      0) return ;;
      *) echo -e "\n${R} ❌ Invalid Option!${N}"; sleep 1 ;;
    esac
  done
}

# ==========================================
# 🖥️ MAIN MENU
# ==========================================
show_menu() {
  header
  echo -e "${BW} SELECT AN OPTION:${N}\n"

  echo -e "  ${BG}[ 1 ]${N}  🚀  Install Blueprint 1"
  echo -e "  ${BY}[ 2 ]${N}  ⚡  Install Blueprint 2 (Fresh Rebuild)"
  echo -e "  ${BM}[ 3 ]${N}  🛠️   Auto Fix / Repair"
  echo -e "  ${BM}[ 4 ]${N}  🛠️   HyperV1"
  echo -e "  ${BR}[ 5 ]${N}  🗑️   Uninstall Blueprint"
  echo -e ""
  echo -e "  ${BR}[ 0 ]${N}  ❌  Exit Panel"
  
  echo -e "\n${C} ──────────────────────────────────────────────────────────${N}"
}

# ==========================================
# 🔄 EXECUTION LOOP
# ==========================================
while true; do
  show_menu
  read -p " 👉 Enter your choice: " opt

  case $opt in
    1) blueprint1 ;;
    2) blueprint2 ;;
    3) autofix ;;
    4) bash <(curl -s https://raw.githubusercontent.com/rajubhi-collab/One-click-Cmds/refs/heads/main/ptero/thame/hyperv1.sh) ;;
    5) uninstall_menu ;;
    0) 
       echo -e "\n${M} 👋 Exiting — RAJBHAI Blueprint Hub${N}"
       sleep 0.5
       clear
       exit 
       ;;
    *) 
       echo -e "\n${R} ❌ Invalid Option! Please try again.${N}"
       sleep 1
       ;;
  esac
done
