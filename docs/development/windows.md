# Windows builds with Nix

The Windows targets cross-compile PHP 8.5 x64 extensions from an
`x86_64-linux` host. Both non-thread-safe (NTS) and thread-safe (TS) builds
use the official PHP 8.5.10 development headers and import libraries.

```bash
nix build -L .#php85-windows-nts
nix build -L .#php85-windows-ts
```

Each output contains `php_stemmer.dll` and the extension and Snowball
license notices. Choose the build matching PHP's architecture and thread
safety. The usual Microsoft Visual C++ runtime required by Windows PHP
must be installed on the target machine.

Snowball 2.2.0 is statically linked into the DLL, so a separate libstemmer
DLL is unnecessary. The static library can also be built separately:

```bash
nix build -L .#php85-windows-nts.libstemmer
```

That output contains `lib/libstemmer.lib` and `include/libstemmer.h`.

## Verification

```bash
nix build -L .#checks.x86_64-linux.php85-windows-nts
nix build -L .#checks.x86_64-linux.php85-windows-ts
nix flake check -L
```

Both Windows checks are included in the existing generated GitHub Actions
matrix. They run the PHPT suite under Wine, including the complete pinned
Snowball corpus: 11,019,345 words across 29 languages. A preflight check
requires the expected Windows PHP version, architecture, thread-safety
setting, and loaded extension. A completion marker ensures that the
corpus test cannot silently skip.

Wine uses a fresh prefix inside the Nix build sandbox. Mono, Gecko,
desktop integration, and graphical drivers are disabled. No desktop
display is inherited. The pinned Microsoft runtime DLLs used by Wine are
test dependencies and are not included in the extension output.

These checks exercise Windows PHP under Wine. Native Windows testing,
other PHP versions and architectures, and concurrent requests through a
multithreaded SAPI remain unverified. Composer/PIE Windows installation
support is unchanged; these targets produce DLLs for manual installation.

## Build organization

- `nix/windows/default.nix` assembles the packages and checks. It enables
  Microsoft's SDK license-acceptance setting in the Windows package set
  and allows only the SDK fetcher and SDK as unfree packages. Building
  these targets requires agreement with the
  [Microsoft terms](https://visualstudio.microsoft.com/license-terms/mt644918/).
- `nix/windows/php.nix` pins the Windows PHP development and runtime
  archives. Update their version and all four hashes together.
- `nix/windows/libstemmer.nix` runs a Linux Snowball generator from the
  pinned source, then cross-compiles and archives its C output.
- `nix/windows/extension.nix` compiles the PHP wrapper and links the DLL.
- `nix/windows/check.nix` prepares the headless Wine environment and runs
  the existing tests. Its Microsoft redistributable URL, hash, and cabinet
  selection must be updated together.

The toolchain uses Nixpkgs' `windows.sdk`, which downloads and assembles
the Microsoft headers and libraries with xwin. Clang, `llvm-lib`, and LLD
run on Linux. `/MD` matches PHP's dynamic C runtime; `/Brepro` removes
changing timestamps from the COFF object files. The PHP development
headers receive one include-capitalization adjustment for Linux's case
sensitivity.
