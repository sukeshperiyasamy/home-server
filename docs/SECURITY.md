# Security Guidelines & Policies

## Sensitive Information & Secret Handling

* **Zero Secret Commitment**: Never commit `.env`, private keys (`.key`, `.pem`), certificates, API keys, database credentials, or password-manager vaults to Git.
* **Environment Files**: Local secret configuration must always reside in `.env`, which is strictly ignored by `.gitignore`.
* **Template Variables**: Only generic placeholders belong in `.env.example`.
* **File Browser Password Policy**: Initial administrator credentials must be retrieved from runtime container logs and rotated immediately. Never commit File Browser passwords or databases to Git.

## Network & Access Security

* **No Direct Port Exposure**: Do not forward router ports directly to server services.
* **Tailscale Mesh VPN**: Remote access must use Tailscale for authenticated, end-to-end encrypted tunnels.
* **Tailscale HTTPS**: Web services (Vaultwarden on port 443, File Browser on port 8443) are exposed through Tailscale Serve with automatic TLS, accessible only within the authenticated Tailnet.
* **Tailscale Funnel**: Funnel is permanently disabled to ensure zero exposure to the public internet.
* **SSH Hardening**:
  * Public-key authentication is preferred.
  * Root SSH login is restricted.
* **Least Privilege & Container Isolation**:
  * Application containers must run with minimum required capabilities and avoid privileged mode.
  * Container volume mounts are strictly scoped: File Browser has access only to `/mnt/storage/{documents,photos,videos,downloads}`, with physical isolation from `/mnt/storage/app-data` and `/mnt/storage/backups`.

## Data Encryption

* Any off-site or secondary backups containing personal documents or credentials must be strongly encrypted (e.g. via GPG or Age) before transmission.
