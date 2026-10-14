# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
PYTHON_COMPAT=( python3_{12..15} )
inherit git-r3 udev python-any-r1
DESCRIPTION="T2 Mac DSP and WirePlumber profile integration"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
S="${EGIT_CHECKOUT_DIR}/dsp"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
BDEPEND="${PYTHON_DEPS}"
RDEPEND="media-video/pipewire media-video/wireplumber"
src_compile() {
	python_setup
	emake -C "${S}" PYTHON="${PYTHON}" build
}
src_install() {
	python_setup
	emake -C "${S}" DESTDIR="${ED}" PREFIX=/usr \
		LIBEXECDIR=/usr/libexec UDEVDIR=/usr/lib/udev/rules.d PYTHON="${PYTHON}" install
}

pkg_postinst() {
	udev_reload
	elog "Restart PipeWire and WirePlumber user sessions to load updated T2 DSP profiles."
}
pkg_postrm() {
	udev_reload
}
