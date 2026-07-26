#!/bin/bash

# ==========================================
#  CYBERPUNK PTERODACTYL AUTO DEPLOY v3
# ==========================================

# -------- COLORS --------
RESET="\e[0m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
PURPLE="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"
GRAY="\e[1;90m"

CURRENT_STEP=0
TOTAL_STEPS=15

line(){ echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
step(){ CURRENT_STEP=$((CURRENT_STEP+1)); echo -e "\n${BLUE}[${CURRENT_STEP}/${TOTAL_STEPS}] ➜ $1${RESET}"; }
ok(){ echo -e "${GREEN}✔ $1${RESET}"; }
warn(){ echo -e "${YELLOW}⚠ $1${RESET}"; }
fail(){ echo -e "${RED}✖ $1${RESET}"; }

# -------- EFFECTS --------

type_write() {
    text="$1"
    delay=0.01
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

loading_bar() {
    echo -ne "${GREEN}[ SYSTEM ]${RESET} "
    for i in {1..20}; do
        echo -ne "█"
        sleep 0.03
    done
    echo -e " ${CYAN}ONLINE${RESET}"
}

deploy_bar() {
    echo -ne "${PURPLE}[ DEPLOY ]${RESET} "
    for i in {1..25}; do
        echo -ne "█"
        sleep 0.04
    done
    echo -e " ${GREEN}SUCCESS${RESET}"
}

# -------- HEADER --------
clear
echo -e "${CYAN}"

cat << "EOF"
8888888b.  888                                 888                   888             888 
888   Y88b 888                                 888                   888             888 
888    888 888                                 888                   888             888 
888   d88P 888888 .d88b.  888d888 .d88b.   .d88888  8888b.   .d8888b 888888 888  888 888 
8888888P"  888   d8P  Y8b 888P"  d88""88b d88" 888     "88b d88P"    888    888  888 888 
888        888   88888888 888    888  888 888  888 .d888888 888      888    888  888 888 
888        Y88b. Y8b.     888    Y88..88P Y88b 888 888  888 Y88b.    Y88b.  Y88b 888 888 
888         "Y888 "Y8888  888     "Y88P"   "Y88888 "Y888888  "Y8888P  "Y888  "Y88888 888 
                                                                                 888     
                                                                            Y8b d88P     
                                                                             "Y88P"      
EOF

echo -e "${RESET}"
line
echo -e "${GREEN}        :: PTERODACTYL AUTO DEPLOYMENT SYSTEM :: v3${RESET}"
line
echo ""

# -------- BOOT SEQUENCE --------
echo -ne "${BLUE}[KERNEL] ${RESET}"
type_write "Initializing core modules..."
echo -ne "${BLUE}[MEMORY] ${RESET}"
type_write "Allocating server resources..."
sleep 0.5
loading_bar
echo ""

# -------- DOMAIN INPUT LOOP --------
while true; do
    line
    echo -e "${CYAN}>> CONFIGURATION REQUIRED <<${RESET}"
    echo ""
    type_write "ENTER TARGET DOMAIN:"
    echo -ne "${GREEN} root@deploy:~$ ${RESET}"
    read DOMAIN
    DOMAIN=${DOMAIN:-panel.example.com}

    echo ""
    echo -e "${CYAN}>> TARGET ENTERED: ${WHITE}$DOMAIN${RESET}"
    echo -ne "${YELLOW}Confirm deployment? (y/n): ${RESET}"
    read CONFIRM

    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo ""
        ok "Target Locked: $DOMAIN"
        break
    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
        warn "Re-entering domain configuration..."
    else
        fail "Invalid choice. Use y or n."
    fi
done

echo ""
line
echo -e "${PURPLE}>> EXECUTING ROOT PROTOCOLS...${RESET}"
sleep 1

# -------- ROOT CHECK --------
if [[ $EUID -ne 0 ]]; then
    fail "This script must be run as root!"
    exit 1
fi

PHP_VERSION="8.3"

# ── Step 1: Base packages ──────────────────────────────────────
step "Base packages — curl, gnupg, git, lsb-release"
apt update -y && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release software-properties-common
ok "Base packages ready."

# ── Step 2: PHP repository ─────────────────────────────────────
step "PHP ${PHP_VERSION} repository"
OS=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs 2>/dev/null)
if [[ "$OS" == "ubuntu" ]]; then
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${CODENAME} main" | tee /etc/apt/sources.list.d/sury-php.list
fi
ok "PHP repo configured."

# ── Step 3: Redis repository ───────────────────────────────────
step "Redis repository"
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${CODENAME} main" | tee /etc/apt/sources.list.d/redis.list
apt update -y
ok "Redis repo configured."

# ── Step 4: PHP + services ─────────────────────────────────────
step "PHP ${PHP_VERSION}, MariaDB, Nginx, Redis, Cron"
apt install -y php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server cron
ok "PHP ${PHP_VERSION}, MariaDB, Nginx, Redis installed."

# ── Step 5: Composer ──────────────────────────────────────────
step "Composer (PHP dependency manager)"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ok "Composer installed."

# ── Step 6: Download Pterodactyl panel ────────────────────────
step "Downloading Pterodactyl panel (latest)"
mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzf panel.tar.gz && rm -f panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
ok "Panel extracted to /var/www/pterodactyl."

# ── Step 7: Database setup ────────────────────────────────────
step "MariaDB — database & user"
DB_NAME=panel
DB_USER=pterodactyl
DB_PASS=$(tr -dc 'A-Za-z0-9!@#%^&*' < /dev/urandom | head -c 24)
systemctl enable --now mariadb
mariadb -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';"
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
mariadb -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"
ok "Database '${DB_NAME}' ready with secure password."

# ── Step 8: Environment config ────────────────────────────────
step "Environment (.env) configuration"
cd /var/www/pterodactyl
[ ! -f ".env.example" ] && curl -Lo .env.example https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
grep -q "^APP_ENVIRONMENT_ONLY=" .env \
    && sed -i "s|^APP_ENVIRONMENT_ONLY=.*|APP_ENVIRONMENT_ONLY=false|" .env \
    || echo "APP_ENVIRONMENT_ONLY=false" >> .env
ok ".env configured."

# ── Step 9: PHP dependencies (Composer install) ───────────────
step "PHP dependencies via Composer"
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
ok "PHP dependencies installed."

# ── Step 10: Application key ──────────────────────────────────
step "Generating application key"
php artisan key:generate --force
ok "App key generated."

# ── Step 11: Database migrations ─────────────────────────────
step "Running database migrations & seeders"
php artisan migrate --seed --force
ok "Migrations complete."

# ── Step 12: Permissions & cron ──────────────────────────────
step "File permissions & cron job"
chown -R www-data:www-data /var/www/pterodactyl/*
systemctl enable --now cron
(crontab -l 2>/dev/null | grep -v "pterodactyl"; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
ok "Permissions set, cron scheduled."

# ── Step 13: SSL certificate ──────────────────────────────────
step "Self-signed SSL certificate (4096-bit RSA)"
mkdir -p /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=Pterodactyl/CN=${DOMAIN}" \
    -keyout /etc/certs/panel/privkey.pem -out /etc/certs/panel/fullchain.pem 2>/dev/null
ok "SSL certificate ready at /etc/certs/panel/"

# ── Step 14: Nginx config ─────────────────────────────────────
step "Nginx virtual host configuration"
tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root /var/www/pterodactyl/public;
    index index.php;
    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
    }
    location ~ /\.ht { deny all; }
}
EOF
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
nginx -t && systemctl enable --now nginx && systemctl restart nginx
ok "Nginx configured and running."

# ── Step 15: Queue worker service ────────────────────────────
step "Pterodactyl queue worker (systemd)"
tee /etc/systemd/system/pteroq.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service mariadb.service
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3 --max-time=3600
RestartSec=5s
StartLimitInterval=180s
StartLimitBurst=30
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now pteroq.service
ok "Queue worker running."

# ── Admin user setup ──────────────────────────────────────────
clear
deploy_bar
echo ""
line
echo -e "${CYAN}>> ADMIN ACCOUNT SETUP [15/15 Complete] <<${RESET}"
echo -e "${GRAY}  Create your Pterodactyl panel login credentials${RESET}"
line
echo ""
read -p "  Email Address : " ADMIN_EMAIL
read -p "  First Name    : " ADMIN_FNAME
read -p "  Last Name     : " ADMIN_LNAME
read -p "  Username      : " ADMIN_USERNAME
while true; do
    read -sp "  Password      : " ADMIN_PASSWORD; echo ""
    read -sp "  Confirm Pass  : " ADMIN_PASSWORD2; echo ""
    [[ "$ADMIN_PASSWORD" == "$ADMIN_PASSWORD2" ]] && break
    warn "Passwords do not match. Try again."
done
echo ""

cd /var/www/pterodactyl
php artisan p:user:make \
    --email="$ADMIN_EMAIL" \
    --username="$ADMIN_USERNAME" \
    --name-first="$ADMIN_FNAME" \
    --name-last="$ADMIN_LNAME" \
    --password="$ADMIN_PASSWORD" \
    --admin=1

# ── Final summary ─────────────────────────────────────────────
echo ""
line
echo -e "${GREEN}🚀 Pterodactyl — Deployment Complete!${RESET}"
line
echo -e "${PURPLE}  ── PANEL ACCESS ──${RESET}"
echo -e "${WHITE}  URL         :${RESET} ${CYAN}https://${DOMAIN}${RESET}"
echo -e "${WHITE}  PHP         :${RESET} ${WHITE}${PHP_VERSION}${RESET}"
line
echo -e "${PURPLE}  ── LOGIN CREDENTIALS ──${RESET}"
echo -e "${WHITE}  Email       :${RESET} ${CYAN}${ADMIN_EMAIL}${RESET}"
echo -e "${WHITE}  First Name  :${RESET} ${WHITE}${ADMIN_FNAME}${RESET}"
echo -e "${WHITE}  Last Name   :${RESET} ${WHITE}${ADMIN_LNAME}${RESET}"
echo -e "${WHITE}  Username    :${RESET} ${WHITE}${ADMIN_USERNAME}${RESET}"
echo -e "${WHITE}  Password    :${RESET} ${YELLOW}${ADMIN_PASSWORD}${RESET}"
line
echo -e "${PURPLE}  ── DATABASE ──${RESET}"
echo -e "${WHITE}  DB Name     :${RESET} ${WHITE}${DB_NAME}${RESET}"
echo -e "${WHITE}  DB User     :${RESET} ${WHITE}${DB_USER}${RESET}"
echo -e "${WHITE}  DB Password :${RESET} ${YELLOW}${DB_PASS}${RESET}"
line
echo -e "${GRAY}  SYSTEM: STABLE | QUEUE: ACTIVE | DATABASE: CONNECTED${RESET}"
echo ""
warn "Save your credentials above — they will not be shown again!"
echo ""
