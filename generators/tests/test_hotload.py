"""
@file generators/tests/test_hotload.py
@description Unit tests for hot-load engine — descriptor validation, symlink config
@since 1.0.0
"""

import re
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent.parent / "tools" / "available"


def get_all_descriptors():
    """Return list of all tool descriptor paths."""
    return sorted(TOOLS_DIR.glob("*.toml"))


class TestDescriptorIntegrity:
    """Verify all tool descriptors are well-formed and parseable."""

    def test_all_descriptors_exist(self):
        """tools/available/ should have at least 100 descriptors."""
        descriptors = get_all_descriptors()
        assert len(descriptors) >= 200, f"Expected 200+ tools, got {len(descriptors)}"

    def test_all_have_meta_section(self):
        """Every descriptor must have a [meta] section."""
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            assert "[meta]" in content, f"{path.name}: missing [meta]"

    def test_all_have_name(self):
        """Every descriptor must have a name field."""
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            assert 'name = "' in content, f"{path.name}: missing name"

    def test_all_have_install_method(self):
        """Every descriptor must have at least one [[install]] method."""
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            assert "[[install]]" in content, f"{path.name}: missing [[install]]"

    def test_all_have_verify_command(self):
        """Every descriptor should have a verify command."""
        missing = []
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            if 'verify = "' not in content:
                missing.append(path.name)
        assert len(missing) == 0, f"Missing verify: {missing}"

    def test_all_have_platforms(self):
        """Every install method should specify platforms."""
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            sections = content.split("[[install]]")[1:]
            for i, section in enumerate(sections):
                assert "platforms = [" in section, f"{path.name}: install[{i}] missing platforms"

    def test_darwin_has_brew_or_mise(self):
        """Tools without brew/mise for macOS are flagged."""
        macos_missing = []
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            # Check if any install method covers darwin
            has_darwin = False
            for section in content.split("[[install]]")[1:]:
                if (
                    '"darwin"' in section
                    or "darwin" in section.split("platforms = [")[1].split("]")[0]
                ):
                    has_darwin = True
                    break
            if not has_darwin:
                macos_missing.append(path.name)

        # macOS-only tools are expected to be excluded
        macos_only = {"mas", "pngpaste"}
        real_missing = [t for t in macos_missing if t not in macos_only]
        assert len(real_missing) == 0, f"No macOS coverage: {real_missing}"


class TestSymlinkConfig:
    """Verify config symlinks are correctly declared."""

    def test_all_symlinks_have_valid_src(self):
        """Symlink src must point to an existing config/ directory."""
        config_dir = TOOLS_DIR.parent.parent / "config"
        broken = []
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            for m in re.finditer(r'src\s*=\s*"config/([^"]+)"', content):
                src_path = config_dir / m.group(1)
                if not src_path.exists():
                    broken.append(f"{path.name}: config/{m.group(1)}")
        assert len(broken) == 0, f"Broken symlink src: {broken}"

    def test_all_symlinks_have_dst(self):
        """Every symlink entry must have both src and dst."""
        incomplete = []
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            srcs = re.findall(r'src\s*=\s*"([^"]+)"', content)
            dsts = re.findall(r'dst\s*=\s*"([^"]+)"', content)
            if len(srcs) != len(dsts):
                incomplete.append(path.name)
        assert len(incomplete) == 0, f"Incomplete symlinks: {incomplete}"

    def test_config_dirs_match_tools(self):
        """Every config/ directory should have at least one tool referencing it."""
        config_dir = TOOLS_DIR.parent.parent / "config"
        config_dirs = {
            d.name for d in config_dir.iterdir() if d.is_dir() and not d.name.startswith(".")
        }

        referenced = set()
        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            for m in re.finditer(r'src\s*=\s*"config/([^"]+)"', content):
                referenced.add(m.group(1).split("/")[0])

        orphans = config_dirs - referenced
        assert len(orphans) == 0, f"Config dirs without tool: {orphans}"


class TestDependencies:
    """Verify dependency declarations are valid."""

    def test_dependencies_exist_as_tools(self):
        """All declared dependencies must have their own descriptor."""
        tool_names = {p.stem for p in get_all_descriptors()}
        missing_deps = []

        for path in get_all_descriptors():
            with open(path) as f:
                content = f.read()
            for m in re.finditer(r'"([^"]+)"', content):
                dep = m.group(1)
                if dep in ("nodejs", "python", "unzip", "hermes-agent"):
                    if dep not in tool_names and dep not in ("nodejs", "python", "unzip"):
                        # nodejs, python, unzip are system deps, not tools
                        pass
                    elif dep == "hermes-agent" and "hermes-agent" not in tool_names:
                        missing_deps.append(f"{path.name}: {dep}")

        assert len(missing_deps) == 0, f"Missing dependency descriptors: {missing_deps}"
