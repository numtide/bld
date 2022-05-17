{ nixpkgs, ... }:
{
  bld = nixpkgs.writeShellScriptBin "bld" (builtins.readFile ./bld.sh);
}
