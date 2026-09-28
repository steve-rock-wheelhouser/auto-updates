#!/bin/bash
# ==============================================================================
# install_local.sh
# Local developer / standalone installation script for Auto-Updates
# Installs CLI, runner, systemd units, and config directly to the current system
#
# Copyright (C) 2026 Steve Rock Wheelhouser <steve@wheelhouser.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Error: Local installation requires root privileges. Please run with sudo:" >&2
    echo "  sudo ./install_local.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect package manager
IS_DEB=false
if [ -f /etc/os-release ]; then
    OS_ID=$(grep -E '^(ID|ID_LIKE)=' /etc/os-release 2>/dev/null || true)
    case "$OS_ID" in
        *debian*|*ubuntu*)
            IS_DEB=true
            ;;
    esac
fi

echo "Installing required dependencies..."
if [ "$IS_DEB" = true ] || command -v apt-get &>/dev/null && ! command -v dnf &>/dev/null; then
    apt-get update -qq
    apt-get install -y unattended-upgrades logrotate bash coreutils sed gawk
elif command -v dnf5 &>/dev/null; then
    dnf install -y dnf5-plugin-automatic logrotate || dnf install -y dnf-automatic logrotate
else
    dnf install -y dnf-automatic logrotate
fi

echo "Installing Auto-Updates files..."
install -p -m 0755 bin/auto-updates /usr/bin/auto-updates
install -p -m 0755 libexec/auto-updates-runner /usr/libexec/auto-updates-runner
install -p -m 0644 systemd/auto-updates.service /usr/lib/systemd/system/auto-updates.service
install -p -m 0644 systemd/auto-updates.timer /usr/lib/systemd/system/auto-updates.timer

mkdir -p /etc/auto-updates
if [ ! -f /etc/auto-updates/auto-updates.conf ]; then
    install -p -m 0644 config/auto-updates.conf /etc/auto-updates/auto-updates.conf
fi

mkdir -p /etc/logrotate.d
install -p -m 0644 config/auto-updates.logrotate /etc/logrotate.d/auto-updates

mkdir -p /usr/share/bash-completion/completions
install -p -m 0644 completions/auto-updates.bash /usr/share/bash-completion/completions/auto-updates

mkdir -p /usr/share/man/man8 /usr/share/man/man5
install -p -m 0644 man/auto-updates.8 /usr/share/man/man8/auto-updates.8
install -p -m 0644 man/auto-updates.conf.5 /usr/share/man/man5/auto-updates.conf.5

# Setup log directory
mkdir -p /var/log/auto-updates
touch /var/log/auto-updates/auto-updates.log
chmod 0755 /var/log/auto-updates
chmod 0640 /var/log/auto-updates/auto-updates.log
ln -sfn auto-updates/auto-updates.log /var/log/auto-updates.log 2>/dev/null || true

if [ "$IS_DEB" = false ]; then
    # Configure /etc/dnf/automatic.conf on RPM systems
    mkdir -p /etc/dnf
    if [ -f /etc/dnf/automatic.conf ]; then
        sed -i -E 's/^[#[:space:]]*apply_updates[[:space:]]*=.*/apply_updates = yes/' /etc/dnf/automatic.conf
        sed -i -E 's/^[#[:space:]]*download_updates[[:space:]]*=.*/download_updates = yes/' /etc/dnf/automatic.conf
        sed -i -E 's/^[#[:space:]]*upgrade_type[[:space:]]*=.*/upgrade_type = security/' /etc/dnf/automatic.conf
        sed -i -E 's/^[#[:space:]]*random_sleep[[:space:]]*=.*/random_sleep = 10/' /etc/dnf/automatic.conf
        sed -i -E 's/^[#[:space:]]*emit_via[[:space:]]*=.*/emit_via = stdio/' /etc/dnf/automatic.conf
    else
        cat <<'EOF' > /etc/dnf/automatic.conf
[commands]
apply_updates = yes
download_updates = yes
upgrade_type = security
random_sleep = 10
network_online_timeout = 60

[emitters]
emit_via = stdio
EOF
        chmod 0644 /etc/dnf/automatic.conf
    fi

    # Disable any default distribution dnf timers
    systemctl disable --now dnf-automatic.timer 2>/dev/null || true
    systemctl disable --now dnf-automatic-install.timer 2>/dev/null || true
    systemctl disable --now dnf5-automatic.timer 2>/dev/null || true
else
    # Disable default apt periodic timers to prevent duplicate runs
    systemctl disable --now apt-daily.timer 2>/dev/null || true
    systemctl disable --now apt-daily-upgrade.timer 2>/dev/null || true
fi

# Enable and start auto-updates timer
systemctl daemon-reload
systemctl enable --now auto-updates.timer

echo "================================================================================"
echo " Auto-Updates Local Installation Complete!"
echo " - Default Mode: Security updates only"
echo " - Schedule: Every day at 03:30 AM local time"
echo " - Timer: auto-updates.timer is active"
echo ""
echo " Run 'auto-updates status' to inspect."
echo "================================================================================"
