#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/e2e/test_profiles.sh
# @description E2E test: verify all bootstrap profiles resolve correctly
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-/home/testuser/.dotfiles}"
PROFILES_TOML="${DOTFILES_DIR}/definitions/profiles.toml"
TOOLS_DIR="${DOTFILES_DIR}/tools/available"
PASS=0
FAIL=0

log_pass() { echo "  ✅ $1"; ((PASS++)) || true; }
log_fail() { echo "  ❌ $1"; ((FAIL++)) || true; }

echo "═══════════════════════════════════════════════════════════"
echo "  Profile Resolution Tests"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ─── Helper: get tools array for a profile from TOML ───
get_profile_tools() {
    local profile="$1"
    # Extract the tools array for a profile section
    python3 -c "
import sys
profiles = {}
with open('${PROFILES_TOML}') as f:
    content = f.read()
# Simple TOML line-by-line parser for profiles section
current_profile = None
current_extends = None
in_tools = False
tools = []
for line in content.split('\n'):
    line = line.strip()
    if line.startswith('[profiles.'):
        if current_profile:
            profiles[current_profile] = {'extends': current_extends, 'tools': tools}
        current_profile = line.split('[profiles.')[1].rstrip(']')
        current_extends = None
        in_tools = False
        tools = []
    elif line.startswith('extends = '):
        current_extends = line.split('\"')[1] if '\"' in line else line.split(\"'\")[1]
    elif line == 'tools = [':
        in_tools = True
    elif in_tools and line == ']':
        in_tools = False
    elif in_tools and line.startswith('\"'):
        tool = line.split('\"')[1]
        if tool:
            tools.append(tool)
if current_profile:
    profiles[current_profile] = {'extends': current_extends, 'tools': tools}

# Resolve full tool list for a profile (with inheritance)
def resolve(profile, seen=None):
    if seen is None:
        seen = set()
    if profile in seen:
        return []  # cycle detection
    seen.add(profile)
    if profile not in profiles:
        return []
    p = profiles[profile]
    parent = p.get('extends')
    tools = []
    if parent:
        tools = resolve(parent, seen)
    tools.extend(p.get('tools', []))
    return tools

result = resolve('${profile}')
for t in result:
    print(t)
" 2>/dev/null
}

# ─── Get all defined profiles ───
ALL_PROFILES=$(python3 -c "
with open('${PROFILES_TOML}') as f:
    for line in f:
        line = line.strip()
        if line.startswith('[profiles.') and not line.startswith('[profiles.meta]'):
            print(line.split('[profiles.')[1].rstrip(']'))
" 2>/dev/null)

echo "Profiles found: $(echo "${ALL_PROFILES}" | tr '\n' ' ')"
echo ""

for profile in ${ALL_PROFILES}; do
    echo "───────────────────────────────────────────────────────"
    echo "📦 Profile: ${profile}"
    echo ""

    # Test 1: Resolve tool list
    TOOLS=$(get_profile_tools "${profile}" | sort -u)
    TOOL_COUNT=$(echo "${TOOLS}" | grep -c . || echo 0)
    echo "  Resolved tool count: ${TOOL_COUNT}"
    
    if [[ -z "${TOOLS}" ]]; then
        log_fail "No tools resolved for profile ${profile}"
        echo ""
        continue
    fi

    # Test 2: Check each tool has a descriptor
    MISSING_TOOLS=""
    while IFS= read -r tool; do
        [[ -z "${tool}" ]] && continue
        if [[ ! -f "${TOOLS_DIR}/${tool}.toml" ]]; then
            MISSING_TOOLS="${MISSING_TOOLS} ${tool}"
        fi
    done <<< "${TOOLS}"
    
    if [[ -n "${MISSING_TOOLS}" ]]; then
        log_fail "Missing tool descriptors:${MISSING_TOOLS}"
    else
        log_pass "All ${TOOL_COUNT} tools have descriptors"
    fi

    # Test 3: Verify Bootstrap::run accepts the profile
    source "${DOTFILES_DIR}/lib/core/logger.sh" 2>/dev/null
    source "${DOTFILES_DIR}/lib/core/platform.sh" 2>/dev/null
    source "${DOTFILES_DIR}/lib/core/fs.sh" 2>/dev/null
    source "${DOTFILES_DIR}/lib/core/validator.sh" 2>/dev/null
    source "${DOTFILES_DIR}/lib/modules/bootstrap.sh" 2>/dev/null
    
    if Bootstrap::run --dry-run --profile "${profile}" 2>&1 | grep -q "profile: ${profile}"; then
        log_pass "Bootstrap::run accepts profile '${profile}'"
    else
        log_fail "Bootstrap::run rejected profile '${profile}'"
    fi

    # Test 4: List tools
    echo "  Tools:"
    echo "${TOOLS}" | while IFS= read -r t; do
        [[ -z "${t}" ]] && continue
        echo "    - ${t}"
    done
    echo ""
done

echo "═══════════════════════════════════════════════════════════"
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "═══════════════════════════════════════════════════════════"

if [[ "${FAIL}" -gt 0 ]]; then
    exit 1
fi
