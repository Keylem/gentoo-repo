# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8
EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit git-r3
DESCRIPTION="Shared artwork for the KaiT2en user interface"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
S="${EGIT_CHECKOUT_DIR}/assets"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
src_install() {
	insinto /usr/share/kait2en
	newins "${S}/kait2en-app-logo.png" kait2en-wordmark.png
}
