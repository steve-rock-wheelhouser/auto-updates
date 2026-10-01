---
ticket_id: "BUG-20261001_192116"
type: "run-time"
status: "resolved"
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
closed_at: "2026-10-01T19:57:13Z"
resolved_by: "1.4.2-1"
title: "dnf update is showing everything is up to date and no reboots needed, but auto-updates shows reboot needed in red"
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
- **Fixed in Version**: `1.4.2-1`

## Problem Summary
When running `auto-updates status` on Fedora 44, the dashboard reported `System Reboot Status: REBOOT REQUIRED (Kernel or core libraries updated since boot)` in red, even though `dnf update` and manual inspection indicated the system was fully up to date and no reboot was needed.

## Root Cause
In `bin/auto-updates` and `libexec/auto-updates-runner`, the DNF5 reboot check used `dnf5 --cacheonly needs-restarting -r`:
1. **Cache-Only Failure on Expired Cache**: When local repository metadata cache expired or was invalidated, DNF5 failed with exit code 1 (`Cache-only enabled but no cache for repository`).
2. **Binary Condition Fallback**: The CLI script checked `if dnf5 --cacheonly needs-restarting -r ... then Clean; else REBOOT REQUIRED; fi`. Consequently, ANY non-zero exit code (including cache misses, network failures, or command errors) was treated as a reboot requirement.
3. **Runner Network Query**: In `auto-updates-runner`, running `dnf5 needs-restarting -r` without repo restrictions triggered remote repository mirror queries, causing transient network errors to trigger unwanted system reboots.

## Resolution
1. **Offline Repository Bypassing**:
   Updated both `bin/auto-updates` and `libexec/auto-updates-runner` to invoke `dnf5 --disablerepo='*' needs-restarting -r`. By disabling remote repositories, DNF5 inspects local RPM database entries and running process file descriptors without attempting remote mirror connections or relying on cached repository metadata.
2. **Explicit Exit Code Semantics**:
   - Exit code `0`: Indicates no running process is using deleted/updated libraries (`Clean (No reboot required)`).
   - Exit code `1`: Indicates kernel or core system libraries have been replaced (`REBOOT REQUIRED`).
   - Exit code `> 1`: Indicates command or environment errors, which are not treated as reboot triggers.
3. **Automated Regression Suite**:
   Added comprehensive regression test cases in `tests/unit/test_cli.sh` mocking both DNF5 and legacy `needs-restarting` across exit codes 0, 1, and 2.
4. **Live Verification**:
   Deployed `auto-updates-1.4.2-1.fc44.noarch.rpm` to `user@10.0.0.166:2201`. Verified `auto-updates status` reports `System Reboot Status: Clean (No reboot required)` in green, and `sudo auto-updates-runner --dry-run` executes cleanly.


## Reopened [2026-10-01T19:56:57Z]
- **Reopened By**: `Tester on staging.wheelhouser.com`
- **Status**: Reopened on Staging Hub.

- **Update [2026-10-01T19:57:13Z]**: Fixed false-positive DNF5 reboot check by adding --disablerepo='*' and checking exit code 1
