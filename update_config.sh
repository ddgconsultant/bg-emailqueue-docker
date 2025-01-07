#!/bin/bash

# Function to validate commands
validate() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" | tee -a "$LOG_FILE"
        exit 1
    else
        echo "Success: $1" | tee -a "$LOG_FILE"
    fi
}

LOG_FILE="$HOME/updateconfig.log"
# Path to the password file
PASSWORD_FILE="$HOME/.passwordfile"

# Check if the password file exists
if [ -f "$PASSWORD_FILE" ]; then
    # Source the password file to get the variables
    source "$PASSWORD_FILE"
else
    # Prompt for the API key from the user
    read -sp "Enter EmailQueue - API_KEY: " apikey
    echo

    # Prompt for bgemailqueue_admin password
    read -sp "Enter bgemailqueue_admin password: " adminpass
    echo

    # Prompt for postmaster@birthday.gold password
    read -sp "Enter emailqueue_postmaster@birthday.gold password: " postmasterpass
    echo

    # Prompt for postmaster@birthday.gold password
    read -sp "Enter FTP richard password: " ftppass
    echo

    # Save the variables to the password file
    echo "apikey='$apikey'" > "$PASSWORD_FILE"
    echo "adminpass='$adminpass'" >> "$PASSWORD_FILE"
    echo "postmasterpass='$postmasterpass'" >> "$PASSWORD_FILE"
    echo "ftppass='$ftppass'" >> "$PASSWORD_FILE"
fi

# Ensure necessary variables are set
if [ -z "$apikey" ] || [ -z "$adminpass" ] || [ -z "$postmasterpass" ] || [ -z "$ftppass" ]; then
    echo "One or more required variables are not set. Exiting."
    exit 1
fi




# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null
then

figlet "Installing docker-compose"
    echo "docker-compose not found. Installing..."
    sudo apt-get update
    sudo apt-get -y install docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    docker-compose --version
    validate "Installing docker-compose"
else
    echo "docker-compose is already installed."
    docker-compose --version
fi





figlet "Starting Config"

# Copy the example config file
cp application.config.inc.php.example application.config.inc.php
validate "Copying application.config.inc.php.example to application.config.inc.php"


###---------------------------------------------------------------------------
### 2025
###---------------------------------------------------------------------------
# Configure MySQL and Docker settings
# Create db.config.inc.php
cat > db.config.inc.php << 'EOF'
<?php
namespace Emailqueue;
define("EMAILQUEUE_DB_HOST", "emailqueue-mysql");
define("EMAILQUEUE_DB_UID", "root");
define("EMAILQUEUE_DB_PWD", "change_this_password");
define("EMAILQUEUE_DB_DATABASE", "emailqueue");
define("EMAILQUEUE_DB_PORT", 3306);
?>
EOF
validate "Creating db.config.inc.php"


###---------------------------------------------------------------------------
### 2025
###---------------------------------------------------------------------------
# Setup MySQL directories and config
mkdir -p docker/mysql/conf.d
mkdir -p docker/mysql/data
validate "Creating MySQL directories"


###---------------------------------------------------------------------------
### 2025
###---------------------------------------------------------------------------
# Create replication config
numeric_part=$(hostname | grep -o -E '[0-9]+')
server_id=3${numeric_part}
echo -e "[mysqld]\nserver_id=${server_id}\nlog_bin=mysql-bin\ngtid_mode=ON\nenforce-gtid-consistency=ON\nbinlog-format=ROW\nport=3306\nbind-address=0.0.0.0" > docker/mysql/conf.d/replication.cnf
validate "Creating MySQL replication config"


###---------------------------------------------------------------------------
### 2025
###---------------------------------------------------------------------------
# Update emailqueue_init.sql
sed -i '1iCREATE DATABASE IF NOT EXISTS emailqueue;\nUSE emailqueue;\n\nALTER USER '"'"'root'"'"'@'"'"'%'"'"' IDENTIFIED WITH mysql_native_password BY '"'"'change_this_password'"'"';\nFLUSH PRIVILEGES;\n' docker/mariadb/emailqueue_init.sql
validate "Updating MySQL initialization script"


###---------------------------------------------------------------------------
### 2025
###---------------------------------------------------------------------------
# Fix docker-compose.yml port mapping
sed -i 's/3316:3316/3316:3306/' docker/docker-compose.yml
validate "Updating Docker port mapping"


