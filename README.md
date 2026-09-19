# Home Server Infrastructure

This repository is the **single source of truth** for the home server configuration and infrastructure.

## Architecture Overview

```text
Raspberry Pi / Future Linux Server
        ↓
   Docker Engine
        ↓
   Docker Compose
        ↓
Home-Server Applications
  ├── Portainer CE   (LAN management UI)
  ├── Vaultwarden    (Tailscale HTTPS password vault)
  └── File Browser   (Tailscale HTTPS file manager)
        ↓
  Persistent Data
        ↓
   /mnt/storage
```

## Core Design Principles

1. **OS is Disposable**: The operating system can be reinstalled from scratch at any moment without loss of state.
2. **GitHub is Infrastructure**: This repository contains the code, scripts, compose specifications, and documentation required to recreate the server.
3. **Storage is Persistent**: All personal files, media, databases, and application data reside strictly under `/mnt/storage` (mounted via UUID from dedicated storage).
4. **Zero Secrets in Git**: No personal passwords, tokens, API keys, private certificates, or `.env` files are ever committed to this repository.

## Active Deployed Services

| Service | Container Image | Port Binding | Access Method | Storage Location |
| :--- | :--- | :--- | :--- | :--- |
| **Portainer CE** | `portainer/portainer-ce:2.27.1-alpine` | `10.166.46.195:9000/9443` | LAN Browser | `/mnt/storage/app-data/portainer` |
| **Vaultwarden** | `vaultwarden/server:1.33.2-alpine` | `100.96.171.29:8080` | `https://pi-server.tail1040b5.ts.net` | `/mnt/storage/app-data/vaultwarden` |
| **File Browser** | `filebrowser/filebrowser:v2.63.23` | `100.96.171.29:8082` | `https://pi-server.tail1040b5.ts.net:8443` | `/mnt/storage/app-data/filebrowser` |

## Repository Layout

* `docker-compose.yml`: Definition of running services and container stacks.
* `.env.example`: Template for local environment variables.
* `scripts/`: Operational scripts for setup, maintenance, backup, and health checks.
* `docs/`: Comprehensive architecture, storage, installation, backup, file browser, and security documentation.

## Hardware & Storage Quick Reference

* **Current Host**: Raspberry Pi 3 Model B Plus (ARM64)
* **Persistent Mount**: `/mnt/storage`
* **Storage UUID**: `3EE45445E4540217` (`/dev/sda7`, NTFS)
* **Reserved Partition**: `/dev/sda8` (Untouched/Reserved)
