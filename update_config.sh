#!/bin/bash

# Function to validate commands
validate() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    else
        echo "Success: $1"
    fi
}

figlet "Starting Config"

# Copy the example config file
cp application.config.inc.php.example application.config.inc.php
validate "Copying application.config.inc.php.example to application.config.inc.php"



###---------------------------------------------------------------------------
# Prompt for EmailQueue - API_KEY password
read -sp "Enter EmailQueue - API_KEY: " apikey
echo

# Replace the placeholder with the provided password
sed -i "s/__PUT_EMAILQUEUE_API_KEY_HERE__/$apikey/" application.config.inc.php
validate "Updating EmailQueue - API_KEY"



###---------------------------------------------------------------------------
# Prompt for bgemailqueue_admin password
read -sp "Enter bgemailqueue_admin password: " adminpass
echo

# Replace the placeholder with the provided password
sed -i "s/__PUT_EMAILQUEUE_ADMIN_PASSWORD_HERE__/$adminpass/" application.config.inc.php
validate "Updating bgemailqueue_admin password"


###---------------------------------------------------------------------------
# Prompt for postmaster@birthday.gold password
read -sp "Enter emailqueue_postmaster@birthday.gold password: " postmasterpass
echo

# Replace the placeholder with the provided password
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

# Prompt for FTP password
read -sp "Enter FTP password: " ftppass
echo

# Start FTP transfer
ftp -inv dev4.birthday.gold <<EOF
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
