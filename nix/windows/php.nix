{
  fetchurl,
  runCommand,
  unzip,
  zts,
  minor ? "8.5",
}: let
  release = (builtins.fromJSON (builtins.readFile ./php-versions.json)).${minor};
  inherit (release) version compiler;
  threadSafety =
    if zts
    then "ts"
    else "nts";
  suffix =
    if zts
    then ""
    else "-nts";
  baseUrl = "https://downloads.php.net/~windows/releases/archives";
  develArchive = fetchurl {
    url = "${baseUrl}/php-devel-pack-${version}${suffix}-Win32-${compiler}-x64.zip";
    sha256 = release.${threadSafety}.devel;
  };
  runtimeArchive = fetchurl {
    url = "${baseUrl}/php-${version}${suffix}-Win32-${compiler}-x64.zip";
    sha256 = release.${threadSafety}.runtime;
  };
in {
  inherit version compiler minor zts threadSafety;
  importLibrary =
    if zts
    then "php8ts.lib"
    else "php8.lib";
  headers =
    runCommand "php-${version}-${threadSafety}-windows-x64-devel" {
      nativeBuildInputs = [unzip];
    } ''
      unzip -q ${develArchive}
      mv php-${version}-devel-${compiler}-x64 "$out"
      # Windows tolerates this include's casing; Linux filesystems do not.
      substituteInPlace "$out/include/main/streams/php_stream_transport.h" \
        --replace-fail '<Ws2tcpip.h>' '<ws2tcpip.h>'
      # Older headers predate clang-cl's vectorcall support. Match the ABI of
      # the official MSVC runtime without changing unrelated compiler guards.
      substituteInPlace "$out/include/Zend/zend_portability.h" \
        --replace-quiet '#elif defined(_MSC_VER) && _MSC_VER >= 1800 && !defined(__clang__)' \
                        '#elif defined(_MSC_VER) && _MSC_VER >= 1800'
    '';
  runtime =
    runCommand "php-${version}-${threadSafety}-windows-x64" {
      nativeBuildInputs = [unzip];
    } ''
      unzip -q ${runtimeArchive} -d "$out"
    '';
}
