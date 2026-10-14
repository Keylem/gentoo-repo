# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8
DESCRIPTION="Modular KaiT2en packages for Gentoo on Apple T2 Macs"
HOMEPAGE="https://github.com/Keylem/KaiT2en-Gentoo"
LICENSE="metapackage"
SLOT="0"
KEYWORDS=""
IUSE="+apps drivers services dsp alsa touchbar discrete-gpu hybrid-gpu kernel-patches kernel-builder openzfs kernel-sources kernel-zfs wifi-tools"
REQUIRED_USE="?? ( discrete-gpu hybrid-gpu ) ?? ( kernel-sources kernel-zfs )"
S="${WORKDIR}"
RDEPEND="
    apps? (
        app-misc/kait2en-assets
        app-misc/t2-fan-control
        app-misc/t2-smc-control
        app-misc/t2-power-explorer
        app-misc/t2-force-click
        app-misc/t2-zone-power
    )
    drivers? (
        sys-kernel/kait2en-t2bce-stack
        sys-kernel/kait2en-t2smc
        sys-kernel/kait2en-t2sbs
        sys-kernel/kait2en-t2sep
        sys-kernel/kait2en-t2gmux
        sys-kernel/kait2en-t2bdrm
        sys-kernel/kait2en-t2thunderbolt
        sys-kernel/kait2en-t2smp
        sys-kernel/kait2en-t2mfi-fastcharge
        sys-kernel/kait2en-hid-t2magicmouse
        sys-kernel/kait2en-t2-precision-trackpad
        sys-kernel/kait2en-t2-trackpad-actuator
    )
    services? (
        app-misc/t2-services-common
        app-misc/t2-journal
        app-misc/t2-ave
        app-misc/t2-touchid
    )
    dsp? ( app-misc/t2-dsp )
    alsa? ( app-misc/t2-alsa-ucm )
    touchbar? (
        app-misc/kait2en-touchbar
        sys-kernel/kait2en-t2touchbar
    )
    discrete-gpu? ( app-misc/t2-dgpu-control )
    hybrid-gpu? ( app-misc/t2-hybrid-gpu-control )
    kernel-patches? ( sys-kernel/kait2en-kernel-patches )
    kernel-builder? ( app-misc/t2-kernel-builder )
    wifi-tools? ( app-misc/kait2en-wifi-tools )
    openzfs? ( sys-fs/zfs )
    kernel-sources? ( sys-kernel/kait2en-sources )
    kernel-zfs? ( sys-kernel/kait2en-kernel-openzfs )
"
src_install() { :; }
