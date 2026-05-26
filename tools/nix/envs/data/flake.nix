{
  description = "Data processing and analysis environment";

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
          name = "data";
          packages = with pkgs; [
            sqlite
            datasette
            visidata
            duckdb
            csvkit
          ];
          shellHook = ''
            echo "  env: data (sqlite + datasette + duckdb)"
          '';
        };
      }
    );
}
