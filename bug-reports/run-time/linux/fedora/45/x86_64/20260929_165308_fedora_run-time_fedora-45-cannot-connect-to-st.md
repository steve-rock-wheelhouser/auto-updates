---
ticket_id: "BUG-20260929_165308"
type: "run-time"
status: "open"
severity: "low"
project: "auto-updates"
package: "auto-updates-1.3.2-1.fc45.noarch.rpm"
os: "linux"
arch: "x86_64"
distro: "fedora"
distro_version: "45"
node: "user@10.0.0.166:2207"
commit: "7a515ba"
date: "2026-09-29T16:53:08Z"
title: "Fedora 45 Cannot connect to staging.wheelhouser.com"
---

# [LOW] Fedora 45 Cannot connect to staging.wheelhouser.com

## Environment
- **Project**: `auto-updates`
- **Package**: `auto-updates-1.3.2-1.fc45.noarch.rpm`
- **Platform**: `linux / fedora 45 (x86_64)`
- **Architecture**: `x86_64`
- **Test Node**: `user@10.0.0.166:2207`
- **Git Commit**: `7a515ba`
- **Reported Date**: `2026-09-29T16:53:08Z`

## Problem Summary
Fedora 45 Cannot connect to staging.wheelhouser.com

## Execution Output & Traceback
```text
auto-updater tested and approved
```

## Steps to Reproduce
1. Launch or verify `auto-updates` on fedora 45 (x86_64).
2. Observe reported runtime/installation behavior described above.


## Verified & Accepted [2026-10-01T16:34:56Z]
- **Accepted By**: `Automated Agent`
- **Verification Notes**: Accepted: Tested and approved


## Reopened [2026-10-01T19:04:46Z]
- **Reopened By**: `Tester on staging.wheelhouser.com`
- **Status**: Reopened on Staging Hub.
