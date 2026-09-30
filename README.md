# Auto-Updates: Automated DNF Updates for Fedora, Rocky Linux & AlmaLinux

`auto-updates` is a lightweight, production-grade CLI utility and systemd service that automates and manages `dnf-automatic` out-of-the-box across Red Hat Enterprise Linux (RHEL) family distributions, including **Fedora**, **Rocky Linux**, **AlmaLinux**, and **CentOS Stream**.

---

## Key Features

1. **Zero-Configuration Out-of-the-Box Security Updates**:
   - Immediately upon RPM installation, the system is configured to download and apply **security updates only**.
   - Scheduled to run **every day at 03:30 AM in the local system timezone**.
   - `Persistent=true` ensures that if a computer or server was turned off or sleeping at 03:30 AM, missed updates are executed as soon as the machine boots or wakes up.

2. **Flexible Update Modes**:
   - Easily switch between update modes using the CLI:
     ```bash
     sudo auto-updates set-mode security    # Daily security updates only
     sudo auto-updates set-mode all         # Daily full updates (all packages every day)
     sudo auto-updates set-mode weekly-all  # Daily security + weekly full updates on Sunday
     ```
   - When set to `weekly-all`:
     - **Monday – Saturday**: Runs fast, daily security updates at 03:30 AM (ensuring zero-day patches are not delayed).
     - **Sunday**: Runs a full system upgrade of all packages (features, bug fixes, enhancements, and security) at 03:30 AM.
   - When set to `all`:
     - Runs a full system upgrade of all packages every day at 03:30 AM.
   - When set to `security`:
     - Runs security updates only every day at 03:30 AM.

3. **Configurable Automated Reboot Policy & Build Protection**:
   - Configure automatic reboots when updates require it:
     ```bash
     sudo auto-updates set-reboot when-needed  # Reboot if kernel/system libraries changed
     sudo auto-updates set-reboot when-changed # Reboot whenever any package is updated
     sudo auto-updates set-reboot never        # Never reboot automatically (default)
     ```
   - Includes **intelligent build and task protection**: if an active build or compiling process (`rpmbuild`, `mock`, `make`, `ninja`, `cargo`, `gcc`, container build) or `systemd-inhibit` lock is detected, automated reboots are safely postponed until the next cycle to protect in-flight workloads.

4. **Cross-Distribution & Multi-DNF Support**:
   - Compatible with both **DNF4** (Rocky Linux 8/9, AlmaLinux 8/9, RHEL 8/9) and **DNF5** (Fedora 41+, RHEL 10, Rocky 10).
   - Automatically adapts backend invocation and eliminates conflicting default distribution timers.

5. **Interactive Terminal User Interface (TUI) & Desktop Launcher**:
   - Launch directly via terminal (`auto-updates tui` or `auto-updates -i`) or click the **Auto-Updates** icon in the desktop application launcher.
   - Provides a live status dashboard and an interactive numbered configuration menu: adjust update modes, reboot policies, reboot delay, execution times, weekly upgrade days, and toggle build protection without memorizing CLI syntax.
   - For quick status queries, `auto-updates status` displays a non-interactive overview.

6. **Manual Trigger & Dry-Run Testing**:
   - Run or test updates on demand:
     ```bash
     sudo auto-updates run            # Runs according to today's schedule
     sudo auto-updates run --security # Force security update immediately
     sudo auto-updates run --all      # Force all updates immediately
     auto-updates check               # Dry-run check for available updates
     ```

---

## CLI Usage Reference

| Command | Description |
| :--- | :--- |
| `auto-updates tui` (or `-i`) | **Launch full interactive TUI configuration & actions menu** |
| `auto-updates status` (or `-s`) | Display configuration, timer status, reboot status, and next scheduled run |
| `sudo auto-updates set-mode security` | Set mode to daily security updates only |
| `sudo auto-updates set-mode all` | Set mode to daily full updates (all packages every day) |
| `sudo auto-updates set-mode weekly-all` | Set mode to daily security + weekly full updates |
| `sudo auto-updates set-reboot <policy>` | Set reboot policy: `never`, `when-needed`, or `when-changed` |
| `sudo auto-updates set-reboot-delay <0\|mins>` | Set delay before reboot in minutes (0 = immediate via systemctl reboot) |
| `sudo auto-updates set-build-protection <true\|false>` | Toggle build and compilation process reboot protection |
| `sudo auto-updates enable` | Enable and start the systemd timer |
| `sudo auto-updates disable` | Stop and disable the systemd timer |
| `sudo auto-updates run` | Trigger an immediate update run |
| `sudo auto-updates run --security` | Force an immediate security update |
| `sudo auto-updates run --all` | Force an immediate full system upgrade |
| `auto-updates check` | Dry-run check for available updates |
| `sudo auto-updates set-time <HH:MM>` | Change daily execution time (e.g. `04:00`) |
| `sudo auto-updates set-day <Day>` | Change weekly full update day (e.g. `Sun`, `Sat`) |
| `auto-updates logs [N]` | View the last N lines of `/var/log/auto-updates.log` |
| `auto-updates help` | Display built-in help and examples |
| `auto-updates version` | Display version information |

---

## Configuration File

