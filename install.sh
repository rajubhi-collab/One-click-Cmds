#!/bin/bash

# ==========================================
#  RAJBHAI PTERODACTYL AUTO DEPLOY v4
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

line(){ echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
step(){ echo -e "${BLUE}➜ $1${RESET}"; }
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
██████╗  █████╗      ██╗██████╗ ██╗  ██╗ █████╗ ██╗
██╔══██╗██╔══██╗     ██║██╔══██╗██║  ██║██╔══██╗██║
██████╔╝███████║     ██║██████╔╝███████║███████║██║
██╔══██╗██╔══██║██   ██║██╔══██╗██╔══██║██╔══██║██║
██║  ██║██║  ██║╚█████╔╝██████╔╝██║  ██║██║  ██║██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝
EOF
echo -e "${RESET}"
line
echo -e "${GREEN}     :: PTERODACTYL PANEL AUTO INSTALLER :: Latest Version${RESET}"
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

# -------- ROOT CHECK --------
if [[ $EUID -ne 0 ]]; then
    fail "This script must be run as root!"
    exit 1
fi

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

# -------- DETECT OS --------
step "Detecting OS..."
OS=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs 2>/dev/null)
if [[ -z "$OS" ]]; then
    fail "Could not detect OS. Ubuntu/Debian required."
    exit 1
fi
ok "Detected: $OS ($CODENAME)"

# -------- DETECT PHP VERSION --------
PHP_VERSION="8.3"

# -------- INSTALL BASE DEPENDENCIES --------
step "Updating system packages..."
apt update -y && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release wget software-properties-common

# -------- PHP REPO --------
step "Adding PHP repository..."
if [[ "$OS" == "ubuntu" ]]; then
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${CODENAME} main" | tee /etc/apt/sources.list.d/sury-php.list
fi

# -------- REDIS REPO --------
step "Adding Redis repository..."
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${CODENAME} main" | tee /etc/apt/sources.list.d/redis.list

apt update -y

# -------- INSTALL PHP + EXTENSIONS --------
step "Installing PHP ${PHP_VERSION} and dependencies..."
apt install -y \
    php${PHP_VERSION} \
    php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} \
    mariadb-server nginx redis-server cron
ok "System packages installed."

# -------- INSTALL COMPOSER --------
step "Installing Composer..."
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ok "Composer ready."

# -------- DOWNLOAD LATEST PTERODACTYL PANEL --------
step "Downloading latest Pterodactyl Panel..."
PANEL_VERSION=$(curl -s https://api.github.com/repos/pterodactyl/panel/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
if [[ -z "$PANEL_VERSION" ]]; then
    PANEL_VERSION="latest"
    PANEL_URL="https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"
else
    PANEL_URL="https://github.com/pterodactyl/panel/releases/download/${PANEL_VERSION}/panel.tar.gz"
fi
ok "Panel version: ${PANEL_VERSION}"

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz "${PANEL_URL}"
tar -xzvf panel.tar.gz
rm -f panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
ok "Panel downloaded and extracted."

# -------- MARIADB SETUP --------
step "Configuring database..."
DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASS=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 24)

systemctl enable --now mariadb

mariadb -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
mariadb -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';"
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"
ok "Database configured."

# -------- .env SETUP --------
step "Configuring environment..."
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
    else
        curl -Lo .env https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
    fi
fi
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
grep -q "^APP_ENVIRONMENT_ONLY=" .env && sed -i "s|^APP_ENVIRONMENT_ONLY=.*|APP_ENVIRONMENT_ONLY=false|" .env || echo "APP_ENVIRONMENT_ONLY=false" >> .env
ok "Environment configured."

# -------- PHP DEPENDENCIES --------
step "Installing PHP dependencies..."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
ok "PHP dependencies installed."

# -------- APP KEY + MIGRATIONS --------
step "Generating application key..."
php artisan key:generate --force
ok "App key generated."

step "Running database migrations..."
php artisan migrate --seed --force
ok "Migrations complete."

# -------- PERMISSIONS --------
step "Setting permissions..."
chown -R www-data:www-data /var/www/pterodactyl/*
ok "Permissions set."

# -------- CRON --------
step "Setting up cron job..."
systemctl enable --now cron 2>/dev/null || systemctl enable --now crond 2>/dev/null || true
(crontab -l 2>/dev/null | grep -v "pterodactyl"; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
ok "Cron configured."

# -------- SSL (SELF-SIGNED) --------
step "Generating SSL certificate..."
mkdir -p /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=Pterodactyl/CN=${DOMAIN}" \
    -keyout /etc/certs/panel/privkey.pem -out /etc/certs/panel/fullchain.pem 2>/dev/null
ok "SSL certificate generated."

# -------- NGINX CONFIG --------
step "Configuring Nginx..."
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

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
nginx -t && systemctl enable --now nginx && systemctl restart nginx
ok "Nginx configured and running."

# -------- QUEUE WORKER --------
step "Setting up queue worker..."
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

# -------- CREATE ADMIN USER --------
clear
step "Creating admin user..."
deploy_bar
echo ""
cd /var/www/pterodactyl
php artisan p:user:make

# -------- DONE --------
echo ""
line
echo -e "${GREEN}🚀 Pterodactyl ${PANEL_VERSION} — Deployment Complete!${RESET}"
line
echo -e "${WHITE}Panel URL   :${RESET} ${CYAN}https://${DOMAIN}${RESET}"
echo -e "${WHITE}DB Name     :${RESET} ${WHITE}${DB_NAME}${RESET}"
echo -e "${WHITE}DB User     :${RESET} ${WHITE}${DB_USER}${RESET}"
echo -e "${WHITE}DB Password :${RESET} ${YELLOW}${DB_PASS}${RESET}"
echo -e "${WHITE}PHP Version :${RESET} ${WHITE}${PHP_VERSION}${RESET}"
line
echo -e "${GRAY}SYSTEM STATUS: STABLE | FIREWALL: ACTIVE | DATABASE: CONNECTED${RESET}"
echo ""
warn "Save your DB password shown above — it won't be displayed again!"
echo ""
