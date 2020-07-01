{
  pkgs ? import <nixpkgs> {},
  stdenv ? pkgs.stdenv,
  php ? pkgs.php,
  buildPecl ? pkgs.callPackage <nixpkgs/pkgs/build-support/build-pecl.nix> {
    inherit php stdenv;
  },

  gitignoreSource ? (import (pkgs.fetchFromGitHub {
      owner = "hercules-ci";
      repo = "gitignore";
      rev = "00b237fb1813c48e20ee2021deb6f3f03843e9e4";
      sha256 = "sha256:186pvp1y5fid8mm8c7ycjzwzhv7i6s3hh33rbi05ggrs7r3as3yy";
  }) { inherit (pkgs) lib; }).gitignoreSource,

  snowball-data ? pkgs.fetchFromGitHub {
    owner = "snowballstem";
    repo = "snowball-data";
    rev = "8d35251e456139167a394ea315e4855247fa2471";
    sha256 = "1jsdxc8ypfi3sbbmqln61zjlyvicx3vnd4c112dpmjcxl212yngw";
  },

  phpStemmerVersion ? null,
  phpStemmerSha256 ? null,
  phpStemmerSrc ? pkgs.lib.cleanSourceWith {
    filter = (path: type: (builtins.all (x: x != baseNameOf path) [".idea" ".git" "ci.nix" ".travis.sh" ".travis.yml" ".ci" "nix" "default.nix"]));
    src = gitignoreSource ./.;
  }
}:

pkgs.callPackage ./nix/derivation.nix {
  inherit stdenv php buildPecl;
  inherit phpStemmerVersion phpStemmerSrc phpStemmerSha256;
  inherit snowball-data;
}
