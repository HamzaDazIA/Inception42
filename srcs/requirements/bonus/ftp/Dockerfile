FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf

RUN mkdir -p /var/run/vsftpd/empty

COPY tools/ftp.sh /usr/bin/ftp.sh
RUN chmod +x /usr/bin/ftp.sh


CMD ["/usr/bin/ftp.sh"]
