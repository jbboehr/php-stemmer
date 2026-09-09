{
  pkgs,
  src,
  packages,
  phps,
}: let
  valgrind = name: _:
    packages.${name + "-gcc"}.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [pkgs.valgrind];
      USE_ZEND_ALLOC = "0";
      checkPhase = ''make test TEST_PHP_ARGS="-m"'';
    });
in
  pkgs.lib.mapAttrs' (name: php: pkgs.lib.nameValuePair "${name}-valgrind" (valgrind name php)) phps
  // {
    coverage = pkgs.callPackage ./coverage.nix {package = packages.php85-gcc;};
    pie = pkgs.callPackage ./pie.nix {inherit src;};
  }
