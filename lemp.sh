#!/bin/bash

# Script to install LEMP stack on Astra Linux

# Variables (Please setup it)
DATABASE_ROOT_PASSWORD="ваш_mysql_root_пароль" # Замените!
DATABASE_NAME="assholedb" # DB name
DATABASE_USER="assholeuser" # DB user username
DATABASE_PASSWORD="asshole" # DB user password
PHP_VERSION="7.4"  #  или 8.0, 7.4, и т.д.

# checking
if [[ $EUID -ne 0 ]]; then
  echo "You must be root."
  exit 1
fi

# Commenting out some shit in /etc/apt/preferences.d/smolensk
echo "commenting out some shit in /etc/apt/preferences.d/smolensk for allow us usage packages not only of our release..."
cat << EOF > /etc/apt/preferences.d/smolensk
#Package: *
#Pin: release n=1.7_x86-64
#Pin-Priority: 900
EOF
# adding  /etc/apt/sources.list (Astra Linux repos)
echo "Replacing contents of /etc/apt/sources.list..."
cat << EOF > /etc/apt/sources.list
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-main/     1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-update/   1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-base/     1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 astra-ce
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/uu/last/repository-update/ 1.7_x86-64 main contrib non-free
EOF

# Adding a php mirror
echo "adding a php mirror..."
apt-get install -y apt-transport-https ca-certificates gnupg2 software-properties-common

# Curl availability
if ! command -v curl &> /dev/null
then
    echo "Installing Curl..."
    apt-get install -y curl
fi

curl -fsSL https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/apt.gpg | apt-key add -
echo "deb https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/dists buster main" | tee /etc/apt/sources.list.d/php.list

# packages list update
echo "Doing apt update..."
apt-get update

# Install Nginx
echo "=NGINX INSTALL="
apt-get install -y nginx

# Setup Nginx
echo "=Nginx SETUP="
rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default

cat <<EOF > /etc/nginx/sites-available/shit.conf
server {
    listen 80;
    server_name _; # Замените!
    root /var/www/shit; # Замените!
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock; # Важно!
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/shit.conf /etc/nginx/sites-enabled/shit.conf

echo "creating folder..."
mkdir -p /var/www/shit #

chown -R www-data:www-data /var/www/shit
chmod -R 755 /var/www/shit # Замените!

# Перезапуск Nginx
echo "restart Nginx unit..."
systemctl restart nginx

# Установка MariaDB
echo "=MARIADB INSTALL="
apt-get install -y mariadb-server

# Настройка MariaDB
echo "=MARIADB SETUP=..."

# replacing root db (very important!)
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_ROOT_PASSWORD';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Creating DB
echo "database..."
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "CREATE USER '$DATABASE_USER'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'localhost';"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# php install
echo "=PHP INSTALL="
apt-get install -y php$PHP_VERSION php$PHP_VERSION-fpm php$PHP_VERSION-mysql php$PHP_VERSION-cli php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-intl php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip


echo "php-fpm restart..."
systemctl restart php$PHP_VERSION-fpm

# Create php info (создание phpinfo.php)
echo "Creating php info to check if lemp installed..."
cat <<EOF > /var/www/shit/phpinfo.php 
<?php
phpinfo();
?>
EOF

# 
echo "LEMP appears to be successfully installed."
echo "Please check it at http://yourip/phpinfo.php" 


exit 0
