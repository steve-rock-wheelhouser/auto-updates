#!/usr/bin/env bash
# ==============================================================================
# publish.sh
# Publishes auto-updates RPM and Debian packages to the Wheelhouser LLC repository
# Wheelhouser LLC (c) 2026
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:${PATH:-}"

REPO_DIR="$(cd "$SCRIPT_DIR/../wheelhouserllc-repo" && pwd)"
UPDATE_SCRIPT="$(cd "$SCRIPT_DIR/../wheelhouserllc-repo-scripts" && pwd)/update_repo.sh"

if [ ! -d "$REPO_DIR" ]; then
    echo "❌ Error: Target repository not found at $REPO_DIR" >&2
    exit 1
fi

echo "================================================================================"
echo " Publishing auto-updates Packages to Wheelhouser LLC Repository"
echo " Target Repository: $REPO_DIR"
echo "================================================================================"

# Determine target release version
TARGET_VER="$(grep -m1 '^VERSION=' "$SCRIPT_DIR/bin/auto-updates" | cut -d'"' -f2)"
echo "Target release version: v${TARGET_VER}"

# Locate RPM packages matching target version
EL10_RPM=$(find "$SCRIPT_DIR/build-linux/Output/rocky/10" "$SCRIPT_DIR/dist" -name "*auto-updates-${TARGET_VER}*el10*.noarch.rpm" 2>/dev/null | sort -V | tail -n 1 || true)
FC44_RPM=$(find "$SCRIPT_DIR/build-linux/Output/fedora/44" "$SCRIPT_DIR/dist" -name "*auto-updates-${TARGET_VER}*fc44*.noarch.rpm" 2>/dev/null | sort -V | tail -n 1 || true)

# If RPMs are missing, build them
if [ -z "$EL10_RPM" ] || [ -z "$FC44_RPM" ]; then
    echo "⚠️ RPM packages for v${TARGET_VER} not found. Running build_rpm.sh..."
    ./build_rpm.sh
    EL10_RPM=$(find "$SCRIPT_DIR/build-linux/Output/rocky/10" "$SCRIPT_DIR/dist" -name "*auto-updates-${TARGET_VER}*el10*.noarch.rpm" 2>/dev/null | sort -V | tail -n 1 || true)
    FC44_RPM=$(find "$SCRIPT_DIR/build-linux/Output/fedora/44" "$SCRIPT_DIR/dist" -name "*auto-updates-${TARGET_VER}*fc44*.noarch.rpm" 2>/dev/null | sort -V | tail -n 1 || true)
fi

# Locate DEB package matching target version
DEB_PKG=$(find "$SCRIPT_DIR/build-linux/Output/debian/13" "$SCRIPT_DIR/dist" -name "*auto-updates*${TARGET_VER}*.deb" 2>/dev/null | sort -V | tail -n 1 || true)
if [ -z "$DEB_PKG" ]; then
    echo "⚠️ Debian package for v${TARGET_VER} not found. Running build_deb.sh..."
    ./build_deb.sh
    DEB_PKG=$(find "$SCRIPT_DIR/build-linux/Output/debian/13" "$SCRIPT_DIR/dist" -name "*auto-updates*${TARGET_VER}*.deb" 2>/dev/null | sort -V | tail -n 1 || true)
fi

# 1. Deploy Enterprise Linux 10 RPM (Rocky Linux 10 & AlmaLinux 10)
if [ -n "$EL10_RPM" ]; then
    echo "==> Deploying EL10 RPM: $(basename "$EL10_RPM")..."
    for d in rocky almalinux; do
        for arch in x86_64 aarch64; do
            dest="$REPO_DIR/$d/10/$arch"
            mkdir -p "$dest"
            cp -v "$EL10_RPM" "$dest/"
        done
    done
fi

# 2. Deploy Fedora 44 RPM
if [ -n "$FC44_RPM" ]; then
    echo "==> Deploying Fedora 44 RPM: $(basename "$FC44_RPM")..."
    for arch in x86_64 aarch64; do
        dest="$REPO_DIR/fedora/44/$arch"
        mkdir -p "$dest"
        cp -v "$FC44_RPM" "$dest/"
    done
fi

# 3. Deploy Debian & Ubuntu .deb
if [ -n "$DEB_PKG" ]; then
    echo "==> Deploying Debian / Ubuntu DEB: $(basename "$DEB_PKG")..."
    for dest in "$REPO_DIR/debian/13" "$REPO_DIR/ubuntu/26.04"; do
        mkdir -p "$dest"
        cp -v "$DEB_PKG" "$dest/"
    done
fi

# 4. Trigger Wheelhouser repository maintenance & metadata rebuild
echo ""
echo "==> Updating repository metadata, signing, and indexing..."
if [ -f "$UPDATE_SCRIPT" ]; then
    "$UPDATE_SCRIPT" "$REPO_DIR"
else
    echo "⚠️ Warning: update_repo.sh not found at $UPDATE_SCRIPT."
fi

echo ""
echo "================================================================================"
echo "✅ auto-updates packages published successfully to Wheelhouser LLC repository!"
echo "================================================================================"
