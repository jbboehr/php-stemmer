param(
    [string]$Package,
    [ValidateSet('nts', 'ts')][string]$ThreadSafety
)

$ErrorActionPreference = 'Stop'
$archive = Get-ChildItem "$Package/*.zip"
Expand-Archive $archive.FullName -DestinationPath "$Package/extracted"
$dll = (Get-ChildItem "$Package/extracted/*.dll").FullName.Replace('\', '/')
php -n -d "extension=$dll" .github/scripts/check-release.php 8.5 $ThreadSafety Windows
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$env:TEST_PHP_ARGS = "-d extension=$dll"
php -n "$Package/test/run-tests.php" -n -q --show-diff tests/stemmer_arginfo.phpt tests/stemmer_languages.phpt tests/stemmer_phpinfo.phpt tests/stemmer_stem_word.phpt
exit $LASTEXITCODE
