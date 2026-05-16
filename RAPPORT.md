# Rapport Inception — tout ce qu'il faut savoir pour défendre le projet

Ce document explique l'architecture, chaque choix technique, et comment
**t'approprier le projet** pour la soutenance. Le service custom est **Redis**
(cache objet WordPress), construit depuis ta propre image Debian.

---

## 1. Vue d'ensemble de l'infrastructure

```mermaid
flowchart TB
    Client["Navigateur<br/>https://sgil--de.42.fr"]

    subgraph HOST["Machine hôte (VM)"]
        subgraph NET["Réseau Docker : inception (bridge)"]
            NGINX["nginx<br/>:443 TLSv1.2/1.3<br/>(seul point d'entrée)"]
            WP["wordpress<br/>php-fpm :9000<br/>+ wp-cli"]
            DB["mariadb<br/>:3306"]
            REDIS["redis<br/>:6379<br/>(cache objet)"]
            ADM["adminer<br/>:8080 (bonus)"]
        end

        subgraph DATA["/home/sgil--de/data"]
            VWP[("wordpress_data<br/>/var/www/html")]
            VDB[("mariadb_data<br/>/var/lib/mysql")]
        end

        SEC[/"secrets/*.txt<br/>(hors git)"/]
    end

    Client -- "443" --> NGINX
    NGINX -- "fastcgi 9000" --> WP
    WP -- "3306" --> DB
    WP -- "6379" --> REDIS
    ADM -- "3306" --> DB

    WP --- VWP
    NGINX -. "lecture seule" .- VWP
    DB --- VDB
    SEC -. "/run/secrets" .-> DB
    SEC -. "/run/secrets" .-> WP
```

**Idée clé** : seul `nginx` est exposé à l'extérieur (port 443). Tout le reste
communique uniquement sur le réseau Docker interne `inception`.

---

## 2. Flux d'une requête (du navigateur à la base)

```mermaid
sequenceDiagram
    participant U as Navigateur
    participant N as nginx (443, TLS)
    participant W as wordpress (php-fpm 9000)
    participant R as redis (6379)
    participant D as mariadb (3306)

    U->>N: GET https://sgil--de.42.fr (TLSv1.2/1.3)
    N->>W: FastCGI (.php) vers wordpress:9000
    W->>R: Cache objet présent ?
    alt cache hit
        R-->>W: données en cache
    else cache miss
        W->>D: requête SQL
        D-->>W: résultat
        W->>R: stocke en cache
    end
    W-->>N: HTML généré
    N-->>U: réponse HTTPS
```

---

## 3. Cycle de vie / dépendances au démarrage

```mermaid
flowchart LR
    M["make"] --> S["setup : mkdir /home/sgil--de/data/*"]
    S --> B["docker compose build"]
    B --> U["docker compose up -d"]
    U --> DB["mariadb<br/>(init + users)"]
    DB -- "healthcheck OK" --> WP["wordpress<br/>(wp-cli install)"]
    U --> RE["redis"]
    RE --> WP
    WP --> NG["nginx<br/>(genère TLS + conf)"]
```

`wordpress` attend que `mariadb` soit **healthy** (`condition: service_healthy`)
et que `redis` soit démarré avant de lancer l'installation WordPress.

---

## 4. Détail de chaque service

| Service | Image (= nom service) | Base | Process PID 1 | Rôle |
|--------|----------------------|------|---------------|------|
| mariadb | `mariadb` | debian:12-slim | `mysqld --user=mysql` | Base de données |
| wordpress | `wordpress` | debian:12-slim | `php-fpm8.2 -F` | WordPress + PHP |
| nginx | `nginx` | debian:12-slim | `nginx -g 'daemon off;'` | Reverse proxy TLS |
| redis | `redis` | debian:12-slim | `redis-server` | Cache objet (bonus/custom) |
| adminer | `adminer` | debian:12-slim | `php -S` | GUI base (bonus) |

### mariadb
- Init **sans serveur temporaire ni `sleep`** : utilise `mysql_install_db`
  puis `mysqld --bootstrap` (lit du SQL puis se termine). Pas de boucle infinie.
- Crée la base, l'utilisateur applicatif et fixe le mot de passe root depuis
  les **secrets Docker** (`/run/secrets/...`).
- Tourne en root juste le temps de s'approprier le volume bind, puis
  `mysqld` **abandonne ses privilèges** vers l'utilisateur `mysql`.

### wordpress
- Installé/configuré **automatiquement** via `wp-cli` au premier démarrage :
  `wp core download` → `wp config create` → `wp core install`.
