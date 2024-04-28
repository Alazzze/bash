#!/bin/bash

# Функція для виведення допомоги
show_help() {
    echo "Usage: $0 --root-password <password> [--user <username>] [--user-password <password>] [--ip <ip_address>] [--sql-dump <dump_file>] [--help]"
    echo ""
    echo "Options:"
    echo "  --root-password <password>    Set root password for MySQL"
    echo "  --user <username>              Specify username for MySQL user (default: user)"
    echo "  --user-password <password>     Set password for MySQL user (default: auto-generated)"
    echo "  --ip <ip_address>              Allow access to MySQL only from specified IP address"
    echo "  --sql-dump <dump_file>         SQL dump file to initialize MySQL database"
    echo "  --help                         Display this help message"
}

# Перевірка чи є аргументи
if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

ROOT_PASSWORD=""
USERNAME="user"
USER_PASSWORD=""
IP=""
SQL_DUMP=""

# Обробка переданих аргументів
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --root-password)
            ROOT_PASSWORD="$2"
            shift
            shift
            ;;
        --user)
            USERNAME="$2"
            shift
            shift
            ;;
        --user-password)
            USER_PASSWORD="$2"
            shift
            shift
            ;;
        --ip)
            IP="$2"
            shift
            shift
            ;;
        --sql-dump)
            SQL_DUMP="$2"
            shift
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Перевірка обов'язкових аргументів
if [[ -z "$ROOT_PASSWORD" ]]; then
    echo "Root password is required."
    show_help
    exit 1
fi

# Встановлення MariaDB та інших залежностей
echo "Installing MariaDB Server..."
apt update
apt install -y mariadb-server

# Встановлення root пароля
echo "Setting root password for MariaDB..."
mysql -u root -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$ROOT_PASSWORD'); FLUSH PRIVILEGES;"

# Створення користувача та встановлення йому пароля
if [[ -z "$USER_PASSWORD" ]]; then
    USER_PASSWORD=$(openssl rand -base64 12)
    echo "Auto-generated password for user $USERNAME: $USER_PASSWORD"
fi

echo "Creating MariaDB user $USERNAME..."
mysql -u root -p"$ROOT_PASSWORD" -e "CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$USER_PASSWORD';"
if [[ ! -z "$IP" ]]; then
    echo "Allowing access to MariaDB from IP $IP..."
    mysql -u root -p"$ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'$IP' IDENTIFIED BY '$USER_PASSWORD' WITH GRANT OPTION;"
fi

# Ініціалізація БД з SQL дампу
if [[ ! -z "$SQL_DUMP" ]]; then
    echo "Initializing MariaDB database from SQL dump..."
    mysql -u root -p"$ROOT_PASSWORD" < "$SQL_DUMP"
fi

# Налаштування PHPMyAdmin для роботи з MariaDB
echo "Configuring PHPMyAdmin to work with MariaDB..."
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt install -y phpmyadmin

echo "Initialization completed successfully."

# Виведення інформації
echo "MariaDB root password: $ROOT_PASSWORD"
echo "MariaDB username: $USERNAME"
echo "MariaDB user password: $USER_PASSWORD"
echo "MariaDB access from IP: $IP"
echo "PHPMyAdmin URL: http://your_domain_or_ip/phpmyadmin"
