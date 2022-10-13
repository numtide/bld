{ ... }:
{
  git = builtins.fetchGit;
  mercurial = builtins.fetchMercurial;
  tarball = builtins.fetchTarball;
  url = builtins.fetchurl;
  tree = builtins.fetchTree;
}
