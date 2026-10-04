---
ticket_id: "BUG-20261004_141548_ubuntu"
type: "compilation"
status: "pending"
severity: "high"
project: "auto-updates"
package: "auto-updates_1.4.2-1_all.deb"
os: "linux"
arch: "x86_64"
distro: "ubuntu"
distro_version: "26.04"
node: "ubuntu"
commit: "12b3cab"
date: "2026-10-04T14:15:48Z"
closed_at: ""
resolved_by: ""
pending_at: "2026-10-04T14:26:24Z"
fixed_in: "1.4.3-1"
pending_reason: "Adapted test_cli.sh for Debian/Ubuntu reboot check paths via AUTO_UPDATES_OS_TYPE and REBOOT_REQUIRED_FILE, preventing DNF5 false failure during pre-build test gate in build_deb.sh"
---
# [HIGH] Ubuntu 26.04 Compilation Failure: auto-updates v1.4.2

## Environment
- **Project**: `auto-updates`
- **Package**: `auto-updates_1.4.2-1_all.deb`
- **Platform**: `linux / ubuntu 26.04 (x86_64)`
- **Architecture**: `x86_64`
- **Test Node**: `ubuntu`
- **Git Commit**: `12b3cab`
- **Reported Date**: `2026-10-04T14:15:48Z`

## Problem Summary
Ubuntu 26.04 Compilation Failure: auto-updates v1.4.2

## Execution Output & Traceback
```text
# Compilation Defect Report
**Project**: auto-updates
**Target Version**: v1.4.2
**Platform / Distro**: Ubuntu 26.04 (linux 26.04 x86_64)
**Origin Node**: ubuntu
**Git Commit**: `12b3cab`
**Failure Summary**: Compilation failed with exit code 2: Pre-build test suite in build_deb.sh failed on Ubuntu 26.04

## Build Log Snippet
```text
TASK [Report failure on current host] ******************************************
ok: [ubuntu] => {
    "msg": "❌ Build FAILED on ubuntu (ubuntu 26.04): FAIL: Expected 'REBOOT REQUIRED' when DNF5 exits 1, got:\n================================================================\n                   Auto-Updates Status v1.4.2                   \n================================================================\n  Timer Status             : inactive (disabled) (disabled)\n  Configured Mode          : security (Daily Security Updates Only)\n  Daily Schedule Time      : 03:30 (Local system time)\n  Next Scheduled Run       : None (timer not running)\n  Update Backend           : APT / Unattended-Upgrades (/usr/bin/apt-get)\n  Metadata Refresh         : enabled (query mirrors on every run)\n  Phased Updates           : standard (respect Ubuntu phased rollouts)\n  Reboot Policy            : never (Manual reboot only (recommended for workstations))\n  Reboot Delay             : Immediate (systemctl reboot)\n  Build Protection         : active (defers reboot if builds/inhibitors detected)\n  System Reboot Status     : Clean (No reboot required)\n  Log File                 : /var/log/auto-updates/auto-updates.log\n----------------------------------------------------------------\n  Quick CLI Reference & Prompts:\n    auto-updates -h              View full options and command help\n    auto-updates run             Trigger immediate update check & install\n    sudo auto-updates set-mode   security | all | weekly-all\n    sudo auto-updates set-reboot never | when-needed | when-changed\n    sudo auto-updates set-reboot-delay Delay in mins (0 = immediate reboot via systemctl reboot)\n    sudo auto-updates set-time   Change daily update time (e.g. 03:30)\n    sudo auto-updates set-day    Change weekly update day (e.g. Sun)\n    man auto-updates             Read system manual page\n================================================================"
}
TASK [Fail playbook if any Linux build target failed] **************************
[ERROR]: Task failed: Action failed: Multi-distro Linux compilation failed on one or more nodes. Failed nodes:     debian13  ubuntu
```

## Root Cause
In `tests/unit/test_cli.sh`, mock DNF5 reboot checks were added in v1.4.2. On Ubuntu 26.04, `bin/auto-updates` detects `os_type="deb"` (via `/etc/os-release`), where it checks `/run/reboot-required` and skips DNF5 queries. As a result, `auto-updates status` returns `Clean (No reboot required)`, causing `test_cli.sh` to fail: `FAIL: Expected 'REBOOT REQUIRED' when DNF5 exits 1`. Because `build-linux/build_deb.sh` runs `tests/run_tests.sh` before packaging, this failure halted the Ubuntu build.

## Suggested Remediation
1. Update `tests/unit/test_cli.sh` to only execute DNF5/needs-restarting mock tests on RPM-based distributions, or verify Debian/Ubuntu reboot status using `/run/reboot-required`.
2. Re-run compilation across the Linux fleet via Orchestra or remote build dispatcher.
```

## Steps to Reproduce
1. Launch or verify `auto-updates` on ubuntu 26.04 (x86_64).
2. Observe reported runtime/installation behavior described above.


## Pending Verification [2026-10-04T14:26:24Z]
- **Fix / Staging Notes**: Adapted test_cli.sh for Debian/Ubuntu reboot check paths via AUTO_UPDATES_OS_TYPE and REBOOT_REQUIRED_FILE, preventing DNF5 false failure during pre-build test gate in build_deb.sh
- **Target Candidate**: `1.4.3-1`
