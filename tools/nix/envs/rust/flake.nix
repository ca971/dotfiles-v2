{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "rust";
          packages = with pkgs; [
            rustc
            cargo
            clippy
            rustfmt
            rust-analyzer
            cargo-watch
            cargo-nextest
            pkg-config
            openssl
          ];
          env = {
            RUST_BACKTRACE = "1";
          };
          shellHook = ''
            echo "  env: rust ($(rustc --version 2>/dev/null | cut -d' ' -f2))"
          '';
        };
      }
    );
}
