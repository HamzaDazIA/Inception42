FROM debian:bookworm

RUN apt-get update && apt-get -y upgrade && apt-get -y install nginx openssl

COPY conf/nginx.conf /etc/nginx/sites-available/default

COPY --chmod=755 tools/nginx.sh /usr/bin/nginx.sh

EXPOSE 443

ENTRYPOINT ["nginx.sh"]