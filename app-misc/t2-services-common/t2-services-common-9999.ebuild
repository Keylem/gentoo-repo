# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit git-r3 systemd kait2en-systemd
DESCRIPTION="Shared bridge service integration for Apple T2 Macs"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
KAIT2EN_SYSTEMD_UNITS="t2-services-suspend.service"
IUSE="+networkmanager"
S="${EGIT_CHECKOUT_DIR}/t2-services/shared"
RDEPEND="sys-apps/systemd networkmanager? ( net-misc/networkmanager )"
src_prepare() {
    default
    sed -i 's@/usr/local/@/usr/@g' \
        "${S}/integration/libexec/t2-ncm-sleep" \
        "${S}/integration/libexec/package-actions" || die
}
src_install() {
    sed 's|@LIBEXECDIR@|/usr/libexec|g' \
        "${S}/integration/systemd/t2-services-suspend.service" \
        > "${T}/t2-services-suspend.service" || die
    systemd_dounit "${T}/t2-services-suspend.service"
    exeinto /usr/libexec/t2-services
    doexe "${S}/integration/libexec/t2-ncm-sleep"
    insinto /usr/libexec/t2-services
    doins "${S}/integration/libexec/package-actions"
    exeinto /usr/libexec/t2-services
    newexe "${EGIT_CHECKOUT_DIR}/packaging/lifecycle/kait2en-lifecycle.py" lifecycle.py
    insinto /usr/libexec/t2-services/migration
    doins "${S}"/integration/migration/*
    if use networkmanager; then
        insinto /etc/NetworkManager/conf.d
        doins "${S}/integration/NetworkManager/10-t2-services.conf"
        insinto /etc/NetworkManager/system-connections
        doins "${S}/integration/NetworkManager/t2-ncm.nmconnection"
        fperms 0600 /etc/NetworkManager/system-connections/t2-ncm.nmconnection
    fi
}
pkg_postinst() {
    kait2en_systemd_pkg_postinst
    elog "Enable only services supported by your T2 hardware."
}

pkg_prerm() {
    kait2en_systemd_pkg_prerm
}

pkg_postrm() {
    kait2en_systemd_pkg_postrm
}
