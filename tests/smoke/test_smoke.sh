#!/usr/bin/env bash
# ==============================================================================
# tests/smoke/test_smoke.sh
# Smoke testing suite for auto-updates (AGENTS.md Rule 9)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${REPO_ROOT}"

echo "--- [Smoke Test] Verifying Core Executables and Entry Points ---"

# 1. Verify src/main.sh exists and extracts version
if [ ! -f "src/main.sh" ]; then
    echo "FAIL: src/main.sh not found!" >&2
    exit 1
fi
VERSION_SRC=$(grep -E '^\s*VERSION=' src/main.sh | head -n 1 | awk -F'"' '{print $2}')
if [ -z "${VERSION_SRC}" ]; then
    echo "FAIL: Unable to extract VERSION from src/main.sh!" >&2
    exit 1
fi
echo "  ✔ src/main.sh VERSION=${VERSION_SRC}"

# 2. Verify bin/auto-updates exists, is executable, and matches VERSION
if [ ! -x "bin/auto-updates" ]; then
    echo "FAIL: bin/auto-updates is not executable!" >&2
    exit 1
fi
CLI_VER_OUT=$(./bin/auto-updates --version 2>&1)
if [[ "${CLI_VER_OUT}" != *"${VERSION_SRC}"* ]]; then
    echo "FAIL: bin/auto-updates --version output ('${CLI_VER_OUT}') does not contain '${VERSION_SRC}'!" >&2
    exit 1
fi
echo "  ✔ bin/auto-updates --version matches src/main.sh (${VERSION_SRC})"

# 3. Verify bin/auto-updates --help exits 0 and provides usage info
CLI_HELP_OUT=$(./bin/auto-updates --help 2>&1)
if [[ "${CLI_HELP_OUT}" != *"USAGE:"* ]]; then
    echo "FAIL: bin/auto-updates --help did not output USAGE!" >&2
    exit 1
fi
echo "  ✔ bin/auto-updates --help outputs usage text"

# 4. Verify libexec/auto-updates-runner exists and has valid syntax
if [ ! -f "libexec/auto-updates-runner" ]; then
    echo "FAIL: libexec/auto-updates-runner not found!" >&2
    exit 1
fi
bash -n "libexec/auto-updates-runner"
echo "  ✔ libexec/auto-updates-runner syntax check passed"

# 5. Verify packaging spec matches VERSION
if [ -f "build-linux/auto-updates.spec" ]; then
    SPEC_VER=$(grep -E '^Version:' build-linux/auto-updates.spec | awk '{print $2}' | tr -d ' ')
    if [ "${SPEC_VER}" != "${VERSION_SRC}" ]; then
        echo "FAIL: build-linux/auto-updates.spec Version (${SPEC_VER}) does not match src/main.sh (${VERSION_SRC})!" >&2
        exit 1
    fi
    echo "  ✔ build-linux/auto-updates.spec Version matches src/main.sh (${VERSION_SRC})"
else
    echo "FAIL: build-linux/auto-updates.spec not found!" >&2
    exit 1
fi

# 6. Verify desktop and metainfo assets
if [ -f "desktop/auto-updates.desktop" ]; then
    if command -v desktop-file-validate &>/dev/null; then
        desktop-file-validate desktop/auto-updates.desktop
        echo "  ✔ desktop-file-validate passed"
    else
        echo "  ✔ desktop/auto-updates.desktop exists"
    fi
fi

if [ -f "desktop/auto-updates.metainfo.xml" ]; then
    if command -v appstreamcli &>/dev/null; then
        appstreamcli validate --no-net desktop/auto-updates.metainfo.xml || true
        echo "  ✔ appstreamcli validation checked"
    else
        echo "  ✔ desktop/auto-updates.metainfo.xml exists"
    fi
fi

echo "--- [Smoke Test] All Smoke Checks Passed! ---"
