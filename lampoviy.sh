#!/bin/bash

# Script to automatically install LAMP (Linux, Apache, MariaDB, PHP) on Astra Linux

# Variables (adjust these to your needs)
DATABASE_ROOT_PASSWORD="your_mysql_root_password"  # Replace this!
DATABASE_NAME="exampledb"  # Database name
DATABASE_USER="exampleuser"  # Database user name
DATABASE_PASSWORD="example_password"  # Database user password
PHP_VERSION="8.1"  # or 8.0, 7.4, etc. (Compatible with the sury.org repository)

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Replace the contents of /etc/apt/sources.list with Astra Linux repositories
echo "Replacing the contents of /etc/apt/sources.list with Astra Linux repositories..."
cat << EOF > /etc/apt/sources.list
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-main/     1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-update/   1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-base/     1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 astra-ce
deb https://dl.astralinux.ru/astra/stable/1.7_x86-64/uu/last/repository-update/ 1.7_x86-64 main contrib non-free
EOF

# Comment out the contents of /etc/apt/preferences.d/smolensk to use standard repositories
echo "Commenting out /etc/apt/preferences.d/smolensk to use standard repositories..."
cat << EOF > /etc/apt/preferences.d/smolensk
#Package: *
#Pin: release n=1.7_x86-64
#Pin-Priority: 900
EOF

# Add the PHP repository (mirror)
echo "Adding the PHP repository (mirror)..."
apt-get install -y apt-transport-https ca-certificates gnupg2 software-properties-common

# Check if curl is installed
if ! command -v curl &> /dev/null
then
  echo "Installing curl..."
  apt-get install -y curl
fi

# Import the GPG key for the PHP repository
curl -fsSL https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury.gpg
# Add the PHP repository to the sources list
echo "deb [signed-by=/usr/share/keyrings/sury.gpg] https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/php.list

# Update the package lists
echo "Updating the package lists..."
apt-get update

# Install Apache2
echo "Installing Apache2..."
apt-get install -y apache2

# Configure Apache2
echo "Configuring Apache2..."

# Create the website directory
echo "Creating the website directory..."
mkdir -p /var/www/your_website  # Replace this!
chown -R www-data:www-data /var/www/your_website  # Replace this!
chmod -R 755 /var/www/your_website  # Replace this!

# Create the Apache2 virtual host configuration
echo "Creating the Apache2 virtual host configuration..."
cat <<EOF > /etc/apache2/sites-available/your_website.conf
<VirtualHost *:80>
    ServerName your_domain.com # Replace this!
    DocumentRoot /var/www/your_website # Replace this!
    <Directory /var/www/your_website>  # Replace this!
        AllowOverride All
        Require all granted  # ALLOW ACCESS FROM ALL IP ADDRESSES - SECURITY RISK!
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Enable the virtual host and the rewrite module
a2ensite your_website.conf
a2enmod rewrite

# Restart Apache2
echo "Restarting Apache2..."
systemctl restart apache2

# Install MariaDB
echo "Installing MariaDB..."
apt-get install -y mariadb-server

# Configure MariaDB
echo "Configuring MariaDB..."

# Replace the insecure root password (VERY IMPORTANT!)
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_ROOT_PASSWORD';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Create the database and user
echo "Creating the database and user..."
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "CREATE USER '$DATABASE_USER'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'localhost';"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Install PHP and extensions
echo "Installing PHP and extensions..."
apt-get install -y php$PHP_VERSION libapache2-mod-php$PHP_VERSION php$PHP_VERSION-mysql php$PHP_VERSION-cli php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-intl php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip

# Restart Apache2 to activate PHP
echo "Restarting Apache2 to activate PHP..."
systemctl restart apache2

# Verify the installation (create phpinfo.php)
echo "Verifying the installation..."
cat <<EOF > /var/www/your_website/phpinfo.php  # Replace this!
<?php
phpinfo();
?>
EOF

# Output information
echo "LAMP successfully installed!"
echo "Access phpinfo: http://your_domain.com/phpinfo.php"  # Replace this!
echo "Remember to replace your_domain.com and configure Apache2 correctly."
echo "Also, delete phpinfo.php after verification."

exit 0
