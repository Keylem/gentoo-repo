# KaiT2en on Gentoo: installation and every component

This is the **Portage overlay** procedure, not the Fedora/RPM, DKMS or
`make install` procedure shown in some upstream application READMEs.
Commands are for **amd64 Gentoo using a running systemd profile**.
Select hardware-specific services only after verifying your Mac model.

**Scope and limits:** Package metadata and dependency plans have been checked
in a Gentoo systemd stage3. They do not guarantee all upstream Rust binaries
compile with every live dependency revision, nor that any driver works with
all future kernels. Experimental kernel patches must be verified for **each
kernel release**. Preserve a working bootloader entry and a backup before
changing drivers or ZFS-root boot.

## 1. Identify your machine and kernel

```sh
cat /etc/gentoo-release
readlink -f /etc/init.d 2>/dev/null || true
test -d /run/systemd/system && echo "systemd is running"
cat /sys/class/dmi/id/product_name
uname -r
eselect kernel list
find /lib/modules -maxdepth 2 -name build -print
```

An existing Gentoo **systemd** installation is assumed. Changing init system
profiles is a separate system migration; this overlay does not do it. Confirm
the device is an Apple T2 Intel Mac. Different models have different
Touch Bars, GPUs, temperature sensors and driver requirements.

## 2. Add overlay and allow live packages

Write `/etc/portage/repos.conf/keylem.conf`:

```ini
[keylem]
location = /var/db/repos/keylem
sync-type = git
sync-uri = https://github.com/Keylem/gentoo-repo.git
auto-sync = yes
```

```sh
sudo emaint sync -r keylem
```

Most packages are `-9999` ebuilds with empty KEYWORDS. For this *personal
overlay only*, create `/etc/portage/package.accept_keywords/kait2en`:

```text
*/*::keylem **
```

Use narrower individual atoms if preferred. Inspect live source changes before
updating; a new upstream commit can change build dependencies.

For a minimal GUI bundle, enable only `USE=apps` on the metapackage (its
default), or install individual components:

```sh
sudo emerge --ask --verbose app-misc/kait2en
sudo emerge --ask --verbose app-misc/t2-fan-control
```

For selected groups, create `/etc/portage/package.use/kait2en`:

```text
app-misc/kait2en apps services dsp alsa
```

Add `drivers`, `touchbar`, `discrete-gpu`, `hybrid-gpu`,
`kernel-sources`, `kernel-zfs` or `openzfs` only deliberately.
`discrete-gpu` and `hybrid-gpu` are mutually exclusive.
`kernel-sources` and `kernel-zfs` are mutually exclusive metapackage
choices; the underlying packages are independently installable. A full
`drivers` selection is for testing; on a specific Mac install only needed
modules where possible.

## 3. Each application: package and command

All packages are standalone: `sudo emerge -av <atom>`. GUIs are launched
from the desktop app menu or with the executable shown. A **service** listed
below is *not enabled automatically* by the ebuild.

