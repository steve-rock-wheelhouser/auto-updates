# auto-updates Bug Reports & QA Ticketing System

This directory maintains the file-based QA and issue tracking history for **auto-updates**.
Tickets are created automatically by the Wheelhouser Automated Fleet QA Harness
(`orchestra/scripts/test_candidate_fleet.sh`), via the Staging Hub (`staging.wheelhouser.com`),
or manually filed by maintainers.

## Directory Structure
Standardized enterprise 5-level hierarchy across all defect categories:
```text
bug-reports/
├── <type>/                     # installation | run-time | security | marketing
│   └── <os>/                   # linux | macos | windows | all
│       └── <distro>/           # fedora | rocky | ubuntu | debian | almalinux | macos | windows | all
│           └── <version>/      # 45 | 10.0 | 24.04 | 15 | 11 | all
│               └── <arch>/     # x86_64 | arm64 | all
│                   └── <YYYYMMDD_HHMMSS_<slug>.md>
```

### Hierarchy Breakdown:
- **`<type>`**: Category of defect (`installation`, `run-time`, `security`, `marketing`).
- **`<os>`**: Operating system family (`linux`, `macos`, `windows`, `all`).
- **`<distro>`**: Distribution or platform (`fedora`, `rocky`, `ubuntu`, `debian`, `almalinux`, `macos`, `windows`, `all`).
- **`<version>`**: Distribution release or OS version (`44`, `45`, `10.0`, `24.04`, `15`, `11`, `all`).
- **`<arch>`**: CPU architecture (`x86_64`, `arm64`, `all`).

### Canonical Examples:
- `bug-reports/installation/linux/fedora/45/x86_64/`
- `bug-reports/installation/macos/macos/15/arm64/`
- `bug-reports/run-time/windows/windows/11/x86_64/`
- `bug-reports/security/linux/rocky/10.0/x86_64/`
- `bug-reports/marketing/linux/fedora/45/x86_64/`
- `bug-reports/marketing/all/all/all/all/`

## Frontmatter Schema
Each ticket is formatted in standard Markdown with YAML frontmatter:
```yaml
---
ticket_id: "BUG-YYYYMMDD_HHMMSS"
title: "Concise summary of the defect"
type: "installation"          # installation | run-time | security | marketing
status: "open"                # open | in-progress | pending | resolved | closed
severity: "high"              # low | medium | high | critical
project: "auto-updates"
package: "package-filename.rpm"
os: "linux"                   # linux | macos | windows | all
distro: "rocky"               # rocky | fedora | ubuntu | debian | almalinux | macos | windows | all
distro_version: "10.0"        # 45 | 10.0 | 24.04 | 15 | 11 | all
arch: "x86_64"                # x86_64 | arm64 | all
node: "user@10.0.0.166:2202"
commit: "abcdef0"
date: "YYYY-MM-DDTHH:MM:SSZ"
closed_at: ""                 # Populated upon resolution
resolved_by: ""               # Populated upon resolution
---
```

## Ticket Lifecycle Management
Manage tickets using the central Orchestra CLI tool:
```bash
# List all open bug reports across projects
orchestra/scripts/manage_bugs.py list --status open

# List bugs for this project only
orchestra/scripts/manage_bugs.py list --project auto-updates

# Resolve / Close a bug ticket
orchestra/scripts/manage_bugs.py close BUG-YYYYMMDD_HHMMSS --reason "Enabled EPEL 10" --resolved-by "v0.15.0-2"

# Reopen a ticket
orchestra/scripts/manage_bugs.py reopen BUG-YYYYMMDD_HHMMSS
```
