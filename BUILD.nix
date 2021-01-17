{ writeShellScriptBin }:
{
  bld = writeShellScriptBin "bld" (builtins.readFile ./bld.sh);
}
