{
  description = "bld is an experimental frontend for monorepos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  nixConfig.extra-substituters = [ "https://numtide.cachix.org/" ];
  nixConfig.extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];

  outputs = { self, nixpkgs }:
    let
      eachSystem = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      packages = eachSystem (system: {
        default = import ./. {
          nixpkgs = nixpkgs.legacyPackages.${system};
        };
      });

      # For buildbot
      flake.hydraJobs = self.packages.x86_64-linux;
    };
}
