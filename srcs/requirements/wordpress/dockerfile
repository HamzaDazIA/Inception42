FROM debian:bookworm

RUN apt-get update -y && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php-redis \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY --chmod=755 tools/wordpress.sh /usr/bin/wordpress.sh

RUN mkdir -p /run/php /var/www/html

WORKDIR /var/www/html

EXPOSE 9000
ENTRYPOINT ["/usr/bin/wordpress.sh"]