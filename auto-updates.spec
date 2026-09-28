Name:           auto-updates
Version:        1.0.5
Release:        1%{?dist}
Summary:        CLI and automated system updater for Fedora, Rocky Linux, and AlmaLinux

License:        GPL-3.0-or-later
URL:            https://github.com/steve-rock-wheelhouser/auto-updates
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       dnf-automatic
Requires:       systemd
Requires:       bash
Requires:       coreutils
Requires:       sed
Requires:       gawk

%description
auto-updates is a CLI utility and systemd service that configures and manages
dnf-automatic out-of-the-box on Fedora, Rocky Linux, AlmaLinux, and RHEL.

By default, it enables daily security updates at 03:30 AM local time.
It supports three update modes:
- 'security': Daily security updates only.
- 'all': Daily full updates (all packages every day, matching dnf-automatic standard).
- 'weekly-all' (or 'all-weekly'): Daily security updates plus a weekly full update of all packages (every Sunday at 03:30 AM).

Features:
- Out-of-the-box automated security updates
- Flexible update modes (security-only, daily all updates, or hybrid weekly all updates)
- Daily run at 3:30 AM in the local system timezone
- Persistent timer ensuring missed runs on sleep/boot are executed
- Cross-platform support for DNF4 and DNF5 (Fedora, Rocky Linux, AlmaLinux, RHEL)
- Logging to /var/log/auto-updates.log and systemd journal

%prep
%setup -q

%build
# No compilation required for shell/config sources

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libexecdir}
mkdir -p %{buildroot}%{_unitdir}
mkdir -p %{buildroot}%{_sysconfdir}/auto-updates
mkdir -p %{buildroot}%{_sysconfdir}/dnf
mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
mkdir -p %{buildroot}%{_localstatedir}/log

install -p -m 0755 bin/auto-updates %{buildroot}%{_bindir}/auto-updates
install -p -m 0755 libexec/auto-updates-runner %{buildroot}%{_libexecdir}/auto-updates-runner
install -p -m 0644 systemd/auto-updates.service %{buildroot}%{_unitdir}/auto-updates.service
install -p -m 0644 systemd/auto-updates.timer %{buildroot}%{_unitdir}/auto-updates.timer
install -p -m 0644 config/auto-updates.conf %{buildroot}%{_sysconfdir}/auto-updates/auto-updates.conf
install -p -m 0644 completions/auto-updates.bash %{buildroot}%{_datadir}/bash-completion/completions/auto-updates

touch %{buildroot}%{_localstatedir}/log/auto-updates.log

%post
# Configure /etc/dnf/automatic.conf if it exists or create baseline
if [ -f %{_sysconfdir}/dnf/automatic.conf ]; then
    sed -i -E 's/^[#[:space:]]*apply_updates[[:space:]]*=.*/apply_updates = yes/' %{_sysconfdir}/dnf/automatic.conf
    sed -i -E 's/^[#[:space:]]*download_updates[[:space:]]*=.*/download_updates = yes/' %{_sysconfdir}/dnf/automatic.conf
    sed -i -E 's/^[#[:space:]]*upgrade_type[[:space:]]*=.*/upgrade_type = security/' %{_sysconfdir}/dnf/automatic.conf
    sed -i -E 's/^[#[:space:]]*random_sleep[[:space:]]*=.*/random_sleep = 10/' %{_sysconfdir}/dnf/automatic.conf
    sed -i -E 's/^[#[:space:]]*emit_via[[:space:]]*=.*/emit_via = stdio/' %{_sysconfdir}/dnf/automatic.conf
else
    mkdir -p %{_sysconfdir}/dnf
    cat <<'EOF' > %{_sysconfdir}/dnf/automatic.conf
[commands]
apply_updates = yes
download_updates = yes
upgrade_type = security
random_sleep = 10
network_online_timeout = 60

[emitters]
emit_via = stdio
EOF
    chmod 0644 %{_sysconfdir}/dnf/automatic.conf
fi

# Ensure log file exists with proper permissions
touch %{_localstatedir}/log/auto-updates.log
chmod 0640 %{_localstatedir}/log/auto-updates.log

# Disable any default distribution dnf-automatic timers to prevent duplicate runs
systemctl disable --now dnf-automatic.timer 2>/dev/null || true
systemctl disable --now dnf-automatic-install.timer 2>/dev/null || true
systemctl disable --now dnf5-automatic.timer 2>/dev/null || true

# Reload systemd and enable/start auto-updates timer
systemctl daemon-reload 2>/dev/null || true
systemctl enable --now auto-updates.timer 2>/dev/null || true

echo "================================================================================"
echo " [Auto-Updates] Installed and configured successfully!"
echo " - Default Mode: Security updates only"
echo " - Schedule: Every day at 03:30 AM (local time)"
echo " - Timer: auto-updates.timer is enabled and active"
echo ""
echo " To enable daily full updates (all packages):"
echo "   sudo auto-updates set-mode all"
echo " To enable hybrid weekly all updates (daily security + weekly full):"
echo "   sudo auto-updates set-mode weekly-all"
echo ""
echo " To check status:"
echo "   auto-updates status"
echo "================================================================================"

%preun
if [ "$1" -eq 0 ]; then
    systemctl disable --now auto-updates.timer 2>/dev/null || true
    systemctl stop auto-updates.service 2>/dev/null || true
fi

%postun
systemctl daemon-reload 2>/dev/null || true

%files
%license LICENSE
%doc README.md
%{_bindir}/auto-updates
%{_libexecdir}/auto-updates-runner
%{_unitdir}/auto-updates.service
%{_unitdir}/auto-updates.timer
%dir %{_sysconfdir}/auto-updates
%config(noreplace) %{_sysconfdir}/auto-updates/auto-updates.conf
%{_datadir}/bash-completion/completions/auto-updates
%ghost %{_localstatedir}/log/auto-updates.log

%changelog
* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.5-1
- Standardized update mode naming: 'all' now executes daily full updates (matching dnf-automatic standard).
- Added 'weekly-all' (and 'all-weekly' alias) for the hybrid daily security + weekly full updates schedule.
- Retained 'daily-all' as a backward-compatible alias for 'all'.
- Updated CLI commands, bash completion, main menu, and documentation.

* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.4-1
- Added 'set-reboot' CLI command to configure automated reboot policy.
- Integrated live system reboot status detection (needs-restarting) into 'auto-updates status'.
- Added build and inhibitor protection (DEFER_REBOOT_IF_BUSY) to postpone reboots when active builds or inhibitors are detected.
- Added friendly configuration advisories and bash completions for reboot policies.

* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.3-1
- Force remote repository metadata refresh (--refresh / makecache) before checking and applying updates.
- Added REFRESH_METADATA configuration option and CLI status visibility.

* Sun Sep 27 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.2-1
- Relicensed under GNU General Public License v3 (GPL-3.0-or-later).
- Cleaned and prepared repository structure for public open-source release.

* Sun Sep 27 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.1-1
- Package signing and verification integration with GPG.
- Updated documentation and build pipeline.

* Sun Sep 27 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.0-1
- Initial release of auto-updates for Fedora, Rocky Linux, and AlmaLinux.
- Default daily security updates at 03:30 local time.
- Optional weekly all-updates mode via CLI.
- Systemd timer and service with out-of-the-box activation.
- Cross-platform DNF4 and DNF5 compatibility.
