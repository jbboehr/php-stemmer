{
  lib,
  runCommand,
  llvmPackages,
  src,
  sdk,
  libstemmer,
  php,
}:
runCommand "php-stemmer-${php.version}-windows-x64-${php.threadSafety}" {
  nativeBuildInputs = [llvmPackages.clang-unwrapped llvmPackages.lld];
  passthru = {inherit php libstemmer;};
} ''
  cp ${src}/php_stemmer.c ${src}/php_stemmer.h ${src}/stemmer_arginfo.h .
  clang-cl --target=x86_64-pc-windows-msvc /nologo /Brepro /MD /O2 /TC /utf-8 \
    /vctoolsdir ${sdk}/crt /winsdkdir ${sdk}/sdk \
    /c php_stemmer.c /Fostemmer.obj /FIintrin.h \
    /I${php.headers}/include /I${php.headers}/include/main \
    /I${php.headers}/include/Zend /I${php.headers}/include/TSRM \
    /I${php.headers}/include/ext /I${libstemmer}/include \
    /DPHP_WIN32=1 /DZEND_WIN32=1 /DZEND_DEBUG=0 /DCOMPILE_DL_STEMMER=1 \
    /DZEND_COMPILE_DL_EXT=1 /D_WINDOWS /DWIN32 /D_MBCS /DNDEBUG \
    /DENABLE_INTSAFE_SIGNED_FUNCTIONS ${lib.optionalString php.zts "/DZTS=1"}

  mkdir -p "$out"
  lld-link /dll /out:"$out/php_stemmer.dll" stemmer.obj \
    ${libstemmer}/lib/libstemmer.lib ${php.headers}/lib/${php.importLibrary} \
    /libpath:${sdk}/crt/lib/x64 /libpath:${sdk}/sdk/lib/ucrt/x64 \
    /libpath:${sdk}/sdk/lib/um/x64
  cp ${src}/LICENSE "$out/LICENSE"
  cp ${libstemmer}/share/licenses/libstemmer/COPYING "$out/SNOWBALL-LICENSE"
''
