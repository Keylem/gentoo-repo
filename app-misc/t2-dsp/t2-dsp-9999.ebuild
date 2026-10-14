# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit git-r3 udev
DESCRIPTION="T2 Mac DSP and WirePlumber profile integration"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
S="${EGIT_CHECKOUT_DIR}/dsp"
BDEPEND="dev-lang/python"
RDEPEND="media-video/pipewire media-video/wireplumber"
src_compile() { emake -C "${S}" build; }
src_install() {
    emake -C "${S}" DESTDIR="${ED}" PREFIX=/usr \
        LIBEXECDIR=/usr/libexec UDEVDIR=/usr/lib/udev/rules.d install
}

pkg_postinst() {
    udev_reload
    elog "Restart PipeWire and WirePlumber user sessions to load updated T2 DSP profiles."
}
pkg_postrm() {
    udev_reload
}
