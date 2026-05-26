# Generator Templates

Reserved for Jinja2-based shell config templates.

Future: alternative to the Python emitter classes — define shell configs
as Jinja2 templates that consume the same SSOT Pydantic models.

Currently: the emitter classes in `src/emitters/` generate code directly.
Once templates are implemented, `src/cli.py` can switch between emitter-mode
and template-mode via a `--mode` flag.

Template variables (planned):
  - {{ aliases }}  — AliasDefinitions
  - {{ env }}      — EnvDefinitions
  - {{ path }}     — PathDefinitions
  - {{ functions }} — FunctionDefinitions
  - {{ init }}     — InitDefinitions
  - {{ keybindings }} — KeybindingDefinitions
  - {{ plugins }}  — PluginDefinitions (zsh only)