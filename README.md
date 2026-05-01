# Inception - 42 School Project

This repository contains a Docker-based deployment for the Inception project (42 school).

Goals applied in this fork:
- Remove committed secrets (TLS keys, DB passwords) and use Docker secrets and `.env` placeholders.
- Provide a secure `docker-compose.yml` template using build contexts (no `latest` for project images).
- Add documentation and Makefile helper for building and running the stack.

High-level architecture:
- `nginx` (reverse proxy, TLS) — single HTTPS entrypoint
- `wordpress` (PHP-FPM) — built from `srcs/requirements/wordpress`
- `mariadb` — built from `srcs/requirements/mariadb` with persistent volume
- `redis` (optional cache)
- `adminer` (optional DB GUI)

See `USER_DOC.md` and `DEV_DOC.md` for usage and development details.