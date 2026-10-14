# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit python-any-r1
DESCRIPTION="Locally extracted Apple Broadcom firmware for T2 Mac Wi-Fi and Bluetooth"
HOMEPAGE="https://wiki.t2linux.org/guides/wifi-bluetooth/"
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="fetch mirror bindist strip"
S="${WORKDIR}/firmware"
BDEPEND="${PYTHON_DEPS}"
RDEPEND="app-misc/kait2en-wifi-tools"

src_unpack() {
    python_setup
    # EROOT is not defined during src_* phases; staging is host-local.
    local archive="/var/cache/kait2en-wifi/firmware.tar"
    [[ -r ${archive} ]] || die "No local firmware archive! Run kait2en-wifi-setup prepare and sudo kait2en-wifi-setup stage."
    mkdir -p "${S}" || die
    "${PYTHON}" "${FILESDIR}/validate.py" "${archive}" --extract-to "${S}" ||
        die "Unsafe/invalid firmware archive"
}

src_install() {
    insinto /lib/firmware/brcm
    doins "${S}"/brcm*
}

pkg_postinst() {
    elog "Firmware installed through Portage, without redistribution."
    elog "Reboot to load the new brcmfmac/hci_bcm4377 firmware."
    elog "The staged archive remains at /var/cache/kait2en-wifi/firmware.tar."
    elog "Do not use broadcom-wl on a T2 Mac."
}