| Package (prefix `app-misc/`) | How to use | Optional service / notes |
|---|---|---|
| `t2-fan-control` | `t2-fancontrol-gtk` — inspect sensors and edit fan curve | `t2-fancontrol.service`; monitor temperatures after enabling |
| `t2-force-click` | `t2-force-click` — configure click thresholds and shortcuts | `t2-force-click.service`; needs precision trackpad and actuator modules |
| `t2-smc-control` | `t2-smc-control` — fan/SMC, battery and charging telemetry | `t2-smc-gaugingd.service` handles gauge calibration; needs `t2smc` |
| `t2-power-explorer` | `t2-power-explorer` — inspect power diagnostics | No mandatory daemon |
| `t2-zone-power` | `t2-zonepower-gtk` — view SMC thermal power limits | `t2-zonepowerd.service`; needs `t2smc`; no interactive settings |
| `t2-dgpu-control` | `t2-dgpu-control` — legacy dGPU mode control | Only for appropriate MacBookPro15,3; supports related GPU units |
| `t2-hybrid-gpu-control` | `t2-hybrid-gpu-control` — Intel/AMD hybrid mode | Only for MacBookPro15,1 / 16,1 / 16,4 with *verified* GMUX/AMDGPU patches |
| `t2-power-tune` | `t2-power-tune` — experiment with device and PCIe power settings | Can create a **user-managed** `kait2en-power-tune.service`; risky; test transiently first |
| `kait2en-touchbar` | `kait2en-touchbar --status` | User `kait2en-touchbar.service` plus system `kait2en-touchbar-attach.service`; see section 4 |
| `t2-journal` | `t2journal -b`, `t2journal refresh` | BridgeOS diagnostics; requires T2 NCM network link |
| `t2-ave` | `t2remote --help` | `kait2en-t2-remote.service`; kernel BCE/AVE stack required |
| `t2-touchid` | `fprintd-enroll`, `fprintd-verify` | `kait2en-t2-touchid.service`; see section 5 |
| `t2-services-common` | NetworkManager T2 Bridge profile and suspend coordination | `t2-services-suspend.service` |
| `t2-dsp` | PipeWire/WirePlumber DSP profiles; no standalone GUI | Restart user audio session after install or upgrade |
| `t2-alsa-ucm` | ALSA UCM2 Apple T2 speaker/microphone profiles | No standalone executable |
| `kait2en-assets` | Shared KaiT2en artwork | Installed automatically for GUIs that need it |
| `t2-kernel-builder` | `t2-kernel-builder help` | Gentoo CLI, not upstream Fedora graphical builder |

For each system service, enable *only after checking that your device
supports it*. Example:

```sh
sudo systemctl enable --now t2-fancontrol.service
systemctl status t2-fancontrol.service
journalctl -b -u t2-fancontrol.service --no-pager
```

Stop and disable an optional service using `sudo systemctl disable --now
UNIT.service`. This does not uninstall the ebuild.

### 4. Touch Bar setup

The package depends on `acct-group/kait2en-touchbar`, which creates a
dedicated group for the udev device nodes. It **does not automatically add
your login** to that group:

```sh
sudo emerge -av app-misc/kait2en-touchbar
sudo usermod -aG kait2en-touchbar "$USER"
```

**Reboot** to ensure your login and user systemd manager have the new group
before switching the Touch Bar out of firmware mode. After reboot:

```sh
sudo systemctl --global enable kait2en-touchbar.service
sudo systemctl enable --now kait2en-touchbar-attach.service
systemctl --user enable --now kait2en-touchbar.service
kait2en-touchbar --status
```

To revert to the original Apple firmware row:

```sh
systemctl --user disable --now kait2en-touchbar.service
sudo systemctl --global disable kait2en-touchbar.service
sudo systemctl disable --now kait2en-touchbar-attach.service
sudo reboot
```

Per-user settings: `~/.config/kait2en-touchbar/config.toml` and
`keys.toml`; machine defaults: `/etc/kait2en/touchbar.toml`.
Do not enable competing Touch Bar daemons (tiny-dfr/react-drm).

### 5. Touch ID and T2 bridge setup

```sh
sudo emerge -av app-misc/t2-services-common app-misc/t2-touchid
nmcli connection show "Apple T2 Bridge"
sudo systemctl enable --now kait2en-t2-touchid.service
systemctl status kait2en-t2-touchid.service
fprintd-enroll
fprintd-verify
```

In `/etc/kait2en/t2-touchid.conf`, set
`T2_TOUCHID_BIND_USER=<linux-login>` for automatic binding, or leave
`none` and use `fprintd-enroll` manually. Enrollment of new fingerprints
must first happen in **macOS**; KaiT2en binds an existing T2 identity to the
Linux account. If T2 was power-cycled, macOS may need to unlock its
biometric keybag once. Review PAM policies before enabling biometric login or
sudo; never remove your password fallback.

For AVE remote services:

```sh
sudo emerge -av app-misc/t2-ave
sudo systemctl enable --now kait2en-t2-remote.service
journalctl -b -u kait2en-t2-remote.service
```

The BCE stack contains five symbol-sharing kernel modules and is intentionally
one build unit. The systemd NCM suspend unit is optional: review with
`systemctl cat t2-services-suspend.service` before enabling.

To read logs:

```sh
sudo emerge -av app-misc/t2-journal
t2journal -b
t2journal --list-boots
t2journal -b --grep 'suspend|watchdog'
t2journal refresh --sysdiagnose
```

