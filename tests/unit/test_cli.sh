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

echo "--- [Unit Test] CLI Tests Passed! ---"
