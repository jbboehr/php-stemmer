{
  pkgs,
  php,
}:
# Build zlib into the CLI so corpus tests need no separate extension toolchain.
(php.unwrapped.overrideAttrs (old: {
  configureFlags = old.configureFlags ++ ["--with-zlib"];
  buildInputs = old.buildInputs ++ [pkgs.pkgsMusl.zlib];
})).passthru.buildEnv {
  inherit (pkgs) autoconf automake bison flex libtool pkg-config re2c;
  cgiSupport = false;
  fpmSupport = false;
  pearSupport = false;
  pharSupport = false;
  phpdbgSupport = false;
  argon2Support = false;
  systemdSupport = false;
  valgrindSupport = false;
  extensions = _: [];
}
