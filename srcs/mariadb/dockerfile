FROM debian:bookworm

RUN apt-get -y update && apt-get -y upgrade && apt install -y mariadb-server

COPY conf/mariadb.conf /etc/mysql/mariadb.conf.d/99-mariadb.cnf 

COPY --chmod=755 tools/mariadb.sh /usr/bin

ENTRYPOINT ["mariadb.sh"]