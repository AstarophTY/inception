FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates wget unzip php8.2-fpm php-mysql php-xml php-mbstring php-curl php-gd php-zip \
	&& rm -rf /var/lib/apt/lists/*

RUN sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf \
	&& sed -i 's|^;clear_env = no|clear_env = no|' /etc/php/8.2/fpm/pool.d/www.conf

RUN useradd -r -u 1000 www && mkdir -p /var/www/html && chown -R www:www /var/www/html

WORKDIR /var/www/html

VOLUME ["/var/www/html"]

EXPOSE 9000

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

CMD ["/usr/local/bin/docker-entrypoint.sh"]
