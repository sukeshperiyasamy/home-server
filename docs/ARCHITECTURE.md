# Server Architecture

## Current System

* **Hardware**: Raspberry Pi 3 Model B Plus Rev 1.3 (Broadcom BCM2837B0, Quad-core Cortex-A53 @ 1.4 GHz)
* **Architecture**: 64-bit ARM (`aarch64`)
* **RAM**: 1 GB LPDDR2 (with compressed `zram` swap)
* **Operating System**: Raspberry Pi OS / Debian 13 (trixie) 64-bit
* **Persistent Storage**: Dedicated HDD partition mounted at `/mnt/storage`

## Long-Term Evolution & Migration

The server is designed for portability:
```text
Raspberry Pi 3B+  ──>  Repurposed Linux Laptop  ──>  Dedicated Mini-PC / NAS
```
All persistent user data and container state live under `/mnt/storage`, ensuring that shifting hardware requires only transferring the storage disk and cloning this repository.

## Service Classification & Roadmap

Due to the Raspberry Pi 3B+'s 1 GB RAM, services are introduced based on strict resource suitability:

### Phase A: Lightweight Core (Targeted for Pi 3B+)
* **Docker Engine & Compose**: Base container runtime (~30-50 MB RAM).
* **Portainer CE**: Lightweight container management web UI (~30-40 MB RAM).
* **Tailscale**: Encrypted WireGuard mesh network for zero-trust remote access (~25-35 MB RAM).
* **Vaultwarden**: Lightweight Rust-based Bitwarden-compatible password manager (~30-50 MB RAM).
* **File Browser**: Lightweight Go-based file manager dashboard (~25-35 MB RAM).

### Phase B: High-Resource Services (Planned for Future Laptop)
* **Immich**: Self-hosted photo management. Requires PostgreSQL with pgvector, Redis, machine learning CLIP models, and hardware transcoding pipelines (minimum 4 GB RAM required).
* **Infisical**: Centralized secrets management platform. Requires Node backend, Redis, and PostgreSQL (minimum 2 GB RAM recommended).

## Data & Infrastructure Separation

* **GitHub**: Code, Compose files, configuration templates, documentation.
* **Persistent Storage (`/mnt/storage`)**:
  * `/mnt/storage/photos`: Photo collections and imports.
  * `/mnt/storage/documents`: Personal and work archives.
  * `/mnt/storage/videos`: Video library.
  * `/mnt/storage/downloads`: Temporary and completed downloads.
  * `/mnt/storage/app-data`: Persistent application state and database volumes.
  * `/mnt/storage/backups`: Local snapshots and database dumps.
