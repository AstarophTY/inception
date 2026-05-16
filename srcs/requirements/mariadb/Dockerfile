FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends mariadb-server mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld /var/lib/mysql \
	&& chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

EXPOSE 3306

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
