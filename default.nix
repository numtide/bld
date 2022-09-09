{ system ? builtins.currentSystem
, inputs ? import ./flake.lock.nix { }
, nixpkgs ? import inputs.nixpkgs {
    inherit system;
    # Makes the config pure as well. See <nixpkgs>/top-level/impure.nix:
    config = { };
    overlays = [ ];
  }
, buildGoPackage ? nixpkgs.buildGoPackage
, restrict_eval ? true
, allow-import-from-derivation ? false
}:
with nixpkgs;
let
  bldScript = builtins.replaceStrings [ "restrict-eval true" "restrict-eval ${builtins.toString restrict_eval}" ] [ "allow-import-from-derivation false" "allow-import-from-derivation ${builtins.toString allow-import-from-derivation}" ] (builtins.readFile ./bld.sh);
  bld = writeShellApplication {
    name = "bld";
    runtimeInputs = [ nix fzf ];
    text = bldScript;
  };
  devshell = import inputs.devshell { inherit system; inherit nixpkgs; };
in
{
  inherit bld;
  default = bld;
  devShell = devshell.mkShell {
    imports = [ (devshell.importTOML ./devshell.toml) ];
  };
}
