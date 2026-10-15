#!/usr/bin/env bash
# Copyright 2026 Gentoo Authors; GPL-3.0-or-later
# Run only the platform-independent renamer from the checksum-verified T2 Linux script.
# The caller MUST verify the upstream script's pinned SHA-256 before using this.
set -Eeuo pipefail

if (( $# != 3 )) || [[ ! -f $1 || ! -d $2 ]]; then
    echo "Usage: ${0##*/} verified-firmware.sh firmware-directory output.tar" >&2
    exit 2
fi

upstream=$1
source_dir=$2
archive=$3
renamer=$(mktemp "${TMPDIR:-/tmp}/kait2en-renamer.XXXXXXXX")
trap 'rm -f -- "$renamer"' EXIT

# The upstream Linux dispatcher rejects rename_only ("Invalid option!"),
# although its rename_firmware function is platform-independent. Extract
# that one reviewed function rather than running the upstream install paths.
awk '
    $0 == "rename_firmware () {" { in_function = 1 }
    in_function {
        print
        if ($0 == "}") { complete = 1; exit }
    }
    END { if (!complete) exit 1 }
' "$upstream" >"$renamer" || {
    echo 'Error: unexpected layout of pinned upstream firmware renamer' >&2
    exit 1
}
printf '\nrename_firmware "$@"\n' >>"$renamer"
bash -n "$renamer"
bash "$renamer" "$source_dir" "$archive"
