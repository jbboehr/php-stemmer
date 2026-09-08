{
  runCommand,
  libstemmer,
  llvmPackages,
  gnumake,
  perl,
  sdk,
  snowball,
}: let
  version = "2.2.0";
  generator = libstemmer.overrideAttrs {
    inherit version;
    src = snowball;
  };
in
  runCommand "libstemmer-${version}-windows-x64" {
    nativeBuildInputs = [gnumake perl llvmPackages.clang-unwrapped llvmPackages.llvm];
  } ''
    cp -r ${snowball} source
    chmod -R u+w source
    cd source
    patchShebangs libstemmer

    # Generate C with the Linux executable before compiling Windows objects.
    ln -s ${generator}/bin/snowball snowball
    cat > generation.mk <<'EOF'
    generated: $(C_LIB_SOURCES) $(C_LIB_HEADERS) libstemmer/modules.h libstemmer/libstemmer.c
    EOF
    make -j "$NIX_BUILD_CORES" -o snowball -f GNUmakefile -f generation.mk generated

    mkdir objects
    for source in src_c/*.c runtime/*.c libstemmer/libstemmer.c; do
      name=$(basename "$source" .c)
      clang-cl --target=x86_64-pc-windows-msvc /nologo /Brepro /MD /O2 /TC \
        /vctoolsdir ${sdk}/crt /winsdkdir ${sdk}/sdk \
        /c "$source" /Fo"objects/$name.obj" /Iinclude
    done
    llvm-lib /out:libstemmer.lib objects/*.obj
    install -Dm644 libstemmer.lib "$out/lib/libstemmer.lib"
    install -Dm644 include/libstemmer.h "$out/include/libstemmer.h"
    install -Dm644 COPYING "$out/share/licenses/libstemmer/COPYING"
  ''
