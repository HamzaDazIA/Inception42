#!bin/bash
set -e

if [ ! -f /etc/.firstrun ]; then

# generate ssl cetificate
mkdir -p /etc/nginx/ssl/
openssl req -x509 -nodes -days 365 -newkey rsa:4096  \
            -out /etc/nginx/ssl/cert.crt \
            -keyout /etc/nginx/ssl/cert.key \
            -subj "/CN=${DOMAIN_NAME}" >/dev/null 2>/dev/null

    touch /etc/.firstrun
fi

exec nginx -g 'daemon off;'