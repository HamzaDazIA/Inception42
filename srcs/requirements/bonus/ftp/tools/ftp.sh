#!/bin/bash

set -e

if [ ! -f /etc/.firstrun ]; then

	[ -f /run/secrets/ftp_password ] && export FTP_PASSWORD=$(cat /run/secrets/ftp_password)

	useradd -m "$FTP_USER"
	echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
	chown -R "$FTP_USER" /var/www/html

	touch /etc/.firstrun

fi

exec vsftpd /etc/vsftpd.conf