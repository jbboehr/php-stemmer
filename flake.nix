{
  description = "jbboehr/php-stemmer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    systems.url = "github:nix-systems/default-linux";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    phps = {
      url = "github:fossar/nix-phps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowball = {
      url = "github:snowballstem/snowball/v2.2.0";
      flake = false;
    };
    snowball-data = {
      # Last data revision before the matching libstemmer 2.2.0 release.
      url = "github:snowballstem/snowball-data/0703f1d6a21802c3ff00c2c8b31bd255b74b2aec";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    gitignore,
    git-hooks,
    systems,
    nix-github-actions,
    phps,
    snowball,
    snowball-data,
    ...
  } @ args:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;

        src' = gitignore.lib.gitignoreSource ./.;

        src = pkgs.lib.cleanSourceWith {
          name = "php-stemmer-source";
          src = src';
          filter = gitignore.lib.gitignoreFilterWith {
            basePath = ./.;
            extraRules = ''
              .clang-format
              .editorconfig
              .envrc
              .gitattributes
              .github
              .gitignore
              *.md
              *.nix
              flake.*
            '';
          };
        };

        makePackage = {
          stdenv ? pkgs.stdenv,
          php ? pkgs.php,
          libstemmer ? pkgs.libstemmer,
          corpusData ? null,
        }:
          pkgs.callPackage ./nix/derivation.nix {
            inherit src stdenv php libstemmer corpusData;
            buildPecl = pkgs.callPackage (nixpkgs + "/pkgs/build-support/php/build-pecl.nix") {
              inherit php stdenv;
            };
          };

        makeCheck = package:
          package.override {
            checkSupport = true;
          };

        php85DebugZts = pkgs.php85.override {
          ztsSupport = true;
          phpAttrsOverrides = final: prev: {
            configureFlags = prev.configureFlags ++ ["--enable-debug"];
          };
        };

        pre-commit-check = git-hooks.lib.${system}.run {
          src = src';
          hooks = {
            actionlint.enable = true;
            alejandra.enable = true;
            alejandra.excludes = ["\/vendor\/"];
            clang-format.enable = true;
            clang-format.types_or = ["c" "c++"];
            clang-format.files = "\\.(c|h)$";
            markdownlint.enable = true;
            markdownlint.excludes = ["LICENSE\.md"];
            markdownlint.settings.configuration = {
              MD013 = {
                line_length = 1488;
                table = false;
              };
            };
            shellcheck.enable = true;
            shellcheck.excludes = ["^\\.envrc$"];
          };
        };

        makeDevShell = package:
          (pkgs.mkShell.override {
            stdenv = package.stdenv;
          }) {
            inputsFrom = [package];
            buildInputs = with pkgs; [
              actionlint
              autoconf-archive
              clang-tools
              lcov
              gdb
              valgrind
            ];
            shellHook = ''
              ${pre-commit-check.shellHook}
              mkdir -p .direnv/include
              unlink .direnv/include/php
              ln -sf ${package.php.unwrapped.dev}/include/php/ .direnv/include/php
              export REPORT_EXIT_STATUS=1
              export NO_INTERACTION=1
              # opcache isn't getting loaded for tests because tests are run with '-n' and nixos doesn't compile
              # in opcache and relies on mkWrapper to load extensions
              export TEST_PHP_ARGS='-c ${package.php.phpIni}'
              # php.unwrapped from the buildDeps is overwriting php
              export PATH="${package.php}/bin:$PATH"
            '';
          };

        matrix = with pkgs; {
          php = {
            php81 = phps.packages.${system}.php81;
            inherit php82 php83 php84 php85;
          };
          stdenv = {
            gcc = stdenv;
            clang = clangStdenv;
            musl = pkgsMusl.stdenv;
          };
        };

        buildConfs = lib.cartesianProduct {
          php = builtins.attrNames matrix.php;
          stdenv = [
            "gcc"
            "clang"
            # The extension build does not currently support musl.
            # "musl"
          ];
        };

        buildFn = {
          php,
          stdenv,
        }:
          lib.nameValuePair
          (lib.concatStringsSep "-" (lib.filter (v: v != "") [
            "${php}"
            "${stdenv}"
          ]))
          (
            makePackage {
              php = matrix.php.${php};
              stdenv = matrix.stdenv.${stdenv};
            }
          );

        packages' = builtins.listToAttrs (builtins.map buildFn buildConfs);
        packages =
          packages'
          // {
            php85-debug-zts = makePackage {
              php = php85DebugZts;
              stdenv = matrix.stdenv.gcc;
            };
            corpus = makePackage {
              php = matrix.php.php85;
              stdenv = matrix.stdenv.gcc;
              libstemmer = pkgs.libstemmer.overrideAttrs {
                version = "2.2.0";
                src = snowball;
              };
              corpusData = snowball-data;
            };
            default = packages.php85-gcc;
          };
      in {
        inherit packages;

        devShells = builtins.mapAttrs (name: package: makeDevShell package) packages;

        checks =
          {inherit pre-commit-check;}
          // (builtins.mapAttrs (name: package: makeCheck package) packages);

        formatter = pkgs.alejandra;
      }
    )
    // {
      githubActions.matrix.include = let
        cleanFn = v:
          v
          // {
            attr = builtins.replaceStrings ["\""] [""] v.attr;
            name = builtins.replaceStrings ["githubActions." "checks." "x86_64-linux." "\""] ["" "" "" ""] v.attr;
          };
      in
        builtins.filter (entry: entry.name != "default")
        (builtins.map cleanFn
          (nix-github-actions.lib.mkGithubMatrix {
            attrPrefix = "checks";
            checks = nixpkgs.lib.getAttrs ["x86_64-linux"] self.checks;
          })
          .matrix
          .include);
    };
}
