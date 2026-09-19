# Security Guidelines & Policies

## Sensitive Information & Secret Handling

* **Zero Secret Commitment**: Never commit `.env`, private keys (`.key`, `.pem`), certificates, API keys, database credentials, or password-manager vaults to Git.
* **Environment Files**: Local secret configuration must always reside in `.env`, which is strictly ignored by `.gitignore`.
* **Template Variables**: Only generic placeholders belong in `.env.example`.

## Network & Access Security

* **No Direct Port Exposure**: Do not forward router ports directly to server services.
* **Tailscale Mesh VPN**: Remote access must use Tailscale for authenticated, end-to-end encrypted tunnels.
* **SSH Hardening**:
  * Public-key authentication is preferred.
  * Root SSH login is restricted.
* **Least Privilege**: Application containers must run with minimum required capabilities and avoid privileged mode unless strictly necessary.

## Data Encryption

* Any off-site or secondary backups containing personal documents or credentials must be strongly encrypted (e.g. via GPG or Age) before transmission.
