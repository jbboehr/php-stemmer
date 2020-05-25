let
    generateDistDrv = { pkgs, php }:
        pkgs.runCommand "pecl-stemmer.tgz" {
            buildInputs = [ php ];
            src = builtins.filterSource
                (path: type: baseNameOf path != ".idea" && baseNameOf path != ".git" && baseNameOf path != "ci.nix")
                ./.;
            snowballData = pkgs.fetchgit {
                url = https://github.com/snowballstem/snowball-data.git;
                rev = "8d35251e456139167a394ea315e4855247fa2471";
                sha256 = "1jsdxc8ypfi3sbbmqln61zjlyvicx3vnd4c112dpmjcxl212yngw";
            };
        } ''
            cp -r $src/* .
            chmod -R +w .
            php generate-tests.php $snowballData
            tar cf $out . --transform 's,^,php-stemmer/,'
        '';

    generateTestsForPlatform = { pkgs, php, buildPecl, phpStemmerSrc }:
        pkgs.recurseIntoAttrs {
            stemmer = pkgs.callPackage ./derivation.nix {
               inherit php buildPecl phpStemmerSrc;
            };
        };
in
builtins.mapAttrs (k: _v:
  let
    path = builtins.fetchTarball {
       url = https://github.com/NixOS/nixpkgs/archive/release-20.03.tar.gz;
       name = "nixpkgs-20.03";
    };
    pkgs = import (path) { system = k; };

    phpStemmerSrc = generateDistDrv {
        inherit pkgs;
        inherit (pkgs) php;
    };
  in
  pkgs.recurseIntoAttrs {
    dist = phpStemmerSrc;

    php72 = let
        php = pkgs.php72;
    in generateTestsForPlatform {
        inherit pkgs php phpStemmerSrc;
        buildPecl = pkgs.callPackage "${path}/pkgs/build-support/build-pecl.nix" { inherit php; };
    };

    php73 = let
        php = pkgs.php73;
    in generateTestsForPlatform {
        inherit pkgs php phpStemmerSrc;
        buildPecl = pkgs.callPackage "${path}/pkgs/build-support/build-pecl.nix" { inherit php; };
    };

    php74 = let
        php = pkgs.php74;
    in generateTestsForPlatform {
        inherit pkgs php phpStemmerSrc;
        buildPecl = pkgs.callPackage "${path}/pkgs/build-support/build-pecl.nix" { inherit php; };
    };
  }
) {
  x86_64-linux = {};
  # Uncomment to test build on macOS too
  # x86_64-darwin = {};
}