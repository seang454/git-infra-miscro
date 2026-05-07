FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock* ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-scripts
COPY . .
RUN composer dump-autoload --optimize

FROM php:8.3-apache
WORKDIR /var/www/html
RUN docker-php-ext-install pdo pdo_mysql
COPY --from=vendor /app ./
RUN a2enmod rewrite
EXPOSE 80
