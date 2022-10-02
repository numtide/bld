{ self
, nixpkgs
, inputs
, ...
}:
with nixpkgs;
let
  bin = buildGo118Module
    {
      name = "bld";
      src = nixpkgs.lib.cleanSource ./cmd;
      doCheck = true;
      checkPhase = ''
        HOME=$TMPDIR
        ${nixpkgs.golangci-lint}/bin/golangci-lint run
      '';
      vendorSha256 = "sha256-jmBacHgDzFUqO/ZsaMazcN6r37Yy2VXQdQ4p4CUkTUc";
    };
  lib = import ./lib;
  devshell = import inputs.devshell { inherit system; inherit nixpkgs; };
in
{
  inherit bin lib;
  default = bin;
  devShell = devshell.mkShell {
    imports = [ (devshell.importTOML ./devshell.toml) ];
  };
}
