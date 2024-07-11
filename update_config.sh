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
    echo "apikey=$apikey" > "$PASSWORD_FILE"
    echo "adminpass=$adminpass" >> "$PASSWORD_FILE"
    echo "postmasterpass=$postmasterpass" >> "$PASSWORD_FILE"
    echo "ftppass=$ftppass" >> "$PASSWORD_FILE"
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
