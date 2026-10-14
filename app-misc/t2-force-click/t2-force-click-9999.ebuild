# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit cargo git-r3 systemd xdg kait2en-systemd xdg

DESCRIPTION="Force-click configuration for T2 Mac trackpads"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
KAIT2EN_SYSTEMD_UNITS="t2-force-click.service"
RESTRICT="test"

S="${EGIT_CHECKOUT_DIR}/apps/t2-force-click"

RDEPEND="
    app-misc/kait2en-assets
    gui-libs/gtk:4
    gui-libs/libadwaita:1
    sys-auth/polkit
    
    
    
    
    sys-apps/systemd
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_unpack() {
    git-r3_src_unpack
    cargo_live_src_unpack
}

src_prepare() {
    default
    local f
    while IFS= read -r -d '' f; do
        sed -i -e 's@/usr/local/@/usr/@g' "${f}" || die
    done < <(find "${S}" -type f \( -name '*.rs' -o -name '*.py' \
        -o -name '*.service' -o -name '*.policy' -o -name '*.desktop' \
        -o -name '*.rules' -o -name '*.conf' -o -name '*.toml' \
        -o -name '*.sh' -o -name '*helper' \) -print0)

}

src_configure() {
    cargo_src_configure --locked
}

src_install() {
    cargo_src_install
    insinto /usr/share/applications
    doins "${S}/org.t2forceclick.gtk.desktop"
    insinto /usr/share/icons/hicolor/scalable/apps
    doins "${S}/assets/icons/hicolor/scalable/apps/org.t2forceclick.gtk.svg"
    local unit
    for unit in "${S}"/systemd/*.service; do
        [[ -f ${unit} ]] || continue
        systemd_dounit "${unit}"
    done
}

pkg_postinst() {
    xdg_pkg_postinst
    kait2en_systemd_pkg_postinst
    elog "Enable only services supported by your T2 hardware."
}

pkg_prerm() {
    kait2en_systemd_pkg_prerm
}

pkg_postrm() {
    xdg_pkg_postrm
    kait2en_systemd_pkg_postrm
}
