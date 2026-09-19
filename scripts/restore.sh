#!/usr/bin/env bash
# ==============================================================================
# restore.sh - Vaultwarden Disaster Recovery & Restore
# ==============================================================================
# Restores Vaultwarden from a verified backup archive:
# 1. Validates archive existence and SHA256 checksum
# 2. Inspects archive contents
# 3. Stops the Vaultwarden container
# 4. Creates a safety snapshot of current data before replacement
# 5. Restores database and keys
# 6. Runs integrity checks on restored database
# 7. Restarts Vaultwarden and waits for container health check
# 8. Verifies HTTP 200 on /api/config
#
# Usage: ./scripts/restore.sh /path/to/vaultwarden_backup_YYYYMMDD_HHMMSS.tar.gz
# ==============================================================================

set -euo pipefail

# Configuration
DATA_DIR="${DATA_DIR:-/mnt/storage/app-data/vaultwarden}"
COMPOSE_FILE="${COMPOSE_FILE:-/home/sukesh/home-server/docker-compose.yml}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-45}"
TEMP_RESTORE_DIR=""

log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*"; }
log_warn()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]  $*" >&2; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2; }

cleanup() {
    if [[ -n "${TEMP_RESTORE_DIR}" && -d "${TEMP_RESTORE_DIR}" ]]; then
        rm -rf "${TEMP_RESTORE_DIR}"
    fi
}
trap cleanup EXIT INT TERM

# Argument check
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-backup-archive.tar.gz>" >&2
    echo "Example: $0 /mnt/storage/backups/vaultwarden/latest.tar.gz" >&2
    exit 1
fi

ARCHIVE_PATH="$1"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    log_error "Archive file '${ARCHIVE_PATH}' does not exist."
    exit 1
fi

# Resolve full path
ARCHIVE_PATH="$(readlink -f "${ARCHIVE_PATH}")"
ARCHIVE_DIR="$(dirname "${ARCHIVE_PATH}")"
ARCHIVE_FILE="$(basename "${ARCHIVE_PATH}")"

log_info "Starting Vaultwarden restore process..."
log_info "Selected archive: ${ARCHIVE_PATH}"

# Step 1: Verify SHA256 Checksum
SHA256_FILE="${ARCHIVE_PATH}.sha256"
if [[ -f "${SHA256_FILE}" ]]; then
    log_info "Verifying SHA256 checksum from ${SHA256_FILE}..."
    (cd "${ARCHIVE_DIR}" && sha256sum -c "${SHA256_FILE}") || {
        log_error "SHA256 checksum verification failed!"
        exit 2
    }
    log_info "SHA256 checksum verification: OK"
else
    log_warn "No .sha256 file found at '${SHA256_FILE}'. Proceeding with caution..."
fi

# Step 2: Validate Archive Structure
log_info "Validating archive contents..."
ARCHIVE_CONTENTS="$(tar -tzf "${ARCHIVE_PATH}")"
if ! echo "${ARCHIVE_CONTENTS}" | grep -q "vaultwarden_backup/db.sqlite3"; then
    log_error "Archive is missing required 'vaultwarden_backup/db.sqlite3'!"
    exit 3
fi
if ! echo "${ARCHIVE_CONTENTS}" | grep -q "vaultwarden_backup/rsa_key.pem"; then
    log_error "Archive is missing required 'vaultwarden_backup/rsa_key.pem'!"
    exit 3
fi
log_info "Archive contents verified: valid"

# Step 3: Staging Extraction & Database Integrity Check Before Replacing Live Data
TEMP_RESTORE_DIR="$(mktemp -d -p /tmp vw_restore_XXXXXX)"
log_info "Extracting archive to temporary staging directory..."
tar -xzf "${ARCHIVE_PATH}" -C "${TEMP_RESTORE_DIR}"

STAGED_DIR="${TEMP_RESTORE_DIR}/vaultwarden_backup"
log_info "Verifying SQLite integrity on staged database..."
INTEGRITY_CHECK="$(sqlite3 "${STAGED_DIR}/db.sqlite3" "PRAGMA integrity_check;")"
if [[ "${INTEGRITY_CHECK}" != "ok" ]]; then
    log_error "Staged database integrity check failed: ${INTEGRITY_CHECK}"
    exit 4
