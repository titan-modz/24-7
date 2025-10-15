#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Pterodactyl Panel Installer..."

# === Update system & install dependencies ===
apt update -y && apt upgrade -y
apt install -y curl tar unzip git redis-server mariadb-server nginx certbot python3-certbot-nginx \
php php-cli php-gd php-mysql php-pdo php-mbstring php-tokenizer php-bcmath php-xml php-fpm php-curl \
composer ufw jq -qq

# === Enable services ===
systemctl enable nginx mariadb redis-server
systemctl start nginx mariadb redis-server

# === Secure MariaDB ===
mysql_secure_installation <<EOF

y
n
y
y
EOF

# === Ask for domain ===
read -p "🌐 Enter your panel domain (e.g., panel.azimee.qzz.io): " PANEL_DOMAIN

# === Ask if this is an admin setup ===
read -p "👑 Is this an admin account setup? (y/n): " IS_ADMIN

if [[ "$IS_ADMIN" =~ ^[Yy]$ ]]; then
    echo "⚙️  Enter admin user details:"
    read -p "💌 Admin Email: " ADMIN_EMAIL
    read -p "👤 Admin Username: " ADMIN_USER
    read -p "🧑 Full Name: " ADMIN_NAME
    read -p "🔑 Password: " ADMIN_PASS
fi

# === Create panel directories & download panel ===
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

echo "⬇️ Downloading latest Pterodactyl panel..."
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# === Install composer dependencies ===
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate --force

# === Create database ===
DB_PASS=$(openssl rand -hex 16)
mysql -u root -e "CREATE DATABASE panel;"
mysql -u root -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';"
mysql -u root -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

# === Configure .env ===
php artisan p:environment:setup \
  --author="${ADMIN_EMAIL:-admin@example.com}" \
  --url="https://$PANEL_DOMAIN" \
  --timezone="UTC" \
  --cache=redis \
  --session=redis \
  --queue=redis \
  --redis-host=127.0.0.1 \
  --settings-ui=true

php artisan p:environment:database \
  --host=127.0.0.1 \
  --port=3306 \
  --database=panel \
  --username=pterodactyl \
  --password="$DB_PASS"

# === Run migrations & seed ===
php artisan migrate --seed --force

# === Create admin user if opted ===
if [[ "$IS_ADMIN" =~ ^[Yy]$ ]]; then
    php artisan p:user:make \
      --email="$ADMIN_EMAIL" \
      --username="$ADMIN_USER" \
      --name="$ADMIN_NAME" \
      --password="$ADMIN_PASS" \
      --admin=1
fi

# === Set permissions ===
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl/*

# === Setup Nginx ===
cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# === Setup SSL ===
certbot --nginx -d "$PANEL_DOMAIN" --non-interactive --agree-tos -m "${ADMIN_EMAIL:-admin@example.com}"

echo ""
echo "✅ Panel installation complete!"
echo "🌐 Access at: https://$PANEL_DOMAIN"
if [[ "$IS_ADMIN" =~ ^[Yy]$ ]]; then
    echo "👤 Admin Username: $ADMIN_USER"
    echo "🔑 Admin Password: $ADMIN_PASS"
fi
