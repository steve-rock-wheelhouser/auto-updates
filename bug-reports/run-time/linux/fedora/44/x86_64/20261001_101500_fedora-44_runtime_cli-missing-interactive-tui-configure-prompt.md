---
ticket_id: "BUG-20261001_101500"
title: "auto-updates CLI invocation does not launch interactive TUI dashboard or configure prompt"
type: "run-time"
status: "resolved"
severity: "medium"
project: "auto-updates"
package: "auto-updates-1.3.3-1"
os: "linux"
distro: "fedora"
distro_version: "44"
arch: "x86_64"
commit: "1be5c65"
date: "2026-10-01T10:15:00Z"
closed_at: "2026-10-01T10:25:00Z"
resolved_by: "1.4.0-1"
---

# [MEDIUM] auto-updates CLI invocation does not launch interactive TUI dashboard or configure prompt

## Environment
- **Project**: `auto-updates`
- **Package**: `auto-updates-1.3.3-1`
- **Platform**: `linux / fedora 44 (x86_64)`
- **Architecture**: `x86_64`
- **Reported Date**: `2026-10-01T10:15:00Z`
- **Fixed in Version**: `1.4.0-1`

## Problem Summary
When launching `auto-updates` from the GUI desktop launcher (`auto-updates.desktop`), the desktop entry explicitly passed `Exec=auto-updates tui`, which invoked `cmd_tui` and displayed the interactive `[c]` configure prompt.

However, when launching `auto-updates` directly from a CLI terminal prompt with no arguments, the user received only the static status dashboard and was exited immediately to the shell without any prompt or interactive configure menu (`[c]`).

This differed from the established Wheelhouser TUI standard (such as `git-tools`), where invoking the bare CLI utility from an interactive TTY terminal automatically presents the interactive TUI dashboard and menus, while non-interactive execution (e.g., pipes, scripts, cron jobs) produces static output and terminates cleanly without blocking on standard input.

## Root Cause
In `bin/auto-updates`, the command-line argument parser defaulted missing arguments directly to `status`:
```bash
ACTION="${1:-status}"
shift || true
```
The `cmd_status` function simply formatted and displayed system status information before returning 0. The interactive workflow was relegated exclusively to `cmd_tui`, which was only called if the user explicitly provided `tui`, `-i`, or `--wait`.

## Resolution
1. **Interactive TTY Detection & Dispatch**:
   Updated `bin/auto-updates` entry point dispatch to check whether standard input is an interactive terminal (`[ -t 0 ]`):
   ```bash
   if [ $# -eq 0 ]; then
       if [ -t 0 ]; then
           cmd_tui
           exit 0
       else
           cmd_status
           exit 0
       fi
   fi
   ```
2. **Standardized TUI Shortcuts**:
   Enhanced `cmd_tui` so that direct numeric shortcuts (`0`-`9`), action shortcuts (`r`/`R` for refresh, `p`/`P` for phased updates toggle on Debian/Ubuntu), and `c`/`C` are immediately accepted at the initial prompt.
3. **Regression Tests**:
   Added regression unit tests in `tests/unit/test_cli.sh`:
   - Validates that non-interactive execution (`auto-updates < /dev/null`) outputs the status dashboard and exits cleanly with 0 without blocking.
   - Validates using a pseudoterminal (PTY) that bare execution in an interactive terminal automatically prompts with `"Press [c] to configure, or Enter to close:"`.
