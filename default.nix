{ system ? builtins.currentSystem
, inputs ? import ./flake.lock.nix { }
, nixpkgs ? import inputs.nixpkgs {
    inherit system;
    # Makes the config pure as well. See <nixpkgs>/top-level/impure.nix:
    config = { };
    overlays = [ ];
  }
}:
let
  bld = import ./lib;
in
bld.buildTree {
  path = ./.;
  args = {
    inherit
      inputs
      nixpkgs
      ;
  };
}
