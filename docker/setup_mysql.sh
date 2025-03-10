#!/bin/bash

# Extract numeric part from hostname
numeric_part=$(hostname | grep -o -E '[0-9]+')
server_id=3${numeric_part}
rm -rf replication.cnf

# Create the replication configuration
echo -e "[mysqld]\nserver_id=${server_id}\nlog_bin=mysql-bin\ngtid_mode=ON\nenforce-gtid-consistency=ON\nbinlog-format=ROW\nport=3316\nbind-address=0.0.0.0" > replication.cnf


# Print the generated file for verification
cat replication.cnf