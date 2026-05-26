{
  description = "Go development environment";

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
          name = "go";
          packages = with pkgs; [
            go
            gopls
            delve
            golangci-lint
            gotools
            air
          ];
          env = {
            GOPATH = "${builtins.getEnv "HOME"}/go";
          };
          shellHook = ''
            echo "  env: go ($(go version 2>/dev/null | cut -d' ' -f3))"
          '';
        };
      }
    );
}
