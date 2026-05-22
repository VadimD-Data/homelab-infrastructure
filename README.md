# 🏗️ Production-Grade Homelab Infrastructure

A resilient, secure, and highly optimized single-node homelab infrastructure built on top of **Proxmox VE**. This repository documents the architecture, automation scripts, and system configurations used to host private cloud services and remote environments under a strict **Zero Trust** philosophy.

## 📌 Architecture Overview

The infrastructure leverages a hybrid networking model to securely expose applications without port forwarding, safeguarding the environment against external threats.

* **Hypervisor:** Proxmox VE (Debian-based) running on a dedicated Mini PC.
* **Networking (Zero Trust):** * **Tailscale:** Mesh VPN overlay for secure infrastructure management, SSH access, and administrative dashboards bypassing CGNAT.
    * **Cloudflare Tunnels:** Secure HTTPS ingress for public-facing web applications (`vadcloud.net`) with edge SSL/TLS termination.
* **Storage & Backups:** 512GB Primary SSD for OS and VM disks + 2TB External HDD dedicated to automated disaster recovery.

---

## 🛠️ Infrastructure Component Breakdown

### 1. Node Zero: Hypervisor Level (Proxmox VE)
* **Storage Lifespan Optimization:** Reduced kernel `swappiness` to `10` to minimize unnecessary disk writes and prevent premature SSD degradation.
* **Package Management:** Disabled the default enterprise repository and enabled the stable `No-Subscription` repository for reliable system updates.
* **Hardware Resilience:** BIOS configured for automatic power recovery (*Restore on AC Power Loss*) and optimized fan curves for thermal stability.

### 2. Virtual Machine 1: Linux Core Server (Services & Containers)
Hosts the application layer via Docker and standalone services.
* **Nextcloud Performance Optimization:** Migrated background jobs from AJAX to system-level `cron` tasks executed every 5 minutes, significantly reducing UI latency and database lock contention.
* **Docker Logging Policy:** Enforced global log rotation limits (`max-size: 50m`, `max-file: 3`) via `daemon.json` to mitigate the risk of disk space exhaustion.
* **Self-Healing Mechanisms:** Implemented a local watchdog script (`check_ssh.sh`) triggered via cron to monitor and automatically restore the SSH service in case of unexpected failure.

### 3. Virtual Machine 2: Secure Remote Desktop (Windows)
* Equipped with native **VirtIO** drivers and the **QEMU Guest Agent** to maximize I/O throughput and guarantee file system consistency during hypervisor-level snapshot backups.

---

## 🔒 Security Hardening & Observability

* **Identity & Access Management (IAM):** Mandated Multi-Factor Authentication (2FA/TOTP) across Proxmox VE administrative consoles and Nextcloud. SSH password authentication is disabled globally in favor of Ed25519 cryptographic keys.
* **Automated Backup Strategy:** Nightly zero-downtime backups executed at 02:00 (ZSTD compression, Snapshot mode) targeting the local 2TB drive. Implemented a retention policy of 7 daily and 4 weekly rotations.
* **Proactive Alerting & Event Streaming:** Integrated a custom Proxmox Notification Matcher. Local system mail events (such as hardware S.M.A.R.T. disk alerts) and backup failures bypass traditional blocked SMTP relays, streaming directly to a private **Telegram Bot Webhook** for instantaneous incident response.

---

## 💻 Infrastructure Map & Maintenance Cheat Sheet

### Network Topology

| Service | Local Scope | Remote Overlay (Tailscale) | Public Ingress | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Proxmox VE** | `192.168.1.X:8006` | `100.125.XX.XX:8006` | — | Admin Console (MFA Active) |
| **Linux VM** | `192.168.1.X` | `100.119.XX.XX` | — | Custom SSH Port (`2299`) |
| **CasaOS** | `:82` | `:82` | — | Internal Container Dashboard |
| **Nextcloud** | — | — | `https://vadcloud.net` | Public Cloud (MFA Active) |

### Critical Operations Reference

```bash
# Force remount storage arrays after unpredicted disconnections
mount -a

# Inspect block device UUIDs for persistent mounting (/etc/fstab)
blkid

# Force reload kernel virtual memory parameters
sysctl -p
