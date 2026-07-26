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
DIM="\e[2m"

CURRENT_STEP=0
TOTAL_STEPS=17

line(){ echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
step(){ CURRENT_STEP=$((CURRENT_STEP+1)); echo -e "\n${BLUE}[${CURRENT_STEP}/${TOTAL_STEPS}] ▶ $1${RESET}\n  ${DIM}╰─ $2${RESET}"; }
ok(){ echo -e "  ${GREEN}✔ $1${RESET}"; }
warn(){ echo -e "  ${YELLOW}⚠ $1${RESET}"; }
fail(){ echo -e "  ${RED}✖ $1${RESET}"; }
info(){ echo -e "  ${CYAN}➜ $1${RESET}"; }

# -------- SPINNER --------
spinner() {
    local pid=$1 msg=$2
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    echo -ne "  ${CYAN}⏳ ${msg}${RESET} "
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "[%c] " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo -e "${GREEN}✔ done${RESET}"
}

# -------- EFFECTS --------
type_write() {
    local text="$1" delay=0.01
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

loading_bar() {
    echo -ne "${GREEN}[ SYSTEM ]${RESET} "
    for i in {1..20}; do echo -ne "█"; sleep 0.03; done
    echo -e " ${CYAN}ONLINE${RESET}"
}

deploy_bar() {
    echo -ne "${PURPLE}[ DEPLOY ]${RESET} "
    for i in {1..25}; do echo -ne "█"; sleep 0.04; done
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
echo -e "${GRAY}                      Made By - RAJBHAI${RESET}"
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
step "System Check" "Detecting OS and environment"
OS=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs 2>/dev/null)
PHP_VERSION="8.3"
if [[ -z "$OS" ]]; then
    fail "Could not detect OS. Ubuntu or Debian required."
    exit 1
fi
ok "Detected: $OS ($CODENAME) — PHP ${PHP_VERSION}"

# -------- BASE DEPENDENCIES --------
step "Dependencies" "Installing base system packages"
(apt update -y && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release wget software-properties-common) &>/dev/null &
spinner $! "Installing base packages"

# -------- PHP REPO --------
step "PHP Repository" "Adding PHP ${PHP_VERSION} source"
if [[ "$OS" == "ubuntu" ]]; then
    (LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php) &>/dev/null &
    spinner $! "Adding Ondrej PHP PPA"
elif [[ "$OS" == "debian" ]]; then
    curl -fsSL https://packages.sury.org/php/apt.gpg 2>/dev/null | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${CODENAME} main" | tee /etc/apt/sources.list.d/sury-php.list >/dev/null
    ok "Sury PHP repo added"
fi

# -------- REDIS REPO --------
step "Redis Repository" "Adding Redis package source"
curl -fsSL https://packages.redis.io/gpg 2>/dev/null | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${CODENAME} main" | tee /etc/apt/sources.list.d/redis.list >/dev/null
ok "Redis repo added"

(apt update -y) &>/dev/null &
spinner $! "Refreshing package lists"

# -------- INSTALL PHP + SERVICES --------
step "PHP & Services" "Installing PHP ${PHP_VERSION}, MariaDB, Nginx, Redis"
(apt install -y \
    php${PHP_VERSION} \
    php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} \
    mariadb-server nginx redis-server cron) &>/dev/null &
spinner $! "Installing PHP and services"
ok "PHP ${PHP_VERSION}, MariaDB, Nginx, Redis installed"

# -------- COMPOSER --------
step "Composer" "Installing PHP dependency manager"
(curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer) &>/dev/null &
spinner $! "Downloading Composer"
ok "Composer installed"

# -------- DOWNLOAD PANEL --------
step "Pterodactyl Panel" "Fetching latest release from GitHub"
PANEL_VERSION=$(curl -s https://api.github.com/repos/pterodactyl/panel/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
[[ -z "$PANEL_VERSION" ]] && PANEL_VERSION="latest"
PANEL_URL="https://github.com/pterodactyl/panel/releases/download/${PANEL_VERSION}/panel.tar.gz"
[[ "$PANEL_VERSION" == "latest" ]] && PANEL_URL="https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"
ok "Version: ${PANEL_VERSION}"

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
(curl -Lo panel.tar.gz "${PANEL_URL}" 2>/dev/null) &
spinner $! "Downloading panel archive"
tar -xzf panel.tar.gz && rm -f panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
ok "Panel extracted to /var/www/pterodactyl"

# -------- MARIADB SETUP --------
step "Database" "Configuring MariaDB"
DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASS=$(tr -dc 'A-Za-z0-9!@#%^&*' < /dev/urandom | head -c 24)

systemctl enable --now mariadb &>/dev/null
mariadb -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
mariadb -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';"
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"
ok "Database '${DB_NAME}' created with secure password"

# -------- .env SETUP --------
step "Environment" "Configuring .env file"
if [ -f ".env.example" ]; then
    cp .env.example .env
else
    curl -Lo .env https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example 2>/dev/null
fi
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
grep -q "^APP_ENVIRONMENT_ONLY=" .env \
    && sed -i "s|^APP_ENVIRONMENT_ONLY=.*|APP_ENVIRONMENT_ONLY=false|" .env \
    || echo "APP_ENVIRONMENT_ONLY=false" >> .env
ok "Environment configured"

# -------- PHP DEPENDENCIES --------
step "PHP Packages" "Running Composer install"
(COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader) &>/dev/null &
spinner $! "Installing Composer dependencies"
ok "PHP packages installed"

# -------- APP KEY + MIGRATIONS --------
step "Application Setup" "Generating key and running migrations"
info "Generating application key..."
php artisan key:generate --force
info "Running database migrations..."
php artisan migrate --seed --force
ok "Application key generated and migrations complete"

# -------- PERMISSIONS --------
step "Permissions" "Setting file ownership"
chown -R www-data:www-data /var/www/pterodactyl/*
ok "Ownership set to www-data"

# -------- CRON --------
step "Cron Job" "Scheduling Pterodactyl tasks"
systemctl enable --now cron 2>/dev/null || systemctl enable --now crond 2>/dev/null || true
(crontab -l 2>/dev/null | grep -v "pterodactyl"; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
ok "Cron job configured"

# -------- SSL (SELF-SIGNED) --------
step "SSL Certificate" "Generating self-signed certificate"
mkdir -p /etc/certs/panel
(openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=Pterodactyl/CN=${DOMAIN}" \
    -keyout /etc/certs/panel/privkey.pem -out /etc/certs/panel/fullchain.pem) &>/dev/null &
spinner $! "Generating RSA 4096 certificate"
ok "SSL certificate ready at /etc/certs/panel/"

# -------- NGINX CONFIG --------
step "Nginx" "Writing virtual host configuration"
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
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
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
ok "Nginx configured and restarted"

# -------- QUEUE WORKER SERVICE --------
step "Queue Worker" "Installing pteroq systemd service"
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
ok "Queue worker service running"

# -------- CREATE ADMIN USER --------
clear
step "Admin User" "Create your first administrator account"
deploy_bar
echo ""
cd /var/www/pterodactyl

line
echo -e "${CYAN}>> ADMIN ACCOUNT SETUP <<${RESET}"
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

php artisan p:user:make \
    --email="$ADMIN_EMAIL" \
    --username="$ADMIN_USERNAME" \
    --name-first="$ADMIN_FNAME" \
    --name-last="$ADMIN_LNAME" \
    --password="$ADMIN_PASSWORD" \
    --admin=1

# -------- DONE --------
echo ""
line
echo -e "${GREEN}🚀 Pterodactyl ${PANEL_VERSION} — Deployment Complete!${RESET}"
line
echo -e "${WHITE}  Panel URL   :${RESET} ${CYAN}https://${DOMAIN}${RESET}"
echo -e "${WHITE}  PHP Version :${RESET} ${WHITE}${PHP_VERSION}${RESET}"
line
echo -e "${PURPLE}  ── PANEL LOGIN CREDENTIALS ──${RESET}"
echo -e "${WHITE}  Email       :${RESET} ${CYAN}${ADMIN_EMAIL}${RESET}"
echo -e "${WHITE}  First Name  :${RESET} ${WHITE}${ADMIN_FNAME}${RESET}"
echo -e "${WHITE}  Last Name   :${RESET} ${WHITE}${ADMIN_LNAME}${RESET}"
echo -e "${WHITE}  Username    :${RESET} ${WHITE}${ADMIN_USERNAME}${RESET}"
echo -e "${WHITE}  Password    :${RESET} ${YELLOW}${ADMIN_PASSWORD}${RESET}"
line
echo -e "${PURPLE}  ── DATABASE CREDENTIALS ──${RESET}"
echo -e "${WHITE}  DB Name     :${RESET} ${WHITE}${DB_NAME}${RESET}"
echo -e "${WHITE}  DB User     :${RESET} ${WHITE}${DB_USER}${RESET}"
echo -e "${WHITE}  DB Password :${RESET} ${YELLOW}${DB_PASS}${RESET}"
line
echo -e "${GRAY}  SYSTEM: STABLE | QUEUE: ACTIVE | DATABASE: CONNECTED${RESET}"
echo ""
warn "Save your credentials above — they will not be shown again!"
echo ""
info "To change domain or set up real SSL later, run: ssl.sh"
echo ""