### 6. GPU modes, fan management and power tuning

GPU control packages **conflict** with one another. The hybrid GUI requires
kernel patch functionality not guaranteed by the overlay; do not enable
hybrid mode merely because the program installs. The dGPU-off/power
profiles are also hardware- and boot-mode-sensitive. Keep a fallback
boot option and verify `cat /sys/class/dmi/id/product_name` first.

Start the fan and SMC GUIs in monitoring mode before enabling their
daemons. Observe fan RPM, temperatures and charge behavior, and do not
disable firmware over-temperature protections. T2 Zone Power runs a
hardware throttling daemon only when its corresponding unit is enabled.

For `t2-power-tune`, apply one change per session and test sleep/wake.
If its dynamically created power-tuning systemd unit breaks boot, add
`systemd.mask=kait2en-power-tune.service` once to the boot command line,
then disable the unit and remove the **user-created** file from
`/etc/systemd/system/` after recovery. Portage cannot own that
runtime-created configuration file.

### 7. Individually installable kernel drivers

Each entry is a separate `sys-kernel/` package:

| Kernel package suffix (`kait2en-`) | Resulting kernel module(s) |
|---|---|
| `t2bce-stack` | `t2bce_dma`, `t2bce_core`, `t2bce_vhci`, `t2bce_audio`, `t2bce_ave` |
| `t2smc`, `t2sbs`, `t2sep` | `t2smc`, `t2sbs`, `t2sep` |
| `t2gmux`, `t2bdrm` | `t2gmux`, `t2bdrm` |
| `t2thunderbolt`, `t2smp`, `t2mfi-fastcharge` | Corresponding names with underscores |
| `hid-t2magicmouse` | `hid_t2magicmouse` |
| `t2-precision-trackpad`, `t2-trackpad-actuator` | `t2_precision_trackpad`, `t2_trackpad_actuator` |
| `t2touchbar` | `t2hid`, `t2touchbar_bl`, `t2touchbar_kbd` |

Example:

```sh
sudo emerge -av sys-kernel/kait2en-t2smc
modinfo t2smc
sudo modprobe t2smc
journalctl -k -b --no-pager | tail -n 80
```

Out-of-tree modules are built against Gentoo's selected kernel build tree
using `linux-mod-r1`, not Fedora DKMS. Check whether your distribution
kernel already supplies equivalent modules before installing out-of-tree
copies. Test for clashes and back up the previous kernel. The BCE group must
build together to share Kbuild symbol versions.

## 8. Kernel installation option A — Gentoo sources

This option installs real **Gentoo Linux kernel sources** plus staged T2
patches, but does **not** automatically apply an unverified patch series:

```sh
sudo emerge -av sys-kernel/kait2en-sources
sudo emerge -av app-misc/t2-kernel-builder
t2-kernel-builder sources
eselect kernel list
```

Select the correct `gentoo-sources` tree using `sudo eselect kernel
set N`. Preflight any experimental patches:

```sh
kait2en-kernel-preflight /usr/src/linux
```

Only if the **entire** numbered series applies, review each file and opt in
through `/etc/portage/patches/sys-kernel/gentoo-sources/` **before**
re-emerging the kernel sources. Manual builds can then use Gentoo's
kernel configuration/build tooling; an OpenZFS module is built separately
against those *same* configured kernel sources. A successful source
installation does not imply a bootable compiled kernel. For the Gentoo
source package, the original patches must not be copied twice and must
be removed for rollback.

## 9. Kernel installation option B — Portage kernel with OpenZFS

Recommended for automatic kernel/module rebuild integration on systems
already using Gentoo distribution kernels. These are *two* kernel outputs:
Linux and the external `zfs.ko`. OpenZFS normally cannot simply be enabled
as a built-in mainline kernel Kconfig option.

```sh
sudo mkdir -p /etc/portage/package.use
printf 'sys-kernel/installkernel dracut\n' |
    sudo tee /etc/portage/package.use/kait2en-initramfs
sudo emerge -av sys-kernel/installkernel
sudo emerge -av sys-kernel/kait2en-kernel-openzfs
```

