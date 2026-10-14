#!/usr/bin/env bash
# Run only inside an expendable Gentoo systemd stage3 container!
# Exercises real Portage file ownership and install->reinstall->unmerge.
set -euo pipefail

test_atom() {
    local atom=$1 owned=$2
    printf ':: install %s\n' "${atom}"
    emerge --ask=n --oneshot "${atom}" || { echo "FAIL: install ${atom}" >&2; return 1; }
    [[ -f ${owned} ]] || { echo "FAIL: missing installed file: ${owned}" >&2; return 1; }

    printf ':: reinstall %s\n' "${atom}"
    emerge --ask=n --oneshot --nodeps --emptytree "${atom}" ||
        { echo "FAIL: reinstall ${atom}" >&2; return 1; }
    [[ -f ${owned} ]] || { echo "FAIL: update removed expected file: ${owned}" >&2; return 1; }

    printf ':: unmerge %s\n' "${atom}"
    emerge --ask=n --unmerge "${atom}" || { echo "FAIL: unmerge ${atom}" >&2; return 1; }
    [[ ! -e ${owned} ]] || { echo "FAIL: orphaned installed file: ${owned}" >&2; return 1; }
}

test_atom app-misc/t2-kernel-builder /usr/bin/t2-kernel-builder
test_atom app-misc/kait2en-assets /usr/share/kait2en/kait2en-wordmark.png
test_atom sys-kernel/kait2en-kernel-patches /usr/bin/kait2en-kernel-preflight
# Build and install the real DMG conversion utility (not only pretend metadata).
test_atom dev-util/dmg2img /usr/bin/dmg2img
test_atom app-misc/kait2en-wifi-tools /usr/bin/kait2en-wifi-setup

# Generate benign test bytes; never download or distribute proprietary Apple
# firmware in CI. Exercise the *installed* staging helper, then confirm the
# unprivileged Portage build user can read the archive.
synthetic=$(mktemp /tmp/kait2en-synthetic-firmware.XXXXXXXX.tar)
python3 - "$synthetic" <<'PY'
import io
import sys
import tarfile
with tarfile.open(sys.argv[1], "w") as tar:
    data = b"synthetic test payload, NOT real Apple firmware"
    info = tarfile.TarInfo("brcmfmac4377b3-pcie.apple.bin")
    info.size = len(data)
    tar.addfile(info, io.BytesIO(data))
PY
emerge --ask=n --oneshot app-misc/kait2en-wifi-tools
kait2en-wifi-setup stage "$synthetic"
rm -f "$synthetic"
[[ $(stat -c '%a:%G' /var/cache/kait2en-wifi) == 750:portage ]] ||
    { echo "FAIL: firmware staging directory must be root:portage mode 750" >&2; exit 1; }
[[ $(stat -c '%a:%G' /var/cache/kait2en-wifi/firmware.tar) == 640:portage ]] ||
    { echo "FAIL: firmware archive must be root:portage mode 640" >&2; exit 1; }
runuser -u portage -- test -r /var/cache/kait2en-wifi/firmware.tar ||
    { echo "FAIL: Portage build user cannot read staged firmware" >&2; exit 1; }
test_atom sys-firmware/kait2en-wifi-firmware /lib/firmware/brcm/brcmfmac4377b3-pcie.apple.bin
# The original staged archive is not package-owned and must survive unmerge.
[[ -s /var/cache/kait2en-wifi/firmware.tar ]] ||
    { echo "FAIL: Portage unexpectedly removed user-staged firmware" >&2; exit 1; }
emerge --ask=n --unmerge app-misc/kait2en-wifi-tools
rm -f /var/cache/kait2en-wifi/firmware.tar
rmdir /var/cache/kait2en-wifi
echo "PASS: real Portage install/reinstall/unmerge, unprivileged staging, synthetic Wi-Fi firmware"

