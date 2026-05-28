# ============================================================================
# @file        config/nix/flake.nix
# @description Nix Flake — power-user cross-platform environment.
#              Provides: dev shells, packages, home-manager, templates.
#
# @usage       nix develop                  # Default dev shell
#              nix develop .#rust           # Rust dev shell
#              nix develop .#python         # Python dev shell
#              nix develop .#devops         # DevOps shell
#              nix profile install .        # Install all packages
#              nix flake init -t ~/dotfiles/config/nix#rust  # New Rust project
#
# @author      ca971
# @version     2.0.0
# ============================================================================
{
  description = "Dotfiles Enterprise — Power-user development environment";

  inputs = {
    # ── Core ─────────────────────────────────────────────────────────
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    # ── Flake utilities ──────────────────────────────────────────────
    flake-utils.url = "github:numtide/flake-utils";

    # ── Home Manager ─────────────────────────────────────────────────
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── macOS (nix-darwin) ───────────────────────────────────────────
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Rust toolchain ───────────────────────────────────────────────
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Devenv (reproducible dev environments) ───────────────────────
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Nix formatter ────────────────────────────────────────────────
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, flake-utils, home-manager, darwin, rust-overlay, devenv, treefmt-nix, ... }:
    let
      # ── Supported systems ──────────────────────────────────────────
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      # ── Per-system outputs ─────────────────────────────────────────
      perSystemOutputs = flake-utils.lib.eachSystem supportedSystems (system:
        let
          # Overlays for customized packages
          overlays = [
            rust-overlay.overlays.default
            (import ./overlays/default.nix)
          ];

          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };

          pkgs-stable = import nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };

          # Package sets
          commonPkgs = import ./packages/common.nix { inherit pkgs; };
          devtoolsPkgs = import ./packages/devtools.nix { inherit pkgs; };
          platformPkgs =
            if pkgs.stdenv.isDarwin
            then import ./packages/darwin.nix { inherit pkgs; }
            else import ./packages/linux.nix { inherit pkgs; };

        in
        {
          # ── Dev Shells ─────────────────────────────────────────────
          devShells = {
            # Default — all tools
            default = pkgs.mkShell {
              name = "dotfiles-dev";
              buildInputs = commonPkgs ++ platformPkgs ++ devtoolsPkgs;
              shellHook = ''
                if [ -n "$IN_NIX_SHELL" ]; then
                  echo ""
                  echo "  ⚠️  Already inside a Nix shell ($name)"
                  echo "  Exit first with: exit"
                  echo ""
                else
                  echo ""
                  echo "  ❄️  Nix dev shell — ${system}"
                  echo "  Packages: ${toString (builtins.length (commonPkgs ++ platformPkgs ++ devtoolsPkgs))} tools"
                  echo ""
                fi
              '';
            };

            # Rust
            rust = import ./shells/rust.nix { inherit pkgs; };

            # Python
            python = import ./shells/python.nix { inherit pkgs; };

            # Node.js
            node = import ./shells/node.nix { inherit pkgs; };

            # Go
            go = import ./shells/go.nix { inherit pkgs; };

            # DevOps (K8s, Terraform, Docker, etc.)
            devops = import ./shells/devops.nix { inherit pkgs; };

            # Minimal — just essential CLI tools
            minimal = pkgs.mkShell {
              name = "minimal";
              buildInputs = commonPkgs;
            };
          };

          # ── Packages ───────────────────────────────────────────────
          packages = {
            default = pkgs.buildEnv {
              name = "dotfiles-env";
              paths = commonPkgs ++ platformPkgs;
              pathsToLink = [ "/bin" "/share" "/etc" ];
            };

            full = pkgs.buildEnv {
              name = "dotfiles-full";
              paths = commonPkgs ++ platformPkgs ++ devtoolsPkgs;
              pathsToLink = [ "/bin" "/share" "/etc" ];
            };
          };

          # ── Formatter ──────────────────────────────────────────────
          formatter = pkgs.nixpkgs-fmt;

          # ── Checks ─────────────────────────────────────────────────
          checks = {
            format = pkgs.runCommand "check-format" { } ''
              ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${self}/config/nix
              touch $out
            '';
          };
        }
      );

    in
    perSystemOutputs // {

      # ── Templates (nix flake init) ─────────────────────────────────
      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust project with Nix flake";
        };
        python = {
          path = ./templates/python;
          description = "Python project with Nix flake";
        };
        node = {
          path = ./templates/node;
          description = "Node.js project with Nix flake";
        };
        go = {
          path = ./templates/go;
          description = "Go project with Nix flake";
        };
      };

      # ── Overlays ───────────────────────────────────────────────────
      overlays.default = import ./overlays/default.nix;
    };
}
