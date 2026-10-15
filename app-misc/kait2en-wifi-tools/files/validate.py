#!/usr/bin/env python3
"""Validate/extract a locally obtained Broadcom firmware tarball without unsafe tar members."""
import argparse
from pathlib import Path
import re
import shutil
import sys
import tarfile

ALLOWED = re.compile(r"brcm(?:fmac|bt)[A-Za-z0-9,_+.-]+\.(?:bin|txt|clm_blob|txcap_blob|ptb)")
MAX_FILE = 32 * 1024 * 1024
MAX_TOTAL = 100 * 1024 * 1024

def validate(source, dest=None):
    members, regulars, names, total = [], {}, set(), 0
    with tarfile.open(source, "r:*") as archive:
        for member in archive:
            name = member.name
            if not ALLOWED.fullmatch(name) or name in names:
                raise ValueError(f"Unsupported firmware member: {name!r}")

            if member.isfile():
                data_member = member
                regulars[name] = member
            elif member.islnk() and member.size == 0 and member.linkname in regulars:
                # The pinned upstream exporter de-duplicates identical firmware
                # using tar hard links to an earlier regular file. Only accept
                # those in-archive references; never create filesystem links.
                data_member = regulars[member.linkname]
            else:
                raise ValueError(f"Unsupported firmware member: {name!r}")

            if not 1 <= data_member.size <= MAX_FILE:
                raise ValueError(f"Unexpected firmware size: {name} ({data_member.size})")
            # Account for expanded hard links to bound installed disk usage too.
            total += data_member.size
            if total > MAX_TOTAL:
                raise ValueError("Firmware archive is too large")
            names.add(name)
            members.append((name, data_member))

        if not any(n.startswith("brcmfmac") and n.endswith(".bin") for n in names):
            raise ValueError("No Broadcom Wi-Fi .bin firmware found")
        if dest:
            target_dir = Path(dest)
            target_dir.mkdir(parents=True, exist_ok=True)
            for name, data_member in members:
                source_file = archive.extractfile(data_member)
                if source_file is None:
                    raise ValueError(f"Missing archive member: {name}")
                target = target_dir / name
                with target.open("xb") as output:
                    shutil.copyfileobj(source_file, output)
                target.chmod(0o644)
    print(f"Validated {len(members)} Broadcom firmware files ({total} bytes).")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--extract-to", type=Path)
    args = parser.parse_args()
    try:
        validate(args.archive, args.extract_to)
    except (OSError, ValueError, tarfile.TarError) as exc:
        print(f"Firmware validation failed: {exc}", file=sys.stderr)
        sys.exit(1)
