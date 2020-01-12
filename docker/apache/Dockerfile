FROM php:7.3-apache

# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Additional PHP packages
RUN docker-php-ext-install mysqli opcache

# Install git
RUN apt-get update &&\
    apt-get install \
	git \
    -y

# Install app from official git repository
RUN git clone https://github.com/tin-cat/emailqueue.git /emailqueue
# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# Get composer packages
RUN composer --working-dir=/emailqueue update

# Setup apache serving paths
ENV APACHE_DOCUMENT_ROOT /emailqueue
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Configure PHP to use a specific timezone
RUN printf '[PHP]\ndate.timezone = "UTC"\n' > /usr/local/etc/php/conf.d/tzone.ini

# Create db configuration file
RUN echo "<?php\n" \   
	"namespace Emailqueue;\n" \
	"define(\"EMAILQUEUE_DB_HOST\", \"mariadb\");\n" \
	"define(\"EMAILQUEUE_DB_UID\", \"root\");\n" \
	"define(\"EMAILQUEUE_DB_PWD\", false);\n" \
	"define(\"EMAILQUEUE_DB_DATABASE\", \"emailqueue\");\n" \
	"?>" > /emailqueue/config/db.config.inc.php

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

CMD ( cron -f & ) && apache2-foreground 