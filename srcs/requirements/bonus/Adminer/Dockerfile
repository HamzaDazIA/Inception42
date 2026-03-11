FROM debian:bookworm

RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install php php-mysql wget -y && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

RUN wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php -O /var/www/html/index.php
RUN chmod 755 /var/www/html/index.php
RUN chown -R www-data:www-data /var/www/html

EXPOSE 8080

ENTRYPOINT ["php", "-S", "[::]:8080", "-t", "/var/www/html"]