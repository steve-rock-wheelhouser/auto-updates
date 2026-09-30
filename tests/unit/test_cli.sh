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

# 3. Test completions file syntax
if [ -f "${REPO_ROOT}/completions/auto-updates.bash" ]; then
    bash -n "${REPO_ROOT}/completions/auto-updates.bash"
    echo "  ✔ Shell completion syntax valid"
fi

echo "--- [Unit Test] CLI Tests Passed! ---"