- **Deux utilisateurs** créés (exigence du sujet) :
  - admin : `WP_ADMIN_USER` (= `sgil-de`, **ne contient pas** `admin`).
  - second : `WP_USER` (rôle `author`).
- Branche **Redis** : constantes `WP_REDIS_HOST/PORT` dans `wp-config.php`,
  plugin `redis-cache` activé + `wp redis enable` (drop-in `object-cache.php`).
- Pas de nginx dans ce conteneur (php-fpm seul, écoute TCP 9000).

### nginx
- **Seul** conteneur exposé, **port 443 uniquement**, `TLSv1.2`/`TLSv1.3`.
- Certificat auto-signé généré au démarrage (`setup_ssl.sh`).
- Le domaine est injecté dans la conf via `envsubst` (`${DOMAIN_NAME}`),
  donc 0 valeur en dur, tout vient du `.env`.
- `entrypoint.sh` finit par `exec nginx -g 'daemon off;'` → nginx est PID 1.

### redis (service custom)
Voir section 7 dédiée.

### adminer (bonus)
Image **construite par nous** (Debian + php-cli + adminer.php servi par le
serveur web intégré de PHP). Accessible sur `http://localhost:8080`.

---

## 5. Volumes & secrets

```mermaid
flowchart LR
    subgraph Host
        H1["/home/sgil--de/data/mariadb"]
        H2["/home/sgil--de/data/wordpress"]
        F1["secrets/db_password.txt"]
        F2["secrets/db_root_password.txt"]
        F3["secrets/credentials.txt"]
    end
    subgraph Conteneurs
        C1["mariadb:/var/lib/mysql"]
        C2["wordpress:/var/www/html"]
        C3["nginx:/var/www/html (ro)"]
        S1["/run/secrets/db_password"]
        S2["/run/secrets/db_root_password"]
        S3["/run/secrets/wp_credentials"]
    end
    H1 --- C1
    H2 --- C2
    H2 -. ro .- C3
    F1 --> S1
    F2 --> S2
    F3 --> S3
```

- **Volumes nommés bind-backed** : déclarés comme volumes Docker nommés
  (`driver: local`, `driver_opts type=none,o=bind`) mais leurs données
  vivent dans `/home/sgil--de/data`. C'est la solution attendue par le sujet
  (volume nommé **ET** données dans `/home/login/data`).
- **Secrets** : fichiers texte hors git, montés en lecture seule dans
  `/run/secrets/`. Aucun mot de passe dans les Dockerfiles ni dans git.
- `credentials.txt` contient les mots de passe WordPress au format
  `WP_ADMIN_PASSWORD=...` / `WP_USER_PASSWORD=...`.

---

## 6. Notions à maîtriser pour la soutenance

### Machine virtuelle vs Docker
Une VM virtualise un **OS complet** (noyau inclus) via un hyperviseur :
lourd, lent à démarrer, isolation forte. Un conteneur Docker partage le
**noyau de l'hôte** et n'isole que les processus/fs/réseau : léger,
démarrage en secondes. Ici un conteneur ≠ une VM → pas de `tail -f`,
pas de boucle infinie, **un seul processus principal en PID 1**.

### Secrets vs variables d'environnement
Les variables d'env (`.env`) sont pratiques mais **visibles** (`docker
inspect`, logs, `/proc`). Les **secrets** sont des fichiers montés en
lecture seule, hors image et hors git → on y met **uniquement les mots de
passe**. Le `.env` ne contient que des valeurs non sensibles (domaine,
noms de base, logins).

### Réseau Docker vs réseau Host
`network: host` supprimerait l'isolation réseau (le conteneur utilise la
pile réseau de l'hôte) → **interdit** par le sujet. On crée un **réseau
bridge dédié** (`inception`) : les conteneurs se joignent par leur **nom de
service** (DNS interne Docker), et seul le port 443 de nginx est publié.

### Volumes Docker vs bind mounts
Un **bind mount** monte un chemin hôte arbitraire (fragile, dépend du
chemin). Un **volume nommé** est géré par Docker (cycle de vie clair). Le
sujet impose des volumes nommés *mais* avec les données dans
`/home/login/data` → on combine les deux via `driver_opts` (volume nommé
adossé à un bind contrôlé). Bind mount « brut » interdit pour ces 2 volumes.

---

## 7. Service custom : Redis (cache objet WordPress)

**Pourquoi Redis ?** WordPress recalcule beaucoup d'objets (options,
requêtes) à chaque page. Le *object cache* Redis garde ces résultats en
mémoire → moins de requêtes MariaDB, pages plus rapides. C'est un service
utile et facile à justifier en défense.

**Comment c'est branché :**

```mermaid
flowchart LR
    WP["wordpress<br/>plugin redis-cache<br/>object-cache.php"] -- "set/get :6379" --> R["redis<br/>maxmemory 64mb<br/>policy allkeys-lru"]
