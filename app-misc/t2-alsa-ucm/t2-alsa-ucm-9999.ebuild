# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit git-r3
DESCRIPTION="ALSA UCM profiles for the Apple T2 BCE audio interface"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
S="${EGIT_CHECKOUT_DIR}/modules/t2bce_audio-alsa-ucm-conf"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
RDEPEND="media-libs/alsa-ucm-conf"
src_install() {
	insinto /usr/share/alsa/ucm2
	doins -r "${S}/ucm2/AppleT2" "${S}/ucm2/conf.d"
	einstalldocs
}
