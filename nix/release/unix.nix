{
  lib,
  stdenv,
  patchelf,
  php,
  libstemmer,
  src,
}:
stdenv.mkDerivation {
  pname = "php-stemmer-release";
  version = php.version;
  inherit src;
  nativeBuildInputs = lib.optionals stdenv.isLinux [patchelf];
  dontConfigure = true;
  dontFixup = true;
  buildPhase = ''
    runHook preBuild
    includes=()
    for directory in . main Zend TSRM ext; do
      includes+=("-I${php.unwrapped.dev}/include/php/$directory")
    done
    $CC -O2 -fPIC -DCOMPILE_DL_STEMMER=1 "''${includes[@]}" \
      -I${libstemmer}/include php_stemmer.c ${libstemmer}/lib/libstemmer.a \
      ${
      if stdenv.isDarwin
      then "-bundle -Wl,-undefined,dynamic_lookup"
      else "-shared -Wl,--exclude-libs,ALL"
    } \
      -o stemmer.so
    runHook postBuild
  '';
  installPhase = ''
    mkdir -p "$out"
    cp stemmer.so "$out/"
    ${lib.optionalString stdenv.isLinux ''
      patchelf --remove-rpath "$out/stemmer.so"
      # A distributable extension must not require Nix or a shared Snowball library.
      needed=$(patchelf --print-needed "$out/stemmer.so")
      case "$needed" in
        libc.so.6|libc.so) ;;
        *) echo "Unexpected shared libraries: $needed" >&2; exit 1 ;;
      esac
    ''}
    ${lib.optionalString stdenv.isDarwin ''
      test "$(lipo -archs "$out/stemmer.so")" = arm64
      otool -L "$out/stemmer.so"
      if otool -l "$out/stemmer.so" | grep -q /nix/store; then
        echo "Mach-O contains a Nix runtime dependency" >&2
        exit 1
      fi
    ''}
  '';
}
