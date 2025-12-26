FROM php:8.2-cli

RUN apt-get update && apt-get install -y \
git \
unzip \
libzip-dev \
sqlite3 \
&& docker-php-ext-install zip

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html