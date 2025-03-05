FROM php:8.3-apache
COPY . /var/www/html/helmet_shop/
RUN docker-php-ext-install mysqli pdo pdo_mysql
EXPOSE 80