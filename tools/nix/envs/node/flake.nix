{
  description = "Node.js development environment";

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
          name = "node";
          packages = with pkgs; [
            nodejs_22
            pnpm
            typescript
            nodePackages.typescript-language-server
            nodePackages.prettier
          ];
          shellHook = ''
            echo "  env: node ($(node --version 2>/dev/null))"
          '';
        };
      }
    );
}
