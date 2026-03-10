#!/bin/bash

set -e 

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    echo "Start initialization Mariadb ... " 

    [ -f "/run/secrets/db_root_password" ] && export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    [ -f "/run/secrets/db_password" ] && export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mariadbd --user=mysql --bootstrap << EOF

FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY  '$MYSQL_ROOT_PASSWORD';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
    echo "MariaDB initialized successfully!"
else 
    echo "MariaDB database already exists. Skipping initialization."
fi

exec mariadbd -u mysql
