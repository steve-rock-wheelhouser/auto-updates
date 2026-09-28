#!/bin/bash
# ==============================================================================
# build_deb.sh
# Builds the auto-updates Debian / Ubuntu (.deb) package
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
VERSION="1.1.0"
RELEASE="1"
ARCH="all"
DEB_NAME="${NAME}_${VERSION}-${RELEASE}_${ARCH}.deb"

echo "================================================================================"
echo " Building Debian/Ubuntu (.deb) package: ${DEB_NAME}"
echo "================================================================================"

BUILD_ROOT="${SCRIPT_DIR}/build/deb"
rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"
mkdir -p "${SCRIPT_DIR}/dist"

STAGE_DIR="${BUILD_ROOT}/pkg"
mkdir -p "${STAGE_DIR}"/{DEBIAN,usr/bin,usr/libexec,lib/systemd/system,etc/auto-updates,etc/logrotate.d,usr/share/bash-completion/completions,usr/share/man/man8,usr/share/man/man5,usr/share/doc/auto-updates}

# Install application files
install -p -m 0755 bin/auto-updates "${STAGE_DIR}/usr/bin/auto-updates"
install -p -m 0755 libexec/auto-updates-runner "${STAGE_DIR}/usr/libexec/auto-updates-runner"
install -p -m 0644 systemd/auto-updates.service "${STAGE_DIR}/lib/systemd/system/auto-updates.service"
install -p -m 0644 systemd/auto-updates.timer "${STAGE_DIR}/lib/systemd/system/auto-updates.timer"
install -p -m 0644 config/auto-updates.conf "${STAGE_DIR}/etc/auto-updates/auto-updates.conf"
install -p -m 0644 config/auto-updates.logrotate "${STAGE_DIR}/etc/logrotate.d/auto-updates"
install -p -m 0644 completions/auto-updates.bash "${STAGE_DIR}/usr/share/bash-completion/completions/auto-updates"
install -p -m 0644 README.md "${STAGE_DIR}/usr/share/doc/auto-updates/README.md"
install -p -m 0644 debian/copyright "${STAGE_DIR}/usr/share/doc/auto-updates/copyright"

# Install and gzip man pages
gzip -9 -n -c man/auto-updates.8 > "${STAGE_DIR}/usr/share/man/man8/auto-updates.8.gz"
gzip -9 -n -c man/auto-updates.conf.5 > "${STAGE_DIR}/usr/share/man/man5/auto-updates.conf.5.gz"
chmod 0644 "${STAGE_DIR}/usr/share/man/man8/auto-updates.8.gz" "${STAGE_DIR}/usr/share/man/man5/auto-updates.conf.5.gz"

# Install DEBIAN control files
install -p -m 0644 debian/control "${STAGE_DIR}/DEBIAN/control"
# Update version in control file if needed
sed -i "s|^Package:.*|Package: ${NAME}|" "${STAGE_DIR}/DEBIAN/control"
if ! grep -q "^Version:" "${STAGE_DIR}/DEBIAN/control"; then
    sed -i "/^Package:/a Version: ${VERSION}-${RELEASE}" "${STAGE_DIR}/DEBIAN/control"
fi

install -p -m 0755 debian/auto-updates.postinst "${STAGE_DIR}/DEBIAN/postinst"
install -p -m 0755 debian/auto-updates.prerm "${STAGE_DIR}/DEBIAN/prerm"
install -p -m 0755 debian/auto-updates.postrm "${STAGE_DIR}/DEBIAN/postrm"

cat <<EOF > "${STAGE_DIR}/DEBIAN/conffiles"
/etc/auto-updates/auto-updates.conf
/etc/logrotate.d/auto-updates
EOF

# Calculate installed-size in KB
INSTALLED_SIZE=$(du -sk --exclude=DEBIAN "$STAGE_DIR" | cut -f1)
sed -i "/^Version:/a Installed-Size: ${INSTALLED_SIZE}" "${STAGE_DIR}/DEBIAN/control"

# Generate md5sums
(
    cd "$STAGE_DIR"
    find . -type f ! -path './DEBIAN/*' | sed 's|^\./||' | sort | while read -r f; do
        md5sum "$f"
    done > DEBIAN/md5sums
    chmod 0644 DEBIAN/md5sums
)

DEST_DEB="${SCRIPT_DIR}/dist/${DEB_NAME}"

if command -v dpkg-deb &>/dev/null; then
    echo "Building .deb using dpkg-deb..."
    dpkg-deb --build --root-owner-group "$STAGE_DIR" "$DEST_DEB"
else
    echo "dpkg-deb not found; assembling .deb package using portable ar/tar pipeline..."
    TMP_PKG=$(mktemp -d)
    trap 'rm -rf "$TMP_PKG"' EXIT

    echo "2.0" > "${TMP_PKG}/debian-binary"

    (
        cd "${STAGE_DIR}/DEBIAN"
        tar --numeric-owner --owner=0 --group=0 -czf "${TMP_PKG}/control.tar.gz" .
    )

    (
        cd "$STAGE_DIR"
        tar --numeric-owner --owner=0 --group=0 --exclude='./DEBIAN' -czf "${TMP_PKG}/data.tar.gz" .
    )

    (
        cd "$TMP_PKG"
        ar rcs "$DEST_DEB" debian-binary control.tar.gz data.tar.gz
    )
fi

echo ""
echo "================================================================================"
echo " Debian Package Built Successfully!"
echo " Package: ${DEST_DEB}"
echo "================================================================================"
ls -lh "$DEST_DEB"

echo ""
echo "Package contents:"
if command -v dpkg-deb &>/dev/null; then
    dpkg-deb -c "$DEST_DEB"
else
    ar -t "$DEST_DEB"
fi

if command -v sha256sum &>/dev/null; then
    echo ""
    echo "SHA256 Checksum:"
    sha256sum "$DEST_DEB"
fi
