{
  lib, php, stdenv, autoreconfHook, fetchurl, libstemmer,
  buildPecl ? import <nixpkgs/pkgs/build-support/build-pecl.nix> {
    # re2c is required for nixpkgs master, must not be specified for <= 19.03
    inherit php stdenv autoreconfHook fetchurl;
  },
  snowball-data ? null,
  phpStemmerVersion ? null,
  phpStemmerSrc ? null,
  phpStemmerSha256 ? null,

  checkSupport ? true
}:

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
  nativeBuildInputs = []
    ++ lib.optional checkSupport snowball-data
    ;

  preCheck = lib.optionalString checkSupport ''
      php generate-tests.php ${snowball-data}
    '';

  doCheck = checkSupport;
  checkTarget = "test";
  checkFlags = ["REPORT_EXIT_STATUS=1" "NO_INTERACTION=1"];
}
