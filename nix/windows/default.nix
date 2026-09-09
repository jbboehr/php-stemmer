{
  nixpkgs,
  system,
  src,
  snowball,
  corpusData,
}: let
  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) ["win-sdk" "xwin-fetch-msvc"];
      microsoftVisualStudioLicenseAccepted = true;
    };
  };
  sdk = pkgs.windows.sdk;
  libstemmer = pkgs.callPackage ./libstemmer.nix {inherit sdk snowball;};
  makePackage = minor: zts:
    pkgs.callPackage ./extension.nix {
      inherit src sdk libstemmer;
      php = pkgs.callPackage ./php.nix {inherit minor zts;};
    };
  packages = builtins.listToAttrs (pkgs.lib.concatMap (minor:
    map (zts: {
      name = "php${builtins.replaceStrings ["."] [""] minor}-windows-${
        if zts
        then "ts"
        else "nts"
      }";
      value = makePackage minor zts;
    }) [false true]) (builtins.attrNames (builtins.fromJSON (builtins.readFile ./php-versions.json))));
in
  if system == "x86_64-linux"
  then {
    inherit packages;
    checks = builtins.mapAttrs (_: package:
      pkgs.callPackage ./check.nix {inherit src package corpusData;})
    packages;
  }
  else {
    packages = {};
    checks = {};
  }
