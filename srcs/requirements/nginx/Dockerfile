FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		nginx openssl curl gettext-base \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html /etc/nginx/ssl /var/log/nginx

COPY conf.d/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY tools/setup_ssl.sh           /usr/local/bin/setup_ssl.sh
COPY tools/entrypoint.sh          /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/setup_ssl.sh /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
