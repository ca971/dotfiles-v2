#!/usr/bin/env python3
"""
@file skills/generate.py
@description SSOT skill generator — TOML → agent-specific formats (Markdown, YAML, etc.)
@since 1.0.0
@version 1.1.0

Skill TOML schema:
  [meta]
  name = "..."
  description = "..."
  triggers = ["...", "..."]

  [content]
  markdown = \"\"\"...\"\"\"          # Default format (required)

  [content.<agent>]                # Per-agent override (optional)
  markdown = \"\"\"...\"\"\"           # Agent-specific markdown
  yaml = \"\"\"...\"\"\"               # Alternative format

Usage:
  python skills/generate.py --all
  python skills/generate.py --agent hermes
"""

import sys
import tomllib
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = PROJECT_ROOT / "skills" / "available"
OUTPUT_DIR = PROJECT_ROOT / "skills" / "generated"

# Supported output formats per agent
# Each agent has a default format and a list of acceptable formats
AGENT_FORMATS = {
    "hermes": {
        "default": "markdown",
        "accepted": ["markdown", "yaml"],
        "header": True,  # YAML frontmatter
    },
    "claude": {
        "default": "markdown",
        "accepted": ["markdown"],
        "header": False,
    },
    "opencode": {
        "default": "markdown",
        "accepted": ["markdown"],
        "header": False,
    },
    "codex": {
        "default": "markdown",
        "accepted": ["markdown", "yaml", "toml"],
        "header": False,
    },
}


def parse_skill(path: Path) -> dict:
    """Parse a skill TOML file, return structured dict."""
    with open(path, "rb") as f:
        data = tomllib.load(f)

    result = {
        "meta": data.get("meta", {}),
        "content": {},
        "overrides": {},
    }

    # Content section may contain format strings AND agent overrides
    raw_content = data.get("content", {})
    for key, value in raw_content.items():
        if isinstance(value, dict):
            # Nested dict → agent override: [content.<agent>]
            result["overrides"][key] = dict(value)
        else:
            # Plain string → format: markdown = "..."
            result["content"][key] = value

    return result


def get_content_for_agent(skill: dict, agent: str) -> tuple[str, str]:
    """
    Get the (format, body) for an agent.
    Falls back to default content.markdown if no agent override.
    """
    # Check for agent override
    if agent in skill["overrides"]:
        override = skill["overrides"][agent]
        info = AGENT_FORMATS[agent]
        # Try each accepted format in priority order
        for fmt in info["accepted"]:
            if fmt in override:
                return fmt, override[fmt]

    # Fall back to default content
    content = skill["content"]
    info = AGENT_FORMATS[agent]
    for fmt in info["accepted"]:
        if fmt in content:
            return fmt, content[fmt]

    # Absolute fallback: use whatever is in default content first key
    if content:
        first_fmt = next(iter(content))
        return first_fmt, content[first_fmt]

    return "markdown", ""


def emit_skill(agent: str, skill: dict) -> str:
    """Generate agent-specific skill file content."""
    meta = skill["meta"]
    fmt, body = get_content_for_agent(skill, agent)
    info = AGENT_FORMATS[agent]

    triggers = ", ".join(meta.get("triggers", []))

    if info["header"]:
        # YAML frontmatter (Hermes format)
        return f"""---
name: {meta["name"]}
description: {meta["description"]}
category: {meta.get("category", "general")}
triggers: [{triggers}]
format: {fmt}
---

{body}
"""

    # Plain format header (Claude, OpenCode, Codex)
    return f"""# {meta["name"]}

> {meta["description"]}
> Format: {fmt} | Triggers: {triggers}

---

{body}
"""


def generate_for_agent(agent: str) -> int:
    """Generate all skills for one agent. Returns count."""
    out_dir = OUTPUT_DIR / agent
    out_dir.mkdir(parents=True, exist_ok=True)

    # Determine file extension based on default format
    _fmt = AGENT_FORMATS[agent]["default"]
    ext_map = {"markdown": ".md", "yaml": ".yaml", "toml": ".toml"}

    count = 0
    for toml_file in sorted(SKILLS_DIR.glob("*.toml")):
        skill = parse_skill(toml_file)
        name = skill["meta"]["name"]

        # Get the actual format that will be used for this skill/agent combo
        actual_fmt, _ = get_content_for_agent(skill, agent)
        ext = ext_map.get(actual_fmt, ".md")

        skill_dir = out_dir / name
        skill_dir.mkdir(parents=True, exist_ok=True)

        output = emit_skill(agent, skill)
        output_path = skill_dir / f"skill{ext}"

        with open(output_path, "w") as f:
            f.write(output)

        print(f"  {agent}/{name}/skill{ext} ({actual_fmt})")
        count += 1

    return count


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Generate skills for AI agents")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--agent", choices=list(AGENT_FORMATS.keys()))
    args = parser.parse_args()

    if not args.all and not args.agent:
        parser.error("Either --all or --agent required")

    agents = list(AGENT_FORMATS.keys()) if args.all else [args.agent]

    print(f"Generating skills from {SKILLS_DIR}")
    total = 0
    for agent in agents:
        n = generate_for_agent(agent)
        total += n

    print(f"\nDone: {total} skills → {len(agents)} agent(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
