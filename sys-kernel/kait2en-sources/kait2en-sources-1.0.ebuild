# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Gentoo-patched Linux sources and opt-in KaiT2en patch toolkit"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
S="${WORKDIR}"
LICENSE="metapackage"
SLOT="0"
KEYWORDS=""
IUSE="openzfs"
RDEPEND="
	sys-kernel/gentoo-sources
	sys-kernel/kait2en-kernel-patches
	openzfs? ( >=sys-fs/zfs-2.4[modules] )
"
src_install() { :; }
pkg_postinst() {
	elog "Gentoo kernel sources are installed by sys-kernel/gentoo-sources."
	elog "KaiT2en's experimental GPU patches are not applied automatically."
	elog "Inspect the chosen /usr/src/linux-* tree and preflight the patch series."
	elog "To build OpenZFS against a custom kernel, select its sources using eselect kernel."
}
