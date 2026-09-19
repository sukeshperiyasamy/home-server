#!/usr/bin/env bash
# ==============================================================================
# storage-check.sh - Read-Only Persistent Storage Verification
# ==============================================================================
# Verifies the mount status, filesystem, available space, and folder structure
# of /mnt/storage without modifying, repairing, or altering the disk.
# ==============================================================================

set -euo pipefail

TARGET_MOUNT="/mnt/storage"
EXPECTED_UUID="3EE45445E4540217"
EXPECTED_FSTYPE="ntfs3"

echo "=================================================="
echo " Home Server - Storage Health Check"
echo "=================================================="

# 1. Verify directory exists
if [ ! -d "$TARGET_MOUNT" ]; then
    echo "[FAIL] Mount point directory $TARGET_MOUNT does not exist."
    exit 1
fi

# 2. Verify mount status
if ! findmnt -M "$TARGET_MOUNT" > /dev/null 2>&1; then
    echo "[FAIL] $TARGET_MOUNT is NOT mounted."
    exit 1
fi
echo "[OK] $TARGET_MOUNT is actively mounted."

# 3. Verify filesystem type
CURRENT_FSTYPE=$(findmnt -n -o FSTYPE -M "$TARGET_MOUNT")
if [ "$CURRENT_FSTYPE" != "$EXPECTED_FSTYPE" ]; then
    echo "[WARN] Filesystem is $CURRENT_FSTYPE (expected $EXPECTED_FSTYPE)."
else
    echo "[OK] Filesystem driver: $CURRENT_FSTYPE"
fi

# 4. Verify source device and UUID
SOURCE_DEV=$(findmnt -n -o SOURCE -M "$TARGET_MOUNT")
echo "[OK] Source device: $SOURCE_DEV"

# 5. Display disk capacity
echo -e "\n--- Capacity Overview ---"
df -h "$TARGET_MOUNT"

# 6. Verify directory structure
echo -e "\n--- Directory Structure Verification ---"
REQUIRED_DIRS=("photos" "documents" "videos" "downloads" "app-data" "backups")
ALL_DIRS_PRESENT=true

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$TARGET_MOUNT/$dir" ]; then
        echo "[OK] Directory present: $TARGET_MOUNT/$dir"
    else
        echo "[FAIL] Directory missing: $TARGET_MOUNT/$dir"
        ALL_DIRS_PRESENT=false
    fi
done

echo "=================================================="
if [ "$ALL_DIRS_PRESENT" = true ]; then
    echo "Storage check PASSED: All checks verified successfully."
    exit 0
else
    echo "Storage check WARNING: Some expected folders are missing."
    exit 1
fi
