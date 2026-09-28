Name:           auto-updates
Version:        1.1.3
Release:        1%{?dist}
Summary:        CLI and automated system updater for Fedora, Rocky Linux, and AlmaLinux

License:        GPL-3.0-or-later
URL:            https://github.com/steve-rock-wheelhouser/auto-updates
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       dnf-automatic
Requires:       systemd
Requires:       bash
Requires:       coreutils
Requires:       sed
Requires:       gawk
Requires:       logrotate
Recommends:     yum-utils

%description
auto-updates is a CLI utility and systemd service that configures and manages
automated updates out-of-the-box on Fedora, Rocky Linux, AlmaLinux, and RHEL.

By default, it enables daily security updates at 03:30 AM local time.
It supports three update modes:
- 'security': Daily security updates only.
- 'all': Daily full updates (all packages every day).
- 'weekly-all': Daily security updates plus a weekly full update of all
  packages (every Sunday at 03:30 AM).

Features:
- Out-of-the-box automated security updates
- Flexible update modes (security-only, daily all, or hybrid weekly all)
- Daily run at 3:30 AM in the local system timezone
- Persistent timer ensuring missed runs on sleep/boot are executed
- Cross-platform support for DNF4 and DNF5
- Logging to /var/log/auto-updates.log and systemd journal

%prep
%setup -q

%build
# No compilation required for shell/config sources

%check
bash -n bin/auto-updates
bash -n libexec/auto-updates-runner
bash -n completions/auto-updates.bash

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libexecdir}
mkdir -p %{buildroot}%{_unitdir}
mkdir -p %{buildroot}%{_sysconfdir}/auto-updates
mkdir -p %{buildroot}%{_sysconfdir}/dnf
mkdir -p %{buildroot}%{_sysconfdir}/logrotate.d
mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
mkdir -p %{buildroot}%{_mandir}/man8
mkdir -p %{buildroot}%{_mandir}/man5
mkdir -p %{buildroot}%{_localstatedir}/log

install -p -m 0755 bin/auto-updates %{buildroot}%{_bindir}/auto-updates
install -p -m 0755 libexec/auto-updates-runner %{buildroot}%{_libexecdir}/auto-updates-runner
install -p -m 0644 systemd/auto-updates.service %{buildroot}%{_unitdir}/auto-updates.service
install -p -m 0644 systemd/auto-updates.timer %{buildroot}%{_unitdir}/auto-updates.timer
install -p -m 0644 config/auto-updates.conf %{buildroot}%{_sysconfdir}/auto-updates/auto-updates.conf
install -p -m 0644 config/auto-updates.logrotate %{buildroot}%{_sysconfdir}/logrotate.d/auto-updates
install -p -m 0644 completions/auto-updates.bash %{buildroot}%{_datadir}/bash-completion/completions/auto-updates
install -p -m 0644 man/auto-updates.8 %{buildroot}%{_mandir}/man8/auto-updates.8
install -p -m 0644 man/auto-updates.conf.5 %{buildroot}%{_mandir}/man5/auto-updates.conf.5

mkdir -p %{buildroot}%{_datadir}/icons/hicolor/scalable/apps
install -p -m 0644 assets/icons/auto-updates.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/auto-updates.svg

mkdir -p %{buildroot}%{_localstatedir}/log/auto-updates
touch %{buildroot}%{_localstatedir}/log/auto-updates/auto-updates.log
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
    ( umask 022 && cat <<'EOF' > %{_sysconfdir}/dnf/automatic.conf
[commands]
apply_updates = yes
download_updates = yes
upgrade_type = security
random_sleep = 10
network_online_timeout = 60

[emitters]
emit_via = stdio
EOF
    )
fi

# Ensure log directory and file exist
mkdir -p %{_localstatedir}/log/auto-updates
touch %{_localstatedir}/log/auto-updates/auto-updates.log
ln -sfn auto-updates/auto-updates.log %{_localstatedir}/log/auto-updates.log 2>/dev/null || true

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
%config(noreplace) %{_sysconfdir}/logrotate.d/auto-updates
%{_datadir}/bash-completion/completions/auto-updates
%{_datadir}/icons/hicolor/scalable/apps/auto-updates.svg
%{_mandir}/man8/auto-updates.8*
%{_mandir}/man5/auto-updates.conf.5*
%dir %{_localstatedir}/log/auto-updates
%ghost %attr(0640, root, root) %{_localstatedir}/log/auto-updates/auto-updates.log
%ghost %attr(0640, root, root) %{_localstatedir}/log/auto-updates.log

%changelog
* Mon Sep 28 2026 Steve Rock <steve.rock@wheelhouser.com> - 1.1.3-1
- Corrected author and maintainer email address in manual pages.

* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.1.2-1
- Fixed 'set-mode' CLI command dispatch in bin/auto-updates.
- Prevented system configuration mutation on dry-run queries.
- Added Recommends: yum-utils for reliable reboot requirement detection on RHEL/Rocky.
- Standardized log paths and updated logrotate policy for both log locations.
- Standardized build output to build-linux/Output/ and integrated publish.sh.

* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.1.1-1
- Added official scalable vector icon (auto-updates.svg) and hicolor desktop icon integration.

* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.1.0-1
- Added native multi-distribution support for Debian and Ubuntu systems.
- Implemented APT backend integration with unattended-upgrades.
- Added native Debian/Ubuntu reboot status detection (/run/reboot-required).
- Added build_deb.sh automated Debian packaging pipeline.

* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.8-1
- Moved project management entry point to src/main.sh per Wheelhouser LLC project standards.
- Added AGENTS.md documenting mandatory version bump and changelog policies.

* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.7-1
- Added logrotate configuration in /etc/logrotate.d/auto-updates.
- Added %%check test section validating script syntax during RPM build.
- Refined description line wrapping, Source0 URL, and file attributes for strict rpmlint compliance.
- Removed dangerous chmod in %%post scriptlet in favor of declarative %%attr in %%files.

* Mon Sep 28 2026 Steve Rock Wheelhouser <steve@wheelhouser.com> - 1.0.6-1
- Added Unix manual pages: auto-updates(8) in section 8 and auto-updates.conf(5) in section 5.
- Documented update modes, schedules, commands, build inhibition protection, and configuration options.
- Added automated rpmlint validation support to the package build workflow.

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
