{ php, stdenv, autoreconfHook, fetchurl, libstemmer,
  buildPecl ? import <nixpkgs/pkgs/build-support/build-pecl.nix> {
    # re2c is required for nixpkgs master, must not be specified for <= 19.03
    inherit php stdenv autoreconfHook fetchurl;
  },
  phpStemmerVersion ? null, phpStemmerSrc ? null, phpStemmerSha256 ? null }:

let
  orDefault = x: y: (if (!isNull x) then x else y);
in

buildPecl rec {
  pname = "stemmer";
  name = "stemmer-${version}";
  version = orDefault phpStemmerVersion "v1.0.2";
  src = orDefault phpStemmerSrc (fetchurl {
    url = "https://github.com/jbboehr/php-stemmer/archive/${version}.tar.gz";
    sha256 = orDefault phpStemmerSha256 "03ljshzvlk0k4nw3xnrksdgn0qdfknqvs0rdxvjdky9m83nnbxak";
  });

  makeFlags = ["phpincludedir=$(out)/include/php/ext/stemmer"];
  buildInputs = [ libstemmer ];

  doCheck = true;
  checkTarget = "test";
  checkFlags = ["REPORT_EXIT_STATUS=1" "NO_INTERACTION=1"];
}

