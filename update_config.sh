#!/bin/bash

# Copy the example config file
cp application.config.inc.php.example application.config.inc.php

# Prompt for bgemailqueue_admin password
read -sp "Enter bgemailqueue_admin password: " adminpass
echo

# Replace the placeholder with the provided password
sed -i "s/__PUT_EMAILQUEUE_ADMIN_PASSWORD_HERE__/$adminpass/" application.config.inc.php

# Prompt for postmaster@birthday.gold password
read -sp "Enter postmaster@birthday.gold password: " postmasterpass
echo

# Replace the placeholder with the provided password
sed -i "s/__PUT_POSTMASTER_PASSWORD_HERE__/$postmasterpass/" application.config.inc.php

echo "Configuration file updated successfully."
