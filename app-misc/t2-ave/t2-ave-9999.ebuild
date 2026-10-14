# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit cargo git-r3 systemd kait2en-systemd

DESCRIPTION="T2 AVE daemon and remote service"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
S="${EGIT_CHECKOUT_DIR}/t2-services/t2-ave"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
KAIT2EN_SYSTEMD_UNITS="kait2en-t2-remote.service"
RESTRICT="test"

RDEPEND="

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
	sed 's|@BINDIR@|/usr/bin|g' "${S}/integration/systemd/kait2en-t2-remote.service" \
		| sed 's|/usr/sbin/modprobe|modprobe|g' > "${T}/kait2en-t2-remote.service" || die
	systemd_dounit "${T}/kait2en-t2-remote.service"
	exeinto /usr/libexec/t2-services/sleep.d
	newexe "${S}/integration/systemd/t2-ave-suspend" t2-ave
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
