#!/bin/bash
# ==============================================================================
# build_rpm.sh
# Automates building the auto-updates RPM package
#
# Copyright (C) 2026 Steve Rock <steve.rock@wheelhouser.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "$SCRIPT_DIR")" == "build-linux" ]]; then
    PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
    PROJECT_ROOT="$SCRIPT_DIR"
fi
cd "$PROJECT_ROOT"

NAME="auto-updates"
VERSION="1.2.2"
RELEASE="1"
TARBALL="${NAME}-${VERSION}.tar.gz"

echo "================================================================================"
echo " Building RPM package: ${NAME}-${VERSION}-${RELEASE}"
echo "================================================================================"

# Verify required tools
for cmd in rpmbuild tar gzip rpmsign; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required tool '$cmd' is not installed." >&2
        exit 1
    fi
done

# Prepare clean build hierarchy
TOPDIR="${PROJECT_ROOT}/build/rpmbuild"
rm -rf "$TOPDIR"
mkdir -p "${TOPDIR}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "${PROJECT_ROOT}/dist"
mkdir -p "${PROJECT_ROOT}/build-linux/Output"/{rocky/10,almalinux/10,fedora/44,fedora/45}

# Create source archive
TEMP_SOURCE_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_SOURCE_DIR"' EXIT

STAGE_DIR="${TEMP_SOURCE_DIR}/${NAME}-${VERSION}"
mkdir -p "$STAGE_DIR"/{bin,libexec,config,systemd,completions,man,assets/icons,desktop}

cp bin/auto-updates "$STAGE_DIR/bin/"
cp libexec/auto-updates-runner "$STAGE_DIR/libexec/"
cp config/auto-updates.conf "$STAGE_DIR/config/"
cp config/auto-updates.logrotate "$STAGE_DIR/config/"
cp systemd/auto-updates.service "$STAGE_DIR/systemd/"
cp systemd/auto-updates.timer "$STAGE_DIR/systemd/"
cp completions/auto-updates.bash "$STAGE_DIR/completions/"
cp man/auto-updates.8 "$STAGE_DIR/man/"
cp man/auto-updates.conf.5 "$STAGE_DIR/man/"
cp assets/icons/auto-updates.svg "$STAGE_DIR/assets/icons/"
cp desktop/auto-updates.desktop "$STAGE_DIR/desktop/"
cp desktop/auto-updates.metainfo.xml "$STAGE_DIR/desktop/"
cp README.md "$STAGE_DIR/"
cp LICENSE "$STAGE_DIR/"

tar -czf "${TOPDIR}/SOURCES/${TARBALL}" -C "$TEMP_SOURCE_DIR" "${NAME}-${VERSION}"
cp auto-updates.spec "${TOPDIR}/SPECS/"

# Detect distribution if running in single-distro builder
LOCAL_DIST=""
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [ "${ID:-}" = "fedora" ]; then
        LOCAL_DIST=".fc${VERSION_ID:-44}"
    elif [ "${ID:-}" = "rocky" ] || [ "${ID:-}" = "almalinux" ]; then
        LOCAL_DIST=".el${VERSION_ID%%.*}"
    fi
fi

if [ -n "$LOCAL_DIST" ]; then
    echo "Running rpmbuild for local distro (${LOCAL_DIST})..."
    rpmbuild -ba \
        --define "_topdir ${TOPDIR}" \
        --define "dist ${LOCAL_DIST}" \
        "${TOPDIR}/SPECS/auto-updates.spec"
fi

if [ -z "$LOCAL_DIST" ] || [ "$LOCAL_DIST" = ".el10" ]; then
    for dtag in ".fc44" ".fc45" ".el10"; do
        if [ "$dtag" != "$LOCAL_DIST" ]; then
            echo "Running rpmbuild (${dtag})..."
            rpmbuild -ba \
                --define "_topdir ${TOPDIR}" \
                --define "dist ${dtag}" \
                "${TOPDIR}/SPECS/auto-updates.spec"
        fi
    done
fi

# Copy resulting RPMs to standardized build-linux/Output and dist
for rpm_file in $(find "${TOPDIR}/RPMS" -name "*.rpm"); do
    rpm_base=$(basename "$rpm_file")
    cp -v "$rpm_file" "${PROJECT_ROOT}/dist/"
    if [[ "$rpm_base" == *".el10."* ]]; then
        cp -v "$rpm_file" "${PROJECT_ROOT}/build-linux/Output/rocky/10/"
        cp -v "$rpm_file" "${PROJECT_ROOT}/build-linux/Output/almalinux/10/"
    elif [[ "$rpm_base" == *".fc44."* ]]; then
        cp -v "$rpm_file" "${PROJECT_ROOT}/build-linux/Output/fedora/44/"
    elif [[ "$rpm_base" == *".fc45."* ]]; then
        cp -v "$rpm_file" "${PROJECT_ROOT}/build-linux/Output/fedora/45/"
    fi
done

cp -v "${TOPDIR}/SRPMS"/*.src.rpm "${PROJECT_ROOT}/dist/" 2>/dev/null || true

echo ""
echo "================================================================================"
echo " Signing RPM packages with GPG..."
echo "================================================================================"
mapfile -t ALL_RPMS < <(find "${PROJECT_ROOT}/build-linux/Output" "${PROJECT_ROOT}/dist" -name "*.rpm" | sort -u)
rpmsign --addsign "${ALL_RPMS[@]}"

echo ""
echo "================================================================================"
echo " Verifying GPG Signatures (Strict Security Mode)..."
echo "================================================================================"
for rpm_pkg in "${ALL_RPMS[@]}"; do
    [ -f "$rpm_pkg" ] || continue
    echo "    Checking: $(basename "$rpm_pkg")"
    if ! rpm -Kv "$rpm_pkg" | grep -qiE "Header.*Signature.*OK"; then
        echo "FATAL: Security verification failed for $rpm_pkg!" >&2
        rpm -Kv "$rpm_pkg" >&2
        exit 1
    fi
done
echo "    [PASS] All package cryptographic signatures verified successfully."

echo ""
echo "================================================================================"
echo " RPM Build & Signing Complete!"
echo " Output files in: ${PROJECT_ROOT}/build-linux/Output/ & ${PROJECT_ROOT}/dist/"
echo "================================================================================"
ls -lh "${PROJECT_ROOT}/dist"

if command -v rpmlint &>/dev/null; then
    echo ""
    echo "================================================================================"
    echo " Running rpmlint package quality validation..."
    echo "================================================================================"
    LATEST_EL_RPM=$(find "${PROJECT_ROOT}/build-linux/Output/rocky/10" -name "*.rpm" 2>/dev/null | head -n 1)
    if [ -n "$LATEST_EL_RPM" ]; then
        rpmlint "$LATEST_EL_RPM" "${TOPDIR}/SPECS/auto-updates.spec" || true
    fi
fi
