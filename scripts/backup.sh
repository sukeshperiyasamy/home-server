#!/usr/bin/env bash
# ==============================================================================
# backup.sh - Vaultwarden Application-Aware Online Backup
# ==============================================================================
# Performs an ACID-compliant live SQLite snapshot using the SQLite Online Backup
# API, captures RSA key files and user uploads, verifies database integrity,
# packages into a compressed tarball, generates SHA256 checksums, and prunes
# expired archives according to RETENTION_DAYS.
#
# Safe for live/zero-downtime execution while Vaultwarden is running.
# ==============================================================================

set -euo pipefail

# Configuration
DATA_DIR="${DATA_DIR:-/mnt/storage/app-data/vaultwarden}"
BACKUP_BASE_DIR="${BACKUP_BASE_DIR:-/mnt/storage/backups/vaultwarden}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE_NAME="vaultwarden_backup_${TIMESTAMP}.tar.gz"
TEMP_DIR=""

# Logging functions
log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  $*"; }
log_warn()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]  $*" >&2; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2; }

# Trap to ensure cleanup of temporary staging files
cleanup() {
    local exit_code=$?
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
    if [[ ${exit_code} -ne 0 ]]; then
        log_error "Backup process aborted or failed with exit code ${exit_code}."
    fi
}
trap cleanup EXIT INT TERM

# Prerequisite checks
if ! command -v sqlite3 >/dev/null 2>&1; then
    log_error "sqlite3 CLI utility is required but not installed. Install with: sudo apt install -y sqlite3"
    exit 1
fi

if [[ ! -d "${DATA_DIR}" ]]; then
    log_error "Data directory '${DATA_DIR}' does not exist."
    exit 1
fi

if [[ ! -f "${DATA_DIR}/db.sqlite3" ]]; then
    log_error "Database '${DATA_DIR}/db.sqlite3' not found."
    exit 1
fi

if [[ ! -f "${DATA_DIR}/rsa_key.pem" ]]; then
    log_error "Required RSA private key '${DATA_DIR}/rsa_key.pem' not found."
    exit 1
fi

# Ensure backup destination directory exists
mkdir -p "${BACKUP_BASE_DIR}"

log_info "Starting Vaultwarden backup..."
log_info "Source data: ${DATA_DIR}"
log_info "Target directory: ${BACKUP_BASE_DIR}"

# Create secure temporary staging directory
TEMP_DIR="$(mktemp -d -p /tmp vw_backup_XXXXXX)"
STAGING_DIR="${TEMP_DIR}/vaultwarden_backup"
mkdir -p "${STAGING_DIR}"

# Step 1: Online SQLite Backup
# Uses the SQLite Online Backup API to safely copy the live WAL-mode database
log_info "Creating online database snapshot using SQLite Online Backup API..."
sqlite3 "${DATA_DIR}/db.sqlite3" ".backup '${STAGING_DIR}/db.sqlite3'"

# Step 2: Integrity Verification of the Snapshot
log_info "Verifying integrity of database snapshot..."
INTEGRITY_CHECK="$(sqlite3 "${STAGING_DIR}/db.sqlite3" "PRAGMA integrity_check;")"
if [[ "${INTEGRITY_CHECK}" != "ok" ]]; then
    log_error "Database integrity check failed: ${INTEGRITY_CHECK}"
    exit 2
fi
log_info "Database snapshot integrity verified: ok"

# Step 3: Copy Required Key and User Data Files
log_info "Copying authentication keys and user data..."
cp -p "${DATA_DIR}/rsa_key.pem" "${STAGING_DIR}/"

if [[ -f "${DATA_DIR}/rsa_key.pub.pem" ]]; then
    cp -p "${DATA_DIR}/rsa_key.pub.pem" "${STAGING_DIR}/"
fi

if [[ -d "${DATA_DIR}/attachments" && $(ls -A "${DATA_DIR}/attachments" 2>/dev/null) ]]; then
    log_info "Including attachments directory..."
    cp -a "${DATA_DIR}/attachments" "${STAGING_DIR}/"
else
    mkdir -p "${STAGING_DIR}/attachments"
fi

if [[ -d "${DATA_DIR}/sends" && $(ls -A "${DATA_DIR}/sends" 2>/dev/null) ]]; then
    log_info "Including sends directory..."
    cp -a "${DATA_DIR}/sends" "${STAGING_DIR}/"
else
    mkdir -p "${STAGING_DIR}/sends"
fi

# Step 4: Collect Metadata
VAULTWARDEN_IMAGE="unknown"
if command -v docker >/dev/null 2>&1 && docker inspect vaultwarden >/dev/null 2>&1; then
    VAULTWARDEN_IMAGE="$(docker inspect vaultwarden --format '{{.Config.Image}}' 2>/dev/null || echo 'unknown')"
fi

FILE_LIST="$(cd "${STAGING_DIR}" && find . -maxdepth 2 -type f | sort | tr '\n' ',' | sed 's/,$//')"

cat <<METADATA > "${STAGING_DIR}/metadata.json"
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "vaultwarden_image": "${VAULTWARDEN_IMAGE}",
  "database_engine": "sqlite3",
  "database_integrity": "${INTEGRITY_CHECK}",
  "backed_up_files": "${FILE_LIST}"
}
METADATA

# Step 5: Create Compressed Archive
ARCHIVE_PATH="${BACKUP_BASE_DIR}/${ARCHIVE_NAME}"
log_info "Compressing archive to ${ARCHIVE_PATH}..."
tar -czf "${ARCHIVE_PATH}" -C "${TEMP_DIR}" "vaultwarden_backup"

# Step 6: Generate SHA256 Checksum
log_info "Generating SHA256 checksum..."
(cd "${BACKUP_BASE_DIR}" && sha256sum "${ARCHIVE_NAME}" > "${ARCHIVE_NAME}.sha256")

# Step 7: Update latest pointers
(cd "${BACKUP_BASE_DIR}" && ln -sf "${ARCHIVE_NAME}" latest.tar.gz && ln -sf "${ARCHIVE_NAME}.sha256" latest.tar.gz.sha256)

ARCHIVE_SIZE="$(du -h "${ARCHIVE_PATH}" | awk '{print $1}')"
log_info "Backup created successfully: ${ARCHIVE_NAME} (${ARCHIVE_SIZE})"

# Step 8: Retention Pruning
if [[ "${RETENTION_DAYS}" -gt 0 ]]; then
    log_info "Pruning backups older than ${RETENTION_DAYS} days..."
    find "${BACKUP_BASE_DIR}" -maxdepth 1 -name "vaultwarden_backup_*.tar.gz" -mtime +"${RETENTION_DAYS}" -exec rm -f {} +
    find "${BACKUP_BASE_DIR}" -maxdepth 1 -name "vaultwarden_backup_*.tar.gz.sha256" -mtime +"${RETENTION_DAYS}" -exec rm -f {} +
fi

log_info "Backup complete."
exit 0
