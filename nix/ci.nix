let
    generateTestsForPlatform = { pkgs, path, php }:
        pkgs.recurseIntoAttrs {
            gcc = pkgs.callPackage ../default.nix {
                inherit php;
                buildPecl = pkgs.callPackage "${path}/pkgs/build-support/build-pecl.nix" { inherit php; };
            };
            clang = let
                stdenv = pkgs.clangStdenv;
            in pkgs.callPackage ../default.nix {
                inherit php stdenv;
                buildPecl = pkgs.callPackage "${path}/pkgs/build-support/build-pecl.nix" { inherit php stdenv; };
            };
        };
in
builtins.mapAttrs (k: _v:
  let
    path = builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-20.03.tar.gz";
        name = "nixpkgs-20.03";
    };
    pkgs = import (path) { system = k; };
  in
  pkgs.recurseIntoAttrs {
    php72 = let
        php = pkgs.php72;
    in generateTestsForPlatform {
        inherit pkgs php path;
    };

    php73 = let
        php = pkgs.php73;
    in generateTestsForPlatform {
        inherit pkgs php path;
    };

    php74 = let
        php = pkgs.php74;
    in generateTestsForPlatform {
        inherit pkgs php path;
    };
  }
) {
  x86_64-linux = {};
  # Uncomment to test build on macOS too
  # x86_64-darwin = {};
}