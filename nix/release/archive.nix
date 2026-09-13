{
  runCommand,
  fetchurl,
  lib,
  python3,
  unzip,
  binary,
  filename,
  member,
  src,
  snowball,
  php,
  corpusData,
  ci,
  testPhp ? null,
}:
runCommand filename {
  nativeBuildInputs = [python3 unzip];
  passthru.ci =
    ci
    // {
      release = true;
      artifact = "pie-${ci.php}-${ci.platform}";
    };
} ''
  mkdir -p "$out/test"
  # Kept outside the release ZIP; CI uses the same test driver and corpus.
  cp ${php.unwrapped.dev}/lib/build/run-tests.php "$out/test/run-tests.php"
  ln -s ${corpusData} "$out/test/corpus"
  python - "$out/${filename}.zip" <<'PY'
  import sys
  import zipfile
  from pathlib import Path

  with zipfile.ZipFile(sys.argv[1], "w", compression=zipfile.ZIP_DEFLATED) as archive:
      for name, source in sorted({
          "${member}": "${binary}",
          "LICENSE": "${src}/LICENSE",
          "SNOWBALL-LICENSE": "${snowball}/COPYING",
      }.items()):
          entry = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
          entry.create_system = 3
          entry.external_attr = 0o100644 << 16
          entry.compress_type = zipfile.ZIP_DEFLATED
          archive.writestr(entry, Path(source).read_bytes())
  PY
  unzip -t "$out/${filename}.zip"
  PHP_INI_SCAN_DIR= ${lib.getExe php} -c ${php.phpIni} ${./check-pie-archive.php} \
    ${import ../pie.nix {inherit fetchurl;}} ${src} \
    "$out/${filename}.zip" ${lib.escapeShellArg (builtins.toJSON ci)}
  ${lib.optionalString (testPhp != null) ''
    unzip -q "$out/${filename}.zip" -d extracted
    cp -r ${src}/tests tests
    chmod -R u+w tests
    mkdir -p .github/scripts
    cp ${../../.github/scripts/check-release.php} .github/scripts/check-release.php
    cp ${src}/php_stemmer.h .
    export TEST_PHP_EXECUTABLE=${lib.getExe testPhp}
    export TEST_PHP_ARGS="-c ${testPhp.phpIni} -d extension=$PWD/extracted/stemmer.so"
    export STEMMER_CORPUS_DIR=${corpusData}
    export STEMMER_CORPUS_MARKER="$PWD/corpus-passed"
    export NO_INTERACTION=1 REPORT_EXIT_STATUS=1 TEST_TIMEOUT=600
    "$TEST_PHP_EXECUTABLE" -n -d extension="$PWD/extracted/stemmer.so" \
      .github/scripts/check-release.php ${ci.php} nts ${
      if ci.platform == "darwin"
      then "Darwin"
      else "Linux"
    }
    "$TEST_PHP_EXECUTABLE" -n "$out/test/run-tests.php" -n -q --show-diff tests
    test -f "$STEMMER_CORPUS_MARKER"
  ''}
''
