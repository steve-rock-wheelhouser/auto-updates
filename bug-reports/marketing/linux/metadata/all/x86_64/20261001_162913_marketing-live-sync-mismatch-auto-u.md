---
ticket_id: "BUG-20261001_162913"
type: "marketing"
status: "resolved"
severity: "high"
project: "auto-updates"
package: "auto-updates-1.4.1"
os: "linux"
arch: "x86_64"
distro: "metadata"
distro_version: ""
node: "local"
commit: "HEAD"
date: "2026-10-01T16:29:13Z"
closed_at: "2026-10-01T16:34:48Z"
resolved_by: "Resolved: Promoted auto-updates v1.4.1 to wheelhouserllc-repo, updated website product page and updates API version.json to 1.4.1, and verified 100% Stage 5 marketing pass"
accepted_by: "Automated Agent"
---
# [HIGH] Marketing & Live Sync Mismatch: auto-updates v1.4.1

## Environment
- **Project**: `auto-updates`
- **Package**: `auto-updates-1.4.1`
- **Platform**: `linux / metadata (x86_64)`
- **Architecture**: `x86_64`
- **Test Node**: `staging.wheelhouser.com / local`
- **Git Commit**: `HEAD`
- **Reported Date**: `2026-10-01T16:29:13Z`

## Problem Summary
Marketing & Live Sync Mismatch: auto-updates v1.4.1

## Execution Output & Traceback
```text
# Marketing Verification (Stage 5) Discrepancy Report
**Project**: auto-updates
**Target Version**: v1.4.1
**Detection**: Wheelhouser Orchestra Stage 5 Marketing Validator

## Identified Discrepancies
- ❌ App Card version badge mismatch: found 'v1.3.2' in wheelhouserllc-repo/index.html, expected 'v1.4.1'
- ❌ Product page metadata out of sync: meta-pill has '1.3.2-1', expected 'v1.4.1'; specs-list has '1.3.2-1', expected '1.4.1'
- ❌ version.json latest_version is '1.3.2', expected '1.4.1'
- ❌ No physical RPM or DEB packages matching version '1.4.1' found in wheelhouserllc-repo subtrees

## Required Remediation Steps
1. Update App Card version badge in `wheelhouserllc-repo/index.html` to `v1.4.1`.
2. Update product page `wheelhouser-website/products/auto-updates.html` meta-pill and specs list.
3. Run `wheelhouser-website/push.sh` and `wheelhouserllc-repo-scripts/update_repo.sh`.
4. Or run: `orchestra/scripts/validate_marketing.py --project auto-updates --version 1.4.1 --sync`
```

## Steps to Reproduce
1. Launch or verify `auto-updates` on metadata (x86_64).
2. Observe reported runtime/installation behavior described above.


## Verified & Accepted [2026-10-01T16:34:48Z]
- **Accepted By**: `Automated Agent`
- **Verification Notes**: Resolved: Promoted auto-updates v1.4.1 to wheelhouserllc-repo, updated website product page and updates API version.json to 1.4.1, and verified 100% Stage 5 marketing pass
