# Use an official PHP Apache runtime

FROM php:8.2-apache

# Enable Apache modules

RUN apt-get update && apt-get install -y libapache2-mod-auth-openidc

RUN a2enmod rewrite
RUN a2enmod auth_openidc

# Install PostgreSQL client and its PHP extensions

RUN apt-get update \
    && apt-get install -y libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql
# Set the working directory to /var/www/html

WORKDIR /var/www/html

# Copy the PHP code file in /app into the container at /var/www/html

COPY app/index.php index.php

# Copy apache config with oidc settings

COPY 000-default.conf  /etc/apache2/sites-enabled/000-default.conf 
