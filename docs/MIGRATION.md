# Hardware Migration Guide

This guide details the procedure for migrating this server from the Raspberry Pi 3B+ to a secondary machine (e.g. an old laptop or mini-PC running Linux).

## Migration Overview

Because data is decoupled from the operating system, migration requires zero data copying:

```text
New Linux Host (Laptop / Mini-PC)
       ↓
  Install Linux (Debian / Ubuntu)
       ↓
  Install Git & Docker
       ↓
  Clone home-server Repository
       ↓
  Connect Existing 1 TB USB HDD
       ↓
  Mount UUID 3EE45445E4540217 to /mnt/storage
       ↓
  Restore .env Variables
       ↓
  docker compose up -d
```

## Step-by-Step Procedure

1. **Prepare New Host**:
   * Install standard 64-bit Linux server distribution.
   * Install Docker Engine, Docker Compose plugin, and Git.
2. **Connect Storage**:
   * Connect the 1 TB USB HDD to the new machine.
   * Locate the partition by UUID (`3EE45445E4540217`) using `sudo blkid`. Do not rely on `/dev/sdX` names.
   * Add the persistent mount entry to `/etc/fstab` pointing to `/mnt/storage`.
   * Mount the drive: `sudo mkdir -p /mnt/storage && sudo mount -a`.
3. **Clone Infrastructure**:
   * `git clone https://github.com/sukeshperiyasamy/home-server.git /home/$USER/home-server`
   * Copy your backed-up `.env` file to `/home/$USER/home-server/.env`.
4. **Deploy Stacks**:
   * Run `docker compose up -d` in the repository directory.
   * On higher-resource hardware (e.g. 8+ GB RAM laptop), enable heavy services such as Immich pointing to existing `/mnt/storage/photos`.
