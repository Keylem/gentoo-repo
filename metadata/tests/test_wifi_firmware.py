#!/usr/bin/env python3
"""Offline tests for firmware importing and the pinned upstream renamer."""
import io
from pathlib import Path
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[2]
validator = ROOT / "sys-firmware/kait2en-wifi-firmware/files/validate.py"
renamer = ROOT / "app-misc/kait2en-wifi-tools/files/rename-pinned-firmware.sh"


def archive(path, entries):
    with tarfile.open(path, "w") as out:
        for name, payload, kind in entries:
            info = tarfile.TarInfo(name)
            if kind == "symlink":
                info.type = tarfile.SYMTYPE
                info.linkname = "/etc/passwd"
            elif kind == "hardlink":
                info.type = tarfile.LNKTYPE
                info.linkname = payload.decode("ascii")
            else:
                info.size = len(payload)
            out.addfile(info, io.BytesIO(payload) if kind == "file" else None)


with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    wifi = "brcmfmac4377b3-pcie.apple.bin"
    duplicate_wifi = "brcmfmac4364b3-pcie.apple.bin"
    good = root / "good.tar"
    # Pinned upstream firmware.sh uses tar hard links for identical binaries.
    archive(good, [(wifi, b"wifi", "file"),
                   (duplicate_wifi, wifi.encode(), "hardlink"),
                   ("brcmfmac4377b3-pcie.apple.txt", b"config", "file"),
                   ("brcmbt4377b3-apple,tahiti-m.ptb", b"bt", "file")])
    p = subprocess.run(["python3", str(validator), str(good),
                        "--extract-to", str(root / "out")], capture_output=True)
    assert p.returncode == 0, p.stderr
    assert (root / "out" / wifi).read_bytes() == b"wifi"
    assert (root / "out" / duplicate_wifi).read_bytes() == b"wifi"
    assert not (root / "out" / duplicate_wifi).is_symlink()

    for idx, entries in enumerate((
        [("../outside.bin", b"x", "file")],
        [(wifi, b"", "symlink")],
        [(wifi, b"ok", "file"), (wifi, b"duplicate", "file")],
        [("random.txt", b"x", "file")],
        [("brcmbt4377b3-apple,tahiti-m.ptb", b"no_wifi", "file")],
        [(wifi, b"ok", "file"),
         (duplicate_wifi, b"../outside", "hardlink")],
        [(wifi, b"ok", "file"),
         (duplicate_wifi, b"/etc/passwd", "hardlink")],
        [(duplicate_wifi, wifi.encode(), "hardlink"),
         (wifi, b"ok", "file")],
    )):
        bad = root / f"bad-{idx}.tar"
        archive(bad, entries)
        p = subprocess.run(["python3", str(validator), str(bad)], capture_output=True)
        assert p.returncode != 0, (idx, p.stdout, p.stderr)

    # Test Linux behavior without downloading or mounting a recovery image:
    # the upstream shell dispatcher refuses rename_only, but the extracted
    # platform-independent function should run and receive both arguments.
    fixture = root / "firmware.sh"
    source = root / "source"
    source.mkdir()
    output = root / "renamed.tar"
    fixture.write_text("""#!/usr/bin/env bash
rename_firmware () {
    printf 'renamed:%s\\n' "$1" >"$2"
}
echo 'Error: Invalid option!' >&2
exit 97
""")
    p = subprocess.run(["bash", str(renamer), str(fixture), str(source), str(output)],
                       capture_output=True)
    assert p.returncode == 0, p.stderr
    assert output.read_text() == f"renamed:{source}\\n"
    assert b"Invalid option" not in p.stderr

    fixture.write_text("#!/usr/bin/env bash\necho missing-renamer\n")
    p = subprocess.run(["bash", str(renamer), str(fixture), str(source), str(output)],
                       capture_output=True)
    assert p.returncode != 0, p.stdout

helper = (ROOT / "app-misc/kait2en-wifi-tools/files/kait2en-wifi-setup").read_text()
ebuild = (ROOT / "app-misc/kait2en-wifi-tools/kait2en-wifi-tools-1.0.ebuild").read_text()
# Unpack can run as the unprivileged portage user. Root-only mode 0700
# on the staging directory or 0600 on its archive would break the install.
assert 'install -d -o root -g portage -m 0750' in helper
assert 'install -o root -g portage -m 0640' in helper
assert 'install -m 0600 -- "$1" "$temp"' not in helper
assert "sha256sum --check --status" in helper
assert "39ac6d26bd265f5d32198062f515ad15ef93afb7a74e702be2b008090d5bd5f3" in helper
assert "c1c1d8aa25bb5f089e46ccd0d9738fc13bfbd784f499aa924466c690f059961e" in helper
assert 'bash "$RENAMER" "$tmp/firmware.sh"' in helper
assert 'bash firmware.sh rename_only' not in helper
assert 'newexe "${FILESDIR}/rename-pinned-firmware.sh" rename-pinned-firmware.sh' in ebuild
assert subprocess.run(["bash", "-n", str(renamer)]).returncode == 0
print("PASS: verified renamer bypasses Linux dispatcher; firmware importer expands safe hardlinks and rejects unsafe archives")
