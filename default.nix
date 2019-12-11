{
  pkgs ? import <nixpkgs> {},
  php ? pkgs.php,
  buildPecl ? pkgs.callPackage <nixpkgs/pkgs/build-support/build-pecl.nix> {
    inherit php;
  },

  phpStemmerVersion ? null,
  phpStemmerSrc ? ./.,
  phpStemmerSha256 ? null
}:

pkgs.callPackage ./derivation.nix {
  inherit php buildPecl phpStemmerVersion phpStemmerSrc phpStemmerSha256;
}

