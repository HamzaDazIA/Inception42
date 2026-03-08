#!/bin/bash

set -e 

if [ ! -d "/var/lib/mysql/$MARIADB_DATABASE" ]; then
    echo "Start initialization Mariadb ... " 

    [ -f "/run/secrets/mariadb_root_password" ] && export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mariadb_root_password)
    [ -f "/run/secrets/mariadb_password" ] && export MYSQL_PASSWORD=$(cat /run/secrets/mariadb_password)

    mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mariadbd --user=mysql --bootstrap << EOF

FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\`;
CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MARIADB_DATABASE\`.* TO '$MARIADB_USER'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY  '$MYSQL_ROOT_PASSWORD';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
    echo "MariaDB initialized successfully!"
else 
    echo "MariaDB database already exists. Skipping initialization."
fi

exec mariadbd -u mysql
