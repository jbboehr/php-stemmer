{
  runCommand,
  python3,
  unzip,
  binary,
  filename,
  member,
  src,
  snowball,
  php,
  corpusData,
  ci,
}:
runCommand filename {
  nativeBuildInputs = [python3 unzip];
  passthru.ci =
    ci
    // {
      release = true;
      artifact = "pie-${ci.php}-${ci.platform}";
    };
} ''
  mkdir -p "$out/test"
  # Kept outside the release ZIP; CI uses the same test driver and corpus.
  cp ${php.unwrapped.dev}/lib/build/run-tests.php "$out/test/run-tests.php"
  ln -s ${corpusData} "$out/test/corpus"
  python - "$out/${filename}.zip" <<'PY'
  import sys
  import zipfile
  from pathlib import Path

  with zipfile.ZipFile(sys.argv[1], "w", compression=zipfile.ZIP_DEFLATED) as archive:
      for name, source in sorted({
          "${member}": "${binary}",
          "LICENSE": "${src}/LICENSE",
          "SNOWBALL-LICENSE": "${snowball}/COPYING",
      }.items()):
          entry = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
          entry.create_system = 3
          entry.external_attr = 0o100644 << 16
          entry.compress_type = zipfile.ZIP_DEFLATED
          archive.writestr(entry, Path(source).read_bytes())
  PY
  unzip -t "$out/${filename}.zip"
''
