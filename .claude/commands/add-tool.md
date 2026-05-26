---
description: Generate a new tool descriptor in tools/available/
---

Create a new tool descriptor TOML file in tools/available/ for the tool: $ARGUMENTS

The descriptor must follow this structure:
- [meta] section: name, description, homepage, category, verify command
- [[install]] sections: ordered by priority (mise > uv > curl > cargo > brew > system)
- [config] section: symlinks and dependencies

Research the tool to determine:
1. The correct verify command
2. Which install methods are available (check mise plugins, uv packages, official install scripts)
3. Platform compatibility
4. Any dependencies

Use the Elite documentation header standard.
