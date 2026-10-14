# KaiT2en for Gentoo Linux — MacBook Pro T2 setup

**A beginner's step-by-step guide** to using Gentoo Linux on an Intel Apple
MacBook Pro with the T2 chip. You can run **Linux only**, without keeping a
macOS partition. Wi-Fi firmware can be downloaded from Apple's recovery server
without macOS installed.

> **Status:** Community overlay under active testing, not a ready-made Gentoo
> installation ISO. A compatible Gentoo kernel, bootloader, and working
> fallback are still necessary. The scripts below do not erase disks or enable
> experimental kernel patches automatically.

## Before starting

You will need a T2 MacBook Pro, a USB installation drive, a way to access the
Internet initially **without the built-in Wi-Fi** (USB phone tethering or
Ethernet), and backups of anything you want to keep.

**Boot/security setup:** On T2 Macs, first use macOS Recovery's
**Utilities → Startup Security Utility** to choose **No Security** and allow
booting from external media. This is a T2 firmware setting, **not** the same
thing as needing macOS installed for Wi-Fi. If you erased macOS before changing
boot policy, you may need to restore access to Apple Recovery first.
[Read the T2 Linux pre-install guide](https://wiki.t2linux.org/guides/preinstall/).

### Step 1 — Install Gentoo Linux itself

Download a Gentoo **amd64 systemd stage3** and use the
[official Gentoo AMD64 Handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64)
for partitioning, stage3 installation, selecting the systemd profile,
configuring a bootloader and making your first boot.

**Do not copy partitioning commands from another Mac:** disk layouts,
EFI partitions, and whether macOS is retained differ. Do not format the EFI
System Partition unless you know it is safe. Preserve your recovery route.

For beginners, get a working Gentoo boot with a **source-built Gentoo
distribution kernel**, initramfs and NetworkManager **before** adding T2
extras. Verify:

```sh
cat /etc/gentoo-release
test -d /run/systemd/system && echo "systemd is running"
cat /sys/class/dmi/id/product_name
uname -r
```

If systemd isn't running, select a Gentoo systemd installation/profile first.
This overlay does not convert an OpenRC system automatically.

### Step 2 — Get temporary Internet access

The Mac's Broadcom chip may need firmware before Wi-Fi can work. Use Ethernet
via USB adapter or USB tethering from a phone. Check the link:

```sh
nmcli device status
ping -c 3 github.com
```

If `nmcli` is not installed, install/enable NetworkManager on Gentoo:

```sh
sudo emerge -av net-misc/networkmanager
sudo systemctl enable --now NetworkManager.service
```

### Step 3 — Add this overlay

Copy these commands **one at a time**:

```sh
sudo mkdir -p /etc/portage/repos.conf
sudo tee /etc/portage/repos.conf/keylem.conf >/dev/null <<'EOF'
[keylem]
location = /var/db/repos/keylem
sync-type = git
sync-uri = https://github.com/Keylem/gentoo-repo.git
auto-sync = yes
EOF
sudo emaint sync -r keylem
```

Most apps in this repository track development `9999` versions. Allow these
**only in the keylem overlay**, not all Gentoo packages:

```sh
sudo mkdir -p /etc/portage/package.accept_keywords
echo '*/*::keylem **' | sudo tee /etc/portage/package.accept_keywords/kait2en
```

> These instructions apply once the linked PR has been merged to `main`.
> For testing the draft branch, use a separate clone of its branch as your
> local overlay.

### Step 4 — Get the MacBook Wi-Fi firmware (NO macOS required)

This is an **optional one-time firmware setup**, not part of a normal Portage
build. It uses [kholia's macOS recovery downloader](https://github.com/kholia/OSX-KVM/blob/master/fetch-macOS-v2.py)
and T2 Linux's Broadcom firmware renamer. Apple firmware is proprietary and
**never stored in this GitHub repository**.

```sh
sudo emerge -av app-misc/kait2en-wifi-tools
```

Run the next command **as your regular login user, without sudo**. It downloads
an Apple recovery image (approximately 650 MB) and extracts the firmware to a
local archive; allow several GB of free storage. It may ask for `sudo` to
mount the recovery image **read-only**.

```sh
kait2en-wifi-setup prepare sonoma
```

If Apple no longer provides usable Sonoma recovery, try `ventura` or
`monterey`. If the command fails, see the
[T2 Linux Wi-Fi guide](https://wiki.t2linux.org/guides/wifi-bluetooth/)
rather than trying a random firmware download.

After it prints the output path, **stage** that file (replace the example home
path with yours):

```sh
sudo kait2en-wifi-setup stage "$HOME/.cache/kait2en-wifi/firmware.tar"
sudo emerge -av sys-firmware/kait2en-wifi-firmware
sudo reboot
```

After reboot, connect through your desktop's network menu or:

```sh
nmcli device wifi list
nmcli --ask device wifi connect "YOUR_NETWORK"
```

Using `--ask` avoids leaving your Wi-Fi password in shell history.

**If you still have no Wi-Fi:** check `lspci -nn`,
`journalctl -k -b | grep -i brcm` and `nmcli device status`. You need
the kernel's **`brcmfmac` driver**, not `broadcom-wl`.
The required recovery image may vary by model and Apple availability;
this process has not been tested on every MacBook Pro T2.

### Step 5 — Install the T2 kernel driver components

The distribution kernel may already contain some drivers. **Do not install
every module blindly**: older and in-kernel copies can conflict.

Check `lsmod`, `modinfo t2smc` and your machine's hardware first. For a
typical SMC/trackpad setup, inspect the install plan:

```sh
sudo emerge -pvt sys-kernel/kait2en-t2smc
sudo emerge -av sys-kernel/kait2en-t2smc
```

Additional individually packaged drivers (BCE, Touch Bar, trackpad, GPU and
others) are described in the [complete component guide](docs/INSTALL-AND-USE.md).
These are external modules built for Gentoo's selected kernel.

### Step 6 — Install the apps

Install the basic control apps as a group:

```sh
sudo emerge -av app-misc/kait2en
```

Or choose **just one app**:

```sh
sudo emerge -av app-misc/t2-fan-control
```

You should now find Fan Control, SMC Control, Power Explorer, Force Click and
Zone Power in your desktop application menu (depending on what you installed).

**Important:** Services aren't enabled automatically. After verifying your
hardware, you can start Fan Control's background service with:

```sh
sudo systemctl enable --now t2-fancontrol.service
```

### Step 7 — Optional Touch Bar, Touch ID, audio and GPU features

| Goal | Package to install | Next action |
|---|---|---|
| Touch Bar | `app-misc/kait2en-touchbar` | Join `kait2en-touchbar` group; reboot; enable user service |
| Touch ID | `app-misc/t2-touchid` | Configure bridge service and `fprintd`; enroll in macOS first |
| Speakers/DSP | `app-misc/t2-alsa-ucm`, `app-misc/t2-dsp` | Restart audio session |
| T2 diagnostics | `app-misc/t2-journal` | Run `t2journal -b` |
| GPU switching | `app-misc/t2-dgpu-control` **or** `app-misc/t2-hybrid-gpu-control` | Check exact Mac model and kernel patch compatibility |
| Kernel helper | `app-misc/t2-kernel-builder` | Run `t2-kernel-builder help` |

The [complete guide](docs/INSTALL-AND-USE.md) has the commands and model
restrictions for all of these. Don't enable GPU switching on an unsupported Mac.

### Step 8 — Optional Gentoo kernel sources or OpenZFS

For kernel **sources** managed through Portage:

```sh
sudo emerge -av sys-kernel/kait2en-sources
```

For the Gentoo source-built **distribution kernel + OpenZFS external module**:

```sh
sudo mkdir -p /etc/portage/package.use
printf 'sys-fs/zfs dist-kernel modules\nsys-kernel/installkernel dracut\n' |
    sudo tee /etc/portage/package.use/kait2en-zfs
sudo emerge -av sys-kernel/kait2en-kernel-openzfs
```

These metapackages **stage** T2 kernel patches; they don't apply unverified
patches automatically. Use `kait2en-kernel-preflight` to check applicability.
If you boot from ZFS, test the exact kernel/ZFS version and initramfs before
switching your default boot entry. Keep your previous bootable kernel.
See [the advanced kernel guide](docs/INSTALL-AND-USE.md#9-kernel-installation-option-b--portage-kernel-with-openzfs).

### Step 9 — Update or undo your changes

```sh
sudo emaint sync -r keylem
sudo emerge -av1 app-misc/t2-fan-control
```

To remove an optional application cleanly:

```sh
sudo systemctl disable --now t2-fancontrol.service
sudo emerge --unmerge app-misc/t2-fan-control
sudo emerge --ask --pretend --depclean
```

To remove the extracted Apple Wi-Fi firmware from **Portage's installed
files**, use `sudo emerge --unmerge sys-firmware/kait2en-wifi-firmware`.
The staging archive at `/var/cache/kait2en-wifi/firmware.tar` and your
`~/.cache/kait2en-wifi` copy are intentionally preserved so you can recover
Wi-Fi after reinstalling. Remove those copies manually if you no longer need
them. Uninstalling firmware will make Wi-Fi unavailable after the next reload
or reboot unless an alternative firmware is present.

## More detailed instructions

- **[All applications, systemd services, kernels, OpenZFS and troubleshooting](docs/INSTALL-AND-USE.md)**
- [Official Gentoo Handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64)
- [T2 Linux pre-install boot-security instructions](https://wiki.t2linux.org/guides/preinstall/)
- [T2 Linux Wi-Fi and Bluetooth firmware documentation](https://wiki.t2linux.org/guides/wifi-bluetooth/)

**Testing status:** Package dependency resolution and CI checks are not an
end-to-end Gentoo kernel or real Apple T2 hardware certification. Please keep a
known-good Linux boot entry.
