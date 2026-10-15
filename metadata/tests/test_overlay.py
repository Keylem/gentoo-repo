#!/usr/bin/env python3
"""Fast structural checks; not a replacement for emerge or hardware tests."""
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
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
    # pkgcheck flags space-indented and trailing-whitespace ebuild lines.
    for line_number, line in enumerate(data.splitlines(), 1):
        assert not line.startswith(" "), f"{ebuild}:{line_number}: use tabs for indentation"
        assert line == line.rstrip(), f"{ebuild}:{line_number}: trailing whitespace"
    assert "\n\n\n" not in data, f"{ebuild}: pkgcheck DoubleEmptyLine"
    declarations = {
        name: match.start() for name in ("S", "KEYWORDS", "IUSE", "RESTRICT")
        if (match := re.search(r"^" + name + r"=", data, re.M))
    }
    for key in ("KEYWORDS", "IUSE", "RESTRICT"):
        if "S" in declarations and key in declarations:
            assert declarations["S"] < declarations[key], f"{ebuild}: S must precede {key}"
    if "IUSE" in declarations and "RESTRICT" in declarations:
        assert declarations["IUSE"] < declarations["RESTRICT"], f"{ebuild}: IUSE must precede RESTRICT"
    if "domenu " in data:
        assert any("desktop" in line.split()[1:] for line in data.splitlines()
                   if line.startswith("inherit ")), f"{ebuild}: domenu needs desktop.eclass"
    assert re.search(r"^EAPI=8$", data, re.M), ebuild
    for inherit in re.findall(r"^inherit (.*)$", data, re.M):
        classes = inherit.split()
        assert len(classes) == len(set(classes)), f"duplicate eclass inherit: {ebuild}"
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
doc = (ROOT / "metadata/docs/INSTALL-AND-USE.md").read_text()
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
power_tune = (ROOT / "app-misc/t2-power-tune/t2-power-tune-9999.ebuild").read_text()
for native in ("gui-libs/gtk:4[introspection]", "gui-libs/libadwaita:1[introspection]", "x11-libs/gdk-pixbuf:2[introspection]"):
    assert native in power_tune
# Portage source phases do not expose EROOT. The firmware has already been
# staged in the host cache; it must not interpolate an undefined target root.
firmware_ebuild = (ROOT / "sys-firmware/kait2en-wifi-firmware/kait2en-wifi-firmware-1.0.ebuild").read_text()
firmware_unpack = firmware_ebuild.split("src_unpack() {", 1)[1].split("src_install()", 1)[0]
assert 'local archive="/var/cache/kait2en-wifi/firmware.tar"' in firmware_unpack
assert "${EROOT}" not in firmware_unpack and "${EROOT%/}" not in firmware_unpack

# systemd_get_systemunitdir includes EPREFIX, while Portage's insinto adds
# EPREFIX again. Strip it to avoid breaking prefix installations.
touchid = (ROOT / "app-misc/t2-touchid/t2-touchid-9999.ebuild").read_text()
assert 'systemunitdir=$(systemd_get_systemunitdir)' in touchid
assert 'insinto "${systemunitdir#"${EPREFIX}"}/fprintd.service.d"' in touchid

# A previous green Portage job was a false positive: an apostrophe inside
# bash -c '...' terminated the script before it reached any emerge check.
# Refuse that pattern for every Docker-based Gentoo QA workflow.
for workflow in ("portage-qa.yml", "build-smoke.yml", "pkgcheck.yml"):
    workflow_text = (ROOT / ".github/workflows" / workflow).read_text()
    start = "bash -euo pipefail -c '"
    assert workflow_text.count(start) == 1, workflow
    embedded = workflow_text.split(start, 1)[1].split("\n            '", 1)[0]
    assert "'" not in embedded, f"Unescaped quote can bypass {workflow}"
portage_workflow = (ROOT / ".github/workflows/portage-qa.yml").read_text()
assert 'bash /var/db/repos/keylem/metadata/tests/smoke_portage_lifecycle.sh' in portage_workflow
assert 'echo "PASS: complete Gentoo Portage QA"' in portage_workflow
assert "grep -Fxq 'PASS: complete Gentoo Portage QA'" in portage_workflow

# GTK4 and Rust dependencies compile from source in a fresh Gentoo stage3.
# Multiple real Portage runs exhausted the old 55-minute runner deadline
# before reaching the GTK app, so preserve enough time to test the app itself.
build_smoke = (ROOT / ".github/workflows/build-smoke.yml").read_text()
timeout = re.search(r"^    timeout-minutes: (\d+)$", build_smoke, re.M)
assert timeout and 120 <= int(timeout.group(1)) <= 180, "GTK/Rust smoke timeout too short or unbounded"
for atom in ("app-misc/t2-journal", "app-misc/t2-fan-control"):
    assert f"          - {atom}" in build_smoke, f"missing build-smoke atom {atom}"
assert 'emerge --ask=n --verbose --oneshot --jobs=2 --load-average=2 "${ATOM}"' in build_smoke
assert 'echo "PASS: actual Rust build + install for ${ATOM}"' in build_smoke
# Binary packages accelerate upstream dependencies but never substitute for
# the overlay application build. Reject unsigned binaries and missing trust keys.
assert "https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/" in build_smoke
assert "verify-signature = true" in build_smoke
assert "binpkg-request-signature" in build_smoke
assert "app-portage/getuto" in build_smoke
assert "\n              getuto\n" in build_smoke
assert '--getbinpkg --usepkg-exclude ${ATOM}' in build_smoke
assert build_smoke.index("getuto\n") < build_smoke.index('emerge --ask=n --verbose --oneshot')



# Stable or ~amd64-keyworded metapackages must not require unkeyworded
# live 9999 ebuilds. The overlay intentionally requires explicit acceptance.
for package in ("app-misc/kait2en-wifi-tools",
                "sys-firmware/kait2en-wifi-firmware",
                "sys-kernel/kait2en-sources",
                "sys-kernel/kait2en-kernel-openzfs"):
    ebuild = next((ROOT / package).glob("*.ebuild"))
    assert 'KEYWORDS=""' in ebuild.read_text(), f"{package}: unsafe keyword promotion"
for package in ("app-misc/kait2en-wifi-tools", "app-misc/t2-dsp",
                "sys-firmware/kait2en-wifi-firmware"):
    ebuild = next((ROOT / package).glob("*.ebuild"))
    assert "python3_{12..15}" in ebuild.read_text(), f"{package}: outdated Python compatibility"

print(f"PASS: {len(expected)} independently packaged atoms, valid ebuild shell/XML and metapackage refs")
