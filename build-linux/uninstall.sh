#!/bin/bash
# ==============================================================================
# uninstall.sh
# Uninstalls standalone / source installation of Auto-Updates
#
# Copyright (C) 2026 Steve Rock <steve.rock@wheelhouser.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Error: Uninstallation requires root privileges. Please run with sudo:" >&2
    echo "  sudo ./uninstall.sh" >&2
    exit 1
fi

PURGE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge|-p)
            PURGE=true
            shift
            ;;
        -h|--help)
            echo "Usage: sudo ./uninstall.sh [--purge]"
            echo "  --purge: Also remove configuration (/etc/auto-updates) and logs (/var/log/auto-updates)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo "==> Stopping and disabling Auto-Updates systemd units..."
systemctl disable --now auto-updates.timer 2>/dev/null || true
systemctl stop auto-updates.service 2>/dev/null || true

echo "==> Removing installed Auto-Updates binaries and services..."
rm -f /usr/bin/auto-updates
rm -f /usr/libexec/auto-updates-runner
rm -f /usr/lib/systemd/system/auto-updates.service
rm -f /usr/lib/systemd/system/auto-updates.timer
systemctl daemon-reload 2>/dev/null || true

echo "==> Removing man pages, completions, and desktop assets..."
rm -f /usr/share/bash-completion/completions/auto-updates
rm -f /usr/share/man/man8/auto-updates.8
rm -f /usr/share/man/man5/auto-updates.conf.5
rm -f /usr/share/icons/hicolor/scalable/apps/auto-updates.svg
rm -f /usr/share/applications/auto-updates.desktop
rm -f /usr/share/metainfo/auto-updates.metainfo.xml
rm -f /etc/logrotate.d/auto-updates

if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi

if [ "$PURGE" = true ]; then
    echo "==> Purging configuration and log files..."
    rm -rf /etc/auto-updates
    rm -rf /var/log/auto-updates
    rm -f /var/log/auto-updates.log
else
    echo "Note: Configuration (/etc/auto-updates) and logs (/var/log/auto-updates) retained."
    echo "      Run with --purge to remove them."
fi

echo "================================================================================"
echo " Auto-Updates has been successfully uninstalled."
echo "================================================================================"
