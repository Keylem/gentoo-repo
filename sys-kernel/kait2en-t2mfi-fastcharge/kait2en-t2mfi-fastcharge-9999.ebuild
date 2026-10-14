# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit git-r3 linux-mod-r1

DESCRIPTION="Apple T2 out-of-tree kernel drivers (t2mfi_fastcharge)"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
RESTRICT="test"
S="${EGIT_CHECKOUT_DIR}/modules/t2mfi_fastcharge"

src_compile() {
    # Use the kernel chosen by Gentoo, not uname -r or Fedora's kernel-devel.
    # Building BCE as one unit keeps modpost symbol versions consistent.
    emake "${MODULES_MAKEARGS[@]}" \
        KDIR="${KV_OUT_DIR}" KERNEL_SRC="${KV_OUT_DIR}" \
        KVER="${KV_FULL}" KVERSION="${KV_FULL}" all
}

src_install() {
    linux_moduleinto extra
    linux_domodule "${S}/t2mfi_fastcharge.ko"
    modules_post_process
    einstalldocs
}

pkg_postinst() {
    linux-mod-r1_pkg_postinst
    elog "Modules were built for ${KV_FULL}; use @module-rebuild after kernel changes."
}
