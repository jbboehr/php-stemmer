{
  lib,
  php,
  stdenv,
  libstemmer,
  buildPecl,
  src,
  checkSupport ? true,
  corpusData ? null,
}:
buildPecl (
  {
    pname = "stemmer";
    name = "stemmer";
    version = "master";
    inherit src;

    passthru = {
      inherit php stdenv libstemmer;
    };

    makeFlags = ["phpincludedir=$(dev)/include"];
    buildInputs = [libstemmer];

    nativeBuildInputs = [php.unwrapped.dev];
    doCheck = checkSupport;

    NO_INTERACTION = "1";
    REPORT_EXIT_STATUS = "1";
  }
  // lib.optionalAttrs (corpusData != null) {
    STEMMER_CORPUS_DIR = toString corpusData;
    STEMMER_CORPUS_MARKER = ".stemmer-corpus-passed";
    # run-tests.php uses -n; load zlib to read the compressed Arabic corpus.
    TEST_PHP_ARGS = "-c ${php.phpIni}";
    TEST_TIMEOUT = "600";

    preInstall = ''
      if [[ ! -f "$STEMMER_CORPUS_MARKER" ]]; then
        echo "The Snowball corpus test did not run successfully" >&2
        exit 1
      fi
    '';
  }
)
