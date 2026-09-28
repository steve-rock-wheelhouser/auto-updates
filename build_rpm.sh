#!/bin/bash
# ==============================================================================
# build_rpm.sh
# Automates building the auto-updates RPM package
#
# Copyright (C) 2026 Steve Rock Wheelhouser <steve@wheelhouser.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

NAME="auto-updates"
VERSION="1.0.3"
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
TOPDIR="${SCRIPT_DIR}/build/rpmbuild"
rm -rf "$TOPDIR"
mkdir -p "${TOPDIR}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "${SCRIPT_DIR}/dist"

# Create source archive
TEMP_SOURCE_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_SOURCE_DIR"' EXIT

STAGE_DIR="${TEMP_SOURCE_DIR}/${NAME}-${VERSION}"
mkdir -p "$STAGE_DIR"/{bin,libexec,config,systemd,completions}

cp bin/auto-updates "$STAGE_DIR/bin/"
cp libexec/auto-updates-runner "$STAGE_DIR/libexec/"
cp config/auto-updates.conf "$STAGE_DIR/config/"
cp systemd/auto-updates.service "$STAGE_DIR/systemd/"
cp systemd/auto-updates.timer "$STAGE_DIR/systemd/"
cp completions/auto-updates.bash "$STAGE_DIR/completions/"
cp README.md "$STAGE_DIR/"
cp LICENSE "$STAGE_DIR/"

tar -czf "${TOPDIR}/SOURCES/${TARBALL}" -C "$TEMP_SOURCE_DIR" "${NAME}-${VERSION}"
cp auto-updates.spec "${TOPDIR}/SPECS/"

echo "Running rpmbuild..."
rpmbuild -ba \
    --define "_topdir ${TOPDIR}" \
    "${TOPDIR}/SPECS/auto-updates.spec"

# Copy resulting RPMs to dist
cp -v "${TOPDIR}/RPMS"/noarch/*.rpm "${SCRIPT_DIR}/dist/" 2>/dev/null || cp -v "${TOPDIR}/RPMS"/*/*.rpm "${SCRIPT_DIR}/dist/"
cp -v "${TOPDIR}/SRPMS"/*.src.rpm "${SCRIPT_DIR}/dist/"

echo ""
echo "================================================================================"
echo " Signing RPM packages with GPG..."
echo "================================================================================"
rpmsign --addsign "${SCRIPT_DIR}/dist"/*.rpm

echo ""
echo "================================================================================"
echo " Verifying GPG Signatures..."
echo "================================================================================"
for rpm_pkg in "${SCRIPT_DIR}/dist"/*.rpm; do
    echo -n "$(basename "$rpm_pkg"): "
    rpm -K "$rpm_pkg"
done

echo ""
echo "================================================================================"
echo " RPM Build & Signing Complete!"
echo " Output files in: ${SCRIPT_DIR}/dist/"
echo "================================================================================"
ls -lh "${SCRIPT_DIR}/dist"

echo ""
echo "Package inspection:"
BUILT_RPM=$(find "${SCRIPT_DIR}/dist" -name "${NAME}-${VERSION}*.noarch.rpm" | head -n 1)
if [ -n "$BUILT_RPM" ]; then
    echo "Signature details:"
    rpm -qi -p "$BUILT_RPM" | grep -A 2 -i "Signature"
    echo ""
    echo "Files in package:"
    rpm -qpl "$BUILT_RPM"
fi
