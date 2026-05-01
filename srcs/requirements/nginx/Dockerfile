FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends nginx openssl curl \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html /etc/nginx/ssl /var/log/nginx

COPY conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY tools/setup_ssl.sh /usr/local/bin/setup_ssl.sh
RUN chmod +x /usr/local/bin/setup_ssl.sh

EXPOSE 443

VOLUME ["/var/www/html","/etc/nginx/ssl"]

CMD ["/bin/sh","-c","/usr/local/bin/setup_ssl.sh && nginx -g 'daemon off;'"]
