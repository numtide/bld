{
  description = "bld is an experimental frontend for monorepos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
  };

  nixConfig.extra-substituters = [ "https://numtide.cachix.org/" ];
  nixConfig.extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];

  outputs = { self, nixpkgs, devshell }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      legacyPackages = forAllSystems (system:
        import self {
          nixpkgs = nixpkgs.legacyPackages.${system};
          inherit system;
        });

      packages = forAllSystems (system: {
        inherit (self.legacyPackages.${system}) default bld;
      });

      devShells = forAllSystems (system: {
        default = self.legacyPackages.${system}.devShell;
      });

      lib = import ./lib;

      hydraJobs = self.packages.x86_64-linux;
    };
}
