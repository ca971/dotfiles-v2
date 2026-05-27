#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/modules/snapshot.sh
# @description System state snapshots — save and restore dotfiles state
# @class Snapshot
# @since 1.0.0
# @version 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

readonly SNAPSHOT_DIR="${DOTFILES_DIR}/local/snapshots"

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create a snapshot of current dotfiles state
# ═══════════════════════════════════════════════════════════════════════════════
Snapshot::create() {
    local label="${1:-}"
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"
    local snap_name="${timestamp}"
    [[ -n "${label}" ]] && snap_name="${timestamp}_${label}"

    local snap_dir="${SNAPSHOT_DIR}/${snap_name}"
    mkdir -p "${snap_dir}"

    Logger::info "Creating snapshot: ${snap_name}"

    # Save state.json
    local state_file="${DOTFILES_DIR}/local/state.json"
    if [[ -f "${state_file}" ]]; then
        cp "${state_file}" "${snap_dir}/state.json"
        Logger::debug "Snapshot: saved state.json"
    fi

    # Save current theme
    if [[ -f "${state_file}" ]]; then
        jq -r '.theme // "minimal"' "${state_file}" > "${snap_dir}/theme" 2>/dev/null || true
    fi

    # Save git HEAD for reference
    git -C "${DOTFILES_DIR}" rev-parse HEAD > "${snap_dir}/git-head" 2>/dev/null || true

    # Save list of installed tools from mise
    if command -v mise >/dev/null 2>&1; then
        mise ls --installed 2>/dev/null > "${snap_dir}/mise-installed" || true
    fi

    # Metadata
    cat > "${snap_dir}/metadata.json" <<EOF
{
  "name": "${snap_name}",
  "timestamp": "${timestamp}",
  "label": "${label:-none}",
  "platform": "$(uname -s)",
  "hostname": "$(hostname -s)"
}
EOF

    Logger::success "Snapshot created: ${snap_name}"
    Logger::info "  Location: ${snap_dir}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description List all available snapshots
# ═══════════════════════════════════════════════════════════════════════════════
Snapshot::list() {
    if [[ ! -d "${SNAPSHOT_DIR}" ]] || [[ -z "$(ls -A "${SNAPSHOT_DIR}" 2>/dev/null)" ]]; then
        Logger::info "No snapshots found."
        return 0
    fi

    printf "%-25s %-20s %s\n" "SNAPSHOT" "DATE" "LABEL"
    printf "%-25s %-20s %s\n" "───────" "────" "─────"

    local snap
    for snap_dir in "${SNAPSHOT_DIR}"/*/; do
        [[ -d "${snap_dir}" ]] || continue
        local snap
        snap="$(basename "${snap_dir}")"
        local meta="${snap_dir}/metadata.json"
        if [[ -f "${meta}" ]]; then
            local label
            label="$(jq -r '.label' "${meta}" 2>/dev/null || echo "?")"
            local ts
            ts="$(jq -r '.timestamp' "${meta}" 2>/dev/null || echo "?")"
            local date_str
            date_str="$(echo "${ts}" | sed 's/\(....\)\(..\)\(..\)_\(..\)\(..\)\(..\)/\1-\2-\3 \4:\5:\6/')"
            printf "%-25s %-20s %s\n" "${snap}" "${date_str}" "${label}"
        else
            printf "%-25s %-20s %s\n" "${snap}" "unknown" "-"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Rollback to a previous snapshot
# @param $1 Snapshot name
# ═══════════════════════════════════════════════════════════════════════════════
Snapshot::rollback() {
    local snap_name="${1:?Snapshot name required (use 'dotfiles snapshot list' to see available)}"
    local snap_dir="${SNAPSHOT_DIR}/${snap_name}"

    if [[ ! -d "${snap_dir}" ]]; then
        Logger::error "Snapshot not found: ${snap_name}"
        Logger::info "Run 'dotfiles snapshot list' to see available snapshots."
        return 1
    fi

    Logger::info "Rolling back to snapshot: ${snap_name}"

    # Create a safety snapshot first
    Logger::info "Creating safety snapshot before rollback..."
    Snapshot::create "pre-rollback-${snap_name}"

    # Restore state.json
    if [[ -f "${snap_dir}/state.json" ]]; then
        cp "${snap_dir}/state.json" "${DOTFILES_DIR}/local/state.json"
        Logger::success "Restored state.json"
    else
        Logger::warn "No state.json in snapshot"
    fi

    # Show git diff
    if [[ -f "${snap_dir}/git-head" ]]; then
        local snap_head
        snap_head="$(cat "${snap_dir}/git-head")"
        local current_head
        current_head="$(git -C "${DOTFILES_DIR}" rev-parse HEAD)"
        if [[ "${snap_head}" != "${current_head}" ]]; then
            Logger::info "Git HEAD changed since snapshot:"
            Logger::info "  Snapshot: ${snap_head:0:8}"
            Logger::info "  Current:  ${current_head:0:8}"
            Logger::info "  Run 'git log ${snap_head:0:8}..${current_head:0:8}' to see changes"
        fi
    fi

    Logger::success "Rollback complete!"
    Logger::info "Run 'dotfiles generate' to regenerate configs if needed."
    Logger::info "Run 'exec \$SHELL -l' to reload your shell."
    return 0
}
