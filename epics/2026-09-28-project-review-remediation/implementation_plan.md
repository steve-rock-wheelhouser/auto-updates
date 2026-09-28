# Implementation Plan - Auto-Updates Project Review Remediation (v1.1.2)

Remediate issues identified in the Auto-Updates project review, bring the project into strict compliance with `AGENTS-GLOBAL.md` and `AGENTS-BUILD.md`, bump version to `1.1.2` (incorporating upstream v1.1.1 icon updates) per the Mandatory Version Bump policy in `AGENTS.md`, implement `publish.sh`, and publish updated packages to the Wheelhouser Linux repository.

## Proposed Changes

### 1. Fix Critical Bugs in CLI & Runner

#### [bin/auto-updates](file:///home/user/Projects/auto-updates/bin/auto-updates)
- Fix command dispatcher in `case "$ACTION" in` to match `set-mode|mode)` so `auto-updates set-mode <mode>` succeeds.
- In `completions/auto-updates.bash`, add `set-mode` to `commands`.
- Standardize `LOG_FILE` default in `load_config()` to `/var/log/auto-updates/auto-updates.log`.
- In `cmd_status()` and `cmd_logs()`, gracefully fallback or handle unprivileged access if the log file is `0640` root-owned.

#### [libexec/auto-updates-runner](file:///home/user/Projects/auto-updates/libexec/auto-updates-runner)
- In dry-run mode (`--dry-run`):
  - Do NOT modify `/etc/dnf/automatic.conf` on disk.
  - On RPM systems, use `dnf $REFRESH_OPT check-upgrade` or `dnf5 $REFRESH_OPT check-upgrade --security` directly to inspect available updates without triggering downloads or mutating config.
  - On Debian/Ubuntu, continue using `unattended-upgrade --dry-run` or `apt-get -s dist-upgrade`.

#### [config/auto-updates.logrotate](file:///home/user/Projects/auto-updates/config/auto-updates.logrotate)
- Update path matching to `/var/log/auto-updates/*.log /var/log/auto-updates.log` to rotate both directory and legacy file locations.

#### [auto-updates.spec](file:///home/user/Projects/auto-updates/auto-updates.spec)
- Bump version to `1.1.1`, `Release: 1%{?dist}`.
- Add `Recommends: yum-utils` so `needs-restarting` is present on RHEL/CentOS/Rocky for reboot policy `when-needed`.
- Update `%changelog` with release notes for `1.1.1-1`.

#### [src/main.sh](file:///home/user/Projects/auto-updates/src/main.sh)
- Add `VERSION="1.1.1"`.
- Use `$VERSION` variable in header banner.
- Add changelog entry for `1.1.1` to the file header roadmap.
- In `show_menu()`, add native support for installing `.deb` if on Debian/Ubuntu systems.

---

### 2. Packaging & Build Pipeline Modernization

#### [build_rpm.sh](file:///home/user/Projects/auto-updates/build_rpm.sh)
- Bump `VERSION="1.1.1"`.
- Standardize output directory hierarchy per `AGENTS-BUILD.md`:
  `build-linux/Output/<distro>/<releasever>/` (e.g. `build-linux/Output/rocky/10/`, `build-linux/Output/almalinux/10/`, `build-linux/Output/fedora/44/`).
  Also maintain convenient copies in `dist/`.
- Cross-build packages using `--define "dist .el10"` and `--define "dist .fc44"`.
- Enforce strict signature verification without permissive fallbacks:
  Assert `rpm -Kv "$pkg" | grep -qiE "Header.*Signature.*OK"` on all built RPMs.

#### [build_deb.sh](file:///home/user/Projects/auto-updates/build_deb.sh)
- Bump `VERSION="1.1.1"`.
- Route built `.deb` into `build-linux/Output/debian/13/` and `build-linux/Output/ubuntu/26.04/` (and maintain `dist/` copy).

#### [debian/changelog](file:///home/user/Projects/auto-updates/debian/changelog)
- Add entry for `1.1.1-1`.

#### [man/auto-updates.8](file:///home/user/Projects/auto-updates/man/auto-updates.8) & [man/auto-updates.conf.5](file:///home/user/Projects/auto-updates/man/auto-updates.conf.5)
- Bump version to `1.1.1`.
- Ensure `set-mode` is listed alongside `mode`.

#### [.gitignore](file:///home/user/Projects/auto-updates/.gitignore)
- Add `*.deb`, `build-linux/Output/`, and sensitive key patterns per `AGENTS-GLOBAL.md`.

---

### 3. Repository Deployment Pipeline (`publish.sh`)

#### [NEW] [publish.sh](file:///home/user/Projects/auto-updates/publish.sh)
- Create root `publish.sh` in `auto-updates/` to deploy built packages into [`wheelhouserllc-repo`](file:///home/user/Projects/wheelhouserllc-repo):
  - Copies `noarch` RPMs to `rocky/10/{x86_64,aarch64}`, `almalinux/10/{x86_64,aarch64}`, and `fedora/44/{x86_64,aarch64}`.
  - Copies `all` DEBs to `debian/13/` and `ubuntu/26.04/`.
  - Executes [`wheelhouserllc-repo-scripts/update_repo.sh`](file:///home/user/Projects/wheelhouserllc-repo-scripts/update_repo.sh) to sign packages, rebuild RPM `repodata`, generate signed APT metadata (`Release`, `InRelease`), and commit/sync the repository.

---

## Verification Plan

### Automated Tests
1. **Shell Syntax Check**:
   ```bash
   bash -n bin/auto-updates libexec/auto-updates-runner build_rpm.sh build_deb.sh install_local.sh publish.sh src/main.sh completions/auto-updates.bash
   ```
2. **CLI Command Verification**:
   - Test `sudo auto-updates set-mode all` (assert success without unknown command error).
   - Test `auto-updates status`.
   - Test `auto-updates check` (verify `/etc/dnf/automatic.conf` remains unchanged).
3. **Build & Signature Verification**:
   - Run `./build_rpm.sh` -> verify packages built and signed in `build-linux/Output/` with `rpm -Kv` reporting OK.
   - Run `./build_deb.sh` -> verify `.deb` package built in `build-linux/Output/`.
4. **Publishing Pipeline**:
   - Run `./publish.sh` -> verify packages are placed in `wheelhouserllc-repo`, `createrepo_c` and `update_deb_repo.py` succeed.
5. **Git & Epic Traceability**:
   - Generate `walkthrough.md` in `epics/2026-09-28-project-review-remediation/`.
   - Commit changes with Conventional Commits.
