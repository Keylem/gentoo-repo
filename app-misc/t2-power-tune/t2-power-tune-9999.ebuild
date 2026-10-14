# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit git-r3 systemd kait2en-systemd
DESCRIPTION="Power management tuning GUI for Apple T2 Macs"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
KAIT2EN_SYSTEMD_UNITS="kait2en-power-tune.service"
S="${EGIT_CHECKOUT_DIR}/apps/t2-power-tune"
RDEPEND="app-misc/kait2en-assets dev-python/pygobject gui-libs/gtk:4 gui-libs/libadwaita:1 sys-apps/pciutils sys-apps/polkit sys-apps/systemd"
src_prepare() {
    default
    sed -i 's@/usr/local/@/usr/@g' "${S}/t2-power-tune.py" \
        "${S}/t2-power-tune-helper" "${S}/t2-power-tune-status" \
        "${S}/org.t2powertune.policy" || die
}
src_install() {
    newbin "${S}/t2-power-tune.py" t2-power-tune
    exeinto /usr/libexec
    doexe "${S}/t2-power-tune-helper" "${S}/t2-power-tune-status"
    insinto /usr/share/polkit-1/actions
    doins "${S}/org.t2powertune.policy"
    insinto /usr/share/applications
    doins "${S}/org.t2powertune.gtk.desktop"
    insinto /usr/share/icons/hicolor/scalable/apps
    doins "${S}/org.t2powertune.gtk.svg"
}

pkg_postinst() {
    kait2en_systemd_pkg_postinst
}
pkg_prerm() {
    kait2en_systemd_pkg_prerm
}
pkg_postrm() {
    kait2en_systemd_pkg_postrm
    if [[ -z ${REPLACED_BY_VERSION} ]]; then
        elog "If the GUI created /etc/systemd/system/kait2en-power-tune.service,"
        elog "review and remove it manually; Portage will not delete user-created units."
    fi
}
