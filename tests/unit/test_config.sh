#!/usr/bin/env bash
# ==============================================================================
# tests/unit/test_config.sh
# Unit testing suite for auto-updates configuration parsing and validation
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${REPO_ROOT}"

echo "--- [Unit Test] Testing Configuration Parsing and Validation ---"

CONF_FILE="${REPO_ROOT}/config/auto-updates.conf"
if [ ! -f "${CONF_FILE}" ]; then
    echo "FAIL: Configuration template ${CONF_FILE} does not exist!" >&2
    exit 1
fi

# Test 1: Sourcing default configuration file
(
    # Subshell to isolate variables
    # shellcheck source=/dev/null
    source "${CONF_FILE}"

    # MODE validation
    if [[ ! "${MODE}" =~ ^(security|all|weekly-all|all-weekly)$ ]]; then
        echo "FAIL: Invalid default MODE='${MODE}'" >&2
        exit 1
    fi

    # SCHEDULE_TIME validation (HH:MM)
    if [[ ! "${SCHEDULE_TIME}" =~ ^[0-2][0-9]:[0-5][0-9]$ ]]; then
        echo "FAIL: Invalid SCHEDULE_TIME='${SCHEDULE_TIME}'" >&2
        exit 1
    fi

    # WEEKLY_DAY validation (Sun-Sat)
    if [[ ! "${WEEKLY_DAY}" =~ ^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)$ ]]; then
        echo "FAIL: Invalid WEEKLY_DAY='${WEEKLY_DAY}'" >&2
        exit 1
    fi

    # REBOOT policy validation
    if [[ ! "${REBOOT}" =~ ^(never|when-needed|when-changed)$ ]]; then
        echo "FAIL: Invalid REBOOT policy='${REBOOT}'" >&2
        exit 1
    fi

    # REBOOT_DELAY validation (numeric)
    if [[ ! "${REBOOT_DELAY}" =~ ^[0-9]+$ ]]; then
        echo "FAIL: Invalid REBOOT_DELAY='${REBOOT_DELAY}'" >&2
        exit 1
    fi

    # DEFER_REBOOT_IF_BUSY validation (boolean)
    if [[ ! "${DEFER_REBOOT_IF_BUSY}" =~ ^(true|false)$ ]]; then
        echo "FAIL: Invalid DEFER_REBOOT_IF_BUSY='${DEFER_REBOOT_IF_BUSY}'" >&2
        exit 1
    fi

    # INCLUDE_PHASED_UPDATES validation (boolean)
    if [[ ! "${INCLUDE_PHASED_UPDATES}" =~ ^(true|false)$ ]]; then
        echo "FAIL: Invalid INCLUDE_PHASED_UPDATES='${INCLUDE_PHASED_UPDATES}'" >&2
        exit 1
    fi

    echo "  ✔ Default configuration values pass strict schema validation"
)

# Test 2: Custom config overrides in temporary sandbox
TEMP_CONF=$(mktemp)
trap 'rm -f "${TEMP_CONF}"' EXIT

cat <<'EOF' > "${TEMP_CONF}"
MODE=weekly-all
SCHEDULE_TIME=04:15
WEEKLY_DAY=Sat
REBOOT=when-needed
REBOOT_DELAY=15
DEFER_REBOOT_IF_BUSY=false
INCLUDE_PHASED_UPDATES=true
EOF

(
    # Subshell
    # shellcheck source=/dev/null
    source "${TEMP_CONF}"

    [ "${MODE}" = "weekly-all" ] || exit 1
    [ "${SCHEDULE_TIME}" = "04:15" ] || exit 1
    [ "${WEEKLY_DAY}" = "Sat" ] || exit 1
    [ "${REBOOT}" = "when-needed" ] || exit 1
    [ "${REBOOT_DELAY}" = "15" ] || exit 1
    [ "${DEFER_REBOOT_IF_BUSY}" = "false" ] || exit 1
    [ "${INCLUDE_PHASED_UPDATES}" = "true" ] || exit 1

    echo "  ✔ Custom configuration overrides correctly parsed"
)

echo "--- [Unit Test] Configuration Tests Passed! ---"
