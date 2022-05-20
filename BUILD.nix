{ nixpkgs, ... }:
{
  default = nixpkgs.writeShellScriptBin "bld" (builtins.readFile ./bld.sh);
}
