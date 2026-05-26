{
  description = "DevOps and cloud infrastructure environment";

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
          name = "devops";
          packages = with pkgs; [
            terraform
            kubectl
            helm
            awscli2
            doctl
            ansible
            k9s
            stern
            kubectx
            trivy
          ];
          shellHook = ''
            echo "  env: devops (cloud infrastructure)"
          '';
        };
      }
    );
}
