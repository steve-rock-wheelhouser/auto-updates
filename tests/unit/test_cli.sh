#!/usr/bin/env bash
# ==============================================================================
# tests/unit/test_cli.sh
# Unit testing suite for auto-updates CLI syntax and arguments
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${REPO_ROOT}"

echo "--- [Unit Test] Testing CLI Argument Dispatch & Syntax Integrity ---"

# 1. Test script syntax across all shell scripts in the repository
for script in \
    "${REPO_ROOT}/bin/auto-updates" \
    "${REPO_ROOT}/libexec/auto-updates-runner" \
    "${REPO_ROOT}/src/main.sh" \
    "${REPO_ROOT}/build-linux/build_rpm.sh" \
    "${REPO_ROOT}/build-linux/build_deb.sh" \
    "${REPO_ROOT}/build-linux/install.sh" \
    "${REPO_ROOT}/build-linux/uninstall.sh"; do
    if [ -f "${script}" ]; then
        bash -n "${script}"
        echo "  ✔ Syntax check passed: $(basename "${script}")"
    fi
done

# 2. Test CLI options
# Help commands should exit 0
"${REPO_ROOT}/bin/auto-updates" help >/dev/null
"${REPO_ROOT}/bin/auto-updates" --help >/dev/null
"${REPO_ROOT}/bin/auto-updates" -h >/dev/null
echo "  ✔ Help commands exit 0"

# Version commands should exit 0
"${REPO_ROOT}/bin/auto-updates" version >/dev/null
"${REPO_ROOT}/bin/auto-updates" --version >/dev/null
"${REPO_ROOT}/bin/auto-updates" -v >/dev/null
echo "  ✔ Version commands exit 0"

# Invalid command should exit non-zero
set +e
"${REPO_ROOT}/bin/auto-updates" invalid-command-does-not-exist >/dev/null 2>&1
EXIT_CODE=$?
set -e

if [ "${EXIT_CODE}" -eq 0 ]; then
    echo "FAIL: Expected non-zero exit code for invalid CLI command!" >&2
    exit 1
fi
echo "  ✔ Invalid command correctly rejected with non-zero exit code"

# 3. Test non-interactive vs interactive CLI execution
# In non-interactive mode (e.g. redirected or stdin from /dev/null), bare command runs status and exits 0 cleanly without blocking
NON_INTERACTIVE_OUT=$("${REPO_ROOT}/bin/auto-updates" < /dev/null 2>&1)
if [[ "${NON_INTERACTIVE_OUT}" != *"Auto-Updates Status"* ]]; then
    echo "FAIL: Bare auto-updates in non-interactive mode did not produce status dashboard!" >&2
    exit 1
fi
echo "  ✔ Bare auto-updates in non-interactive mode runs status and exits cleanly"

# Test explicit status command
"${REPO_ROOT}/bin/auto-updates" status < /dev/null >/dev/null
echo "  ✔ auto-updates status exits 0"

