FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		php8.2-cli php8.2-mysqli wget ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN wget -q "https://www.adminer.org/latest.php" \
		-O /var/www/adminer.php

WORKDIR /var/www

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "adminer.php"]
