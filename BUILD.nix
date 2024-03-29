{ self
, nixpkgs
, inputs
, ...
}:
with nixpkgs;
let
  bld = buildGoModule
    {
      name = "bld";
      src = nixpkgs.lib.cleanSource ./cmd;
      doCheck = true;
      checkPhase = ''
        HOME=$TMPDIR
        ${nixpkgs.golangci-lint}/bin/golangci-lint run
      '';
      vendorHash = "sha256-jmBacHgDzFUqO/ZsaMazcN6r37Yy2VXQdQ4p4CUkTUc";
    };
  lib = import ./lib;
  devshell = import inputs.devshell { inherit system; inherit nixpkgs; };
in
{
  inherit bld lib;
  default = bld;
  # legacy attribute...
  bin = bld;
  devShell = devshell.mkShell {
    imports = [ (devshell.importTOML ./devshell.toml) ];
  };

  # Example for a run target. You can execute this with `bld run hello`
  hello = nixpkgs.writeShellScriptBin "hello" ''
    ${nixpkgs.lib.getExe nixpkgs.hello} "$@"
  '';
}