###---------------------------------------------------------------------------
### 2025
###---------------------------------------------------------------------------
# Update docker-compose.yml
cat > docker/docker-compose.yml << 'EOF'
version: "3.6"
services:
    emailqueue:
        image: trinv/emailqueue-apache:1.5.4
        container_name: emailqueue-apache
        build:
            context: .
            dockerfile: ./apache/Dockerfile
        ports:
            - 8081:443
            - 443:443
        networks:
            - emailqueue
        volumes:
            - ../application.config.inc.php:/var/www/BIRTHDAY_GOLD/emailqueue/config/application.config.inc.php
            - ../db.config.inc.php:/var/www/BIRTHDAY_GOLD/emailqueue/config/db.config.inc.php
            - /var/web_certs/BIRTHDAY_SERVER/birthday.gold:/etc/ssl/private:ro
        restart: unless-stopped
    emailqueue-mysql:
        image: mysql:8.0
        container_name: emailqueue-mysql
        environment:
            - MYSQL_ROOT_PASSWORD=change_this_password
            - MYSQL_DATABASE=emailqueue
        ports:
            - 3316:3306
        networks:
            - emailqueue
        volumes:
            - ./mysql/conf.d:/etc/mysql/conf.d
            - ./mysql/data:/var/lib/mysql
            - ./mariadb/emailqueue_init.sql:/docker-entrypoint-initdb.d/schema.sql:ro
        restart: unless-stopped
networks:
    emailqueue:
        name: emailqueue
EOF
validate "Updating docker-compose.yml"


###---------------------------------------------------------------------------
# Replace placeholders with the provided passwords
sed -i "s/__PUT_EMAILQUEUE_API_KEY_HERE__/$apikey/" application.config.inc.php
validate "Updating EmailQueue - API_KEY"

sed -i "s/__PUT_EMAILQUEUE_ADMIN_PASSWORD_HERE__/$adminpass/" application.config.inc.php
validate "Updating bgemailqueue_admin password"

sed -i "s/__PUT_POSTMASTER_PASSWORD_HERE__/$postmasterpass/" application.config.inc.php
validate "Updating emailqueue_postmaster@birthday.gold password"

echo "Configuration file updated successfully."


###---------------------------------------------------------------------------
# Define the directory for the certificates
cert_dir="/var/web_certs/BIRTHDAY_SERVER/birthday.gold"

# Create the directory if it doesn't exist
mkdir -p "$cert_dir"
validate "Creating directory $cert_dir"


###---------------------------------------------------------------------------
# Define the array with source and destination paths
files=(
    "/BIRTHDAY_SERVER/_CERTS_/birthday.gold/xfer/AAACertificateServices.crt:/var/web_certs/BIRTHDAY_SERVER/birthday.gold/AAACertificateServices.crt"
    "/BIRTHDAY_SERVER/_CERTS_/birthday.gold/xfer/SectigoRSADomainValidationSecureServerCA.crt:/var/web_certs/BIRTHDAY_SERVER/birthday.gold/SectigoRSADomainValidationSecureServerCA.crt"
    "/BIRTHDAY_SERVER/_CERTS_/birthday.gold/xfer/server.key:/var/web_certs/BIRTHDAY_SERVER/birthday.gold/server.key"
    "/BIRTHDAY_SERVER/_CERTS_/birthday.gold/xfer/STAR_birthday_gold.crt:/var/web_certs/BIRTHDAY_SERVER/birthday.gold/STAR_birthday_gold.crt"
    "/BIRTHDAY_SERVER/_CERTS_/birthday.gold/xfer/USERTrustRSAAAACA.crt:/var/web_certs/BIRTHDAY_SERVER/birthday.gold/USERTrustRSAAAACA.crt"
)


# Start FTP transfer
ftp -inv dev.birthday.gold <<EOF
user richard $ftppass
binary
$(for file in "${files[@]}"; do
    src="${file%%:*}"
    dest="${file##*:}"
    echo "get \"$src\" \"$dest\""
done)
bye
EOF
validate "Downloading certificates via FTP"

# Set permissions for the certificates
chmod 440 -R /var/web_certs/BIRTHDAY_SERVER
validate "Setting permissions for /var/web_certs/BIRTHDAY_SERVER"

chmod 400 /var/web_certs/BIRTHDAY_SERVER
validate "Setting permissions for /var/web_certs/BIRTHDAY_SERVER"

echo "Certificates downloaded and permissions set successfully."


###---------------------------------------------------------------------------
# copy cert files
mkdir -p ~/bg-emailqueue-docker/docker/var/web_certs/BIRTHDAY_SERVER/birthday.gold
cp /var/web_certs/BIRTHDAY_SERVER/birthday.gold/* ~/bg-emailqueue-docker/docker/var/web_certs/BIRTHDAY_SERVER/birthday.gold/.
echo "Copied Certificates into docker location."


###---------------------------------------------------------------------------
### 2025
###---------------------------------------------------------------------------
# Open the ports
ufw allow 3316/tcp
ufw allow 8081/tcp
ufw allow 443/tcp
validate "Open ports to EmailQueue"


###---------------------------------------------------------------------------
cd docker/
figlet "Ready to run"
figlet ""
echo "Ready for you to run:  docker-compose up -d"
