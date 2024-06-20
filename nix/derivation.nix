{
  lib,
  php,
  stdenv,
  autoreconfHook,
  fetchurl,
  libstemmer,
  buildPecl,
  pkg-config,
  # snowball-data,
  src,
  checkSupport ? true,
}:
buildPecl rec {
  pname = "stemmer";
  name = "stemmer";
  version = "master";
  inherit src;

  passthru = {
    inherit php stdenv libstemmer;
  };

  makeFlags = ["phpincludedir=$(dev)/include"];
  buildInputs = [libstemmer];

  nativeBuildInputs = [php.unwrapped.dev pkg-config];

  # broken
  # preBuild = lib.optionalString checkSupport ''
  #   php -c ${php.phpIni} generate-tests.php ${snowball-data}
  #   ls -alh ${snowball-data}
  #   ls -alh tests
  # '';

  doCheck = checkSupport;
}