# In interactive terminal mode (simulated via pty), bare command launches cmd_tui with prompt
PTY_OUTPUT=$(python3 -c "
import pty, os, select, time
master, slave = pty.openpty()
pid = os.fork()
if pid == 0:
    os.close(master)
    os.setsid()
    os.dup2(slave, 0)
    os.dup2(slave, 1)
    os.dup2(slave, 2)
    os.close(slave)
    os.execl('${REPO_ROOT}/bin/auto-updates', 'auto-updates')
else:
    os.close(slave)
    out = b''
    start = time.time()
    sent_newline = False
    # Wait up to 15 seconds for interactive prompt
    while time.time() - start < 15:
        r, _, _ = select.select([master], [], [], 0.2)
        if r:
            try:
                chunk = os.read(master, 1024)
                if not chunk:
                    break
                out += chunk
                if b'Press [c] to configure' in out and not sent_newline:
                    os.write(master, b'\n')
                    sent_newline = True
            except OSError:
                break
        else:
            if sent_newline:
                # Once prompt was received and newline sent, wait briefly for clean exit
                break
    os.close(master)
    try:
        os.waitpid(pid, 0)
    except OSError:
        pass
    print(out.decode('utf-8', errors='ignore'))
")
if [[ "${PTY_OUTPUT}" != *"Press [c] to configure, or Enter to close:"* ]]; then
    echo "FAIL: Bare auto-updates in interactive terminal did not prompt for configuration!" >&2
    exit 1
fi
echo "  ✔ Bare auto-updates in interactive terminal prompts for configuration ([c] to configure)"

# 4. Test completions file syntax
if [ -f "${REPO_ROOT}/completions/auto-updates.bash" ]; then
    bash -n "${REPO_ROOT}/completions/auto-updates.bash"
    echo "  ✔ Shell completion syntax valid"
fi

# 5. Regression Test: Reboot status detection does not falsely report REBOOT REQUIRED
# Test that status output contains valid System Reboot Status line
STATUS_OUT=$("${REPO_ROOT}/bin/auto-updates" status < /dev/null)
if [[ "${STATUS_OUT}" != *"System Reboot Status"* ]]; then
    echo "FAIL: Status output does not include System Reboot Status!" >&2
    exit 1
fi
echo "  ✔ System Reboot Status reported in status dashboard"

# Simulate environments with custom PATH containing mocks
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "${MOCK_DIR}"' EXIT

# --- Debian / Ubuntu Reboot Checks ---
# Case 1: Clean (no reboot required file)
DEB_CLEAN_OUT=$(AUTO_UPDATES_OS_TYPE="deb" REBOOT_REQUIRED_FILE="${MOCK_DIR}/nonexistent-flag" "${REPO_ROOT}/bin/auto-updates" status < /dev/null)
if [[ "${DEB_CLEAN_OUT}" != *"Clean (No reboot required)"* ]]; then
    echo "FAIL: Expected 'Clean (No reboot required)' on Debian/Ubuntu when reboot file absent, got:" >&2
    echo "${DEB_CLEAN_OUT}" >&2
    exit 1
fi
echo "  ✔ Debian/Ubuntu without reboot-required correctly reports 'Clean (No reboot required)'"

# Case 2: Reboot required (flag file exists)
touch "${MOCK_DIR}/reboot-required"
echo -e "linux-image-generic\nlibc6" > "${MOCK_DIR}/reboot-required.pkgs"
DEB_REBOOT_OUT=$(AUTO_UPDATES_OS_TYPE="deb" REBOOT_REQUIRED_FILE="${MOCK_DIR}/reboot-required" REBOOT_REQUIRED_PKGS_FILE="${MOCK_DIR}/reboot-required.pkgs" "${REPO_ROOT}/bin/auto-updates" status < /dev/null)
if [[ "${DEB_REBOOT_OUT}" != *"REBOOT REQUIRED"* ]] || [[ "${DEB_REBOOT_OUT}" != *"linux-image-generic"* ]]; then
    echo "FAIL: Expected 'REBOOT REQUIRED (Packages: linux-image-generic libc6)' on Debian/Ubuntu when reboot file exists, got:" >&2
    echo "${DEB_REBOOT_OUT}" >&2
    exit 1
fi
echo "  ✔ Debian/Ubuntu with reboot-required correctly reports 'REBOOT REQUIRED' and packages"

# --- DNF5 Reboot Checks (RPM Mode) ---
# Mock DNF5 that supports needs-restarting
cat <<'EOF' > "${MOCK_DIR}/dnf5"
#!/bin/bash
if [ "$1" = "needs-restarting" ] && [ "$2" = "--help" ]; then
    exit 0
fi
if [[ "$*" == *"--disablerepo="* ]] || [[ "$*" == *"--disablerepo '*'"* ]]; then
    exit "${MOCK_DNF5_EXIT:-0}"
fi
# Without disablerepo, simulate network error
exit 2
EOF
chmod +x "${MOCK_DIR}/dnf5"

# Case 3: DNF5 returns 0 (Clean)
CLEAN_OUT=$(AUTO_UPDATES_OS_TYPE="rpm" REBOOT_REQUIRED_FILE="${MOCK_DIR}/nonexistent-flag" MOCK_DNF5_EXIT=0 PATH="${MOCK_DIR}:${PATH}" "${REPO_ROOT}/bin/auto-updates" status < /dev/null)
if [[ "${CLEAN_OUT}" != *"Clean (No reboot required)"* ]]; then
    echo "FAIL: Expected 'Clean (No reboot required)' when DNF5 exits 0, got:" >&2
    echo "${CLEAN_OUT}" >&2
    exit 1
fi
echo "  ✔ DNF5 with --disablerepo='*' exit 0 correctly reports 'Clean (No reboot required)'"

# Case 4: DNF5 returns 1 (Reboot required)
REBOOT_OUT=$(AUTO_UPDATES_OS_TYPE="rpm" REBOOT_REQUIRED_FILE="${MOCK_DIR}/nonexistent-flag" MOCK_DNF5_EXIT=1 PATH="${MOCK_DIR}:${PATH}" "${REPO_ROOT}/bin/auto-updates" status < /dev/null)
if [[ "${REBOOT_OUT}" != *"REBOOT REQUIRED"* ]]; then
    echo "FAIL: Expected 'REBOOT REQUIRED' when DNF5 exits 1, got:" >&2
    echo "${REBOOT_OUT}" >&2
    exit 1
fi
echo "  ✔ DNF5 with --disablerepo='*' exit 1 correctly reports 'REBOOT REQUIRED'"

# Case 5: DNF5 returns non-zero error (> 1, e.g. cache or network error) -> does NOT falsely report REBOOT REQUIRED
ERR_OUT=$(AUTO_UPDATES_OS_TYPE="rpm" REBOOT_REQUIRED_FILE="${MOCK_DIR}/nonexistent-flag" MOCK_DNF5_EXIT=2 PATH="${MOCK_DIR}:${PATH}" "${REPO_ROOT}/bin/auto-updates" status < /dev/null)
if [[ "${ERR_OUT}" == *"REBOOT REQUIRED"* ]]; then
    echo "FAIL: DNF5 non-1 error code should not trigger REBOOT REQUIRED, got:" >&2
    echo "${ERR_OUT}" >&2
    exit 1
fi
echo "  ✔ DNF5 command error does not falsely report 'REBOOT REQUIRED'"

# --- Fallback: needs-restarting (when DNF5 is not available) ---
# Disable DNF5 in mock
cat <<'EOF' > "${MOCK_DIR}/dnf5"
#!/bin/bash
exit 1
EOF
chmod +x "${MOCK_DIR}/dnf5"

# Mock needs-restarting
cat <<'EOF' > "${MOCK_DIR}/needs-restarting"
#!/bin/bash
exit "${MOCK_NR_EXIT:-0}"
EOF
chmod +x "${MOCK_DIR}/needs-restarting"

# Case 6: needs-restarting returns 0 (Clean)
NR_CLEAN_OUT=$(AUTO_UPDATES_OS_TYPE="rpm" REBOOT_REQUIRED_FILE="${MOCK_DIR}/nonexistent-flag" MOCK_NR_EXIT=0 PATH="${MOCK_DIR}:${PATH}" "${REPO_ROOT}/bin/auto-updates" status < /dev/null)
if [[ "${NR_CLEAN_OUT}" != *"Clean (No reboot required)"* ]]; then
    echo "FAIL: Expected 'Clean (No reboot required)' when needs-restarting exits 0, got:" >&2
    echo "${NR_CLEAN_OUT}" >&2
    exit 1
fi
echo "  ✔ needs-restarting exit 0 correctly reports 'Clean (No reboot required)'"

# Case 7: needs-restarting returns 1 (Reboot required)
NR_REBOOT_OUT=$(AUTO_UPDATES_OS_TYPE="rpm" REBOOT_REQUIRED_FILE="${MOCK_DIR}/nonexistent-flag" MOCK_NR_EXIT=1 PATH="${MOCK_DIR}:${PATH}" "${REPO_ROOT}/bin/auto-updates" status < /dev/null)
if [[ "${NR_REBOOT_OUT}" != *"REBOOT REQUIRED"* ]]; then
    echo "FAIL: Expected 'REBOOT REQUIRED' when needs-restarting exits 1, got:" >&2
    echo "${NR_REBOOT_OUT}" >&2
    exit 1
fi
echo "  ✔ needs-restarting exit 1 correctly reports 'REBOOT REQUIRED'"

echo "--- [Unit Test] CLI Tests Passed! ---"
