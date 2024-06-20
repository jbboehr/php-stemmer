{
  system ? builtins.currentSystem,
  lib ? import <nixpkgs/lib>,
  prefix,
}: attrs:
lib.pipe attrs.${system} [
  builtins.attrNames
  (builtins.map (x: "${prefix}.${system}.${x}"))
  (builtins.concatStringsSep "\n")
]
