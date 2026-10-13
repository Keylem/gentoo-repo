# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Linux support tooling for Apple T2 Macs from the KaiT2en project"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
EGIT_REPO_URI="https://github.com/Keylem/KaiT2en-Gentoo.git"
EGIT_BRANCH="copilot/modify-kai2ten-for-gentoo"

LICENSE="GPL-2 GPL-3 MIT OFL-1.1"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="
	app-admin/sudo
	dev-build/make
	dev-lang/rust
	dev-libs/libinput
	dev-libs/libplist
	dev-python/pygobject
	dev-util/pkgconf
	gui-libs/libadwaita
	media-fonts/jetbrains-mono
	media-libs/alsa-ucm-conf
	sys-apps/polkit
	sys-apps/systemd
	sys-auth/fprintd
	sys-auth/libfprint
	sys-devel/gcc
	sys-kernel/dkms
	x11-libs/gtk+:3
"
DEPEND="${RDEPEND}"

src_prepare() {
	default

	# Dependencies are already managed by Portage for this package.
	sed -i '/install-dependencies\.sh/d' scripts/gentoo/install.sh || die
}

src_install() {
	dodir /opt/kait2en
	cp -a "${S}"/. "${ED}/opt/kait2en/" || die
	find "${ED}/opt/kait2en" -type f -name '*.sh' -exec chmod 0755 {} + || die

	cat > "${T}/kait2en-gentoo-install" <<-'EOS' || die
	#!/usr/bin/env bash
	exec /opt/kait2en/scripts/gentoo/install.sh "$@"
	EOS
	dobin "${T}/kait2en-gentoo-install"
}

pkg_postinst() {
	elog "Run 'kait2en-gentoo-install' as root to install KaiT2en services and modules."
	elog "This installer requires a Gentoo system running systemd on supported Apple T2 hardware."
}
