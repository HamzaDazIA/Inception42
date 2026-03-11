#!/bin/bash

set -e

if  ! id "$FTP_USER" &>/dev/null ; then
    useradd -d /var/www/hhml -s /usr/sbin/nologin $FTP_USER

    [ -f /run/secrets/FTP_PASSWORD ] && export FTP_PASSWORD=$(cat /run/secrets/ftp_password)
    
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

    usermod -aG www-data $FTP_USER

    chown -R $FTP_USER:www-data /var/www/html

    echo "FTP user $FTP_USER created and configured."
else 
    echo "FTP user $FTP_USER already exists."
fi

exec vsftpd /etc/vsftpd.conf