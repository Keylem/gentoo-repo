# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8
DESCRIPTION="User-initiated macOS Recovery Broadcom Wi-Fi firmware extractor for T2 Macs"
HOMEPAGE="https://github.com/Keylem/gentoo-repo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
S="${WORKDIR}"
RDEPEND="
    dev-lang/python
    dev-util/dmg2img
    net-misc/curl
    app-admin/sudo
    sys-apps/coreutils
    sys-apps/util-linux
"
src_install() {
    newbin "${FILESDIR}/kait2en-wifi-setup" kait2en-wifi-setup
    exeinto /usr/libexec/kait2en-wifi
    newexe "${FILESDIR}/validate.py" validate.py
}
pkg_postinst() {
    elog "Wi-Fi firmware download is NOT automatic. Connect via USB tethering or Ethernet."
    elog "Run as a regular user: kait2en-wifi-setup prepare sonoma"
    elog "Then stage the resulting tarball and install sys-firmware/kait2en-wifi-firmware."
}
