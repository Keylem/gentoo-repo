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
echo "PASS: lightweight Portage packages install, reinstall, and unmerge cleanly"
