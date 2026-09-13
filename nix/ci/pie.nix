{
  stdenv,
  fetchurl,
  php85,
  autoconf,
  automake,
  libtool,
  pkg-config,
  libstemmer,
  src,
}: let
  pie = import ../pie.nix {inherit fetchurl;};
in
  stdenv.mkDerivation {
    pname = "stemmer-pie-check";
    version = "1.4.10";
    inherit src;
    nativeBuildInputs = [php85 php85.unwrapped.dev autoconf automake libtool pkg-config];
    buildInputs = [libstemmer];
    dontConfigure = true;
    COMPOSER_DISABLE_NETWORK = "1";
    COMPOSER_NO_INTERACTION = "1";
    buildPhase = ''
      export PIE_WORKING_DIRECTORY="$TMPDIR/pie"
      export COMPOSER_HOME="$TMPDIR/composer"
      php ${pie} repository:remove packagist.org
      php ${pie} repository:add path "$PWD"
      php ${pie} build 'jbboehr/php-stemmer:*@dev' --no-interaction \
        --with-phpize-path=${php85.unwrapped.dev}/bin/phpize
    '';
    installPhase = ''
      mkdir -p "$out"
      cp modules/stemmer.so "$out/"
      php -n -d extension="$out/stemmer.so" -r '
        if (stemmer_stem_word("running", "english", "UTF_8") !== "run") exit(1);
      '
    '';
  }
