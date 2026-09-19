# Persistent Storage Architecture

## Storage Target

* **Mount Point**: `/mnt/storage`
* **Physical Device**: `/dev/sda` (Seagate/Samsung Spinpoint M8 1 TB 2.5" SATA HDD)
* **Target Partition**: `/dev/sda7` (Label: `DATA`)
* **Filesystem**: NTFS (handled via Linux in-kernel `ntfs3` driver)
* **UUID**: `3EE45445E4540217`
* **Usable Capacity**: ~391 GB

## Reserved Partition

* **Partition `/dev/sda8`**: 423.7 GB (`UUID=F80E5A070E59BEF6`).
* **Status**: Intentionally unmounted, untouched, and reserved for future allocation.

## Persistent Mount Configuration (`/etc/fstab`)

To ensure reliability across reboots and device re-ordering, the partition is mounted via UUID rather than device nodes:

```text
UUID=3EE45445E4540217  /mnt/storage  ntfs3  rw,uid=1000,gid=1000,dmask=0022,fmask=0022,iocharset=utf8,nofail,x-systemd.device-timeout=15s  0  0
```

### Mount Option Rationale
* `UUID=...`: Predictable identifier independent of `/dev/sdX` assignments.
* `ntfs3`: High-performance in-kernel NTFS driver.
* `uid=1000,gid=1000`: Maps file ownership directly to standard user `sukesh`.
* `dmask=0022,fmask=0022`: Enforces standard directory (`755`) and file (`644`) permissions.
* `nofail`: Prevents boot hangs if the external USB disk is disconnected.
* `x-systemd.device-timeout=15s`: Limits systemd wait time during startup.

## Directory Layout

```text
/mnt/storage/
├── photos/         # Photographs and raw image archives
├── documents/      # Documents, archives, and personal records
├── videos/         # Video media library
├── downloads/      # Incoming and processed downloads
├── app-data/       # Persistent container volumes and databases
└── backups/        # Local backup archives and database dumps
```
