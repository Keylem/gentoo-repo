# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
DESCRIPTION="Gentoo-native T2 kernel build helper (Portage kernel workflow)"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
S="${WORKDIR}"
RDEPEND="
    sys-apps/portage
    app-admin/eselect
    sys-kernel/gentoo-kernel
"
src_install() {
    newbin "${FILESDIR}/t2-kernel-builder-gentoo" t2-kernel-builder
}
pkg_postinst() {
    elog "Use t2-kernel-builder status / patches / build."
    elog "This replaces the Fedora GUI build backend with Gentoo's Portage workflow."
    elog "It does not provide the upstream graphical frontend."
}