Configuration is stored in `/etc/auto-updates/auto-updates.conf`:

```ini
# /etc/auto-updates/auto-updates.conf

# Mode: 'security' (daily security only), 'all' (daily full updates), or 'weekly-all' (daily security + weekly full)
MODE=security

# Daily update execution time (24-hour local time format: HH:MM)
SCHEDULE_TIME=03:30

# Day of week for full updates when MODE=all (Sun, Mon, Tue, Wed, Thu, Fri, Sat)
WEEKLY_DAY=Sun

# Maximum randomized sleep jitter in seconds (default: 10)
RANDOM_SLEEP=10

# Reboot policy: 'never', 'when-needed', or 'when-changed'
REBOOT=never

# Reboot delay in minutes (0 = immediate via systemctl reboot, N = delayed notice)
REBOOT_DELAY=0

# Notification emitter: 'stdio', 'motd', 'email'
EMIT_VIA=stdio

# Log file location
LOG_FILE=/var/log/auto-updates.log
```

---

## Virtual Machine & Hypervisor Architectures (GNOME Boxes vs. System Libvirt)

When running `auto-updates` inside virtual machines, the hypervisor's execution model directly impacts whether unattended overnight reboots succeed or stall. Linux virtualization relies on two distinct libvirt connection models:

### The Two Virtualization Models

| Feature | GNOME Boxes (`qemu:///session`) | System Libvirt (`qemu:///system`) |
| :--- | :--- | :--- |
| **Intended Use** | Desktop user app (trying out ISOs, quick testing) | Servers, build infrastructure, CI/CD, 24/7 nodes |
| **Execution Context** | Runs as your **desktop user** (`uid 1000`) inside your graphical login session | Runs as a **system daemon** under `root` / `systemd` (`virtqemud.service`) |
| **Tied to Desktop?** | **Yes.** Tied to GNOME Shell, desktop session lock, and user power-saving | **No.** Completely headless; runs whether a user is logged into the desktop or not |
| **Survives Screen Lock / Idle?** | **Often no.** Desktop power management can pause or throttle session VMs | **Yes.** Independent of desktop sleep, screen lock, or user logout |
| **`virsh autostart` Support?** | **Not supported.** (No system daemon exists to boot it before login) | **Native.** Boots automatically when the physical host powers on |
| **Guest Reboot Handling** | Dependent on the desktop UI window and SPICE display channel | Handled directly by the hypervisor daemon; re-posts BIOS/GRUB immediately |

### Recommended Settings for GNOME Boxes (`qemu:///session`)
For development and visual testing VMs running in GNOME Boxes:
1. **Enable "Run in background"**: In GNOME Boxes, open VM **Preferences** -> **General / Resources**, and ensure **"Run in background"** is toggled **ON**. Without this, closing or minimizing the Boxes window may cause the hypervisor to pause or suspend the virtual machine when an ACPI reset occurs.
2. **Reboot Delay (Immediate Restart)**: Keep `REBOOT_DELAY=0` (default) or configure with `sudo auto-updates set-reboot-delay 0`. When updates require a reboot, `auto-updates` executes an immediate `systemctl reboot`. This avoids an unattended 5-minute delayed shutdown (`shutdown -r +5`) where desktop sessions or display sockets can timeout.
3. **Host Power & Sleep**: Ensure the hypervisor host workstation does not enter automatic system sleep or suspend during the scheduled update window (`SCHEDULE_TIME`).
4. **Libvirt Domain Policy**: Verify the VM's domain XML configuration defines `<on_reboot>restart</on_reboot>` rather than `destroy`.

### Enterprise & Production Recommendation: Use System Libvirt
For mission-critical production environments, build orchestration nodes (such as build runners), CI/CD runners, and 24/7 server infrastructure:
- **Switch to System Libvirt (`qemu:///system`)** managed via `virt-manager`, Cockpit, or `virsh`.
- **Enable Host Autostart**:
  ```bash
  virsh --connect qemu:///system autostart <domain-name>
  ```
- **Why this is critical for production**: System Libvirt runs under systemd, operates completely independently of desktop user login sessions, survives host sleep/lockouts, boots automatically when the physical host powers on, and immediately handles guest kernel reboots in under 15 seconds.


---

## Building the RPM Package

To build the RPM package locally:

```bash
cd /home/user/projects/Auto-Updates
./build-linux/build_rpm.sh
```

The resulting RPM package will be placed in the `dist/` directory:
```
dist/auto-updates-1.0.0-1.<dist>.noarch.rpm
```

To install the built RPM:
```bash
sudo dnf install dist/auto-updates-1.0.0-1.*.noarch.rpm
```

---

## Manual / Local Installation

If you want to install or test without building an RPM package, run:

```bash
sudo ./install_local.sh
```

---

## Verification & Monitoring

Check the status of the systemd timer and service:
```bash
systemctl status auto-updates.timer
systemctl list-timers auto-updates.timer
journalctl -u auto-updates.service -n 50 --no-pager
```

---

## License

This project is licensed under the **GNU General Public License v3 or later (GPL-3.0-or-later)** - see the [LICENSE](LICENSE) file for details.

Copyright (C) 2026 Steve Rock <steve.rock@wheelhouser.com>

