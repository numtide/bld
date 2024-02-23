{ supportedSystems }:
system: packages:
let
  # Adopted from nixpkgs.lib
  inherit (builtins) listToAttrs concatMap attrNames filter;
  nameValuePair = name: value: { inherit name value; };
  intersectLists = e: filter (x: builtins.elem x e);
  filterAttrs = pred: set:
    listToAttrs (
      concatMap
        (name:
          let v = set.${name}; in
          if pred name v then [ (nameValuePair name v) ] else [ ]
        )
        (attrNames set)
    );

  # Everything that nix flake check requires for the packages output
  sieve = n: v:
    with v;
    let
      inherit (builtins) isAttrs;
      isDerivation = x: isAttrs x && x ? type && x.type == "derivation";
      isBroken = meta.broken or false;
      platforms = meta.platforms or supportedSystems;
      badPlatforms = meta.badPlatforms or [ ];
    in
    # check for isDerivation, so this is independently useful of
      # flattenTree, which also does filter on derivations
    (isDerivation v && !isBroken && (builtins.length (intersectLists supportedSystems platforms) > 0) &&
    !(builtins.elem system badPlatforms)) || (!isDerivation v)
  ;
in
filterAttrs sieve packages
