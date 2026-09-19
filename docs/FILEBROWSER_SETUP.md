# File Browser Setup & Verification Guide

## 1. Overview

File Browser is a lightweight web dashboard that provides file upload, download, preview, directory creation, renaming, and deletion capabilities for the Raspberry Pi home server.

It is deployed as a Docker container running on the internal Tailscale network, protected by Tailscale Serve HTTPS on dedicated port `8443`.

---

## 2. Server Architecture

```text
Client Browser (Tailscale-connected device)
  │
  ▼
Tailscale WireGuard Mesh Tunnel
  │
  ▼
Tailscale Serve (TLS Certificate via Let's Encrypt / MagicDNS)
  │
  ▼ https://pi-server.tail1040b5.ts.net:8443
Host Port: 100.96.171.29:8082 (Strictly bound to Tailscale IP)
  │
  ▼
File Browser Container (filebrowser/filebrowser:v2.63.23)
  │
  ├── /srv/documents  <──> /mnt/storage/documents
  ├── /srv/photos     <──> /mnt/storage/photos
  ├── /srv/videos     <──> /mnt/storage/videos
  └── /srv/downloads  <──> /mnt/storage/downloads
```

* **Host Hardware**: Raspberry Pi 3 Model B+ (ARM64, ~1 GB RAM)
* **Operating System**: Debian 13 (Trixie) 64-bit
* **Data Storage**: `/mnt/storage` (NTFS partition `/dev/sda7`)
* **Host IP Binding**: `100.96.171.29:8082` (Zero LAN or public WAN exposure)
* **Access URL**: `https://pi-server.tail1040b5.ts.net:8443`

---

## 3. File Browser Configuration

File Browser stores its configuration and user database in a dedicated application directory on persistent storage:

* Database directory: `/mnt/storage/app-data/filebrowser/database`
* Configuration directory: `/mnt/storage/app-data/filebrowser/config`

Directory-level bind mounts (`/database` and `/config`) are utilized rather than file-level mounts. This ensures that the container entrypoint (`/init.sh`) safely initializes `settings.json` from defaults and maintains an embedded bbolt database (`filebrowser.db`) without mount race conditions or file-locking conflicts on NTFS.

---

## 4. Docker Compose Service

The service is defined in `/home/sukesh/home-server/docker-compose.yml`:

```yaml
  filebrowser:
    image: filebrowser/filebrowser:v2.63.23
    container_name: filebrowser
    restart: unless-stopped
    user: "1000:1000"
    ports:
      # Bound strictly to Raspberry Pi Tailscale address (no public exposure)
      - "100.96.171.29:8082:80"
    volumes:
      # Data directories exposed to user (app-data and backups are strictly excluded)
      - ${STORAGE_ROOT:-/mnt/storage}/documents:/srv/documents
      - ${STORAGE_ROOT:-/mnt/storage}/photos:/srv/photos
      - ${STORAGE_ROOT:-/mnt/storage}/videos:/srv/videos
      - ${STORAGE_ROOT:-/mnt/storage}/downloads:/srv/downloads
      # Persistent database and settings directories
      - ${STORAGE_ROOT:-/mnt/storage}/app-data/filebrowser/database:/database
      - ${STORAGE_ROOT:-/mnt/storage}/app-data/filebrowser/config:/config
```

---

## 5. Storage and Directory Isolation

> [!IMPORTANT]
> **Container Namespace Isolation**:
> File Browser must **NEVER** have `/mnt/storage` mounted as its root.

Only user-facing media and document directories are mounted into `/srv`.
The following paths are **strictly excluded**:
* `/mnt/storage/app-data` (Contains Vaultwarden SQLite database, RSA session keys, and Portainer state)
* `/mnt/storage/backups` (Contains system backup tarballs)
* `/var/run/docker.sock`

Because these directories are omitted from the container specification, they physically do not exist inside the container namespace. Even an administrative user inside File Browser cannot browse or modify application secrets.

---

## 6. Tailscale HTTPS Configuration

To provide valid, private HTTPS without disturbing the existing Vaultwarden route on port `443`, Tailscale Serve is configured on dedicated port `8443`:

