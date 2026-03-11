# User Documentation

This document explains how to use the Inception infrastructure as an end user or administrator.

---

## Services Overview

The stack provides the following services:

| Service        | Description                                          | Access                          |
|----------------|------------------------------------------------------|---------------------------------|
| **WordPress**  | A full CMS website for creating and managing content | `https://hdazia.42.fr`          |
| **NGINX**      | Reverse proxy handling HTTPS (TLS) for WordPress     | —  (transparent to the user)    |
| **MariaDB**    | Database storing all WordPress content               | —  (internal only)              |
| **Redis**      | Object cache that speeds up WordPress page loads     | —  (internal only)              |
| **Adminer**    | Web-based database administration panel              | `http://hdazia.42.fr:8080`      |
| **FTP**        | File transfer access to WordPress files              | `ftp://hdazia.42.fr:21`         |
| **Static site**| A simple standalone HTML page                        | `http://hdazia.42.fr:9090`      |
| **cAdvisor**   | Container resource monitoring dashboard              | `http://hdazia.42.fr:9080`      |

---

## Starting and Stopping the Project

All commands are run from the project root directory.

### Start

```bash
make up
```

This builds all Docker images (if not already built) and starts every service in the background. The first launch may take a few minutes while images are built.

### Stop

```bash
make down
```

This stops all running containers. Your data (WordPress files, database) is preserved on disk.

### Full Restart

```bash
make re
```

This removes everything (containers, volumes, images) and rebuilds from scratch.

---

## Accessing the Website

### WordPress Site

Open your browser and navigate to:

```
https://hdazia.42.fr
```

> **Note:** The TLS certificate is self-signed. Your browser will show a security warning — this is expected. Accept the warning to proceed.

### WordPress Admin Panel

To manage WordPress content (posts, pages, users, themes, plugins):

```
https://hdazia.42.fr/wp-admin
```

Log in with the **WordPress admin** credentials (see [Credentials](#locating-and-managing-credentials) below).

### Adminer (Database Panel)

To browse or manage the database directly:

```
http://hdazia.42.fr:8080
```

Use the following connection settings in the Adminer login form:

| Field    | Value                                        |
|----------|----------------------------------------------|
| System   | MySQL                                        |
| Server   | `mariadb`                                    |
| Username | The database user (from your `.env` file, e.g. `wpuser`) |
| Password | The content of `secrets/db_password.txt`     |
| Database | The database name (from your `.env` file, e.g. `wordpress`) |

### Static Site

```
http://hdazia.42.fr:9090
```

### cAdvisor (Monitoring)

```
http://hdazia.42.fr:9080
```

This dashboard shows real-time CPU, memory, network, and filesystem usage of all running containers.

---

## Locating and Managing Credentials

All passwords are stored as plain text files in the `secrets/` directory at the project root:

| File                                  | Purpose                           |
|---------------------------------------|-----------------------------------|
| `secrets/db_password.txt`             | MariaDB database user password    |
| `secrets/db_root_password.txt`        | MariaDB root password             |
| `secrets/wordpress_admin_password.txt`| WordPress admin account password  |
| `secrets/wordpress_password.txt`      | WordPress author account password |
| `secrets/ftp_password.txt`            | FTP user password                 |

### Changing a Password

1. Stop the project:
   ```bash
   make down
   ```
2. Edit the relevant file in `secrets/`, e.g.:
   ```bash
   echo "new_secure_password" > secrets/db_password.txt
   ```
3. For a clean reapply, rebuild from scratch:
   ```bash
   make fclean
   make up
   ```

> **Important:** Changing database passwords after initial setup requires a full rebuild (`make fclean` then `make up`) since the database is initialized once on first run.

### Non-Secret Configuration

Usernames, domain name, and other non-sensitive settings are defined in the `srcs/.env` file. Common variables include:

- `DOMAIN_NAME` — the site domain (e.g. `hdazia.42.fr`)
- `MYSQL_DATABASE` — database name
- `MYSQL_USER` — database username
- `WORDPRESS_ADMIN_USER` — WordPress admin login
- `WORDPRESS_ADMIN_EMAIL` — WordPress admin email
- `FTP_USER` — FTP login username

---

## Checking That Services Are Running

### Quick Check

List all running containers:

```bash
docker ps
```

You should see containers named: `nginx`, `wordpress`, `mariadb`, `redis`, `adminer`, `ftp`, `static_site`, `cadvisor` — all with status **Up**.

### Check a Specific Service

```bash
docker logs <container_name>
```

For example:

```bash
docker logs wordpress
docker logs mariadb
docker logs nginx
```

### Verify WordPress Is Responding

```bash
curl -k https://hdazia.42.fr
```

A successful response returns HTML content. The `-k` flag is needed to accept the self-signed certificate.

### Verify Database Connectivity

```bash
docker exec mariadb mysqladmin ping -u root -p$(cat secrets/db_root_password.txt)
```

A response of `mysqld is alive` confirms the database is running.

### Monitor Container Resources

Open cAdvisor in your browser at `http://hdazia.42.fr:9080` to see live resource usage for all containers.
