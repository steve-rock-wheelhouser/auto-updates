---
ticket_id: "BUG-20260928_212027"
title: "Installation from repo.wheelhouser.com fails on Ubuntu"
type: "installation"
status: "open"
severity: "critical"
project: "auto-updates"
package: "auto-updates_1.1.8-1_all.deb"
os: "linux"
arch: "x86_64"
distro: "ubuntu"
distro_version: "26.04"
node: "user@10.0.0.166:2205"
commit: "79eb4e1"
date: "2026-09-28T21:20:27Z"
closed_at: ""
resolved_by: ""
---

# [CRITICAL] Installation from repo.wheelhouser.com fails on Ubuntu

## Environment
- **Project**: `auto-updates`
- **Package**: `auto-updates_1.1.8-1_all.deb`
- **Platform**: `linux / ubuntu 26.04 (x86_64)`
- **Architecture**: `x86_64`
- **Test Node**: `user@10.0.0.166:2205`
- **Git Commit**: `79eb4e1`
- **Reported Date**: `2026-09-28T21:20:27Z`

## Problem Summary
Installation from repo.wheelhouser.com fails on Ubuntu

## Execution Output & Traceback
```text
How the Ubuntu Tab on Your Site is Structured
Unlike your Rocky Linux tab (which has a single one-step release RPM command):

bash
sudo dnf install https://repo.wheelhouser.com/rocky/10/x86_64/steve-rock-wheelhouser-release-1.0-6.el10.noarch.rpm
The Ubuntu and Debian sections on repo.wheelhouser.com are divided into separate method blocks, each with its own independent code box and copy button:

Step 1: Install GPG Keyring (the one you copied)
bash
sudo install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://repo.wheelhouser.com/steve-rock-wheelhouser-gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/wheelhouser.gpg && sudo chmod a+r /etc/apt/keyrings/wheelhouser.gpg
Step 2: Add Wheelhouser APT Repository (was skipped)
bash
echo "deb [signed-by=/etc/apt/keyrings/wheelhouser.gpg] https://repo.wheelhouser.com/ubuntu/26.04 ./" | sudo tee /etc/apt/sources.list.d/wheelhouser.list
Step 3: Update & Install Packages (was skipped)
bash
sudo apt update && sudo apt install -y <package>
Because each step has its own separate Copy button, clicking the button on Step 1 copied only the keyring setup command. Jumping straight from Step 1 to the bottom package card (sudo apt install auto-updates) bypassed adding the repo source and running apt update.

Recommended Site Improvement
Since this easily catches users (and even caught you on your own site!), you can make the Ubuntu/Debian onboarding as seamless as the RPM distros:

Option A: Provide a single "One-Liner" setup box
Combine Steps 1, 2, and the update into a single copyable command:

bash
sudo install -m 0755 -d /etc/apt/keyrings && \
curl -fsSL https://repo.wheelhouser.com/steve-rock-wheelhouser-gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/wheelhouser.gpg && \
sudo chmod a+r /etc/apt/keyrings/wheelhouser.gpg && \
echo "deb [signed-by=/etc/apt/keyrings/wheelhouser.gpg] https://repo.wheelhouser.com/ubuntu/26.04 ./" | sudo tee /etc/apt/sources.list.d/wheelhouser.list && \
sudo apt update
Option B: Provide a wheelhouser-release.deb package
Just like your steve-rock-wheelhouser-release-*.rpm for Rocky/Alma/Fedora, you could provide a .deb package that puts the keyring in /etc/apt/keyrings/ wheelhouser.gpg and the .sources file in /etc/apt/sources.list.d/, allowing users to install with:

bash
sudo apt install https://repo.wheelhouser.com/ubuntu/wheelhouser-release.deb
```

## Steps to Reproduce
1. Launch or verify `auto-updates` on ubuntu 26.04 (x86_64).
2. Observe reported runtime/installation behavior described above.
