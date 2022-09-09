{ path
, args
}:
let
  # copied from <nixpkgs/lib>
  lib = {
    inherit (builtins)
      attrNames
      concatMap
      concatStringSep
      hasAttr
      head
      isAttrs
      isString
      listToAttrs
      mapAttrs
      parseDrvName
      readDir
      splitString
      substring
      tail
      ;

    getName = x:
      let
        parse = drv: (lib.parseDrvName drv).name;
      in
      if lib.isString x
      then parse x
      else x.pname or (parse x.name);

    getBin = pkg:
      if ! pkg ? outputSpecified || ! pkg.outputSpecified
      then pkg.bin or pkg.out or pkg
      else pkg;

    getExe = x: "${lib.getBin x}/bin/${x.meta.mainProgram or (lib.getName x)}";

    isDerivation = x: x.type or null == "derivation";

    filterAttrs = pred: set:
      lib.listToAttrs (lib.concatMap
        (name:
          let v = set.${name}; in
          if
            pred name v then [{ name = name; value = v; }] else [ ])
        (lib.attrNames set));

    getAttrByKey = name: lib.getAttrFromPath (lib.splitString "." name);

    getAttrFromPath = attrPath:
      let errorMsg = "cannot find attribute `" + lib.concatStringsSep "." attrPath + "'";
      in lib.attrByPath attrPath (abort errorMsg);

    attrByPath = attrPath: default: e:
      let attr = lib.head attrPath; in
      if attrPath == [ ] then e
      else if e ? ${attr}
      then lib.attrByPath (lib.tail attrPath) default e.${attr}
      else default;
  };

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

  # Generates a tree of attributes
  readBuildTree = path:
    # Used to check that the tree evaluation is lazy
    #assert builtins.trace "DEBUG: reading path ${toString path}" true;
    let
      dir = lib.readDir path;
      dirFilter = name: type:
        type == "directory" &&
        ! (lib.hasAttr ".skip-subtree" dir) &&
        lib.substring 0 1 name != "." # ignore folders starting with dot
      ;
      subDirs = lib.filterAttrs dirFilter dir;

      buildAttrs = if dir ? "BUILD.nix" then callBuild path else { };

      op = name: _: readBuildTree "${toString path}/${toString name}";

      subdirAttrs = lib.mapAttrs op subDirs;

      # TODO: fail if there is a collision in the keys
      # TODO: do not automatically recurse for everything
      attrs = { recurseForDerivations = true; } // subdirAttrs // buildAttrs;
    in
    attrs;

  flattenTree = import ./flattenTree.nix;
in
root.self // {
  _flatten = {}: flattenTree root.self;

  _list = path: lib.concatStringsSep "\n" (lib.attrNames (flattenTree (readBuildTree path)));

  _run = key:
    let
      val = lib.getAttrByKey key root.self;
    in
    if lib.isDerivation val then lib.getExe val
    else if !lib.isAttrs val then
      abort "${key} is not a derivation or attrs"
    else if ! val ? default then
      abort "${key} has not default package"
    else if !lib.isDerivation val.default then
      abort "${key}.default is not a derivation"
    else
      lib.getExe val.default;
}
