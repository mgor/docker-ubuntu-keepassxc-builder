#!/bin/bash
PACKAGE="keepassxc"
DEBEMAIL="github@mgor.se"
DEBFULLNAME="docker-ubuntu-${PACKAGE}-builder"
DEBCOPYRIGHT="debian/copyright"
USER=builder
URL="https://github.com/keepassxreboot/keepassxc"
DISTRO="$(lsb_release -sc)"

export DISTRO URL USER DEBCOPYRIGHT DEBFULLNAME DEBEMAIL PACKAGE

run() {
    sudo -Eu "${USER}" -H "${@}"
}

groupadd --gid "${GROUP_ID}" "${USER}" && \
useradd -M -N -u "${USER_ID}" -g "${GROUP_ID}" "${USER}" && \
chown "${USER}" . && \
run git clone "${URL}.git" "${PACKAGE}" && \
cd "${PACKAGE}" || exit

KEEPASSXC_VERSION="$(git tag | tail -1)"
export KEEPASSXC_VERSION

run git checkout "tags/${KEEPASSXC_VERSION}" -b "${KEEPASSXC_VERSION}"

run cmake -DCMAKE_INSTALL_PREFIX=/usr -DWITH_XC_AUTOTYPE=ON -DWITH_XC_BROWSER=ON -DCMAKE_BUILD_TYPE=Release

VERSION="$(git tag | sort -u | tail -1)-$(date +"%Y%m%d")-$(git rev-parse --short HEAD)"
export VERSION

run dh_make -p "${PACKAGE}_${VERSION}" -s -y --createorig

# Create overrides for lintian
sudo -Eu "${USER}" -H tee "debian/${PACKAGE}.lintian-overrides" >/dev/null <<EOF
${PACKAGE} binary: binary-without-manpage *
${PACKAGE} binary: icon-size-and-directory-name-mismatch *
EOF

# Fix debian/copyright
COPYRIGHT_YEAR="$(awk '/^Copyright/ {gsub(/-.+/, "", $3); print $3; exit}' COPYING)"
COPYRIGHT_OWNER="$(awk '/^Copyright/ {print $(NF-2)" "$(NF-1)" "$NF; exit}' COPYING)"
export COPYRIGHT_YEAR COPYRIGHT_OWNER

{ echo ""; awk '/Files: debian/,/^$/' "${DEBCOPYRIGHT}"; } | sudo -Eu "${USER}" -H tee "${DEBCOPYRIGHT}.template" >/dev/null
sudo -Eu "${USER}" -H tee "${DEBCOPYRIGHT}" >/dev/null <<EOF

Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${PACKAGE}
Source: $(git config remote.origin.url)

Files: *
Copyright: ${COPYRIGHT_YEAR} ${COPYRIGHT_OWNER}
License: Custom
EOF

#shellcheck disable=SC2002
cat "${DEBCOPYRIGHT}.template" | sudo -Eu "${USER}" -H tee -a "${DEBCOPYRIGHT}" >/dev/null && rm -rf "${DEBCOPYRIGHT}.template"

# Fix debian/changelog
run rm -rf debian/changelog
run dch -D "${DISTRO}" --create --package "${PACKAGE}" --newversion "${VERSION}" "Automagically built in docker"

# Fix debian/control
DESCRIPTION="$(awk 'f{gsub(/\[.+\].*\)/, "KeePassX", $0); print $0;f=0} /## About/{f=1}' README.md | fold -s -w 60 | sed -r 's|^[\ \t]*||g; s|^(.)| \1|')"
SHORT_DESCRIPTION="$(awk -F' - ' '/^KeePass / {print $NF}' README.md)"
export DESCRIPTION SHORT_DESCRIPTION

run sed -i '/^#/d' debian/control
run sed -r -i "s|^(Section:).*|\1 x11|" debian/control
run sed -r -i "s|^(Homepage:).*|\1 ${URL}|" debian/control
run sed -r -i "s|^(Architecture:).*|\1 $(dpkg --print-architecture)|" debian/control
run sed -r -i "s|^(Description:).*|\1 ${SHORT_DESCRIPTION}|" debian/control
run sed -i '$ d' debian/control
echo "${DESCRIPTION}" | sudo -u "${USER}" tee -a debian/control >/dev/null
run rm -rf debian/README.Debian
run cp README.md debian/README.source

if run debuild -i -us -uc -b
then
    cd ../ && rm -rf "${PACKAGE}"
else
    echo "Build failed!"
    exit 1
fi

exit 0
