#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script=${root}/sys-kernel/kait2en-kernel-patches/files/kait2en-kernel-preflight
tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/linux/drivers/gpu/drm/amd" "${tmp}/patches"
: > "${tmp}/linux/Makefile"
printf 'one\n' > "${tmp}/linux/drivers/gpu/drm/amd/example.c"
cat > "${tmp}/patches/0001-first.patch" <<'EOF'
--- a/drivers/gpu/drm/amd/example.c
+++ b/drivers/gpu/drm/amd/example.c
@@ -1 +1 @@
-one
+two
EOF
cat > "${tmp}/patches/0002-second.patch" <<'EOF'
--- a/drivers/gpu/drm/amd/example.c
+++ b/drivers/gpu/drm/amd/example.c
@@ -1 +1 @@
-two
+three
EOF
printf '0001-first.patch\n0002-second.patch\n' > "${tmp}/patches/series"
bash "${script}" "${tmp}/linux" "${tmp}/patches"
[[ $(cat "${tmp}/linux/drivers/gpu/drm/amd/example.c") == one ]] ||
    { echo "FAIL: preflight altered real source" >&2; exit 1; }
printf 'unrelated\n' > "${tmp}/linux/drivers/gpu/drm/amd/example.c"
if bash "${script}" "${tmp}/linux" "${tmp}/patches" >/dev/null 2>&1; then
    echo "FAIL: bad patch series accepted" >&2; exit 1
fi
cat > "${tmp}/patches/0002-second.patch" <<'EOF'
--- a/fs/zfs/example.c
+++ b/fs/zfs/example.c
@@ -1 +1 @@
-two
+three
EOF
if bash "${script}" "${tmp}/linux" "${tmp}/patches" >/dev/null 2>&1; then
    echo "FAIL: patch outside AMD GPU tree accepted" >&2; exit 1
fi
echo "PASS: ordered patch series, non-mutating preflight, off-tree rejection"
