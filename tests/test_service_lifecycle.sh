#!/usr/bin/env bash
# Mock test: upgrade must never disable a service; final unmerge should.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT
log=${tmp}/calls
systemd_is_booted() { return 0; }
systemctl() { printf '%s\n' "$*" >> "${log}"; return 0; }
ewarn() { :; }
elog() { :; }
source "${root}/eclass/kait2en-systemd.eclass"
KAIT2EN_SYSTEMD_UNITS="example.service"
EROOT=/
REPLACED_BY_VERSION=9999
kait2en_systemd_pkg_prerm
[[ ! -e ${log} ]] || { echo "FAIL: upgrade touched systemd" >&2; exit 1; }
REPLACED_BY_VERSION=
kait2en_systemd_pkg_prerm
grep -qx 'disable --now example.service' "${log}" ||
    { echo "FAIL: final unmerge did not disable unit" >&2; exit 1; }
: > "${log}"
EROOT=/some-other-root
kait2en_systemd_pkg_prerm
[[ ! -s ${log} ]] || { echo "FAIL: alternate ROOT touched systemd" >&2; exit 1; }
echo "PASS: upgrade preserves services, unmerge disables them, alternate ROOT is safe"
