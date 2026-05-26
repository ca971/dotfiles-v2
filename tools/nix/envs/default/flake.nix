{
  description = "Default environment — base utilities";

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
          name = "default";
          packages = with pkgs; [
            coreutils
            findutils
            gnugrep
            gnused
            jq
            yq-go
            tree
            curl
            wget
          ];
          shellHook = ''
            echo "  env: default (base utilities)"
          '';
        };
      }
    );
}
