#!/bin/bash

# Extract numeric part from hostname
numeric_part=$(hostname | grep -o -E '[0-9]+')
server_id=3${numeric_part}

# Create the replication configuration
echo -e "[mysqld]\nserver_id=${server_id}\nlog_bin=mysql-bin\ngtid_mode=ON\nenforce-gtid-consistency=ON\nbinlog-format=ROW\nport=3316\nbind-address=0.0.0.0" > /etc/mysql/conf.d/replication.cnf

# Start MySQL service
service mysql start

# Wait for MySQL to be ready
until mysqladmin ping -hlocalhost --silent; do
    sleep 1
done

# Create users and grant privileges
mysql -uroot -e "CREATE USER 'bgdbreplicator1'@'%' IDENTIFIED BY 'change_this_password'; GRANT REPLICATION SLAVE ON *.* TO 'bgdbreplicator1'@'%';"
mysql -uroot -e "CREATE USER 'birthday_gold_admin'@'%' IDENTIFIED BY 'change_this_password'; GRANT ALL ON *.* TO 'birthday_gold_admin'@'%' WITH GRANT OPTION;"

# Stop MySQL service
#service mysql stop
