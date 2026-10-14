# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit git-r3
DESCRIPTION="Patch series for experimental Apple T2 GPU runtime power management"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
RDEPEND="sys-devel/patch sys-apps/kmod"
S="${EGIT_CHECKOUT_DIR}/patches/runtime/gpu-runtime-pm"
src_install() {
    insinto /usr/share/kait2en/kernel-patches/gpu-runtime-pm
    doins "${S}/series" "${S}"/*.patch
    newbin "${FILESDIR}/kait2en-kernel-preflight" kait2en-kernel-preflight
}
pkg_postinst() {
    elog "Patches are staged under /usr/share/kait2en/kernel-patches, not automatically applied."
    elog "Run kait2en-kernel-preflight /usr/src/linux before opting into patches."
    elog "Build kernels through sys-kernel/gentoo-kernel and /etc/kernel/config.d (not Fedora RPM/DKMS)."
}
