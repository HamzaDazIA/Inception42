#!/bin/bash
set -e 

until mysqladmin ping -h "mariadb" --silent; do
    echo "Waiting for MariaDB to be available..."
    sleep 2
done

[ -f "/run/secrets/db_password" ] && export DB_PASSWORD=$(cat /run/secrets/db_password)
[ -f "/run/secrets/wordpress_admin_password" ] && export WP_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
[ -f "/run/secrets/db_root_password" ] && export DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
[ -f "/run/secrets/wordpress_password" ] && export WP_PASSWORD=$(cat /run/secrets/wordpress_password)

if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Start initialization WordPress ... "

    wp core download --path=/var/www/html --allow-root > /dev/null

    wp config create --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbhost=mariadb:3306 \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --allow-root
    
    wp core install --path=/var/www/html --allow-root \
        --skip-email \
        --url="$DOMAIN_NAME" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL"

    wp user create --allow-root \
        "$WORDPRESS_USER" \
        "$WORDPRESS_EMAIL" \
        --user_pass="$WP_PASSWORD" \
        --role=author
    
    echo "WordPress step completed"
else
    echo "Wordpress is already initialized"
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F