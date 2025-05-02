#!/bin/bash

# Скрипт для автоматической установки LEMP на Astr

# Переменные (настройте под ваши нужды)
DATABASE_ROOT_PASSWORD="ваш_mysql_root_пароль" # Замените!
DATABASE_NAME="assholedb" # Имя базы данных
DATABASE_USER="assholeuser" # Имя пользователя базы данных
DATABASE_PASSWORD="asshole" # Пароль пользователя базы данных
PHP_VERSION="7.4"  #  или 8.0, 7.4, и т.д.

# Проверка наличия прав root
if [[ $EUID -ne 0 ]]; then
  echo "Необходимо запустить скрипт от имени root."
  exit 1
fi

# Комментируем содержимое /etc/apt/preferences.d/smolensk
echo "Комментируем /etc/apt/preferences.d/smolensk для использования стандартных репозиториев..."
cat << EOF > /etc/apt/preferences.d/smolensk
#Package: *
#Pin: release n=1.7_x86-64
#Pin-Priority: 900
EOF

# Добавление репозитория PHP (зеркало)
echo "Добавление репозитория PHP (зеркало)..."
apt-get install -y apt-transport-https ca-certificates gnupg2 software-properties-common

# Проверка наличия curl
if ! command -v curl &> /dev/null
then
    echo "Installing Curl..."
    apt-get install -y curl
fi

curl -fsSL https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury.gpg
echo "deb [signed-by=/usr/share/keyrings/sury.gpg] https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/php.list

# Обновление списка пакетов
echo "Обновление списка пакетов..."
apt-get update

# Установка Nginx
echo "Установка Nginx..."
apt-get install -y nginx

# Настройка Nginx (простая конфигурация по умолчанию)
echo "Настройка Nginx..."
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
# Создание директории для сайта
echo "Создание директории для сайта..."
mkdir -p /var/www/shit #

chown -R www-data:www-data /var/www/shit
chmod -R 755 /var/www/shit # Замените!

# Перезапуск Nginx
echo "Перезапуск Nginx..."
systemctl restart nginx

# Установка MariaDB
echo "Установка MariaDB..."
apt-get install -y mariadb-server

# Настройка MariaDB
echo "Настройка MariaDB..."

# Замена небезопасного пароля root (ОЧЕНЬ ВАЖНО!)
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_ROOT_PASSWORD';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Создание базы данных и пользователя
echo "Создание базы данных и пользователя..."
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "CREATE USER '$DATABASE_USER'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'localhost';"
mysql -u root -p"$DATABASE_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Установка PHP и расширений
echo "Установка PHP и расширений..."
apt-get install -y php$PHP_VERSION php$PHP_VERSION-fpm php$PHP_VERSION-mysql php$PHP_VERSION-cli php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-intl php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip

# Настройка PHP-FPM
echo "Настройка PHP-FPM..."
# (Опционально: Можете настроить php.ini и pool-файлы php-fpm здесь)

# Перезапуск PHP-FPM
echo "Перезапуск PHP-FPM..."
systemctl restart php$PHP_VERSION-fpm

# Проверка установки (создание phpinfo.php)
echo "Проверка установки..."
cat <<EOF > /var/www/your_website/phpinfo.php # Замените!
<?php
phpinfo();
?>
EOF

# Вывод информации
echo "LEMP успешно установлен!"
echo "Доступ к phpinfo: http://yourip.com/phpinfo.php" # Зам
echo "Не забудьте заменить your_domain.com и настроить Nginx правильно."
echo "Также, удалите phpinfo.php после проверки."

exit 0
