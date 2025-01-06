# Use the latest MySQL 8 image
FROM mysql:8.0 as mysql

# Use the PHP Apache image
FROM php:7.3-apache

# Copy MySQL client configuration
COPY --from=mysql /etc/mysql /etc/mysql

# Move PHP ini configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Additional PHP packages
RUN docker-php-ext-install mysqli opcache

# Install necessary tools and Apache2 with SSL
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-ssl \
    git \
    unzip \
    apt-utils \
    socat \
    default-mysql-client \
    nano && \
    a2enmod ssl

# Install Apache2
RUN apt-get install apache2 -y

# Ensure the directory exists and clone the specified emailqueue repository
RUN if [ -d "/var/www/BIRTHDAY_GOLD/emailqueue" ]; then \
        rm -rf /var/www/BIRTHDAY_GOLD/emailqueue; \
    fi && \
    mkdir -p /var/www/BIRTHDAY_GOLD/emailqueue && \
    git clone https://github.com/ddgconsultant/emailqueue.git /var/www/BIRTHDAY_GOLD/emailqueue

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Get composer packages
RUN composer --working-dir=/var/www/BIRTHDAY_GOLD/emailqueue update

# Setup apache serving paths
ENV APACHE_DOCUMENT_ROOT /var/www/BIRTHDAY_GOLD/emailqueue
#RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
#RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" /etc/apache2/sites-available/*.conf
RUN sed -i "s|/var/www/|${APACHE_DOCUMENT_ROOT}|g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Configure PHP to use a specific timezone
RUN printf '[PHP]\ndate.timezone = "UTC"\n' > /usr/local/etc/php/conf.d/tzone.ini

# Create db configuration file
RUN echo "<?php\n" \
    "namespace Emailqueue;\n" \
    "define(\"EMAILQUEUE_DB_HOST\", \"emailqueue-mysql\");\n" \
    "define(\"EMAILQUEUE_DB_UID\", \"root\");\n" \
    "define(\"EMAILQUEUE_DB_PWD\", false);\n" \
    "define(\"EMAILQUEUE_DB_DATABASE\", \"emailqueue\");\n" \
	"define(\"EMAILQUEUE_DB_PORT\", 3316);\n" \
    "?>" > /var/www/BIRTHDAY_GOLD/emailqueue/config/db.config.inc.php

# Install cron
RUN apt-get update && apt-get -y install cron

# Add crontab file in the cron directory
ADD apache/cronjobs /etc/cron.d/cronjobs

# Give execution rights on the cron job
RUN chmod u=rwx,g=rx,o=rx /etc/cron.d/cronjobs

# Add crontab
RUN crontab -u root /etc/cron.d/cronjobs

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Copy the SSL cert file into the container
RUN mkdir -p /etc/ssl/private
COPY STAR_birthday_gold.crt /etc/ssl/private/STAR_birthday_gold.crt
COPY server.key /etc/ssl/private/server.key

RUN chmod +x /etc/ssl/private/STAR_birthday_gold.crt
RUN chmod +x /etc/ssl/private/server.key

# Update the default SSL configuration to point to the mounted certificates
RUN sed -i "s|SSLCertificateFile.*|SSLCertificateFile /etc/ssl/private/STAR_birthday_gold.crt|g" /etc/apache2/sites-available/default-ssl.conf
RUN sed -i "s|SSLCertificateKeyFile.*|SSLCertificateKeyFile /etc/ssl/private/server.key|g" /etc/apache2/sites-available/default-ssl.conf

# Enable SSL configuration in Apache
RUN a2ensite default-ssl

# Create a startup script to dynamically set server_id, create users, and configure MySQL for external access
# RUN echo "#!/bin/bash\n" \
#     "numeric_part=\$(hostname | grep -o -E '[0-9]+')\n" \
#     "server_id=3\${numeric_part}\n" \
#     "echo -e \"[mysqld]\\nserver_id=\${server_id}\\nlog_bin=mysql-bin\\ngtid_mode=ON\\nenforce-gtid-consistency=ON\\nbinlog-format=ROW\\nport=3316\\nbind-address=0.0.0.0\" > /etc/mysql/conf.d/replication.cnf\n" \
#     "service mysql start\n" \
#     "until mysqladmin ping -hlocalhost --silent; do\n" \
#     "    sleep 1\n" \
#     "done\n" \
#     "mysql -uroot -e \"CREATE USER 'bgdbreplicator1'@'%' IDENTIFIED BY 'change_this_password'; GRANT REPLICATION SLAVE ON *.* TO 'bgdbreplicator1'@'%';\"\n" \
#     "mysql -uroot -e \"CREATE USER 'birthday_gold_admin'@'%' IDENTIFIED BY 'change_this_password'; GRANT ALL ON *.* TO 'birthday_gold_admin'@'%' WITH GRANT OPTION;\"\n" \
#     "service mysql stop\n" > ~/setup_mysql.sh

#RUN chmod +x setup_mysql.sh
#RUN ./setup_mysql.sh

# Copy the setup script into the container
COPY setup_mysql.sh /usr/local/bin/setup_mysql.sh

# Make sure the script is executable
RUN chmod +x /usr/local/bin/setup_mysql.sh

# Expose port 3316 for external MySQL access
EXPOSE 3316

# Run the startup script and start Apache
ENTRYPOINT service mysql start && socat TCP-LISTEN:3316,fork TCP:localhost:3306 & /usr/local/bin/setup_mysql.sh && ( cron -f & ) && apache2-foreground

#ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/setup_mysql.sh && exec docker-entrypoint.sh mysqld"]
