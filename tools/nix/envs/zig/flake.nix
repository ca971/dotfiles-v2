{
  description = "Zig systems programming environment";

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
          name = "zig";
          packages = with pkgs; [
            zig
            zls
          ];
          shellHook = ''
            echo "  env: zig ($(zig version 2>/dev/null))"
          '';
        };
      }
    );
}
