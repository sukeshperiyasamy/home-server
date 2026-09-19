# Server Installation & Implementation Phases

This document outlines the phased installation lifecycle for the home server.

## Phase Overview

* [x] **Phase 0: System Audit** — Read-only hardware, OS, and resource assessment.
* [x] **Phase 1: Persistent Storage** — HDD identification, NTFS mount via UUID, fstab configuration.
* [x] **Phase 2: Infrastructure Repository** — Git setup, repository skeleton, documentation, safety checks.
* [x] **Phase 3: Docker & Docker Compose** — Docker Engine (v29.8.1) and Compose plugin (v5.5.1) installed from official Docker repository.
* [x] **Phase 4: Portainer CE** — Deployed Portainer CE (v2.27.1-alpine) via Docker Compose; persistent data at `/mnt/storage/app-data/portainer`; bound strictly to LAN IP.
* [x] **Phase 5: Tailscale** — Host-installed WireGuard mesh VPN (tailscaled) enabled at boot; provides encrypted zero-trust private remote access without router port forwarding.
* [x] **Phase 6: Core Services (Vaultwarden)** — Deployed Vaultwarden (v1.33.2-alpine) via Docker Compose; persistent data at `/mnt/storage/app-data/vaultwarden`; private access bound strictly to Tailscale IP (no WAN exposure). Note: Storage filesystem is currently NTFS; ext4 is recommended for long-term Linux-native database workloads. Backups are not yet configured.
* [ ] **Phase 7: Backup Framework** — *Not installed yet.* Automated configuration and database dumps.
* [ ] **Phase 8: Disaster Recovery Verification** — *Not installed yet.* Restore validation drills.
