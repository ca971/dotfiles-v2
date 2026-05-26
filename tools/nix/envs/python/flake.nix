{
  description = "Python development environment";

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
          name = "python";
          packages = with pkgs; [
            python313
            uv
            ruff
            mypy
            python313Packages.ipython
          ];
          env = {
            PYTHONDONTWRITEBYTECODE = "1";
          };
          shellHook = ''
            echo "  env: python ($(python3 --version 2>/dev/null))"
          '';
        };
      }
    );
}
