# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit cargo git-r3 systemd

DESCRIPTION="Touch ID bridge for fprintd on T2 Macs"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
RESTRICT="test"

S="${EGIT_CHECKOUT_DIR}/t2-services/t2-touchid"

RDEPEND="
    
    
    sys-auth/fprintd
    net-misc/networkmanager
    sys-kernel/kait2en-t2bce-stack
    
    
    
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
    sed 's|@BINDIR@|/usr/bin|g' "${S}/integration/systemd/kait2en-t2-touchid.service" \
        > "${T}/kait2en-t2-touchid.service" || die
    systemd_dounit "${T}/kait2en-t2-touchid.service"
    insinto "$(systemd_get_systemunitdir)/fprintd.service.d"
    newins "${S}/integration/fprintd/fprintd-kait2en-t2-touchid.conf" kait2en-t2-touchid.conf
    insinto /usr/share/dbus-1/system.d
    doins "${S}/integration/dbus/org.kait2en.TouchId.conf"
    insinto /etc/kait2en
    doins "${S}/config/t2-touchid.conf"
}

pkg_postinst() {
    elog "Services are installed but intentionally not auto-enabled."
    elog "Enable only those matching your T2 Mac hardware using systemctl."
}
