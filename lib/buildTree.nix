{ path
, args
, supportedSystems ? [
    "aarch64-darwin"
    "aarch64-genode"
    "aarch64-linux"
    "aarch64-netbsd"
    "aarch64-none"
    "aarch64_be-none"
    "arm-none"
    "armv5tel-linux"
    "armv6l-linux"
    "armv6l-netbsd"
    "armv6l-none"
    "armv7a-darwin"
    "armv7a-linux"
    "armv7a-netbsd"
    "armv7l-linux"
    "armv7l-netbsd"
    "avr-none"
    "i686-cygwin"
    "i686-darwin"
    "i686-freebsd"
    "i686-genode"
    "i686-linux"
    "i686-netbsd"
    "i686-none"
    "i686-openbsd"
    "i686-windows"
    "js-ghcjs"
    "m68k-linux"
    "m68k-netbsd"
    "m68k-none"
    "mips64el-linux"
    "mipsel-linux"
    "mipsel-netbsd"
    "mmix-mmixware"
    "msp430-none"
    "or1k-none"
    "powerpc-netbsd"
    "powerpc-none"
    "powerpc64-linux"
    "powerpc64le-linux"
    "powerpcle-none"
    "riscv32-linux"
    "riscv32-netbsd"
    "riscv32-none"
    "riscv64-linux"
    "riscv64-netbsd"
    "riscv64-none"
    "s390-linux"
    "s390-none"
    "s390x-linux"
    "s390x-none"
    "vc4-none"
    "wasm32-wasi"
    "wasm64-wasi"
    "x86_64-cygwin"
    "x86_64-darwin"
    "x86_64-freebsd"
    "x86_64-genode"
    "x86_64-linux"
    "x86_64-netbsd"
    "x86_64-none"
    "x86_64-openbsd"
    "x86_64-redox"
    "x86_64-solaris"
    "x86_64-windows"
  ]
}:
let
  # copied from <nixpkgs/lib>
  lib = {
    inherit (builtins)
      attrNames
      concatMap
      concatStringsSep
      hasAttr
      head
      isAttrs
      isString
      listToAttrs
      mapAttrs
      parseDrvName
      readDir
      substring
      tail
      ;


    splitString =
      let
        addContextFrom = a: b: builtins.substring 0 0 a + b;
        escape = list: builtins.replaceStrings list (map (c: "\\${c}") list);
        range =
          # First integer in the range
          first:
          # Last integer in the range
          last:
          if first > last then
            [ ]
          else
            builtins.genList (n: first + n) (last - first + 1);
        stringToCharacters = s:
          map (p: builtins.substring p 1 s) (range 0 (builtins.stringLength s - 1));
        escapeRegex = escape (stringToCharacters "\\[{()^$?*+|.");
      in
      _sep: _s:
        let
          sep = builtins.unsafeDiscardStringContext _sep;
          s = builtins.unsafeDiscardStringContext _s;
          splits = builtins.filter builtins.isString (builtins.split (escapeRegex sep) s);
        in
        map (v: addContextFrom _sep (addContextFrom _s v)) splits;

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

  hasSupport = kernel: builtins.foldl' (x: y: x || y) false (map (i: builtins.match (".+-" + kernel) i != null) supportedSystems);
  hasLinuxSupport = hasSupport "linux";
  hasDarwinSupport = hasSupport "darwin";

  root = {
    self = readBuildTree path // { inherit hasLinuxSupport hasDarwinSupport; };
    inherit supportedSystems;
  } // args;

  filterPackages = import ./filterPackages.nix { inherit supportedSystems; };

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

      buildAttrs = if dir ? "BUILD.nix" then filterPackages supportedSystems (callBuild path) else { };

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


