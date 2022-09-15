{ self
, nixpkgs
, inputs
, ...
}:
with nixpkgs;
let
  bldScript = builtins.readFile ./bld.sh;
  bin = writeShellApplication {
    name = "bld";
    runtimeInputs = [ nix fzf ];
    text = bldScript;
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
