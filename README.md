*This project has been created as part of the 42 curriculum by sgil--de.*

# Inception

## Description

Inception is a system administration project. It builds a small Docker
infrastructure made of dedicated containers — **NGINX** (TLS reverse proxy),
**WordPress + php-fpm**, **MariaDB** — plus bonus services (**Redis** object
cache, **Adminer**). Every image is built from scratch from the penultimate
stable Debian, orchestrated with Docker Compose and a Makefile. NGINX is the
only entrypoint, exposed on port 443 with TLSv1.2/TLSv1.3 only.

## Instructions

Prerequisites: Docker Engine + Docker Compose, run inside a Virtual Machine.

```bash
# 1. Copy and adapt the environment file
cp .env.example srcs/.env

# 2. Map the domain to localhost (on the VM)
echo "127.0.0.1 sgil--de.42.fr" | sudo tee -a /etc/hosts

# 3. Build and start everything
make
```

Then open `https://sgil--de.42.fr`. Useful targets: `make logs`, `make ps`,
`make down`, `make clean`, `make fclean`, `make re`.
See `USER_DOC.md` (end users) and `DEV_DOC.md` (developers).

## Resources

- Docker docs — https://docs.docker.com/
- Docker Compose — https://docs.docker.com/compose/
- WP-CLI — https://wp-cli.org/
- NGINX + php-fpm (FastCGI) — https://nginx.org/en/docs/
- MariaDB Docker init — https://mariadb.com/kb/en/
- Redis object cache for WordPress — https://wordpress.org/plugins/redis-cache/

**Use of AI:** AI was used as an assistant to audit the project against the
subject, refactor the service Dockerfiles/entrypoints (WordPress wp-cli
automation, MariaDB bootstrap, NGINX envsubst), wire the Redis object cache,
and draft the documentation. Every generated change was reviewed, tested via
`docker compose config`, and is fully understood by the author.

## Project description

Docker is used to run each service in its **own container** from a
**self-built image** (Debian 12, the penultimate stable). The Makefile calls
`docker compose` which builds the Dockerfiles in `srcs/requirements/*`.
Persistent data lives in named volumes backed by `/home/sgil--de/data`.
Passwords are provided as Docker secrets; non-sensitive values via `.env`.

Main design choices and comparisons:

- **Virtual Machines vs Docker** — A VM virtualizes a full OS (own kernel)
  through a hypervisor: heavy, strong isolation, slow boot. A container
  shares the host kernel and isolates only processes/fs/network: lightweight,
  starts in seconds. Hence one process as PID 1, no `tail -f`/infinite loop.
- **Secrets vs Environment Variables** — Env vars are convenient but visible
  (`docker inspect`, logs). Secrets are read-only files mounted at
  `/run/secrets`, kept out of the image and git. Only passwords are secrets;
  the `.env` holds non-sensitive config.
- **Docker Network vs Host Network** — `network: host` removes network
  isolation and is forbidden. A dedicated bridge network (`inception`) lets
  containers reach each other by service name; only port 443 is published.
- **Docker Volumes vs Bind Mounts** — A raw bind mount is fragile and
  forbidden for the two required volumes. Named volumes are managed by
  Docker; here `driver_opts` makes them store data under
  `/home/sgil--de/data` as required.
