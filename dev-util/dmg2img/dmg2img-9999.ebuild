# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8
EGIT_REPO_URI="https://github.com/Lekensteyn/dmg2img.git"
inherit git-r3 toolchain-funcs
DESCRIPTION="Convert Apple compressed DMG images to standard disk images"
HOMEPAGE="https://github.com/Lekensteyn/dmg2img"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
DEPEND="app-arch/bzip2 virtual/zlib"
RDEPEND="${DEPEND}"
src_compile() {
	emake CC="$(tc-getCC)" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" dmg2img
}
src_install() {
	dobin dmg2img
}