fi
log_info "Staged database integrity: ok"

# Step 4: Stop Vaultwarden Container
log_info "Stopping Vaultwarden container before replacing live data..."
docker compose -f "${COMPOSE_FILE}" stop vaultwarden

# Step 5: Create Pre-Restore Safety Snapshot of Live Data
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PRE_RESTORE_SNAPSHOT="/mnt/storage/app-data/vaultwarden.pre-restore-${TIMESTAMP}"
log_info "Creating pre-restore safety snapshot at ${PRE_RESTORE_SNAPSHOT}..."
if [[ -d "${DATA_DIR}" ]]; then
    cp -a "${DATA_DIR}" "${PRE_RESTORE_SNAPSHOT}"
    log_info "Pre-restore snapshot created successfully."
else
    mkdir -p "${DATA_DIR}"
fi

# Step 6: Deploy Restored Data
log_info "Restoring files into ${DATA_DIR}..."
# Remove old WAL/SHM locks from live dir if present
rm -f "${DATA_DIR}/db.sqlite3-wal" "${DATA_DIR}/db.sqlite3-shm" "${DATA_DIR}/db.sqlite3"

# Copy staged files
cp -p "${STAGED_DIR}/db.sqlite3" "${DATA_DIR}/"
cp -p "${STAGED_DIR}/rsa_key.pem" "${DATA_DIR}/"

if [[ -f "${STAGED_DIR}/rsa_key.pub.pem" ]]; then
    cp -p "${STAGED_DIR}/rsa_key.pub.pem" "${DATA_DIR}/"
fi

if [[ -d "${STAGED_DIR}/attachments" ]]; then
    rm -rf "${DATA_DIR}/attachments"
    cp -a "${STAGED_DIR}/attachments" "${DATA_DIR}/"
fi

if [[ -d "${STAGED_DIR}/sends" ]]; then
    rm -rf "${DATA_DIR}/sends"
    cp -a "${STAGED_DIR}/sends" "${DATA_DIR}/"
fi

# Step 7: Restart Vaultwarden Container
log_info "Starting Vaultwarden container..."
docker compose -f "${COMPOSE_FILE}" start vaultwarden

# Step 8: Health Check Verification
log_info "Waiting for Vaultwarden container to become healthy (timeout: ${HEALTH_TIMEOUT}s)..."
START_TIME="$(date +%s)"
HEALTHY=false

while true; do
    CURRENT_TIME="$(date +%s)"
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    STATUS="$(docker inspect vaultwarden --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' 2>/dev/null || echo 'unknown')"
    
    if [[ "${STATUS}" == "healthy" ]]; then
        HEALTHY=true
        break
    fi
    
    if [[ ${ELAPSED} -ge ${HEALTH_TIMEOUT} ]]; then
        break
    fi
    
    sleep 2
done

if [[ "${HEALTHY}" != "true" ]]; then
    log_error "Vaultwarden did not reach healthy state within ${HEALTH_TIMEOUT}s (status: ${STATUS})!"
    log_warn "Pre-restore safety snapshot is preserved at: ${PRE_RESTORE_SNAPSHOT}"
    exit 5
fi
log_info "Vaultwarden container is running and healthy."

# Step 9: API Endpoint Verification
log_info "Verifying Vaultwarden API endpoint..."
HTTP_CODE="$(curl -k -s -o /dev/null -w "%{http_code}" https://pi-server.tail1040b5.ts.net/api/config || echo '000')"

if [[ "${HTTP_CODE}" == "200" ]]; then
    log_info "Vaultwarden API returned HTTP 200 OK."
    log_info "Restore completed successfully!"
    log_info "Pre-restore backup retained at: ${PRE_RESTORE_SNAPSHOT}"
else
    log_error "API check failed with HTTP ${HTTP_CODE}!"
    log_warn "Pre-restore snapshot preserved at: ${PRE_RESTORE_SNAPSHOT}"
    exit 6
fi

exit 0
