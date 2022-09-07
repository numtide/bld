{ nixpkgs, restrict_eval ? true, allow-import-from-derivation ? false, ... }:
with nixpkgs;
let
  bldScript = builtins.replaceStrings [ "restrict-eval true" "restrict-eval ${builtins.toString restrict_eval}" ] [ "allow-import-from-derivation false" "allow-import-from-derivation ${builtins.toString allow-import-from-derivation}" ] (builtins.readFile ./bld.sh);
in
writeShellApplication {
  name = "bld";
  runtimeInputs = [ nix ];
  text = bldScript;
}
