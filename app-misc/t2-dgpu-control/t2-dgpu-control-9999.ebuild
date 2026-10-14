# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="main"
EGIT_CHECKOUT_DIR="${WORKDIR}/kait2en"
inherit desktop cargo git-r3 systemd xdg kait2en-systemd

DESCRIPTION="Discrete GPU controls for supported T2 MacBook models"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
S="${EGIT_CHECKOUT_DIR}/apps/t2-dgpu-control"
LICENSE="GPL-3+"
SLOT="0"
KEYWORDS=""
KAIT2EN_SYSTEMD_UNITS="kait2en-dgpu-off.service kait2en-dgpu-suspend.service kait2en-amdgpu-profile.service kait2en-amdgpu-profile-resume.service"
RESTRICT="test"


RDEPEND="
	app-misc/kait2en-assets
	gui-libs/gtk:4
	gui-libs/libadwaita:1
	sys-auth/polkit



	!app-misc/t2-hybrid-gpu-control
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
	domenu "${S}/org.t2dgpucontrol.gtk.desktop"
	insinto /usr/share/icons/hicolor/scalable/apps
	doins "${S}/assets/icons/hicolor/scalable/apps/org.t2dgpucontrol.gtk.svg"
	local unit
	for unit in "${S}"/systemd/*.service; do
		[[ -f ${unit} ]] || continue
		systemd_dounit "${unit}"
	done
	exeinto /usr/libexec
	doexe "${S}/contrib/t2-dgpu-control-helper"
	exeinto /usr/libexec
	doexe "${S}/contrib/t2-dgpu-control-status"
	insinto /usr/share/polkit-1/actions
	doins "${S}/contrib/org.t2dgpucontrol.policy"
	insinto /usr/share/polkit-1/actions
	doins "${S}/contrib/org.t2dgpucontrol.status.policy"
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
