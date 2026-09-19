# Backup Philosophy & Strategy

## Core Principles

1. **Storage Is Not Backup**: Storing data on `/mnt/storage` provides persistence, not redundancy. A single physical drive failure can destroy all data.
2. **GitHub Is Not a Personal Data Backup**: GitHub stores only configuration, scripts, and documentation. No personal media, documents, or database secrets are ever stored in Git.
3. **Application-Aware Backups**: Live databases (such as SQLite or PostgreSQL) cannot be safely backed up by simple file copies while active; application-aware dumps are required.

## 3-2-1 Strategy (Roadmap)

For true resilience, the server will adopt a 3-2-1 backup strategy:
* **3 Copies of Data**: Primary data, local backup, off-site backup.
* **2 Different Media**: Internal/external USB HDD and secondary storage.
* **1 Off-Site Copy**: Encrypted cloud storage or remote secondary server via Tailscale.

## Backup Tiers

* **Tier 1 (Configuration)**: Git repository + `.env` backup (kept encrypted and offline).
* **Tier 2 (Databases)**: Daily automated dumps placed in `/mnt/storage/backups/database/`.
* **Tier 3 (User Data)**: Periodic synchronization of photos and documents to a secondary physical target.

*Note: Automated backup scripts will be implemented and validated in Phase 7.*
