{
  fetchurl,
  runCommand,
  unzip,
  zts,
}: let
  version = "8.5.10";
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
    url = "${baseUrl}/php-devel-pack-${version}${suffix}-Win32-vs17-x64.zip";
    sha256 =
      if zts
      then "0031d279f13f21e81fd62f9a98e919f28b1875ba457916d60daed85586e479dd"
      else "b277dafab9654b23dec28fdebe47385248fdd33bbe8ecdc33b8681ef1b5c7788";
  };
  runtimeArchive = fetchurl {
    url = "${baseUrl}/php-${version}${suffix}-Win32-vs17-x64.zip";
    sha256 =
      if zts
      then "a6bc8b2f3d7bfb397ccb973db2f959e61e530e0986c9cea262dd4a317ec599d8"
      else "22ec430195984d233eb9e62c637a945bbcda06efca2f392d9d96d62c6acd34f8";
  };
in {
  inherit version zts threadSafety;
  importLibrary =
    if zts
    then "php8ts.lib"
    else "php8.lib";
  headers =
    runCommand "php-${version}-${threadSafety}-windows-x64-devel" {
      nativeBuildInputs = [unzip];
    } ''
      unzip -q ${develArchive}
      mv php-${version}-devel-vs17-x64 "$out"
      # Windows tolerates this include's casing; Linux filesystems do not.
      substituteInPlace "$out/include/main/streams/php_stream_transport.h" \
        --replace-fail '<Ws2tcpip.h>' '<ws2tcpip.h>'
    '';
  runtime =
    runCommand "php-${version}-${threadSafety}-windows-x64" {
      nativeBuildInputs = [unzip];
    } ''
      unzip -q ${runtimeArchive} -d "$out"
    '';
}
