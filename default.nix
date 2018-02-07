# when using nix-shell, run "configurePhase" otherwise you'll have missing headers
# to use a specific version of php, run `nix-shell --arg php '(import <nixpkgs> {}).php56'`

{ php ? (import <nixpkgs> {}).php, pkgs ? import <nixpkgs> {} }:

let
  buildPecl = import <nixpkgs/pkgs/build-support/build-pecl.nix> {
    inherit php;
    inherit (pkgs) stdenv autoreconfHook fetchurl;
  };
  libstemmer = pkgs.lib.callPackageWith pkgs ({ lib, stdenv, fetchFromGitHub, cmake }: stdenv.mkDerivation rec {
    name = "libstemmer-2017-03-02";

    src = fetchFromGitHub {
      owner = "zvelo";
      repo = "libstemmer";
      rev = "78c149a3a6f262a35c7f7351d3f77b725fc646cf";
      sha256 = "06md6n6h1f2zvnjrpfrq7ng46l1x12c14cacbrzmh5n0j98crpq7";
    };

    nativeBuildInputs = [ cmake ];

    meta = with lib; {
      description = "Snowball Stemming Algorithms";
      homepage = "http://snowball.tartarus.org/";
      license = licenses.bsd3;
      maintainers = with maintainers; [ fpletz ];
      platforms = platforms.all;
    };
  }) {};
in
buildPecl rec {
  name = "stemmer-${version}";
  version = "1.0.2";
  src = ./.;
  buildInputs = [ libstemmer ];
  doCheck = true;
  checkTarget = "test";
  checkFlagsArray = ["REPORT_EXIT_STATUS=1" "NO_INTERACTION=1" "TEST_PHP_DETAILED=1"];
}