The metapackage depends on `sys-kernel/gentoo-kernel` and
`sys-fs/zfs[modules,dist-kernel]`. If using patches, inspect/test the
specific upstream series with `kait2en-kernel-preflight SOURCE_TREE`,
then deliberately stage them under the **distribution kernel** user-patch
directory `/etc/portage/patches/sys-kernel/gentoo-kernel/` before emerging.
Portage's `eapply_user` must run during kernel preparation. Do **not**
assume patches fit because filenames look recent.

```sh
t2-kernel-builder status
sudo t2-kernel-builder build-zfs
sudo emerge -av @module-rebuild
# Replace KERNEL_RELEASE by the actual new /lib/modules directory name
t2-kernel-builder verify-zfs KERNEL_RELEASE
modinfo -k KERNEL_RELEASE zfs
```

For ZFS root, ensure the *new* initramfs really includes `zfs.ko`,
the necessary ZFS userspace/configuration and your correct boot
parameters. Use `lsinitrd` for a Dracut image and verify
`zpool status` on a mounted pool **only after safe boot testing**.
Keep the old kernel, initramfs and known-good boot entry. Never test
unverified patches on the only copy of important data.

### Kernel updates and rollback

On kernel update, rebuild the matching T2 modules and OpenZFS modules,
check generated kernel release and rebuild the initramfs if necessary:

```sh
sudo emerge -av @module-rebuild
sudo emerge --config sys-kernel/gentoo-kernel
```

`USE=dist-kernel` is appropriate for a distribution kernel.
If a patch fails on a newer kernel, **remove it** from your chosen
`/etc/portage/patches/sys-kernel/...` directory and rebuild the
unpatched package rather than forcing it to apply.

## 10. Update and completely remove selected applications

Check what Portage owns:

```sh
qlist -e app-misc/t2-fan-control       # from app-portage/portage-utils
equery files app-misc/t2-fan-control   # from app-portage/gentoolkit
```

For live `9999` ebuilds, synchronizing the overlay does not necessarily
rebuild unchanged installed versions. Request the re-emerge you intend:

```sh
sudo emaint sync -r keylem
sudo emerge -av1 app-misc/t2-fan-control
sudo emerge -av1 sys-kernel/kait2en-t2smc
```

To remove an optional app, disable its unit first, then unmerge that app:

```sh
sudo systemctl disable --now t2-fancontrol.service
sudo emerge -C app-misc/t2-fan-control
sudo emerge -av --depclean
```

**Removing the metapackage by itself does not automatically remove each
component**, and dependent packages may still be needed elsewhere. Inspect
any proposed depclean, particularly ZFS and your current kernel.
User settings in `~/.config`, other home directories and user-created
`/etc/systemd/system` units are intentionally retained. Only remove
those manually after backup and verification. System group membership is
not blindly erased by unmerging the Touch Bar package.

## 11. What still needs testing before production

Validate each selected package with `emerge --pretend`, `emerge`,
reinstall and unmerge in a disposable systemd Gentoo installation. For
T2 hardware, also test module loading, display switching, trackpad
force click, fan control, Bluetooth/USB through BCE, networking across
suspend, Touch ID and device permissions. For the kernel+OpenZFS
combination, validate the **exact** ZFS version against the **exact**
kernel headers/source/config and your ZFS-root recovery path. A static
QA pass alone is not a 100% compatibility certification.

## Appendix: exact Portage atoms for optional drivers and kernels

The following names can be passed directly to `emerge -av`. Install only
what your hardware requires; this is not a command to install everything:

```text
sys-kernel/kait2en-hid-t2magicmouse
sys-kernel/kait2en-t2-precision-trackpad
sys-kernel/kait2en-t2-trackpad-actuator
sys-kernel/kait2en-t2bce-stack
sys-kernel/kait2en-t2bdrm
sys-kernel/kait2en-t2gmux
sys-kernel/kait2en-t2mfi-fastcharge
sys-kernel/kait2en-t2sbs
sys-kernel/kait2en-t2sep
sys-kernel/kait2en-t2smc
sys-kernel/kait2en-t2smp
sys-kernel/kait2en-t2thunderbolt
sys-kernel/kait2en-t2touchbar
sys-kernel/kait2en-kernel-patches
sys-kernel/kait2en-sources
sys-kernel/kait2en-kernel-openzfs
```
