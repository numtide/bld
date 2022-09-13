{ self
, nixpkgs
, inputs
, restrict_eval
, allow-import-from-derivation
, ...
}:
with nixpkgs;
let
  bldScript = builtins.replaceStrings [ "restrict-eval true" "restrict-eval ${toString restrict_eval}" ] [ "allow-import-from-derivation false" "allow-import-from-derivation ${toString allow-import-from-derivation}" ] (builtins.readFile ./bld.sh);
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
