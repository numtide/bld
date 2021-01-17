# bld

bld is an experimental build tool for monorepos inspired by Bazel, and 
implemented with Nix. This is meant to evolve and its current form is not the
final one.

This tool has two sides: a CLI and a Nix library, that are meant to be able to
work together.

## Principles

We steal the notion of "targets" from Bazel, making each folder open-ended.

It should be possible to type `bld` in any folder and get the build output of
the current folder (and below?).

It should be possible to build any targets using purely `nix-build`.

## Future ideas

* Resolve the targets purely with Nix. It should be necessary to connect the
  BUILD.nix files manually like currently.
* Snapshot nixpkgs. In order to speed-up nixpkgs, we want to be able to
  snapshot the build outputs that we are going to use.
* Add nix evaluation caching to speed-up builds.
* Introduce incremental rebuild Nix libraries for various languages.
* Hook in pre-processing tools. It should be possible to update a third-party
  package hash automatically.
