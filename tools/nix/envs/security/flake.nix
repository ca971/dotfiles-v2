{
  description = "Security and secrets management environment";

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
          name = "security";
          packages = with pkgs; [
            age
            sops
            gnupg
            openssl
            cosign
          ];
          shellHook = ''
            echo "  env: security (age + sops + gpg)"
          '';
        };
      }
    );
}
