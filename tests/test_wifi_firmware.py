#!/usr/bin/env python3
"""Offline security checks for the firmware tar importer; no Apple files needed."""
import io
from pathlib import Path
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
validator = ROOT / "sys-firmware/kait2en-wifi-firmware/files/validate.py"

def archive(path, entries):
    with tarfile.open(path, "w") as out:
        for name, payload, kind in entries:
            info = tarfile.TarInfo(name)
            if kind == "symlink":
                info.type = tarfile.SYMTYPE
                info.linkname = "/etc/passwd"
            else:
                info.size = len(payload)
            out.addfile(info, io.BytesIO(payload) if kind == "file" else None)

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    good = root / "good.tar"
    archive(good, [("brcmfmac4377b3-pcie.apple.bin", b"wifi", "file"),
                   ("brcmfmac4377b3-pcie.apple.txt", b"config", "file"),
                   ("brcmbt4377b3-apple,tahiti-m.ptb", b"bt", "file")])
    p = subprocess.run(["python3", str(validator), str(good), "--extract-to", str(root / "out")], capture_output=True)
    assert p.returncode == 0, p.stderr
    assert (root / "out/brcmfmac4377b3-pcie.apple.bin").read_bytes() == b"wifi"
    for idx, entries in enumerate((
        [("../outside.bin", b"x", "file")],
        [("brcmfmac4377b3-pcie.apple.bin", b"", "symlink")],
        [("brcmfmac4377b3-pcie.apple.bin", b"ok", "file"),
         ("brcmfmac4377b3-pcie.apple.bin", b"duplicate", "file")],
        [("random.txt", b"x", "file")],
        [("brcmbt4377b3-apple,tahiti-m.ptb", b"no_wifi", "file")],
    )):
        bad = root / f"bad-{idx}.tar"
        archive(bad, entries)
        p = subprocess.run(["python3", str(validator), str(bad)], capture_output=True)
        assert p.returncode != 0, (idx, p.stdout, p.stderr)
helper = (ROOT / "app-misc/kait2en-wifi-tools/files/kait2en-wifi-setup").read_text()
assert "sha256sum --check --status" in helper
assert "39ac6d26bd265f5d32198062f515ad15ef93afb7a74e702be2b008090d5bd5f3" in helper
assert "c1c1d8aa25bb5f089e46ccd0d9738fc13bfbd784f499aa924466c690f059961e" in helper
print("PASS: firmware validation accepts actual Broadcom filenames, refuses traversal, links, duplicates, missing Wi-Fi")
