# v2.0.2

This release fixes PIE installation of the prebuilt binaries published in 2.0.1.

- Preserve the `v` version prefix in release archive names and in the DLL names
  inside Windows archives, matching PIE's lookup of the `v2.0.2` release.
- Fix binary installation on Windows x64, for both NTS and ZTS PHP 8.1–8.5.
- Fix binary selection on Linux x64 (glibc and musl) and macOS arm64, preventing
  an unnecessary fallback to a source build for NTS PHP 8.1–8.5.
- Validate archive and DLL names against PIE's own rules during Nix builds.

The stemming API and bundled Snowball 2.2.0 library are unchanged.
