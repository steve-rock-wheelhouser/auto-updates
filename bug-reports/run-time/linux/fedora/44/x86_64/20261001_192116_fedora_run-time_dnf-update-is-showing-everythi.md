---
ticket_id: "BUG-20261001_192116"
title: "dnf update is showing everything is up to date and no reboots needed, but auto-updates shows reboot needed in red"
type: "run-time"
status: "open"
severity: "high"
project: "auto-updates"
package: "auto-updates-1.4.1-1.fc44.noarch.rpm"
os: "linux"
arch: "x86_64"
distro: "fedora"
distro_version: "44"
node: "user@10.0.0.166:2201"
commit: "7f93ded"
date: "2026-10-01T19:21:16Z"
closed_at: ""
resolved_by: ""
---

# [HIGH] dnf update is showing everything is up to date and no reboots needed, but auto-updates shows reboot needed in red

## Environment
- **Project**: `auto-updates`
- **Package**: `auto-updates-1.4.1-1.fc44.noarch.rpm`
- **Platform**: `linux / fedora 44 (x86_64)`
- **Architecture**: `x86_64`
- **Test Node**: `user@10.0.0.166:2201`
- **Git Commit**: `7f93ded`
- **Reported Date**: `2026-10-01T19:21:16Z`

## Problem Summary
dnf update is showing everything is up to date and no reboots needed, but auto-updates shows reboot needed in red

## Execution Output & Traceback
```text
No log output provided.
```

## Steps to Reproduce
1. Launch or verify `auto-updates` on fedora 44 (x86_64).
2. Observe reported runtime/installation behavior described above.
