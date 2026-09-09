{
  nix-github-actions,
  checks,
  packages,
}: let
  platforms = nix-github-actions.lib.githubPlatforms // {aarch64-darwin = "macos-15";};
  cacheKey = system: "nix-php-${system}-${builtins.baseNameOf packages.${system}.ci-php.drvPath}";
  generated = nix-github-actions.lib.mkGithubMatrix {
    inherit checks;
    attrPrefix = "checks";
    inherit platforms;
  };
  addMetadata = entry:
    entry
    // {
      attr = builtins.replaceStrings ["\""] [""] entry.attr;
      cache-key = cacheKey entry.system;
    }
    // (checks.${entry.system}.${entry.name}.ci or {});
in {
  matrix.include = map addMetadata (builtins.filter (entry: entry.name != "default") generated.matrix.include);
  phpMatrix.include = map (system: {
    inherit system;
    os = platforms.${system};
    cache-key = cacheKey system;
  }) (builtins.attrNames checks);
}
