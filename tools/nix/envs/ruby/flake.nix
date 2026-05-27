{
  description = "Ruby development environment";

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
          name = "ruby";
          packages = with pkgs; [
            ruby
            rubyPackages.solargraph
            rubyPackages.rubocop
          ];
          shellHook = ''
            echo "  env: ruby ($(ruby --version 2>/dev/null))"
          '';
        };
      }
    );
}
