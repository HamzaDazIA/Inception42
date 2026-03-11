# Developer Documentation

This document describes how to set up, build, run, and manage the Inception project as a developer.

---

## Setting Up the Environment from Scratch

### Prerequisites

| Requirement       | Minimum Version | Purpose                         |
|-------------------|-----------------|----------------------------------|
| Docker            | 20.10+          | Container runtime                |
| Docker Compose    | v2+             | Multi-container orchestration    |
| Make              | any             | Build automation                 |
| Linux host or VM  | —               | Bind mounts use Linux paths      |

Install Docker and Compose on Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install docker.io docker-compose-plugin make
sudo usermod -aG docker $USER
# Log out and back in for the group change to take effect
```

### Host Configuration

Add the project domain to your local DNS:

```bash
echo "127.0.0.1  hdazia.42.fr" | sudo tee -a /etc/hosts
```

Create the data directories where volumes will persist:

```bash
sudo mkdir -p /home/hdazia/data/wordpress /home/hdazia/data/mariadb
sudo chown -R $USER:$USER /home/hdazia/data
```

### Configuration Files

#### `srcs/.env`

Create this file with your environment variables. These are **non-sensitive** configuration values:

```env
DOMAIN_NAME=
MYSQL_DATABASE=
MYSQL_USER=
WORDPRESS_TITLE=
WORDPRESS_ADMIN_USER=
WORDPRESS_ADMIN_EMAIL=
WORDPRESS_USER=
WORDPRESS_EMAIL=
FTP_USER=
```

#### `secrets/` Directory

Each file contains a single password (no trailing newline recommended). These are mounted into containers as Docker secrets at `/run/secrets/<name>`:

```bash
echo -n "your_db_password"           > secrets/db_password.txt
echo -n "your_db_root_password"      > secrets/db_root_password.txt
echo -n "your_wp_admin_password"     > secrets/wordpress_admin_password.txt
echo -n "your_wp_user_password"      > secrets/wordpress_password.txt
echo -n "your_ftp_password"          > secrets/ftp_password.txt
```

> **Security:** Never commit real passwords to Git. The `secrets/` directory should contain placeholder values or be listed in `.gitignore` for production use.

---

## Building and Launching the Project

### Makefile Targets

All targets are defined in the root `makefile` and use `srcs/docker-compose.yml`:

| Command      | What It Does                                                        |
|--------------|---------------------------------------------------------------------|
| `make up`    | Builds all images and starts containers in detached mode            |
| `make down`  | Stops and removes all containers (data preserved)                   |
| `make clean` | Stops containers, removes volumes and orphan containers             |
| `make fclean`| Runs `clean` then prunes all Docker images                          |
| `make re`    | Runs `fclean` then `up` — full rebuild from scratch                 |

### Build Process

```bash
make up
```

This executes:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

Docker Compose will:
1. Build each service's image from its `Dockerfile` in `srcs/requirements/`
2. Create the `docker-networks` bridge network
3. Create the `WordPress` and `MariaDB` named volumes (bind-mounted to host paths)
4. Start containers respecting `depends_on` order: MariaDB → WordPress → NGINX / Redis / FTP, etc.

### First Run Behavior

On first launch, each service's entrypoint script runs initialization logic guarded by a `/etc/.firstrun` flag:

- **MariaDB:** Creates the database, users, and grants privileges via bootstrap SQL
- **NGINX:** Generates a self-signed TLS certificate for `$DOMAIN_NAME`
- **WordPress:** Downloads core, creates `wp-config.php`, installs the site, creates users, and enables Redis cache
- **FTP:** Creates the FTP system user

On subsequent starts, these steps are skipped.

---

## Managing Containers and Volumes

### Container Commands

```bash
# List running containers
docker ps

# View logs for a specific service
docker logs wordpress
docker logs -f nginx          # follow logs in real-time

# Open a shell inside a container
docker exec -it wordpress bash
docker exec -it mariadb bash

```

### Volume Commands

```bash
# List Docker volumes
docker volume ls

# Inspect a volume
docker volume inspect srcs_WordPress
docker volume inspect srcs_MariaDB

# Remove all volumes (WARNING: deletes all data)
make clean
```

### Network Commands

```bash
# List networks
docker network ls

# Inspect the project network
docker network inspect docker-networks

# Verify container connectivity
docker exec wordpress ping -c 2 mariadb
docker exec wordpress ping -c 2 redis
```

### Image Commands

```bash
# List built images
docker images

# Remove all project images
make fclean
```

---

## Data Storage and Persistence

### Where Data Lives

| Data              | Container Path   | Host Path                       | Persists After `make down`? | Persists After `make clean`? |
|-------------------|------------------|---------------------------------|-----------------------------|------------------------------|
| WordPress files   | `/var/www/html`  | `/home/hdazia/data/wordpress`   | Yes                         | No (volume removed)          |
| MariaDB database  | `/var/lib/mysql` | `/home/hdazia/data/mariadb`     | Yes                         | No (volume removed)          |

Both are configured in `docker-compose.yml` as named volumes with the `local` driver using bind mount options:

```yaml
volumes:
  WordPress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/hdazia/data/wordpress
  MariaDB:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/hdazia/data/mariadb
```

### How Persistence Works

- `make down` — stops containers but **keeps volumes and host data intact**. Restarting with `make up` resumes where you left off.
- `make clean` — stops containers **and removes Docker volumes**. The host directories (`/home/hdazia/data/`) may still contain residual files, but Docker no longer manages them. A fresh `make up` will re-initialize everything.
- `make fclean` — same as `clean` but also **removes all Docker images**, forcing a full rebuild on next `make up`.

### Inspecting Data on the Host

```bash
# WordPress files
ls -la /home/hdazia/data/wordpress/

# MariaDB data files
ls -la /home/hdazia/data/mariadb/

# Check disk usage
du -sh /home/hdazia/data/*
```

### Backing Up Data

```bash
# Backup WordPress files
tar -czf wordpress_backup.tar.gz -C /home/hdazia/data/wordpress .

# Backup MariaDB via mysqldump (while running)
docker exec mariadb mysqldump -u root -p$(cat secrets/db_root_password.txt) --all-databases > db_backup.sql
```

---

## Project File Reference

| File / Directory                             | Purpose                                      |
|----------------------------------------------|----------------------------------------------|
| `makefile`                                   | Build targets (`up`, `down`, `clean`, etc.)   |
| `srcs/docker-compose.yml`                    | Service definitions, networks, volumes        |
| `srcs/.env`                                  | Non-sensitive environment configuration       |
| `secrets/`                                   | Password files mounted as Docker secrets      |
| `srcs/requirements/nginx/`                   | NGINX Dockerfile, config, TLS setup script    |
| `srcs/requirements/wordpress/`               | WordPress Dockerfile, PHP-FPM config, WP-CLI setup script |
| `srcs/requirements/mariadb/`                 | MariaDB Dockerfile, server config, bootstrap script |
| `srcs/requirements/bonus/redis/`             | Redis Dockerfile and configuration script     |
| `srcs/requirements/bonus/Adminer/`           | Adminer Dockerfile                            |
| `srcs/requirements/bonus/ftp/`               | vsftpd Dockerfile, config, user setup script  |
| `srcs/requirements/bonus/static_site/`       | Lighttpd Dockerfile, config, HTML page        |
| `srcs/requirements/bonus/cadivsor/`          | cAdvisor Dockerfile                           |
