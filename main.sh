#!/bin/bash
# ==============================================================================
# main.sh
# Entry point and management utility for the Auto-Updates project
#
# Copyright (C) 2026 Steve Rock Wheelhouser <steve@wheelhouser.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Roadmap and Changelog:
# 0.1.0 - Initial prototype for dnf-automatic configuration
# 1.0.0 - Full production release:
#         - Standardized CLI utility (auto-updates)
#         - Systemd runner and daily timer at 03:30 AM local time
#         - Daily security updates by default out-of-the-box
#         - Upgraded mode: Daily security + weekly all/non-security updates (Sunday)
#         - Cross-distro support for Fedora, Rocky Linux, AlmaLinux, RHEL (DNF4 & DNF5)
#         - RPM packaging via auto-updates.spec and build_rpm.sh
# 1.0.1 - Integrated GPG signing and verification pipeline into build_rpm.sh
# 1.0.2 - Relicensed under GNU General Public License v3 (GPL-3.0-or-later)
#         Prepared repository and .gitignore for public open-source release
# 1.0.3 - Force remote repository metadata refresh (--refresh / makecache)
#         before checking and applying updates to ensure timely execution
# 1.0.4 - Added 'set-reboot' CLI command with live reboot status detection,
#         advisory notices, and build/session safety deferral guard
# 1.0.5 - Aligned mode definitions with standard DNF: 'all' = daily full updates,
#         'weekly-all' = hybrid weekly updates (with aliases)
# 1.0.6 - Added Unix man pages auto-updates(8) and auto-updates.conf(5),
#         and integrated man directory into RPM build and packaging
# 1.0.7 - Added logrotate integration, %check validation section,
#         and achieved strict rpmlint compliance
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_menu() {
    clear
    echo "================================================================================"
    echo "                Auto-Updates Management & Build Utility (v1.0.7)                "
    echo "================================================================================"
    echo " 1) Build & Sign RPM Package       (Creates dist/auto-updates-1.0.7-1.noarch.rpm)"
    echo " 2) Install/Upgrade RPM Package    (sudo dnf upgrade dist/auto-updates-*.rpm)"
    echo " 3) Run Local Standalone Install   (Directly installs CLI & systemd units)"
    echo " 4) Check Auto-Updates Status      (auto-updates status)"
    echo " 5) Set Mode: Security Only        (sudo auto-updates mode security)"
    echo " 6) Set Mode: Daily All Updates    (sudo auto-updates mode all)"
    echo " 7) Set Mode: Weekly All Updates   (sudo auto-updates mode weekly-all)"
    echo " 8) Configure Reboot Policy        (never / when-needed / when-changed)"
    echo " 9) Test Update Run (Dry Run)      (auto-updates check)"
    echo " 10) Exit"
    echo "================================================================================"
    read -rp "Please select an option [1-10]: " choice

    case "$choice" in
        1)
            ./build_rpm.sh
            ;;
        2)
            RPM_FILE=$(find dist -name "auto-updates-*.noarch.rpm" | head -n 1)
            if [ -n "$RPM_FILE" ]; then
                echo "Installing $RPM_FILE..."
                sudo dnf install -y "$RPM_FILE"
            else
                echo "Error: No built RPM found in dist/. Please build the RPM first (option 1)."
            fi
            ;;
        3)
            sudo ./install_local.sh
            ;;
        4)
            if command -v auto-updates &>/dev/null; then
                auto-updates status
            else
                ./bin/auto-updates status
            fi
            ;;
        5)
            if command -v auto-updates &>/dev/null; then
                sudo auto-updates mode security
            else
                sudo ./bin/auto-updates mode security
            fi
            ;;
        6)
            if command -v auto-updates &>/dev/null; then
                sudo auto-updates mode all
            else
                sudo ./bin/auto-updates mode all
            fi
            ;;
        7)
            if command -v auto-updates &>/dev/null; then
                sudo auto-updates mode weekly-all
            else
                sudo ./bin/auto-updates mode weekly-all
            fi
            ;;
        8)
            echo "Select reboot policy:"
            echo "  1) never        - Never reboot automatically (recommended for workstations)"
            echo "  2) when-needed  - Reboot only if kernel/core libraries require it"
            echo "  3) when-changed - Reboot whenever any package is updated"
            read -rp "Choice [1-3]: " rchoice
            case "$rchoice" in
                1) rpol="never" ;;
                2) rpol="when-needed" ;;
                3) rpol="when-changed" ;;
                *) echo "Invalid choice"; return ;;
            esac
            if command -v auto-updates &>/dev/null; then
                sudo auto-updates set-reboot "$rpol"
            else
                sudo ./bin/auto-updates set-reboot "$rpol"
            fi
            ;;
        9)
            if command -v auto-updates &>/dev/null; then
                auto-updates check
            else
                ./bin/auto-updates check
            fi
            ;;
        10|q|Q)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
}

# Handle command-line arguments if provided
if [ $# -gt 0 ]; then
    case "$1" in
        --build|-b|build)
            ./build_rpm.sh
            ;;
        --install|-i|install)
            RPM_FILE=$(find dist -name "auto-updates-*.noarch.rpm" | head -n 1)
            if [ -n "$RPM_FILE" ]; then
                sudo dnf install -y "$RPM_FILE"
            else
                echo "No built RPM found. Building now..."
                ./build_rpm.sh
                sudo dnf install -y dist/auto-updates-*.noarch.rpm
            fi
            ;;
        --local|local)
            sudo ./install_local.sh
            ;;
        --status|-s|status)
            ./bin/auto-updates status
            ;;
        --help|-h|help)
            echo "Usage: ./main.sh [build|install|local|status|help]"
            ;;
        *)
            ./bin/auto-updates "$@"
            ;;
    esac
else
    # Interactive menu if no arguments provided and interactive shell
    if [ -t 0 ]; then
        show_menu
    else
        ./bin/auto-updates status
    fi
fi
