# Security Audit Report: <project_name> v<VERSION>

## Executive Summary
- **Project**: `<project_name>`
- **Version**: `<VERSION>`
- **Audit Date**: `YYYY-MM-DD`
- **Auditor / Evaluator**: `Wheelhouser Security QA / <Name>`
- **Target Git Commit**: `<commit_sha>`
- **Overall Status**: `PASSED | ACTION REQUIRED | FAILED`

---

## 1. Automated Secret & Credential Scanning
Pre-flight scan for hardcoded credentials, private keys, cloud tokens, and sensitive files using `git-tools scan-secrets`.

| Check | Tool / Command | Findings | Status |
| :--- | :--- | :--- | :--- |
| Sensitive Files (.env, .pem, .key) | `git-tools scan-secrets` | 0 detected | PASSED |
| Token / Password Regex Scan | `git-tools scan-secrets` | 0 detected | PASSED |
| Working Tree Cleanliness | `git status --porcelain` | Clean | PASSED |

**Scanner Output**:
```text
<paste output from git-tools scan-secrets or pre-commit scanner>
```

---

## 2. Dependency & Supply Chain Verification
Inspection of external dependencies, libraries, and submodules for known CVEs and security advisories.

| Dependency | Required Version | Installed Version | Advisory Status |
| :--- | :--- | :--- | :--- |
| Core Shell / System Binaries | POSIX Bash >= 4.4 | Bash 5.2+ | No known advisories |
| Package Managers | DNF / APT | System native | Clean |
| External Libraries | None (Pure Shell) | None | Zero third-party supply chain attack surface |

---

## 3. Filesystem Permissions & Least Privilege Audit
Validation of platform install scripts, desktop launchers, and binary execution privileges.

| Component | Target Location | Perms | Least Privilege Verification | Status |
| :--- | :--- | :--- | :--- | :--- |
| Management CLI | `/usr/bin/auto-updates` | `0755` | Root owned, executable by all, non-SUID | PASSED |
| Runner Daemon | `/usr/libexec/auto-updates-runner` | `0755` | Root owned, restricted invocation | PASSED |
| Configuration | `/etc/auto-updates/auto-updates.conf` | `0644` | Root writable only | PASSED |
| Systemd Units | `/usr/lib/systemd/system/` | `0644` | System service & timer definitions | PASSED |
| Log Directory | `/var/log/auto-updates/` | `0750` / `0640` | Restricted log read privileges | PASSED |
| Temporary Sandboxes | `/tmp` | `mktemp -d` | Clean trap cleanup on exit | PASSED |

---

## 4. Cross-Platform Binary Hardening & Packaging
Audit of packaging manifests, signing certificates, and sandbox entitlements across Linux distributions.

- **Linux RPM Packaging**:
  - Spec file permissions (`auto-updates.spec`): Standard `%defattr(-,root,root,-)`, executable `%attr(0755,root,root)`, config `%config(noreplace)`.
  - GPG Signature: Validated release signature pipeline (`build-linux/build_rpm.sh`).
- **Linux Debian Packaging**:
  - Permissions & Control (`build-linux/build_deb.sh`): Standard root ownership, safe file permissions, conforming to Debian policy.

---

## 5. Security Defects & Remediation (Rule 12)
List of any security bugs filed or remediated during this release cycle.

| Ticket ID | Severity | Problem Description | Resolution / Commit | Status |
| :--- | :--- | :--- | :--- | :--- |
| *(None)* | -- | No open security vulnerabilities reported | -- | PASSED |

---

## 6. Final Certification & Sign-Off
- [x] All automated secret scanning completed with zero defects.
- [x] All automated regression, smoke, and unit tests passed.
- [x] No unpatched security issues remain open (AGENTS.md Rule 12).
- [x] Package artifacts verified against supply-chain tampering.

**Sign-off**: `CERTIFIED FOR RELEASE`
**Date**: `YYYY-MM-DD`