```

1. Image **construite** depuis `debian:12-slim` (pas d'image DockerHub) :
   [srcs/requirements/redis/Dockerfile](srcs/requirements/redis/Dockerfile).
2. Config dédiée [srcs/requirements/redis/conf/redis.conf](srcs/requirements/redis/conf/redis.conf) :
   - `save ""` + `appendonly no` → cache **volatil**, aucune persistance
     (donc pas de volume nécessaire).
   - `maxmemory 64mb` + `allkeys-lru` → mémoire bornée, éviction LRU.
   - `daemonize no` → `redis-server` reste au premier plan = **PID 1**.
3. Côté WordPress : extension PHP `php8.2-redis`, plugin `redis-cache`
   activé, constantes `WP_REDIS_HOST=redis` / `WP_REDIS_PORT=6379` posées
   dans `wp-config.php` par l'entrypoint, puis `wp redis enable`.

**Vérifier en soutenance :**
```bash
docker exec -it wordpress wp redis status --allow-root
docker exec -it redis redis-cli INFO keyspace
docker exec -it redis redis-cli MONITOR   # voir le trafic en direct
```

---

## 8. Utilisation

```bash
make            # crée les dossiers data, build, démarre (détaché)
make logs       # suivre les logs
make ps         # état des conteneurs
make down       # arrêter (garde les données)
make clean      # arrêter + supprimer les volumes
make fclean     # tout nettoyer (images + data hôte)
make re         # fclean puis relance
```

**Prérequis domaine** (sinon le navigateur n'atteint pas le site) :
ajouter dans `/etc/hosts` de la VM :
```
127.0.0.1   sgil--de.42.fr
```

Accès :
- Site : `https://sgil--de.42.fr` (certificat auto-signé → accepter l'alerte)
- Admin WP : `https://sgil--de.42.fr/wp-admin` (user `sgil-de`)
- Adminer : `http://localhost:8080` (serveur : `mariadb`)

---

## 9. Ce qui a été corrigé (avant → après)

| Problème | Avant | Après |
|---------|-------|-------|
| WordPress non installé | simple `wget` du core | wp-cli : install + 2 users + redis |
| Volumes hors `/home` | volumes nus | `driver_opts` → `/home/sgil--de/data` |
| Secrets vides + commités | fichiers 0 octet, suivis git | remplis + `git rm --cached` |
| Domaine absent | `server_name localhost` | `${DOMAIN_NAME}` via envsubst + `.env` |
| Noms d'images | `inception_xxx:1.0.0` | `mariadb`, `wordpress`, `nginx`... |
| `.env` à la racine | `../.env` | `srcs/.env` (arbo conforme) |
| Healthcheck nginx | `curl -f` (échoue) | `curl -fk` |
| PID 1 nginx | `sh -c "... && nginx"` | `exec nginx` via entrypoint |
| redis/adminer | images DockerHub | Dockerfiles maison |
| MariaDB init | serveur temp + `sleep` | `mysqld --bootstrap` (propre) |

---

## 10. Questions probables en défense (et réponses)

- **« Pourquoi pas une image WordPress toute faite ? »** — Le sujet
  l'interdit ; on construit nos images depuis Debian 12 (avant-dernière
  stable).
- **« Pourquoi `mysqld --bootstrap` et pas un `sleep` ? »** — Un conteneur
  n'est pas une VM ; pas de hack/boucle. `--bootstrap` exécute le SQL
  d'init puis rend la main, et le process final `mysqld` est PID 1.
- **« Où sont les mots de passe ? »** — Dans `secrets/*.txt`, hors git,
  montés dans `/run/secrets`. Rien en dur, rien dans `.env`.
- **« Pourquoi deux réseaux... non, un réseau ? »** — Un seul réseau bridge
  `inception` suffit, isolation interne, résolution DNS par nom de service,
  seul 443 publié.
- **« Le volume est-il un bind mount ? »** — Non, c'est un **volume nommé**
  Docker ; `driver_opts` le fait simplement pointer vers
  `/home/sgil--de/data` comme l'exige le sujet.
- **« Domaine ? »** — `sgil--de.42.fr` → `127.0.0.1` via `/etc/hosts`,
  injecté dans la conf nginx par `envsubst`.
