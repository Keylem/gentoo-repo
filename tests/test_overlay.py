#!/usr/bin/env python3
"""Fast structural checks; not a replacement for emerge or hardware tests."""
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
rust = ("t2-fan-control","t2-force-click","t2-smc-control","t2-power-explorer",
        "t2-zone-power","t2-dgpu-control","t2-hybrid-gpu-control",
        "kait2en-touchbar","t2-journal","t2-ave","t2-touchid")
other = ("t2-power-tune","kait2en-assets","t2-dsp","t2-alsa-ucm","t2-services-common","t2-kernel-builder")
modules = ("hid-t2magicmouse","t2-precision-trackpad","t2-trackpad-actuator",
           "t2bdrm","t2gmux","t2mfi-fastcharge","t2sbs","t2sep","t2smc",
           "t2smp","t2thunderbolt","t2touchbar","t2bce-stack")
expected = {f"app-misc/{name}" for name in (*rust,*other,"kait2en")}
expected |= {f"sys-kernel/kait2en-{name}" for name in modules}
expected.add("sys-kernel/kait2en-kernel-patches")
expected.update(("sys-kernel/kait2en-sources", "sys-kernel/kait2en-kernel-openzfs", "acct-group/kait2en-touchbar", "app-misc/kait2en-wifi-tools", "sys-firmware/kait2en-wifi-firmware", "dev-util/dmg2img"))
actual = set()
for ebuild in ROOT.glob("*/*/*.ebuild"):
    package = ebuild.parent.relative_to(ROOT).as_posix()
    actual.add(package)
    data = ebuild.read_text()
    assert re.search(r"^EAPI=8$", data, re.M), ebuild
    assert "src_install()" in data or package != "app-misc/kait2en", ebuild
    assert "/opt/kait2en" not in data, ebuild
    assert "install.sh" not in data, ebuild
    assert "systemctl enable" not in data, ebuild
    assert "dkms install" not in data, ebuild
    assert package in ("app-misc/t2-kernel-builder", "sys-kernel/kait2en-sources", "sys-kernel/kait2en-kernel-openzfs", "acct-group/kait2en-touchbar", "app-misc/kait2en-wifi-tools", "sys-firmware/kait2en-wifi-firmware") or "KEYWORDS=\"\"" in data, ebuild
    assert list(ebuild.parent.glob("metadata.xml")), ebuild
    subprocess.run(["bash", "-n", str(ebuild)], check=True)
    ET.parse(ebuild.parent / "metadata.xml")
assert actual == expected, f"missing={expected-actual}, extra={actual-expected}"
for package in (*rust,):
    eb = (ROOT / "app-misc" / package / f"{package}-9999.ebuild").read_text()
    assert "cargo_live_src_unpack" in eb and "cargo_src_install" in eb, package
for package in modules:
    name = f"kait2en-{package}"
    eb = (ROOT / "sys-kernel" / name / f"{name}-9999.ebuild").read_text()
    assert "linux-mod-r1" in eb and "KV_OUT_DIR" in eb and "modules_post_process" in eb, name
meta = (ROOT / "app-misc/kait2en/kait2en-9999.ebuild").read_text()
for package in expected - {"app-misc/kait2en"}:
    if package in ("app-misc/t2-power-tune", "acct-group/kait2en-touchbar", "sys-firmware/kait2en-wifi-firmware", "dev-util/dmg2img"):
        continue  # separately installable, not in the default metapackage
    assert package in meta, f"metapackage missing {package}"
assert "?? ( discrete-gpu hybrid-gpu )" in meta
assert "openzfs? ( sys-fs/zfs )" in meta
assert "wifi-tools? ( app-misc/kait2en-wifi-tools )" in meta
assert "kernel-sources? ( sys-kernel/kait2en-sources )" in meta
assert "kernel-zfs? ( sys-kernel/kait2en-kernel-openzfs )" in meta
assert "?? ( kernel-sources kernel-zfs )" in meta
assert "acct-group/kait2en-touchbar" in (ROOT / "app-misc/kait2en-touchbar/kait2en-touchbar-9999.ebuild").read_text()
for name in ("t2-force-click", "t2-smc-control", "t2-zone-power"):
    eb = (ROOT / "app-misc" / name / f"{name}-9999.ebuild").read_text()
    assert "sys-kernel/kait2en-" in eb, name
for name in ("t2-fan-control", "t2-force-click", "t2-smc-control", "t2-zone-power", "t2-dgpu-control", "t2-ave", "t2-touchid", "t2-services-common", "kait2en-touchbar", "t2-power-tune"):
    eb = (ROOT / "app-misc" / name / f"{name}-9999.ebuild").read_text()
    assert "kait2en_systemd_pkg_prerm" in eb, name
    assert "kait2en_systemd_pkg_postrm" in eb, name
    assert "KAIT2EN_SYSTEMD_UNITS=" in eb, name
for name in ("t2-fan-control", "t2-force-click", "t2-smc-control", "t2-power-explorer", "t2-zone-power", "t2-dgpu-control", "t2-hybrid-gpu-control", "t2-power-tune"):
    eb = (ROOT / "app-misc" / name / f"{name}-9999.ebuild").read_text()
    assert "xdg_pkg_postinst" in eb and "xdg_pkg_postrm" in eb, name
for name in ("kait2en-touchbar", "t2-dsp"):
    eb = (ROOT / "app-misc" / name / f"{name}-9999.ebuild").read_text()
    assert "udev_reload" in eb, name
doc = (ROOT / "docs/INSTALL-AND-USE.md").read_text()
for package in expected:
    if package != "acct-group/kait2en-touchbar":
        assert package.split("/")[-1] in doc, f"Not documented: {package}"
cli = (ROOT / "app-misc/t2-kernel-builder/files/t2-kernel-builder-gentoo").read_text()
for command in ("sources", "build-zfs", "verify-zfs", "status"):
    assert command in cli
readme = (ROOT / "README.md").read_text()
assert "kait2en-wifi-setup prepare sonoma" in readme
assert "sys-firmware/kait2en-wifi-firmware" in readme
assert "fetch-macOS-v2.py" in readme
for path in ("app-misc/kait2en-wifi-tools/files/kait2en-wifi-setup",):
    subprocess.run(["bash", "-n", str(ROOT / path)], check=True)
print(f"PASS: {len(expected)} independently packaged atoms, valid ebuild shell/XML and metapackage refs")
