---
description: Run validation checks on the dotfiles project
---

Run the following validation checks on the dotfiles project:

1. Run `shellcheck` on all `.sh` files in lib/ and bin/
2. Check that all shell files have the required header documentation
3. Verify that all files in definitions/ are valid TOML (use taplo if available)
4. Run `ruff check` on generators/src/ if Python files exist
5. Run `bats tests/unit/` if test files have content
6. Check permissions on local/secrets and local/ssh (should be 700)

Report results as pass/fail with details on failures.
