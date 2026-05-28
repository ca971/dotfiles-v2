#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/uninstall.sh
# @description Tool uninstallation dispatcher
# @class ToolUninstaller
# @since 1.0.0
# @version 1.0.0
# @see lib/hotload/engine.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# @description Uninstall a tool using the method it was installed with
# @param $1 {string} Tool name
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
ToolUninstaller::uninstall() {
    local tool="${1:?Tool name required}"

    if ! StateManager::is_installed "${tool}"; then
        Logger::warn "ToolUninstaller: ${tool} is not installed"
        return 1
    fi

    local method
    method="$(StateManager::get_method "${tool}")"

    if [[ -z "${method}" ]]; then
        Logger::error "ToolUninstaller: unknown install method for ${tool}"
        return 1
    fi

    Logger::info "Uninstalling ${tool} (installed via ${method})..."

    local rc=0
    case "${method}" in
        mise)   MiseAdapter::uninstall "${tool}" || rc=1 ;;
        uv)     UvAdapter::uninstall "${tool}" || rc=1 ;;
        curl)
            local toml_file="${DOTFILES_DIR}/tools/available/${tool}.toml"
            local uninstall_cmd=""
            if [[ -f "${toml_file}" ]] && command -v taplo >/dev/null 2>&1; then
                uninstall_cmd="$(taplo get -f "${toml_file}" -o json 2>/dev/null | jq -r '.uninstall.command // empty')"
            fi
            CurlAdapter::uninstall "${tool}" "${uninstall_cmd}" || rc=1
            ;;
        cargo)  CargoAdapter::uninstall "${tool}" || rc=1 ;;
        brew)   BrewAdapter::uninstall "${tool}" || rc=1 ;;
        system) SystemAdapter::uninstall "${tool}" || rc=1 ;;
        git)
            local toml_file="${DOTFILES_DIR}/tools/available/${tool}.toml"
            if [[ -f "${toml_file}" ]] && command -v taplo >/dev/null 2>&1; then
                local json repo ref target
                json="$(taplo get -f "${toml_file}" -o json 2>/dev/null)"
                # Find the git install method
                local git_idx
                git_idx="$(echo "${json}" | jq -r '[.install | to_entries[] | select(.value.method == "git")][0].key // empty')"
                if [[ -n "${git_idx}" ]]; then
                    repo="$(echo "${json}" | jq -r ".install[${git_idx}].repo // empty")"
                    ref="$(echo "${json}" | jq -r ".install[${git_idx}].ref // \"main\"")"
                    target="$(echo "${json}" | jq -r ".install[${git_idx}].target // \"~/.config/${tool}\"")"
                    GitAdapter::uninstall "${repo}" "${ref}" "${target}" || rc=1
                else
                    Logger::error "ToolUninstaller: no git install entry found for ${tool}"
                    rc=1
                fi
            else
                Logger::error "ToolUninstaller: cannot read descriptor for ${tool}"
                rc=1
            fi
            ;;
        *)      Logger::error "ToolUninstaller: unknown method: ${method}"; return 1 ;;
    esac

    if [[ "${rc}" -eq 0 ]]; then
        StateManager::mark_uninstalled "${tool}"
        Logger::success "Uninstalled ${tool}"
    else
        Logger::error "Failed to uninstall ${tool}"
    fi

    return "${rc}"
}
