# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit cargo git-r3 systemd kait2en-systemd udev

DESCRIPTION="Userspace Touch Bar daemon for T2 Macs"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
S="${EGIT_CHECKOUT_DIR}/apps/t2-touchbar"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
KAIT2EN_SYSTEMD_UNITS="kait2en-touchbar-attach.service"
RESTRICT="test"

RDEPEND="
	>=dev-libs/libinput-1.21
	virtual/libudev
	acct-group/kait2en-touchbar

	sys-kernel/kait2en-t2touchbar

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
	systemd_douserunit "${S}/integration/systemd/user/kait2en-touchbar.service"
	systemd_dounit "${S}/integration/systemd/system/kait2en-touchbar-attach.service"
	udev_dorules "${S}/integration/udev/99-zz-kait2en-touchbar.rules"
	insinto /etc/kait2en
	doins "${S}/config/touchbar.toml"
	dodoc "${S}/THIRD-PARTY-NOTICES.md"
}

pkg_postinst() {
	kait2en_systemd_pkg_postinst
	udev_reload
	elog "This also installs a user service. On each user account run systemctl --user disable --now kait2en-touchbar.service before unmerge."
}

pkg_prerm() {
	kait2en_systemd_pkg_prerm
}

pkg_postrm() {
	kait2en_systemd_pkg_postrm
	udev_reload
}
