# Mandatory Version Bump and Changelog Policy

## Core Principle
Never make source code modifications without an explicit version increment and a clear, descriptive changelog entry.

## Rules for Every Code Modification
Whenever making ANY code changes, refactors, bug fixes, or new features in this repository:

1. **Automated Version & Build Control (Single Source of Truth)**:
   - Primary application entry points (`src/main.sh`, `src/main.py`, `src/main.c`, `src/main.ps1`, etc.) serve as the single source of truth for `APP_VERSION` / `VERSION`. Never manually hardcode version increments across downstream scripts or packaging manifests.
   - For `auto-updates`, `src/main.sh` is the canonical single source of truth for `VERSION`.
   - When updating `VERSION = "X.Y.Z"` and adding the corresponding changelog entry (`# X.Y.Z - <description>`) in `src/main.sh`, build runners (`build-linux/build_rpm.sh`, `build-linux/build_deb.sh`) automatically inherit and propagate that version into downstream packages and manifests:
     - Linux RPM spec: `build-linux/auto-updates.spec` (`Version:`, `%changelog`)
     - Linux Debian packaging: `debian/changelog`, `debian/control`
     - AppStream catalog: `desktop/auto-updates.metainfo.xml` (`<release version="X.Y.Z" date="...">`)
     - Executable CLI & runner: `bin/auto-updates`, `libexec/auto-updates-runner`
     - System manpages: `man/auto-updates.8`, `man/auto-updates.conf.5`
     - Shell completions: `completions/auto-updates.bash`

2. **Add Header Changelog Entry**:
   - Add a numbered version entry to the top docstring / changelog comment section of `src/main.sh` and `bin/auto-updates`:
     `# X.Y.Z - Clear explanation of the fix or feature.`
   - Append a corresponding `%changelog` entry in `auto-updates.spec` and `debian/changelog`.
   - Ensure the summary accurately describes the changes made so all developers, packagers, and automated systems have an immediate source of truth.

3. **Zero Unversioned Code Changes**:
   - No silent or untracked changes. Every edit must be tied to a documented version increment.

4. **Commit Changes**:
   - Commit changes with a clear and descriptive commit message using `./push.sh` (or `git-tools push`).

5. **Cross-Platform Consistency**:
   - Wheelhouser LLC applications and developer tools are cross-platform and cross-architecture (Windows x86_64/ARM64, macOS x86_64/ARM64, Linux x86_64/ARM64). Ensure that source code, CLI parameters, security audits, and metadata are consistent and compatible across all supported platforms (POSIX Bash, PowerShell 5.1/7+, Windows Command Prompt, and Python).

6. **Packaging and Installation Integrity**:
   - Ensure native platform installers (`install_local.sh`, `publish.sh`, packaging scripts) maintain clean isolation, idempotency, and strict validation of system paths without breaking user shell environments.

7. **Windows Packaging Standard**:
   - When building Windows desktop packages, applications are packaged strictly as MSIX (`build-msix/AppxManifest.xml`). Inno Setup (`.iss` / `.exe` setup installers) and WiX MSI installers are deprecated and no longer supported.

8. **Epic and Architectural Documentation Archival**:
   - Always archive the `implementation_plan.md` and `walkthrough.md` into `epics/YYYY-MM-DD-<epic-name>/` and commit them to the repository for every epic, feature, or major architectural modification.

9. **Automated Testing Standards**:
   - All projects must have a `<project_name>/tests/` directory with at least one test script.
   - All tests must pass before any build steps can be taken.
   - All new features must have tests.
   - All bug fixes must have tests.
   - Tests shall be written in the same language as the code being tested (Bash/POSIX shell for `auto-updates`).
   - Regression testing must be performed before any build steps can be taken.
   - Complete or End-to-End (EtE) testing is composed of all automated tests.
   - Smoke testing can be a documented subset of the unit tests.

10. **Bug Report and Tracking Standards**:
   - All projects must maintain a dedicated `<project_name>/bug-reports/` directory for file-based QA and issue tracking.
   - **Directory & File Structure**:
     `<project_name>/bug-reports/<type>/<os>/<distro>/<version>/<arch>/<YYYYMMDD_HHMMSS_<slug>.md>`
     - **`<type>`**: Category of the issue:
       - `installation`: Package manager, installer script, MSIX/DMG/RPM/DEB packaging, PATH, or dependency failures.
       - `run-time`: Execution errors, crashes, CLI argument errors, timeouts, or UI/terminal glitches.
       - `security`: Credential leaks, permission escalations, CVEs, or pre-commit scanner bypasses.
       - `marketing`: AppStream metadata, store listings, banners, icons, or documentation discrepancies.
     - **`<os>`**: Operating system family (`linux`, `macos`, `windows`, `all`).
     - **`<distro>`**: Distribution or platform line (`rocky`, `fedora`, `ubuntu`, `debian`, `almalinux`, `macos`, `windows`, `all`).
     - **`<version>`**: Distribution or OS version line (`44`, `45`, `10.0`, `24.04`, `26.04`, `15`, `11`, `all`).
     - **`<arch>`**: System architecture (`x86_64`, `arm64`, `all`).
     - **Filename**: `<YYYYMMDD_HHMMSS_<descriptive-hyphenated-slug>.md>` timestamped to the ticket creation time.
   - **Required YAML Frontmatter Schema**:
     Every bug report markdown file must begin with valid YAML frontmatter:
     ```yaml
     ---
     ticket_id: "BUG-YYYYMMDD_HHMMSS"
     title: "Concise summary of the defect"
     type: "installation"          # installation | run-time | security | marketing
     status: "open"                # open | in-progress | pending | resolved | closed
     severity: "high"              # low | medium | high | critical
     project: "<project_name>"
     package: "<package_name-version>"
     os: "linux"                   # linux | macos | windows | all
     distro: "rocky"               # rocky | fedora | ubuntu | debian | almalinux | macos | windows | all
     distro_version: "10.0"        # 45 | 10.0 | 24.04 | 26.04 | 15 | 11 | all
     arch: "x86_64"                # x86_64 | arm64 | all
     commit: "abcdef0"
     date: "YYYY-MM-DDTHH:MM:SSZ"
     closed_at: ""                 # Populated upon resolution
     resolved_by: ""               # Populated upon resolution (commit or release version)
     ---
     ```
   - **Lifecycle & Resolution Rules**:
     - **Triage Status Flow**: `open` -> `in-progress` -> `pending` (awaiting fleet verification) -> `resolved` / `closed`.
     - **Resolution Documentation**: When resolving a ticket, populate `closed_at` and `resolved_by` in frontmatter, and append a markdown section to the body detailing the root cause, fix commit, and verification steps.
     - **Regression Test Requirement**: Per Rule 9, every resolved bug must be accompanied by an automated test in `<project_name>/tests/` verifying the defect does not regress.
     - **Central Hub Synchronization**: Sync ticket statuses with the Staging Hub (`staging.wheelhouser.com`) using `python3 orchestra/scripts/manage_bugs.py sync`.

11. **Security Audits**:
    - All versions must have security audits before release.
    - Results are documented in `<project_name>/security/<VERSION>_sec_audit.md`.

12. **Security Patching**:
    - All security issues must be patched before the next release.
    - All security issues must be documented in `<project_name>/bug-reports/security/<os>/<distro>/<version>/<arch>/<YYYYMMDD_HHMMSS_<slug>.md`.
