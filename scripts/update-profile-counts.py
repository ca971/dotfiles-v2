#!/usr/bin/env python3
"""
@file scripts/update-profile-counts.py
@description Update profile tool counts in README.md and bootstrap.sh from profiles.toml
@since 1.0.0
"""

import re

PROJECT = "/Users/ca/.dotfiles"
PROFILES = f"{PROJECT}/definitions/profiles.toml"
README = f"{PROJECT}/README.md"
BOOTSTRAP = f"{PROJECT}/bootstrap.sh"

# 1. Resolve profile tool counts
profiles = {}
with open(PROFILES) as f:
    content = f.read()

current = None
extends = None
in_tools = False
tools = []
for line in content.split("\n"):
    s = line.strip()
    if s.startswith("[profiles.") and "meta" not in s:
        if current:
            profiles[current] = {"extends": extends, "tools": list(tools)}
        current = s.split("[profiles.")[1].rstrip("]")
        extends = None
        in_tools = False
        tools = []
    elif s.startswith("extends = "):
        extends = s.split('"')[1] if '"' in s else s.split("'")[1]
    elif s == "tools = [":
        in_tools = True
    elif in_tools and s == "]":
        in_tools = False
    elif in_tools and s.startswith('"'):
        t = s.split('"')[1]
        if t:
            tools.append(t)
if current:
    profiles[current] = {"extends": extends, "tools": list(tools)}


def resolve(name, seen=None):
    if seen is None:
        seen = set()
    if name in seen or name not in profiles:
        return set()
    seen.add(name)
    p = profiles[name]
    r = set(p["tools"])
    if p.get("extends"):
        r |= resolve(p["extends"], seen)
    return r


counts = {name: len(resolve(name)) for name in profiles}
print("Profile counts:", counts)

# 2. Update README.md
with open(README) as f:
    readme = f.read()

for name, count in counts.items():
    # Handle both formats: "| `name` | N |" and "| `name`|   N  | ..."
    readme = re.sub(
        rf"\| *`{name}` *\| *\d+ *\|",
        f"| `{name}`|   {count:<4} |",
        readme,
    )

with open(README, "w") as f:
    f.write(readme)
print("README.md updated")

# 3. Update bootstrap.sh interactive menu
with open(BOOTSTRAP) as f:
    bootstrap = f.read()

for name, count in counts.items():
    pattern = rf'"{name} \(\d+ tools'
    replacement = f'"{name} ({count} tools'
    bootstrap = re.sub(pattern, replacement, bootstrap)

with open(BOOTSTRAP, "w") as f:
    f.write(bootstrap)
print("bootstrap.sh updated")
