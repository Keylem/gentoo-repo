# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: kait2en-systemd.eclass
# @MAINTAINER:
# Keylem Gentoo overlay maintainers
# @SUPPORTED_EAPIS: 8
# @BLURB: Manage T2 package systemd services safely through Portage
# @DESCRIPTION:
# Stop package-owned system services only on final unmerge; preserve their
# enabled state on upgrades. Never erase user state, or affect another root.
# Ebuilds set KAIT2EN_SYSTEMD_UNITS and call the phase functions.
#
# @ECLASS_VARIABLE: KAIT2EN_SYSTEMD_UNITS
# @DESCRIPTION:
# Space-separated package-owned system unit names to disable on final unmerge.
# Per-user units are excluded.

inherit systemd

# @FUNCTION: kait2en_systemd_pkg_prerm
# @DESCRIPTION:
# Stop and disable system units on final unmerge, never during upgrade.
kait2en_systemd_pkg_prerm() {
    [[ -z ${REPLACED_BY_VERSION} ]] || return 0
    [[ ${EROOT} == / ]] || return 0
    systemd_is_booted || return 0

    local unit
    for unit in ${KAIT2EN_SYSTEMD_UNITS}; do
        if systemctl --quiet is-enabled "${unit}" ||
           systemctl --quiet is-active "${unit}"; then
            systemctl disable --now "${unit}" ||
                ewarn "Unable to disable ${unit}; inspect it manually."
        fi
    done
}

# @FUNCTION: kait2en_systemd_reload
# @DESCRIPTION:
# Reload systemd only for the live running systemd root.
kait2en_systemd_reload() {
    [[ ${EROOT} == / ]] || return 0
    systemd_is_booted || return 0
    systemctl daemon-reload ||
        ewarn "systemd daemon-reload failed; rerun it after boot."
}

# @FUNCTION: kait2en_systemd_pkg_postinst
# @DESCRIPTION:
# Reload the systemd manager after merge and report upgrade instructions.
kait2en_systemd_pkg_postinst() {
    kait2en_systemd_reload
    if [[ -n ${REPLACING_VERSIONS} ]]; then
        elog "Package updated. Restart any enabled T2 services when convenient."
    else
        elog "T2 services are not auto-enabled; enable only on a supported Mac."
    fi
}

# @FUNCTION: kait2en_systemd_pkg_postrm
# @DESCRIPTION:
# Reload the systemd manager after unmerge without deleting user settings.
kait2en_systemd_pkg_postrm() {
    kait2en_systemd_reload
    if [[ -z ${REPLACED_BY_VERSION} ]]; then
        elog "Portage removed package files. User-modified /etc settings and user-unit"
        elog "enablement in home directories are retained by design."
    fi
}
