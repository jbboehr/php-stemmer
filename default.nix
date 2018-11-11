{
  pkgs ? import <nixpkgs> {},
  php ? pkgs.php,

  phpStemmerVersion ? null,
  phpStemmerSrc ? ./.,
  phpStemmerSha256 ? null
}:

pkgs.callPackage ./derivation.nix {
  inherit php phpStemmerVersion phpStemmerSrc phpStemmerSha256;
}

