{
  runCommand,
  fetchurl,
  cabextract,
  wineWow64Packages,
  php85,
  writeShellScript,
  makeFontsConf,
  src,
  package,
  corpusData,
}: let
  wine = wineWow64Packages.stable;
  # PHP checks the VCRUNTIME version; Wine's built-in DLL is insufficient.
  redist = fetchurl {
    url = "https://download.visualstudio.microsoft.com/download/pr/ebdab8e5-1d7b-4d9f-a11b-cbb1720c3b12/843068991DAAA1F73AD9F6239BCE4D0F6A07A51F18C37EA2A867E9BECA71295C/VC_redist.x64.exe";
    sha256 = "843068991daaa1f73ad9f6239bce4d0f6a07a51f18c37ea2a867e9beca71295c";
  };
  runtime =
    runCommand "vcruntime-windows-x64" {
      nativeBuildInputs = [cabextract];
    } ''
      cabextract -q -d outer ${redist}
      # a4 is the x64 minimum-runtime cabinet in this pinned installer.
      cabextract -q -d inner outer/a4
      install -Dm644 inner/vcruntime140.dll_amd64 "$out/vcruntime140.dll"
      install -Dm644 inner/vcruntime140_1.dll_amd64 "$out/vcruntime140_1.dll"
    '';
  windowsPhp = writeShellScript "windows-php" ''
    exec ${wine}/bin/wine "$WINEPREFIX/drive_c/php/php.exe" "$@"
  '';
in
  runCommand "${package.name}-check" {
    nativeBuildInputs = [wine php85.unwrapped];
  } ''
    export WINEPREFIX="$TMPDIR/wine-prefix"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export FONTCONFIG_FILE=${makeFontsConf {fontDirectories = [];}}
    export WINEDLLOVERRIDES='mscoree,mshtml,winemenubuilder,winex11.drv,winewayland.drv=;vcruntime140,vcruntime140_1=n,b'
    export WINEDEBUG=-all
    unset DISPLAY WAYLAND_DISPLAY
    mkdir -p "$XDG_CACHE_HOME/fontconfig"
    trap 'wineserver -k || true' EXIT
    echo "Initializing headless Wine"
    timeout 60 wineboot -i

    cp -r ${package.php.runtime} "$WINEPREFIX/drive_c/php"
    chmod -R u+w "$WINEPREFIX/drive_c/php"
    cp ${runtime}/*.dll "$WINEPREFIX/drive_c/php/"
    cp ${package}/php_stemmer.dll "$WINEPREFIX/drive_c/php/ext/"
    # PHP cannot enumerate the corpus through Wine's Z: mapping on some hosts.
    cp -r ${corpusData} "$WINEPREFIX/drive_c/corpus"

    export TEST_PHP_EXECUTABLE=${windowsPhp}
    export TEST_PHP_ARGS='-d extension=C:/php/ext/php_stemmer.dll'
    export STEMMER_CORPUS_DIR=C:/corpus
    export STEMMER_CORPUS_MARKER=C:/corpus-passed
    export NO_INTERACTION=1 REPORT_EXIT_STATUS=1 TEST_TIMEOUT=600
    echo "Checking Windows PHP and extension loading"
    "$TEST_PHP_EXECUTABLE" -n -d extension=C:/php/ext/php_stemmer.dll -r '
      if (PHP_OS_FAMILY !== "Windows" || PHP_INT_SIZE !== 8
          || PHP_VERSION !== "${package.php.version}"
          || PHP_ZTS !== ${builtins.toJSON package.php.zts}
          || !extension_loaded("stemmer")) {
        fwrite(STDERR, "Windows PHP configuration or stemmer loading failed\n");
        exit(1);
      }
    '
    cp ${php85.unwrapped.dev}/lib/build/run-tests.php run-tests.php
    cp -r ${src}/tests tests
    chmod -R u+w tests
    php -n run-tests.php -n -q --show-diff tests
    test -f "$WINEPREFIX/drive_c/corpus-passed"
    touch "$out"
  ''
