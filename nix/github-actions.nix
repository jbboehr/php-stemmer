{
  nix-github-actions,
  checks,
}: let
  generated = nix-github-actions.lib.mkGithubMatrix {
    inherit checks;
    attrPrefix = "checks";
    platforms = nix-github-actions.lib.githubPlatforms // {aarch64-darwin = "macos-15";};
  };
  addMetadata = entry:
    entry
    // {attr = builtins.replaceStrings ["\""] [""] entry.attr;}
    // (checks.${entry.system}.${entry.name}.ci or {});
in {
  matrix.include = map addMetadata (builtins.filter (entry: entry.name != "default") generated.matrix.include);
}
