# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Stop/disable package-owned system services on a final unmerge, not upgrades.
# Do not delete configuration, user enablement links, or application state.

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

kait2en_systemd_reload() {
    [[ ${EROOT} == / ]] || return 0
    systemd_is_booted || return 0
    systemctl daemon-reload ||
        ewarn "systemd daemon-reload failed; rerun it after boot."
}

kait2en_systemd_pkg_postinst() {
    kait2en_systemd_reload
    if [[ -n ${REPLACING_VERSIONS} ]]; then
        elog "Package updated. Restart any enabled T2 services when convenient."
    else
        elog "T2 services are not auto-enabled; enable only on a supported Mac."
    fi
}

kait2en_systemd_pkg_postrm() {
    kait2en_systemd_reload
    if [[ -z ${REPLACED_BY_VERSION} ]]; then
        elog "Portage removed package files. User-modified /etc settings and user-unit"
        elog "enablement in home directories are retained by design."
    fi
}
