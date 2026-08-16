{
  php,
  stdenv,
  libstemmer,
  buildPecl,
  pkg-config,
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
  doCheck = checkSupport;
}
