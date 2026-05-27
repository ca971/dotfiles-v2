#!/usr/bin/env python3
"""
@file skills/generate.py
@description SSOT skill generator — TOML → agent-specific formats (Hermes, Claude, OpenCode)
@since 1.0.0
@version 1.0.0

Usage:
  python skills/generate.py --all          # Generate for all agents
  python skills/generate.py --agent hermes # Generate for specific agent
"""

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = PROJECT_ROOT / "skills" / "available"
OUTPUT_DIR = PROJECT_ROOT / "skills" / "generated"


def parse_skill_toml(path: Path) -> dict:
    """Parse a skill TOML file into a dict."""
    import re

    with open(path) as f:
        content = f.read()

    skill = {"meta": {}, "content": {}}
    section = None

    for line in content.split("\n"):
        s = line.strip()
        if s.startswith("[meta]"):
            section = "meta"
        elif s.startswith("[content]"):
            section = "content"
        elif "=" in s and section:
            key, _, val = s.partition("=")
            key = key.strip()
            val = val.strip().strip('"')
            skill[section][key] = val

    # Fix multi-line prompt
    if "prompt" in skill["content"]:
        m = re.search(r'prompt\s*=\s*"""\s*(.*?)\s*"""', content, re.DOTALL)
        if m:
            skill["content"]["prompt"] = m.group(1).strip()

    return skill


def emit_hermes(skill: dict) -> str:
    """Generate Hermes SKILL.md format."""
    meta = skill["meta"]
    content = skill["content"]

    triggers = meta.get("triggers", "").strip("[]").replace('"', "").replace(" ", "")

    return f"""---
name: {meta["name"]}
description: {meta["description"]}
category: {meta.get("category", "general")}
triggers: [{triggers}]
---

{content.get("prompt", "")}
"""


def emit_claude(skill: dict) -> str:
    """Generate Claude Code skill format (markdown)."""
    meta = skill["meta"]
    content = skill["content"]

    return f"""# {meta["name"]}

> {meta["description"]}

**Triggers:** {meta.get("triggers", "")}

---

{content.get("prompt", "")}
"""


def emit_opencode(skill: dict) -> str:
    """Generate OpenCode skill format (markdown, same as Claude)."""
    return emit_claude(skill)


def emit_codex(skill: dict) -> str:
    """Generate Codex instruction format."""
    meta = skill["meta"]
    content = skill["content"]

    return f"""# {meta["description"]}

{content.get("prompt", "")}
"""


EMITTERS = {
    "hermes": ("SKILL.md", emit_hermes),
    "claude": ("skill.md", emit_claude),
    "opencode": ("skill.md", emit_opencode),
    "codex": ("instruction.md", emit_codex),
}


def generate_for_agent(agent: str) -> int:
    """Generate skills for one agent. Returns count of skills generated."""
    ext, emitter = EMITTERS[agent]
    out_dir = OUTPUT_DIR / agent
    out_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for toml_file in sorted(SKILLS_DIR.glob("*.toml")):
        skill = parse_skill_toml(toml_file)
        name = skill["meta"]["name"]

        # Create skill subdirectory
        skill_dir = out_dir / name
        skill_dir.mkdir(parents=True, exist_ok=True)

        output = emitter(skill)
        output_path = skill_dir / ext
        with open(output_path, "w") as f:
            f.write(output)

        print(f"  {agent}/{name}/{ext}")
        count += 1

    return count


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Generate skills for AI agents")
    parser.add_argument("--all", action="store_true", help="Generate for all agents")
    parser.add_argument(
        "--agent",
        choices=list(EMITTERS.keys()),
        help="Generate for specific agent",
    )
    args = parser.parse_args()

    if not args.all and not args.agent:
        parser.error("Either --all or --agent required")

    agents = list(EMITTERS.keys()) if args.all else [args.agent]

    print(f"Generating skills from {SKILLS_DIR}")
    total = 0
    for agent in agents:
        count = generate_for_agent(agent)
        total += count

    print(f"\nDone: {total} skills generated for {len(agents)} agent(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
