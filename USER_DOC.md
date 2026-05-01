 # User Documentation
 
 This document explains how to run the project locally and the security considerations.
 
 Prerequisites:
 - Docker Engine and Docker Compose
 
 Quick start (development):
 1. Copy `.env` and customize values if needed.
 2. Put secure passwords into `secrets/db_password.txt` and `secrets/db_root_password.txt` (one line each). Ensure these files are not committed.
 3. From the project root run:
 
 ```bash
 cd srcs
 docker compose build
 docker compose up -d
 ```
 
 Access:
 - HTTPS site: https://localhost (nginx listens only on 443)
 - Adminer: http://localhost:8080 (optional)
 
 Security notes:
 - TLS keys should never be committed. Use `srcs/requirements/nginx/tools/setup_ssl.sh` to generate local self-signed certs for testing, or mount production certs via Docker secrets.
 - Use Docker secrets for database passwords in production.
