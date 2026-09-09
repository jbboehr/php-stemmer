{
  pkgs,
  system,
  phps,
  src,
  snowball,
  corpusData,
  windows,
}: let
  inherit (pkgs) lib;
  version = builtins.head (builtins.match ''.*#define PHP_STEMMER_VERSION "([^"]+)".*'' (builtins.readFile ../../php_stemmer.h));
  unixTarget =
    if pkgs.stdenv.isDarwin
    then {
      os = "darwin";
      arch = "arm64";
      libcs = ["bsdlibc"];
    }
    else {
      os = "linux";
      arch = "x86_64";
      libcs = ["glibc" "musl"];
    };
  makeArchive = args: pkgs.callPackage ./archive.nix ({inherit src snowball corpusData;} // args);
  makeUnixArchive = phpName: php: libc: let
    buildPkgs =
      if libc == "musl"
      then pkgs.pkgsMusl
      else pkgs;
    libstemmer = buildPkgs.libstemmer.overrideAttrs {
      version = "2.2.0";
      src = snowball;
    };
    extension = pkgs.callPackage ./unix.nix {
      inherit php src libstemmer;
      inherit (buildPkgs) stdenv;
    };
    minor = lib.versions.majorMinor php.version;
    platform = "${unixTarget.os}${lib.optionalString (unixTarget.os == "linux") "-${libc}"}";
    package = makeArchive {
      inherit php;
      binary = "${extension}/stemmer.so";
      member = "stemmer.so";
      filename = "php_stemmer-${version}_php${minor}-${unixTarget.arch}-${unixTarget.os}-${libc}-nts";
      ci = {
        php = minor;
        inherit platform;
        ts = "nts";
      };
    };
  in
    lib.nameValuePair "release-${phpName}-${platform}" package;
  makeWindowsArchive = name: extension: let
    inherit (extension) php;
    filename = "php_stemmer-${version}-${php.minor}-${php.threadSafety}-${php.compiler}-x86_64";
  in
    lib.nameValuePair "release-${name}" (makeArchive {
      inherit filename;
      php = pkgs.php85;
      binary = "${extension}/php_stemmer.dll";
      member = "${filename}.dll";
      ci = {
        php = php.minor;
        platform = "windows-${php.threadSafety}";
        ts = php.threadSafety;
      };
    });
  unixPackages = lib.concatMap (name: map (makeUnixArchive name phps.${name}) unixTarget.libcs) (builtins.attrNames phps);
  packages = lib.optionalAttrs (builtins.elem system ["x86_64-linux" "aarch64-darwin"]) (
    builtins.listToAttrs (unixPackages ++ lib.mapAttrsToList makeWindowsArchive windows.packages)
  );
in {
  inherit packages;
  checks = packages;
}
