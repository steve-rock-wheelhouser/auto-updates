#!/bin/bash
# ==============================================================================
# main.sh
# Entry point and management utility for the Auto-Updates project
#
# Copyright (C) 2026 Steve Rock <steve.rock@wheelhouser.com>
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
# 1.0.8 - Moved main entry point to src/main.sh per Wheelhouser LLC project standards
# 1.1.0 - Added native Debian/Ubuntu (.deb) packaging and APT backend support
# 1.1.1 - Added official scalable vector icon (icon.svg) and hicolor desktop icon integration
# 1.1.2 - Remediated project review findings: fixed set-mode CLI dispatch,
#         prevented dry-run config mutation, added yum-utils dependency,
#         standardized build output to build-linux/Output, and integrated publish.sh
# 1.1.3 - Corrected author and maintainer email address to steve.rock@wheelhouser.com
# 1.1.4 - Enhanced set-reboot help output and documentation with detailed policy explanations
# 1.1.5 - Added comprehensive value proposition and global marketing strategy documentation
# 1.1.6 - Added desktop launcher (Terminal=true), AppStream metainfo, and marketing banner SVG
# 1.1.7 - Fixed package discovery in publish.sh to dynamically target active release version
# 1.1.8 - Integrated AppStream showcase screenshots, hero banner, and branding metadata
# 1.2.0 - Added version display to status header and quick CLI command reference prompts
#         (auto-updates -h, man auto-updates, auto-updates run) for desktop launcher and interactive terminal sessions
# 1.2.1 - Expanded status Quick CLI reference with set-reboot options (never|when-needed|when-changed), set-time, and set-day
# 1.2.2 - Add configurable REBOOT_DELAY with immediate systemctl reboot (delay 0)
# 1.2.3 - Add interactive TUI configuration menu, direct desktop launcher, and hypervisor manual
# 1.2.4 - Anti-reboot-loop safeguards: uptime safety floor (900s), reboot rate limiter, package change tracking
# 1.3.0 - Two-tier interactive TUI: initial status dashboard with [c] prompt to enter configuration menu or Enter to close
# 1.3.1 - version update to test orchestra process
# 1.3.2 - version update to test orchestra process
# 1.3.3 - Add Ubuntu APT phased updates detection, INCLUDE_PHASED_UPDATES option, and DNF transaction conflict warnings
# 1.4.0 - Standardize interactive CLI TUI workflow: default bare auto-updates invocation in interactive terminals to TUI dashboard and config menu matching git-tools
# 1.4.1 - Fix test_cli.sh interactive PTY race condition: dynamically wait for TUI prompt to allow needs-restarting and package queries to complete on Rocky Linux and AlmaLinux build nodes
# ==============================================================================

set -euo pipefail

VERSION="1.4.1"

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SRC_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

