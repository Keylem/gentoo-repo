# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit cargo git-r3 systemd

DESCRIPTION="Hybrid GPU controls for supported T2 MacBook models"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
RESTRICT="test"
IUSE="environment"

S="${EGIT_CHECKOUT_DIR}/apps/t2-hybrid-gpu-control"

RDEPEND="
    app-misc/kait2en-assets
    gui-libs/gtk:4
    gui-libs/libadwaita:1
    sys-apps/polkit
    
    
    
    !app-misc/t2-dgpu-control
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
    insinto /usr/share/applications
    doins "${S}/org.t2hybridgpucontrol.gtk.desktop"
    insinto /usr/share/icons/hicolor/scalable/apps
    doins "${S}/assets/icons/hicolor/scalable/apps/org.t2hybridgpucontrol.gtk.svg"
    exeinto /usr/libexec
    doexe "${S}/contrib/t2-hybrid-gpu-control-helper"
    exeinto /usr/libexec
    doexe "${S}/contrib/t2-hybrid-gpu-control-status"
    insinto /usr/share/polkit-1/actions
    doins "${S}/contrib/org.t2hybridgpucontrol.policy"
    insinto /usr/share/polkit-1/actions
    doins "${S}/contrib/org.t2hybridgpucontrol.status.policy"
    if use environment; then
        insinto /etc/environment.d
        doins "${S}/contrib/90-kait2en-gsk-renderer.conf"
    fi
}

pkg_postinst() {
    elog "Services are installed but intentionally not auto-enabled."
    elog "Enable only those matching your T2 Mac hardware using systemctl."
}
