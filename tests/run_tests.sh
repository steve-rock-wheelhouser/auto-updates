#!/usr/bin/env bash
# ==============================================================================
# tests/run_tests.sh - Wheelhouser Master Automated Test Runner
# Executes Smoke and Unit test suites per AGENTS.md Rule 9.
# Returns 0 on complete pass, non-zero on any test failure.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

echo "========================================================================"
echo "🧪 Running Wheelhouser Automated Test Suite (AGENTS.md Rule 9)"
echo "   Target Project: auto-updates"
echo "========================================================================"

# --- Phase 1: Smoke Tests ---
echo "==> [1/2] Running Smoke Tests (tests/smoke/)..."
bash "${REPO_ROOT}/tests/smoke/test_smoke.sh"
echo "  ✔ Smoke Tests: PASSED"

# --- Phase 2: Unit & Regression Tests ---
echo "==> [2/2] Running Unit & Regression Tests (tests/unit/)..."
bash "${REPO_ROOT}/tests/unit/test_config.sh"
bash "${REPO_ROOT}/tests/unit/test_cli.sh"
echo "  ✔ Unit Tests: PASSED"

echo "========================================================================"
echo "✅ All Automated Tests Passed Successfully! Build Gate Cleared."
echo "========================================================================"
