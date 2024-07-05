# Use the PHP Apache image
FROM php:7.3-apache

# Move PHP ini configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Additional PHP packages
RUN docker-php-ext-install mysqli opcache

# Install git and ssl module
RUN apt-get update && \
    apt-get install -y git && \
    a2enmod ssl && \
    a2ensite default-ssl

# Ensure the directory exists and clone the specified emailqueue repository
RUN mkdir -p /var/www/BIRTHDAY_GOLD/emailqueue && \
    git clone https://github.com/tin-cat/emailqueue.git /var/www/BIRTHDAY_GOLD/emailqueue

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Get composer packages
RUN composer --working-dir=/var/www/BIRTHDAY_GOLD/emailqueue update

# Setup apache serving paths
ENV APACHE_DOCUMENT_ROOT /var/www/BIRTHDAY_GOLD/emailqueue
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Configure PHP to use a specific timezone
RUN printf '[PHP]\ndate.timezone = "UTC"\n' > /usr/local/etc/php/conf.d/tzone.ini

# Create db configuration file
RUN echo "<?php\n" \
    "namespace Emailqueue;\n" \
    "define(\"EMAILQUEUE_DB_HOST\", \"emailqueue-mysql\");\n" \
    "define(\"EMAILQUEUE_DB_UID\", \"root\");\n" \
    "define(\"EMAILQUEUE_DB_PWD\", false);\n" \
    "define(\"EMAILQUEUE_DB_DATABASE\", \"emailqueue\");\n" \
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

# Update the default SSL configuration to point to the mounted certificates
RUN sed -i 's|SSLCertificateFile.*|SSLCertificateFile /etc/ssl/private/STAR_birthday_gold.crt|' /etc/apache2/sites-available/default-ssl.conf && \
    sed -i 's|SSLCertificateKeyFile.*|SSLCertificateKeyFile /etc/ssl/private/server.key|' /etc/apache2/sites-available/default-ssl.conf

# Enable SSL configuration in Apache
RUN a2enmod ssl
RUN a2ensite default-ssl
RUN service apache2 restart

# Run Apache and cron
CMD ( cron -f & ) && apache2-foreground
