FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates curl \
		php8.2-fpm php8.2-cli php8.2-mysql php8.2-xml php8.2-mbstring \
		php8.2-curl php8.2-gd php8.2-zip php8.2-redis mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

RUN sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf \
	&& sed -i 's|^;clear_env = no|clear_env = no|' /etc/php/8.2/fpm/pool.d/www.conf \
	&& mkdir -p /run/php

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
		-o /usr/local/bin/wp \
	&& chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

EXPOSE 9000

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
