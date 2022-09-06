{ path
, args
, lib # nixpkgs-lib
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
        ! (builtins.hasAttr ".skip-subtree" dir) &&
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

  getAttrByKey = name: lib.getAttrFromPath (lib.splitString "." name);

  getName = x:
    let
      parse = drv: (builtins.parseDrvName drv).name;
    in
    if builtins.isString x
    then parse x
    else x.pname or (parse x.name);

  getBin = pkg:
    if ! pkg ? outputSpecified || ! pkg.outputSpecified
    then pkg.bin or pkg.out or pkg
    else pkg;

  getExe = x: "${getBin x}/bin/${x.meta.mainProgram or (getName x)}";
in
root.self // {
  _flatten = {}: import ./flattenTree.nix root.self;

  _run = key:
    let
      val = getAttrByKey key root.self;
    in
    if lib.isDerivation val then getExe val
    else if !lib.isAttrs val then
      abort "${key} is not a derivation or attrs"
    else if ! val ? default then
      abort "${key} has not default package"
    else if !lib.isDerivation val.default then
      abort "${key}.default is not a derivation"
    else
      getExe val.default;
}
