---
ticket_id: "BUG-20260928_190114"
type: "installation"
status: "open"
severity: "high"
project: "auto-updates"
package: "auto-updates-1.2.1-1.fc45.noarch.rpm"
os: "linux"
arch: "x86_64"
distro: "fedora"
distro_version: "45"
node: "user@10.0.0.166:2207"
commit: "7c38be6"
date: "2026-09-28T23:01:14Z"
---

# Installation Failure: auto-updates on Fedora 45

## Environment
- **Node**: `user@10.0.0.166:2207`
- **Distribution**: `Fedora 45`
- **Package**: `auto-updates-1.2.1-1.fc45.noarch.rpm`
- **Git Commit**: `7c38be6`
- **Timestamp**: `2026-09-28 23:01:14 UTC`

## Execution Output & Error Traceback
```text
Warning: Permanently added '[10.0.0.166]:2207' (ED25519) to the list of known hosts.
--> Terminating any running instances of auto-updates...
--> Running: sudo dnf upgrade -y --nogpgcheck /tmp/auto-updates-1.2.1-1.fc45.noarch.rpm
--> dnf upgrade failed, trying dnf reinstall / install...
--> Installation failed to register package.
sudo: a password is required
sudo: a password is required
sudo: a password is required
```

## Reproduction Command
```bash
sudo apt-get install -y --reinstall /tmp/auto-updates-1.2.1-1.fc45.noarch.rpm  # (or sudo dnf upgrade -y --nogpgcheck)\nQT_QPA_PLATFORM=offscreen timeout 4 auto-updates
```
