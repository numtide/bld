{ nixpkgs, ... }:
with nixpkgs;
writeShellApplication {
  name = "bld";
  runtimeInputs = [ nix ];
  text = builtins.readFile ./bld.sh;
}
