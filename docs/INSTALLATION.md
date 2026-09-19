# Server Installation & Implementation Phases

This document outlines the phased installation lifecycle for the home server.

## Phase Overview

* [x] **Phase 0: System Audit** — Read-only hardware, OS, and resource assessment.
* [x] **Phase 1: Persistent Storage** — HDD identification, NTFS mount via UUID, fstab configuration.
* [x] **Phase 2: Infrastructure Repository** — Git setup, repository skeleton, documentation, safety checks.
* [x] **Phase 3: Docker & Docker Compose** — Docker Engine (v29.8.1) and Compose plugin (v5.5.1) installed from official Docker repository.
* [x] **Phase 4: Portainer CE** — Deployed Portainer CE (v2.27.1-alpine) via Docker Compose; persistent data at `/mnt/storage/app-data/portainer`; bound strictly to LAN IP.
* [x] **Phase 5: Tailscale** — Host-installed WireGuard mesh VPN (tailscaled) enabled at boot; provides encrypted zero-trust private remote access without router port forwarding.
* [x] **Phase 6: Core Services (Vaultwarden & Tailscale HTTPS)** — Deployed Vaultwarden (v1.33.2-alpine) via Docker Compose; persistent data at `/mnt/storage/app-data/vaultwarden`; bound to Tailscale IP; secured with Tailscale Serve private HTTPS (`https://pi-server.tail1040b5.ts.net`).
* [x] **Phase 7: Backup Framework** — Implemented application-aware online SQLite backup (`scripts/backup.sh`) and disaster recovery restore (`scripts/restore.sh`) with SHA-256 verification and automated retention pruning.
* [ ] **Phase 8: Disaster Recovery Verification** — *Planned next.* Controlled restore drill and validation.
