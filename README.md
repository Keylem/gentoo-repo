# KaiT2en Gentoo overlay

This **personal Gentoo overlay** packages [KaiT2en](https://github.com/Keylem/KaiT2en-Gentoo) for **amd64 Gentoo with a systemd profile**. Unlike the abandoned `/opt` + installer approach, Portage owns each installed file; ebuilds do **not** call upstream `install.sh`, `emerge`, `dkms`, `systemctl enable`, or `make install` on the host.

## Add repository

Create `/etc/portage/repos.conf/keylem.conf`:

```ini
[keylem]
location = /var/db/repos/keylem
sync-type = git
sync-uri = https://github.com/Keylem/gentoo-repo.git
auto-sync = yes
```

After merging this branch, `emaint sync -r keylem`. For PR testing before merge, clone the PR branch into a local overlay with the same repo name instead.

All source-based KaiT2en packages are **9999 live ebuilds**, so their `KEYWORDS` are intentionally empty. In `/etc/portage/package.accept_keywords/kait2en` enable them explicitly, for example:

```
app-misc/kait2en **
app-misc/t2-fan-control **
sys-kernel/kait2en-t2smc **
```

The metapackage uses multiple live dependencies, so add `**` for each selected dependency. The `app-misc/t2-kernel-builder` Gentoo CLI uses a regular `1.0` ebuild.

## Independently installable packages

**Rust GUI apps** (each installs its own binary/desktop icon/service/polkit helpers as available):
`app-misc/t2-fan-control`, `app-misc/t2-force-click`, `app-misc/t2-smc-control`, `app-misc/t2-power-explorer`, `app-misc/t2-zone-power`, `app-misc/t2-dgpu-control`, `app-misc/t2-hybrid-gpu-control`, `app-misc/kait2en-touchbar`.

**Other programs/services:** `app-misc/t2-journal`, `app-misc/t2-ave`, `app-misc/t2-touchid`, `app-misc/t2-power-tune`, `app-misc/t2-services-common`, `app-misc/t2-dsp`, `app-misc/t2-alsa-ucm`, `app-misc/t2-kernel-builder`.

**Kernel drivers** (one ebuild per Kbuild unit, names prefixed with `sys-kernel/kait2en-`): `hid-t2magicmouse`, `t2-precision-trackpad`, `t2-trackpad-actuator`, `t2bdrm`, `t2gmux`, `t2mfi-fastcharge`, `t2sbs`, `t2sep`, `t2smc`, `t2smp`, `t2thunderbolt`, `t2touchbar`, and `t2bce-stack`. The BCE stack is intentionally one build unit because five kernel modules share a Kbuild/modpost symbol namespace.

The **metapackage** is `app-misc/kait2en`; core apps are on by default and services, drivers, Touch Bar, audio, GPU flavor, and kernel patchset are selectable with USE flags. Discrete and hybrid GPU modes are mutually exclusive and should be chosen only on supported models.

## Gentoo kernel workflow

- Use `sys-kernel/gentoo-kernel` from source (or manually selected `gentoo-sources`/custom source tree). `gentoo-kernel-bin` cannot incorporate custom kernel source patches.
- Use `/etc/kernel/config.d/*.config` for supported Gentoo distribution-kernel configuration snippets.
- `sys-kernel/kait2en-kernel-patches` **stages** the upstream `gpu-runtime-pm` series under `/usr/share/kait2en/kernel-patches/gpu-runtime-pm`. It does not apply unverified patches automatically. Inspect `series`, target kernel version and each patch; opt in via `/etc/portage/patches/sys-kernel/gentoo-kernel/` (Portage's `eapply_user`) if the exact series applies.
- The **new** `t2-kernel-builder` command is a Gentoo CLI wrapper exposing `status`, `patches`, and `build`; it delegates builds to Portage. This is **not** a port of the upstream Fedora/Koji graphical kernel builder.
- `linux-mod-r1` builds modules against Gentoo's selected `KV_OUT_DIR`, with Gentoo toolchain/signing/compression/depmod handling. Enable `USE=dist-kernel` where appropriate and use `emerge --ask @module-rebuild` when rebuilding custom kernels. Select a kernel with `eselect kernel` when relevant.

## Services and hardware

Units are installed via `systemd.eclass` and **not auto-enabled**. On supported machines, inspect then enable only the relevant services, e.g. `systemctl enable --now t2-fancontrol.service`. The touchbar has a **user** unit and a separate system attach unit. Polkit entries and drivers are package-owned. For power management and graphics, verify machine model first.

## Validation before deploying to a real machine

```bash
python3 tests/test_overlay.py
find app-misc sys-kernel -name '*.ebuild' -exec bash -n '{}' +
pkgcheck scan --repo=keylem
emerge -pvt app-misc/t2-fan-control
emerge -pvt app-misc/t2-ave
emerge -pvt sys-kernel/kait2en-t2bce-stack
emerge -pvt app-misc/kait2en
```

For **each** live package, perform a real `ebuild path/to/package-9999.ebuild manifest clean unpack prepare compile install` in a Gentoo test system/chroot, including the enabled systemd profile. For hardware/runtime checks test kernel module loading, suspend/resume, and Touch ID **on the exact Mac model**. This repository's structural checks alone do not prove 100% install/runtime compatibility; upstream builds move with `main`, kernel APIs vary, and the Fedora-specific upstream GUI has not been ported.

**Important:** These modules and some kernel patches can affect boot, storage, power management, or suspend. Keep a working fallback kernel/boot entry.

## Clean installs, upgrades, and uninstallations

All package-owned binaries, policy files, icons, unit files, udev rules,
kernel modules, DSP profiles and upstream patch files are installed into the
Portage image. No install hook directly copies to `/usr/local` or `/opt`.
Nothing automatically enables a service or patches the running kernel.

On **first install** choose only the components and compatible GPU model
you need. To **update**, synchronize the overlay and explicitly rebuild live
ebuilds (`-9999` packages) to obtain a new upstream revision, preferably
the entire chosen KaiT2en set together. When a unit file changes, restart
the service yourself at a suitable maintenance time. The eclass deliberately
does not stop/disable services during upgrades.

On **unmerge**, the custom systemd lifecycle code stops/disables *system*
units owned by that package, only for a real running systemd installation
and only on final unmerge; Portage removes package-owned files. **Per-user**
units such as `kait2en-touchbar.service` must be disabled from each
participating account before removing the package:

```bash
systemctl --user disable --now kait2en-touchbar.service
sudo emerge --ask --unmerge app-misc/kait2en-touchbar
```

On the final unmerge of `app-misc/t2-power-tune`, any service created
interactively by the GUI in `/etc/systemd/system/` must also be reviewed and
removed manually. Portage must not remove files it did not install. Likewise,
`CONFIG_PROTECT` may preserve modified files under `/etc`, and application
state under home folders is *never silently deleted*. Removing only the
metapackage does **not** remove its independent dependencies: use
`emerge --ask --depclean` once they are no longer required by any other
package, and inspect the plan before accepting it.

After an update to a Gentoo kernel, use `USE=dist-kernel`, rebuild external
modules as needed and regenerate the ZFS-aware initramfs before reboot.
Always keep an older bootable kernel.

## OpenZFS compatibility gate

The `kernel-patches` package stages the **currently available AMD GPU
patch series**, not patches to OpenZFS or to the Linux VFS. These files are
*not* proof of compatibility with every Linux release or OpenZFS build.

```bash
sudo emerge --ask sys-kernel/gentoo-kernel sys-fs/zfs
kait2en-kernel-preflight /usr/src/linux
# Only if the preflight passes and you have reviewed the exact patch series:
# copy the numbered patch files into /etc/portage/patches/sys-kernel/gentoo-kernel/
# Rebuild the kernel and OpenZFS for this identical kernel.
sudo emerge --ask --oneshot sys-kernel/gentoo-kernel sys-fs/zfs
kait2en-kernel-preflight --installed-zfs KERNEL_RELEASE
```

Before a ZFS-root reboot, validate `modprobe -S KERNEL_RELEASE -n -v zfs`,
the initramfs contents and bootloader entry without replacing the working
fallback. Kernel patch application + `modinfo` do **not** establish mount,
scrub, snapshot, suspend or rollback safety. Test those on real hardware,
and never test unreviewed patches against the only copy of a pool.

Gentoo currently ships `sys-fs/zfs` and `sys-fs/zfs-kmod` for different
packaging flows; do not force both. The optional `openzfs` USE flag on the
metapackage selects `sys-fs/zfs`, but the operator still has to ensure the
particular ZFS release supports the selected kernel. `linux-mod-r1` or a
successful patch dry-run alone does not validate that API relationship.
