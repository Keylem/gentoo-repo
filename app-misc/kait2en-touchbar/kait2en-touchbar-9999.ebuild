# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit cargo git-r3 systemd

DESCRIPTION="Userspace Touch Bar daemon for T2 Macs"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
RESTRICT="test"

S="${EGIT_CHECKOUT_DIR}/apps/t2-touchbar"

RDEPEND="
    
    
    
    
    sys-kernel/kait2en-t2touchbar
    
    sys-apps/systemd
"
DEPEND="${RDEPEND}"

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
    systemd_douserunit "${S}/integration/systemd/user/kait2en-touchbar.service"
    systemd_dounit "${S}/integration/systemd/system/kait2en-touchbar-attach.service"
    insinto /usr/lib/udev/rules.d
    doins "${S}/integration/udev/99-zz-kait2en-touchbar.rules"
    insinto /etc/kait2en
    doins "${S}/config/touchbar.toml"
    dodoc "${S}/THIRD-PARTY-NOTICES.md"
}

pkg_postinst() {
    elog "Services are installed but intentionally not auto-enabled."
    elog "Enable only those matching your T2 Mac hardware using systemctl."
}