show_menu() {
    clear
    echo "================================================================================"
    echo "            Auto-Updates Management & Build Utility (v${VERSION})               "
    echo "================================================================================"
    echo " 1) Build & Sign RPM Package       (Creates build-linux/Output/... & dist/...)"
    echo " 2) Build Debian (.deb) Package    (Creates build-linux/Output/... & dist/...)"
    echo " 3) Promote / Publish (via Orchestra) (Central release pipeline)"
    echo " 4) Install/Upgrade Local Package  (Installs built RPM or DEB for current OS)"
    echo " 5) Install from Source (Standalone) (sudo ./build-linux/install.sh)"
    echo " 6) Check Auto-Updates Status      (auto-updates status)"
    echo " 7) Set Mode: Security Only        (sudo auto-updates set-mode security)"
    echo " 8) Set Mode: Daily All Updates    (sudo auto-updates set-mode all)"
    echo " 9) Set Mode: Weekly All Updates   (sudo auto-updates set-mode weekly-all)"
    echo " 10) Configure Reboot Policy       (never / when-needed / when-changed)"
    echo " 11) Test Update Run (Dry Run)     (auto-updates check)"
    echo " 12) Exit"
    echo "================================================================================"
    echo "================================================================================"
    read -rp "Please select an option [1-12]: " choice

    case "$choice" in
        1)
            ./build-linux/build_rpm.sh
            ;;
        2)
            ./build-linux/build_deb.sh
            ;;
        3)
            if [ -f "${PROJECT_ROOT}/../orchestra/scripts/promote_production.sh" ]; then
                "${PROJECT_ROOT}/../orchestra/scripts/promote_production.sh" --project auto-updates
            else
                echo "Notice: Deployment & publishing is managed centrally by Wheelhouser Orchestra (AGENTS.md Rule 13)."
                echo "Run: orchestra/scripts/promote_production.sh --project auto-updates on the release node."
            fi
            ;;
        4)
            if [ -f /etc/os-release ] && grep -qiE '(debian|ubuntu)' /etc/os-release; then
                DEB_FILE=$(find dist build-linux/Output -name "auto-updates_*.deb" 2>/dev/null | head -n 1)
                if [ -n "$DEB_FILE" ]; then
                    echo "Installing $DEB_FILE..."
                    sudo apt-get install -y "$DEB_FILE" || sudo dpkg -i "$DEB_FILE"
                else
                    echo "Error: No built .deb package found. Please build Debian package first (option 2)."
                fi
            else
                RPM_FILE=$(find dist build-linux/Output -name "auto-updates-*.noarch.rpm" 2>/dev/null | head -n 1)
                if [ -n "$RPM_FILE" ]; then
                    echo "Installing $RPM_FILE..."
                    sudo dnf install -y "$RPM_FILE"
                else
                    echo "Error: No built RPM found. Please build the RPM first (option 1)."
                fi
            fi
            ;;
        5)
            sudo ./build-linux/install.sh
            ;;
        6)
            if command -v auto-updates &>/dev/null; then
                auto-updates status
            else
                ./bin/auto-updates status
            fi
            ;;
        7)
            if command -v auto-updates &>/dev/null; then
                sudo auto-updates set-mode security
            else
                sudo ./bin/auto-updates set-mode security
            fi
            ;;
        8)
            if command -v auto-updates &>/dev/null; then
                sudo auto-updates set-mode all
            else
                sudo ./bin/auto-updates set-mode all
            fi
            ;;
        9)
            if command -v auto-updates &>/dev/null; then
                sudo auto-updates set-mode weekly-all
            else
                sudo ./bin/auto-updates set-mode weekly-all
            fi
            ;;
        10)
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
        11)
            if command -v auto-updates &>/dev/null; then
                auto-updates check
            else
                ./bin/auto-updates check
            fi
            ;;
        12|q|Q)
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
            ./build-linux/build_rpm.sh
            ;;
        --install|-i|install)
            RPM_FILE=$(find dist -name "auto-updates-*.noarch.rpm" | head -n 1)
            if [ -n "$RPM_FILE" ]; then
                sudo dnf install -y "$RPM_FILE"
            else
                echo "No built RPM found. Building now..."
                ./build-linux/build_rpm.sh
                sudo dnf install -y dist/auto-updates-*.noarch.rpm
            fi
            ;;
        --local|local)
            sudo ./build-linux/install.sh
            ;;
        --status|-s|status)
            ./bin/auto-updates status
            ;;
        --publish|-p|publish)
            if [ -f "${PROJECT_ROOT}/../orchestra/scripts/promote_production.sh" ]; then
                "${PROJECT_ROOT}/../orchestra/scripts/promote_production.sh" --project auto-updates
            else
                echo "Notice: Deployment & publishing is managed centrally by Wheelhouser Orchestra (AGENTS.md Rule 13)."
            fi
            ;;
        --help|-h|help)
            echo "Usage: ./main.sh [build|publish|install|local|status|help]"
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
