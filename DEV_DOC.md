# Developer Documentation

## Set up the environment from scratch

Prerequisites: a Virtual Machine with Docker Engine + Docker Compose, and
the `make` tool.

1. **Environment file** — copy and adapt:
   ```bash
   cp .env.example srcs/.env
   ```
   `srcs/.env` holds only non-sensitive values (domain, DB/site names,
   logins, redis host). It is git-ignored.

2. **Secrets** — three files under `secrets/` (git-ignored, created locally):
   ```bash
   openssl rand -base64 18 | tr -d '/+=' > secrets/db_root_password.txt
   openssl rand -base64 18 | tr -d '/+=' > secrets/db_password.txt
   printf 'WP_ADMIN_PASSWORD=%s\nWP_USER_PASSWORD=%s\n' \
       "$(openssl rand -base64 18 | tr -d '/+=')" \
       "$(openssl rand -base64 18 | tr -d '/+=')" > secrets/credentials.txt
   chmod 600 secrets/*.txt
   ```

3. **Domain** — `echo "127.0.0.1 sgil--de.42.fr" | sudo tee -a /etc/hosts`.

## Build and launch (Makefile + Docker Compose)

```bash
make            # setup (host data dirs) -> build -> up -d
make build      # build images only
make up         # start
make logs       # follow logs
make re         # fclean + rebuild
```

`make` runs `docker compose` from `srcs/` (compose file:
`srcs/docker-compose.yml`). Each service builds its own Dockerfile under
`srcs/requirements/<service>/`. Images are named exactly like their service.

## Manage containers and volumes

```bash
make ps                         # status
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker volume ls                # mariadb_data, wordpress_data
docker network inspect srcs_inception
make clean                      # remove containers + volumes
```

## Where the data is stored and how it persists

- `wordpress_data` → host `/home/sgil--de/data/wordpress`
  (mounted at `/var/www/html`).
- `mariadb_data` → host `/home/sgil--de/data/mariadb`
  (mounted at `/var/lib/mysql`).

Both are **named volumes** declared with `driver_opts` (`type=none`,
`o=bind`) so Docker manages them while the bytes physically live under
`/home/sgil--de/data`. The Makefile `setup` target creates these
directories before the first build. Data survives `make down`/`up`; it is
destroyed by `make clean`/`fclean`. Redis holds only a volatile cache
(no volume, no persistence).

## Repository layout

```
.
├── Makefile
├── secrets/                 (git-ignored)
├── srcs/
│   ├── .env                 (git-ignored)
│   ├── docker-compose.yml
│   └── requirements/
│       ├── mariadb/   (Dockerfile + docker-entrypoint.sh)
│       ├── wordpress/ (Dockerfile + docker-entrypoint.sh)
│       ├── nginx/     (Dockerfile + conf.d/ + tools/)
│       ├── redis/     (Dockerfile + conf/redis.conf)
│       └── adminer/   (Dockerfile)
└── RAPPORT.md / README.md / USER_DOC.md / DEV_DOC.md
```
