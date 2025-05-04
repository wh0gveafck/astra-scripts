#!/bin/bash

# LAMP STACK INSTALL SCRIPT FOR ASTRA LINUX

# Variables (change it)
DATABASE_ROOT_PASSWORD="asshole"  # замените
DATABASE_NAME="testdb"  # замените
DATABASE_USER=assholeuser" # замените
DATABASE_PASSWORD="example_password"  # zamenite
PHP_VERSION="7.3"  # или 8.0, 7.4, и т.д. 

# Пroot checkt
if [[ $EUID -ne 0 ]]; then
  echo "Error, you must be root."
  exit 1
fi

# Replacing sources list
echo "Replacing repos in /etc/apt/sources.list to astra repos..."
cat << EOF > /etc/apt/sources.list
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-main/     1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-update/   1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-base/     1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 astra-ce
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/uu/last/repository-update/ 1.7_x86-64 main contrib non-free
EOF

# Commenting out some shit in /etc/apt/preferences.d/smolensk
echo "commenting out some shit in /etc/apt/preferences.d/smolensk for allow us usage packages not only of our release..."
cat << EOF > /etc/apt/preferences.d/smolensk
#Package: *
#Pin: release n=1.7_x86-64
#Pin-Priority: 900
EOF

echo "Astra Mode disable"
sudo echo "AstraMode off" >> /etc/apache2/apache2.conf

# adding php mirror(disabled)
echo "adding php mirror..."
apt-get install -y apt-transport-https ca-certificates gnupg2 software-properties-common

# curl check
if ! command -v curl &> /dev/null
then
  echo "Installing curl..."
  apt-get install -y curl
fi

#curl -fsSL https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury.gpg
#echo "deb [signed-by=/usr/share/keyrings/sury.gpg] https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/php.list

# update repos
echo "Doing apt update..."
apt-get update

# Install Apache2
echo "Installing Apache2..."
apt-get install -y apache2


echo "apache2 setup..."

echo "Сreating site directory..."
mkdir -p /var/www/shit  # Замените!
chown -R www-data:www-data /var/www/shit  # Замените!
chmod -R 755 /var/www/shit  # Замените!

\
echo "Сreating vhost for Apache2..."
cat <<EOF > /etc/apache2/sites-available/lamp.conf
<VirtualHost *:80>
    ServerName localhost # Замените!
    DocumentRoot /var/www/shit # Замените!
    <Directory /var/www/shit>  # Замените!
        AllowOverride All
        Require all granted  # РАЗРЕШИТЬ ДОСТУП СО ВСЕХ IP-АДРЕСОВ
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Аctivate vhost and rewrite module
a2ensite your_website.conf
a2enmod rewrite

# apache 2 restart
echo "attempting to restart apache 2 unit..."
systemctl restart apache2

# Mariadb install
echo "Installing MariaDB..."
apt-get install -y mariadb-server

# MariaDB setup
echo "Setup MariaDB..."

# root password 
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_ROOT_PASSWORD';"
mysql -u root -e "FLUSH PRIVILEGES;"


echo "Сreating database..."
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "CREATE USER '$DATABASE_USER'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'localhost';"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# php install
echo "Php install..."
apt-get install -y php$PHP_VERSION libapache2-mod-php$PHP_VERSION php$PHP_VERSION-mysql php$PHP_VERSION-cli php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-intl php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip

# restart apache2
echo "restarting apache2..."
systemctl restart apache2


echo "Environment check..."
cat <<EOF > /var/www/your_website/phpinfo.php  # Замените!
<?php
phpinfo();
?>
EOF


echo "LAMP appears to be installed!"
echo "Access to phpinfo: http://your_ipOr_domain/phpinfo.php"  # 
echo "Do not forget to type correct address


exit 0
