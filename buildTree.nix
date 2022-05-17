{ path
, args
}:
let
  # Like callPackage but:
  # * assumes ${path}/BUILD.nix
  # * is not overridable
  # * doesn't take an argument
  # * assumes the returned value is an attrset that we want to recurse into
  #
  # In the future it should also take a `self` argument, and maybe collect the
  # path.
  callBuildWith = args: path:
    import "${toString path}/BUILD.nix" args;

  root = { self = readBuildTree path; } // args;

  callBuild = callBuildWith root;

  filterAttrs = pred: set:
    builtins.listToAttrs (builtins.concatMap
      (name:
        let v = set.${name}; in
        if
          pred name v then [{ name = name; value = v; }] else [ ])
      (builtins.attrNames set));

  # Generates a tree of attributes
  readBuildTree = path:
    # Used to check that the tree evaluation is lazy
    assert builtins.trace "DEBUG: reading path ${toString path}" true;
    let
      dir = builtins.readDir path;
      dirFilter = name: type:
        type == "directory" &&
        builtins.substring 0 1 name != "." # ignore folders starting with dot
      ;
      subDirs = filterAttrs dirFilter dir;

      buildAttrs = if dir ? "BUILD.nix" then callBuild path else { };

      op = name: _: readBuildTree "${toString path}/${toString name}";

      subdirAttrs = builtins.mapAttrs op subDirs;

      # TODO: fail if there is a collision in the keys
      # TODO: do not automatically recurse for everything
      attrs = { recurseForDerivations = true; } // subdirAttrs // buildAttrs;
    in
    attrs;
in
root.self
