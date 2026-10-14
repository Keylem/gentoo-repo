# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Gentoo distribution kernel and matching Portage-built OpenZFS modules"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
S="${WORKDIR}"
LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"
RDEPEND="
	sys-kernel/gentoo-kernel
	>=sys-fs/zfs-2.4[dist-kernel,modules]
	sys-kernel/kait2en-kernel-patches
"
src_install() { :; }
pkg_postinst() {
	elog "The Linux kernel and OpenZFS are built via Portage, not statically linked."
	elog "The KaiT2en patch series is staged, not automatically applied."
	elog "Only opt in to patches after exact-version validation; keep a fallback kernel."
	elog "For ZFS root, verify the bootloader and an initramfs including zfs.ko."
}
