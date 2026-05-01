# Developer Documentation

This document details how the repository is organized and guidelines to implement or improve service Dockerfiles.

Structure:
- `srcs/docker-compose.yml` : compose file to build services (templates and constraints are applied)
- `srcs/requirements/nginx` : nginx Dockerfile, conf and tools (SSL helper)
- `srcs/requirements/mariadb` : mariadb Dockerfile and configuration
- `srcs/requirements/wordpress` : WordPress + php-fpm Dockerfile and configuration

Guidelines & constraints (42 Inception):
- Use only Debian or Alpine base images for custom images.
- Do not use `latest` tags for images.
- No `host` network mode.
- Do not run processes with `tail -f` / infinite loops; set proper PID 1.
- Use Docker secrets for any sensitive passwords.
- Expose only necessary ports; `nginx` is the only public-facing service (HTTPS).

Building & developing Dockerfiles:
- Implement services to run as non-root users where possible.
- Keep image layers small: combine apt-get update && apt-get install && rm -rf /var/lib/apt/lists/* in single RUN.
- Add `HEALTHCHECK` directives to Dockerfiles for production readiness where applicable.

Testing locally:
- Use the provided `Makefile` targets to build and run the stack.
