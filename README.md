*This project has been created as part of the 42 curriculum by hdazia.*

# Inception

## Table of Contents

- [Description](#description)
- [Project Description](#project-description)
  - [Virtual Machines vs Docker](#virtual-machines-vs-docker)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
  - [Docker Network vs Host Network](#docker-network-vs-host-network)
  - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
- [Architecture](#architecture)
- [Services](#services)
- [Instructions](#instructions)
- [Resources](#resources)

---

## Description

Inception is a system administration project from the 42 curriculum. The goal is to set up a small infrastructure composed of multiple services running inside **Docker containers**, all orchestrated with **Docker Compose** inside a virtual machine.

The infrastructure includes:

- **NGINX** — the sole entry point, serving as a reverse proxy with TLSv1.2/TLSv1.3 encryption on port 443.
- **WordPress** — a CMS powered by PHP-FPM 8.2, installed and configured automatically via WP-CLI.
- **MariaDB** — the relational database backend for WordPress.

In addition, the following **bonus services** extend the infrastructure:

- **Redis** — in-memory object cache for WordPress.
- **Adminer** — a lightweight web UI for database management.
- **vsftpd (FTP)** — FTP access to the WordPress files volume.
- **Static website** — a simple HTML page served by Lighttpd.
- **cAdvisor** — a container monitoring dashboard by Google.

Every container is built from **Debian Bookworm** — no pre-built images from Docker Hub are used. Sensitive credentials are handled via Docker secrets (never hardcoded), and persistent data is stored on bind-mounted host volumes.

---

## Project Description

### Why Docker?

This project uses **Docker** to containerize each service into its own isolated environment. Docker Compose orchestrates the multi-container setup, defining networks, volumes, secrets, and dependencies declaratively in a single `docker-compose.yml` file. Each service has its own `Dockerfile` that builds from `debian:bookworm`, installs only the required packages, and runs a custom entrypoint script.

The sources included in the project are:

| Service    | Key Software                  | Source / Origin                                   |
|------------|-------------------------------|---------------------------------------------------|
| NGINX      | nginx, openssl                | Debian APT repositories                           |
| WordPress  | PHP-FPM 8.2, WP-CLI          | Debian APT + WP-CLI official phar from GitHub     |
| MariaDB    | mariadb-server                | Debian APT repositories                           |
| Redis      | redis-server                  | Debian APT repositories                           |
| Adminer    | PHP built-in server, Adminer  | Adminer v4.8.1 from GitHub releases               |
| FTP        | vsftpd                        | Debian APT repositories                           |
| Static site| lighttpd                       | Debian APT repositories                           |
| cAdvisor   | cadvisor binary               | Google cAdvisor v0.47.0 from GitHub releases      |

### Design Choices

- **TLS termination at NGINX:** Only NGINX exposes a port (443) to the host. All internal communication happens over the Docker bridge network without encryption, which is standard for internal service-to-service traffic.
- **WP-CLI for automation:** WordPress installation, configuration, user creation, and Redis plugin setup are fully automated — no manual web-based setup is needed.
- **First-run guards:** Each entrypoint script uses a `/etc/.firstrun` flag file to ensure initialization only runs once, making containers safe to restart.
- **Secrets over env vars:** All passwords are provided via Docker secrets (`/run/secrets/`), read at runtime by entrypoint scripts.

---

### Virtual Machines vs Docker

| Aspect             | Virtual Machine                        | Docker Container                      |
|--------------------|----------------------------------------|---------------------------------------|
| **Isolation**      | Full hardware-level isolation via hypervisor (each VM has its own kernel) | Process-level isolation sharing the host kernel via namespaces and cgroups |
| **Startup time**   | Minutes (boots an entire OS)           | Seconds (starts a process)            |
| **Resource usage** | Heavy — each VM reserves CPU, RAM, and disk for a full OS | Lightweight — containers share the host kernel and only consume what the process needs |
| **Portability**    | VM images are large and hypervisor-specific | Docker images are portable across any system running Docker |
| **Use case**       | Running different operating systems, strong security boundaries | Microservices, reproducible environments, CI/CD pipelines |

**In this project:** Docker was chosen because the goal is to run multiple lightweight Linux services that share the same kernel. A full VM per service would be wasteful. Docker provides fast iteration, declarative orchestration via Compose, and minimal overhead.

---

### Secrets vs Environment Variables

| Aspect            | Environment Variables                   | Docker Secrets                         |
|-------------------|-----------------------------------------|----------------------------------------|
| **Storage**       | Stored in the container's environment, visible via `docker inspect` or `/proc/<pid>/environ` | Stored encrypted in Docker's internal store, mounted as tmpfs files at `/run/secrets/` |
| **Visibility**    | Exposed in process listings, logs, and child processes | Only accessible inside the container's filesystem — not visible via inspect or logs |
| **Persistence**   | Set at container creation, immutable    | Mounted at runtime, read from files    |
| **Security**      | Insecure for passwords — easily leaked  | Designed specifically for sensitive data |

**In this project:** All passwords (database, WordPress admin, FTP) are stored as text files in the `secrets/` directory and injected via Docker Compose secrets. Entrypoint scripts read them from `/run/secrets/` at startup. Non-sensitive configuration (database name, domain, usernames) is passed via `.env` environment variables.

---

### Docker Network vs Host Network

| Aspect              | Host Network                           | Docker Bridge Network                  |
|---------------------|----------------------------------------|----------------------------------------|
| **Isolation**       | None — container shares the host's network stack directly | Full — each container gets its own network namespace with a virtual interface |
| **Port conflicts**  | Container ports directly bind to host ports, risking conflicts | Ports are isolated; only explicitly published ports reach the host |
| **Service discovery**| Must use `localhost` or host IP        | Containers resolve each other by container name (DNS built into Docker) |
| **Security**        | All host ports are accessible from the container | Containers can only communicate within the same bridge network |

**In this project:** A custom bridge network (`docker-networks`) is used. This allows containers to communicate by name (e.g., WordPress connects to `mariadb:3306`), keeps services isolated from the host, and only exposes the ports that need to be accessible externally (443, 8080, 9090, 9080, 21).

---

### Docker Volumes vs Bind Mounts

| Aspect            | Docker Named Volumes                   | Bind Mounts                            |
|-------------------|----------------------------------------|----------------------------------------|
| **Management**    | Managed by Docker, stored in Docker's internal storage (`/var/lib/docker/volumes/`) | Maps a specific host directory to the container |
| **Portability**   | Easier to back up and migrate via Docker commands | Tied to a specific host path           |
| **Performance**   | Optimized by Docker's storage driver   | Native filesystem performance          |
| **Flexibility**   | Docker handles permissions and lifecycle | Full control over location and permissions on the host |

**In this project:** Named volumes with `bind` driver options are used — effectively **bind mounts declared as named volumes** in Compose. WordPress data is persisted at `/home/hdazia/data/wordpress` and MariaDB data at `/home/hdazia/data/mariadb`. This gives Docker Compose the lifecycle management of named volumes while storing data at predictable host paths.

---

## Architecture

```
                        ┌──────────────────────────────────────────┐
         Port 443       │          docker-networks (bridge)        │
     ───────────────►   │                                          │
                        │  ┌───────┐    ┌───────────┐   ┌───────┐ │
                        │  │ NGINX ├───►│ WordPress ├──►│MariaDB│ │
                        │  │ :443  │    │ PHP-FPM   │   │ :3306 │ │
                        │  └───────┘    │ :9000     │   └───────┘ │
                        │               └─────┬─────┘             │
                        │                     │                   │
                        │               ┌─────▼─────┐            │
                        │               │   Redis   │            │
                        │               │   :6379   │            │
                        │               └───────────┘            │
                        │                                         │
                        │  ┌─────────┐ ┌─────┐ ┌────────┐ ┌────────────┐
         Port 8080 ────►│  │ Adminer │ │ FTP │ │ Static │ │  cAdvisor  │
         Port 21   ────►│  │ :8080   │ │ :21 │ │ :9090  │ │   :9080    │
         Port 9090 ────►│  └─────────┘ └─────┘ └────────┘ └────────────┘
         Port 9080 ────►│                                         │
                        └──────────────────────────────────────────┘

                        Volumes:
                        ─────────
                        WordPress ──► /home/hdazia/data/wordpress
                        MariaDB   ──► /home/hdazia/data/mariadb
```

---

## Services

### Mandatory

| Service   | Base Image        | Internal Port | Exposed Port | Role                              |
|-----------|-------------------|---------------|--------------|-----------------------------------|
| NGINX     | debian:bookworm   | 443           | 443          | TLS reverse proxy                 |
| WordPress | debian:bookworm   | 9000          | —            | CMS via PHP-FPM 8.2              |
| MariaDB   | debian:bookworm   | 3306          | —            | Relational database               |

### Bonus

| Service      | Base Image        | Internal Port | Exposed Port    | Role                          |
|--------------|-------------------|---------------|-----------------|-------------------------------|
| Redis        | debian:bookworm   | 6379          | —               | WordPress object cache        |
| Adminer      | debian:bookworm   | 8080          | 8080            | Database management web UI    |
| FTP (vsftpd) | debian:bookworm  | 21            | 21, 21000-21010 | FTP access to WordPress files |
| Static site  | debian:bookworm   | 9090          | 9090            | Simple HTML page (Lighttpd)   |
| cAdvisor     | debian:bookworm   | 9080          | 9080            | Container monitoring          |

### Volumes

| Volume    | Host Path                     | Container Path   | Used By                 |
|-----------|-------------------------------|------------------|-------------------------|
| WordPress | `/home/hdazia/data/wordpress` | `/var/www/html`  | NGINX, WordPress, FTP   |
| MariaDB   | `/home/hdazia/data/mariadb`   | `/var/lib/mysql` | MariaDB                 |

### Secrets

| Secret                      | File                                   | Used By            |
|-----------------------------|----------------------------------------|--------------------|
| `db_password`               | `secrets/db_password.txt`              | MariaDB, WordPress |
| `db_root_password`          | `secrets/db_root_password.txt`         | MariaDB, WordPress |
| `wordpress_admin_password`  | `secrets/wordpress_admin_password.txt` | WordPress          |
| `wordpress_password`        | `secrets/wordpress_password.txt`       | WordPress          |
| `ftp_password`              | `secrets/ftp_password.txt`             | FTP                |

---

## Instructions

### Prerequisites

- **Docker** and **Docker Compose** installed
- **Make** installed
- A Linux host or VM (containers bind-mount to `/home/hdazia/data/`)
- Add the domain to your `/etc/hosts`:
  ```
  127.0.0.1  hdazia.42.fr
  ```

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/HamzaDazIA/Inception42.git
   cd Inception42
   ```

2. **Set your secret passwords** in the `secrets/` directory:
   ```bash
   echo "your_db_password"          > secrets/db_password.txt
   echo "your_db_root_password"     > secrets/db_root_password.txt
   echo "your_wp_admin_password"    > secrets/wordpress_admin_password.txt
   echo "your_wp_user_password"     > secrets/wordpress_password.txt
   echo "your_ftp_password"         > secrets/ftp_password.txt
   ```

3. **Create the `.env` file** in `srcs/` with your configuration:
   ```env
   DOMAIN_NAME=hdazia.42.fr
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wpuser
   WORDPRESS_TITLE=Inception
   WORDPRESS_ADMIN_USER=admin
   WORDPRESS_ADMIN_EMAIL=admin@hdazia.42.fr
   WORDPRESS_USER=author
   WORDPRESS_EMAIL=author@hdazia.42.fr
   FTP_USER=ftpuser
   ```

4. **Create the data directories** on the host:
   ```bash
   sudo mkdir -p /home/hdazia/data/wordpress /home/hdazia/data/mariadb
   ```

### Build & Run

```bash
# Build images and start all services in detached mode
make up

# Stop all services
make down

# Stop, remove volumes and orphan containers
make clean

# Full clean — also removes all Docker images
make fclean

# Rebuild everything from scratch
make re
```

### Access

| Service        | URL                            |
|----------------|--------------------------------|
| WordPress      | `https://hdazia.42.fr`         |
| Adminer        | `http://hdazia.42.fr:8080`     |
| Static site    | `http://hdazia.42.fr:9090`     |
| cAdvisor       | `http://hdazia.42.fr:9080`     |

---

## Resources

### Documentation & References

- [Docker Documentation](https://docs.docker.com/) — official Docker reference for images, containers, Compose, networking, volumes, and secrets.
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) — guidelines for writing efficient Dockerfiles.
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/) — full reference for `docker-compose.yml` syntax.
- [NGINX Documentation](https://nginx.org/en/docs/) — configuration reference for the NGINX web server.
- [WordPress CLI (WP-CLI)](https://developer.wordpress.org/cli/commands/) — command reference for automating WordPress installation and management.
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/) — documentation for MariaDB server configuration and SQL.
- [Redis Documentation](https://redis.io/docs/) — reference for Redis configuration and usage.
- [vsftpd Manual](https://security.appspot.com/vsftpd/vsftpd_conf.html) — configuration reference for the vsftpd FTP server.
- [Adminer](https://www.adminer.org/) — official page for the Adminer database management tool.
- [Lighttpd Documentation](https://redmine.lighttpd.net/projects/lighttpd/wiki) — reference for the Lighttpd web server.
- [cAdvisor (GitHub)](https://github.com/google/cadvisor) — container monitoring tool by Google.

### AI Usage
AI was used to:

    Write and structure this README 

---

## Project Structure

```
Inception42/
├── makefile                       # Build/run commands (up, down, clean, fclean, re)
├── README.md                      # This file
├── script.sh                      # Utility script
├── secrets/                       # Docker secrets (password files)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── ftp_password.txt
│   ├── wordpress_admin_password.txt
│   └── wordpress_password.txt
└── srcs/
    ├── docker-compose.yml         # Service orchestration
    └── requirements/
        ├── mariadb/               # MariaDB container
        │   ├── Dockerfile
        │   ├── conf/mariadb.conf
        │   └── tools/mariadb.sh
        ├── nginx/                 # NGINX container
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/nginx.sh
        ├── wordpress/             # WordPress + PHP-FPM container
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/wordpress.sh
        └── bonus/
            ├── Adminer/           # Adminer (DB management UI)
            │   └── Dockerfile
            ├── cadivsor/          # cAdvisor (monitoring)
            │   └── Dockerfile
            ├── ftp/               # vsftpd (FTP server)
            │   ├── Dockerfile
            │   ├── conf/vsftpd.conf
            │   └── tools/ftp.sh
            ├── redis/             # Redis (object cache)
            │   ├── dockerfile
            │   └── tools/redis.sh
            └── static_site/       # Lighttpd (static HTML page)
                ├── Dockerfile
                ├── conf/conf
                └── tools/index.html
```