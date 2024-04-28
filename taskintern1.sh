#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 [--mariadb-version <version>] [--phpmyadmin-version <version>] [--install-all] [--show-versions] [--help]"
    echo ""
    echo "Options:"
    echo "  --mariadb-version <version>       Specify MariaDB version to install"
    echo "  --phpmyadmin-version <version>    Specify PHPMyAdmin version to install"
    echo "  --install-all                      Install both MariaDB and PHPMyAdmin with latest versions"
    echo "  --show-versions                    Display available versions of MariaDB and PHPMyAdmin"
    echo "  --help                             Display this help message"
}

# Checking for arguments
if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

MYSQL_VERSION=""
PHPMYADMIN_VERSION=""
INSTALL_ALL=false
SHOW_VERSIONS=false

# Argument processing
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --mariadb-version)
            MYSQL_VERSION="$2"
            shift
            shift
            ;;
        --phpmyadmin-version)
            PHPMYADMIN_VERSION="$2"
            shift
            shift
            ;;
        --install-all)
            INSTALL_ALL=true
            shift
            ;;
        --show-versions)
            SHOW_VERSIONS=true
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

# Display available versions of MariaDB and PHPMyAdmin
if $SHOW_VERSIONS; then
    echo "Available versions of MariaDB:"
    apt-cache madison mariadb-server
    echo ""
    echo "Available versions of PHPMyAdmin:"
    apt-cache madison phpmyadmin
    exit 0
fi

# Update package lists
sudo apt update

# Install MariaDB
install_mariadb() {
    if [[ -z "$MYSQL_VERSION" ]]; then
        echo "Installing latest version of MariaDB..."
        sudo apt install -y mariadb-server
    else
        echo "Installing MariaDB version $MYSQL_VERSION..."
        sudo apt install -y mariadb-server="$MYSQL_VERSION"
    fi
}

# Install PHPMyAdmin
install_phpmyadmin() {
    if [[ -z "$PHPMYADMIN_VERSION" ]]; then
        echo "Installing latest version of PHPMyAdmin..."
        sudo apt install -y phpmyadmin
    else
        echo "Installing PHPMyAdmin version $PHPMYADMIN_VERSION..."
        sudo apt install -y phpmyadmin="$PHPMYADMIN_VERSION"
    fi
}

# Install both MariaDB and PHPMyAdmin with latest versions
if $INSTALL_ALL; then
    install_mariadb
    install_phpmyadmin
else
    # Install separately
    install_mariadb
    install_phpmyadmin
fi

echo "Installation completed successfully."
