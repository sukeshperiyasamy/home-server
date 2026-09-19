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

## Repository Layout

* `docker-compose.yml`: Definition of running services and container stacks.
* `.env.example`: Template for local environment variables.
* `scripts/`: Operational scripts for setup, maintenance, backup, and health checks.
* `docs/`: Comprehensive architecture, storage, installation, backup, migration, and security documentation.

## Hardware & Storage Quick Reference

* **Current Host**: Raspberry Pi 3 Model B Plus (ARM64)
* **Persistent Mount**: `/mnt/storage`
* **Storage UUID**: `3EE45445E4540217` (`/dev/sda7`, NTFS)
* **Reserved Partition**: `/dev/sda8` (Untouched/Reserved)
