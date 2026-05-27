{
  description = "Elixir and Phoenix development environment";

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
          name = "elixir";
          packages = with pkgs; [
            elixir
            erlang
            elixir_ls
          ];
          shellHook = ''
            echo "  env: elixir ($(elixir --version 2>/dev/null | head -1))"
          '';
        };
      }
    );
}
