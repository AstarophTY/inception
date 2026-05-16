FROM debian:12-slim

ARG GITEA_VERSION=1.22.1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates curl git sqlite3 \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /data/git -s /bin/bash git

RUN curl -fsSL -o /usr/local/bin/gitea \
	https://dl.gitea.com/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64 \
	&& chmod +x /usr/local/bin/gitea

RUN mkdir -p /data /data/gitea/conf \
	&& chown -R git:git /data

ENV USER=git
ENV HOME=/data/git
ENV GITEA_WORK_DIR=/data
ENV GITEA_CUSTOM=/data/gitea

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000

USER git

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
