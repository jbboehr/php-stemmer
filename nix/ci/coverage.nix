{
  package,
  lcov,
}:
package.overrideAttrs (old: {
  nativeBuildInputs = old.nativeBuildInputs ++ [lcov];
  CFLAGS = "-O0 --coverage";
  LDFLAGS = "--coverage";
  checkPhase = ''
    make test
    lcov --capture --directory . --gcov-tool ${package.stdenv.cc.cc}/bin/gcov \
      --include "$PWD/php_stemmer.c" --output-file coverage.info
    # Coverage services resolve source paths against the checkout.
    sed -i "s|SF:$PWD/|SF:|" coverage.info
    grep -q '^SF:php_stemmer.c$' coverage.info
    grep -Eq '^LH:[1-9][0-9]*$' coverage.info
  '';
  installPhase = ''
    mkdir -p "$out"
    cp coverage.info "$out/"
  '';
  passthru = (old.passthru or {}) // {ci.coverage = true;};
})
