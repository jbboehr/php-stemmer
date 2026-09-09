{
  lib,
  linkFarm,
  phps,
}:
# Keep both runtimes and headers reachable when the cache job collects garbage.
linkFarm "ci-php" (map (path: {
  name = builtins.unsafeDiscardStringContext (builtins.baseNameOf path);
  inherit path;
}) (lib.concatMap (php: [php php.unwrapped.dev]) phps))