```bash
sudo tailscale serve --bg --https=8443 http://100.96.171.29:8082
```

Verify active routes:
```bash
tailscale serve status
```

Expected routing configuration:
* `https://pi-server.tail1040b5.ts.net` (port 443) -> `http://100.96.171.29:8080` (Vaultwarden)
* `https://pi-server.tail1040b5.ts.net:8443` -> `http://100.96.171.29:8082` (File Browser)
* Tailscale Funnel: **Disabled** (`tailnet only`).

---

## 7. Authentication and Password Security

File Browser generates an initial random administrator password on first initialization. Retrieve it from the container logs and change it immediately after first login. Never store the password in Git.

### Retrieving Initial Password:
```bash
docker logs filebrowser | grep "User 'admin' initialized"
```

### Password Rotation:
1. Navigate to `https://pi-server.tail1040b5.ts.net:8443`
2. Log in with username `admin` and the temporary password retrieved from the log.
3. Open **Settings** -> **Profile Settings**.
4. Set a strong personal password and save changes.

---

## 8. Verification Tests

### Container Health & Ports
```bash
cd /home/sukesh/home-server
docker compose ps filebrowser
docker port filebrowser
```
* Expected status: `Up (healthy)`
* Expected port: `80/tcp -> 100.96.171.29:8082`

### Directory Isolation Test
```bash
docker exec filebrowser ls -la /srv
docker exec filebrowser ls -la /srv/app-data 2>&1
docker exec filebrowser ls -la /srv/backups 2>&1
```
* `/srv` must list only: `documents`, `photos`, `videos`, `downloads`.
* Attempts to access `app-data` or `backups` must return `No such file or directory`.

### HTTPS Endpoint Tests
```bash
# File Browser HTTPS test
curl -s -o /dev/null -w "%{http_code}\n" https://pi-server.tail1040b5.ts.net:8443/login

# Vaultwarden Regression check
curl -s -o /dev/null -w "%{http_code}\n" https://pi-server.tail1040b5.ts.net/api/config
```
* Both endpoints must return `200`.

---

## 9. Upload/Delete Functional Test

To verify write and delete permissions on host storage:
1. Log into the File Browser web interface.
2. Upload a test document into `documents/`.
3. Verify on the host:
   ```bash
   ls -la /mnt/storage/documents/
   ```
4. Delete the test document through the web interface.
5. Confirm file removal from the host filesystem.

---

## 10. RAM & Resource Check

File Browser is written in Go and has an extremely low resource footprint:

```bash
ps -eo pid,cmd,%mem,rss --sort=-rss | grep filebrowser | grep -v grep
free -h
```
* **RSS Memory**: ~25–35 MiB (<3% of total RAM).
* **System Headroom**: >350 MiB available RAM maintained on the Raspberry Pi 3B+.

---

## 11. Troubleshooting

* **Container restarting with config error**:
  Check `/mnt/storage/app-data/filebrowser/config/settings.json`. If corrupted, delete it and restart the container; `/init.sh` will regenerate a clean default configuration.
* **403 Forbidden on API calls**:
  File Browser requires an active session token (`X-Auth` header). Log in via the web interface to establish a session cookie.
* **Database locked timeout**:
  The bbolt database (`filebrowser.db`) uses exclusive process locking. Do not execute concurrent `filebrowser` CLI commands against the database file while the container is actively running.

---

## 12. Rollback

To cleanly disable or remove File Browser without affecting Vaultwarden or persistent data:

```bash
# 1. Stop and remove container
cd /home/sukesh/home-server
docker compose stop filebrowser
docker compose rm -f filebrowser

# 2. Disable Tailscale Serve route on port 8443
sudo tailscale serve --https=8443 off

# 3. Verify Vaultwarden route remains active
tailscale serve status
```

---

## 13. Git & Upgrade Procedure

* Image version is pinned to `filebrowser/filebrowser:v2.63.23`.
* To update configuration, edit `docker-compose.yml` and run `docker compose up -d filebrowser`.
* Never commit `filebrowser.db` or credentials to version control.
