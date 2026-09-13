<?php

// Use the pinned PIE consumer's rules, with target metadata for cross builds.
use Php\Pie\Platform as P;

require 'phar://' . $argv[1] . '/vendor/autoload.php';

$source = $argv[2];
$archive = $argv[3];
$ci = json_decode($argv[4], true, flags: JSON_THROW_ON_ERROR);
preg_match('/#define PHP_STEMMER_VERSION "([^"]+)"/', file_get_contents("$source/php_stemmer.h"), $version);
$metadata = json_decode(file_get_contents("$source/composer.json"), true, flags: JSON_THROW_ON_ERROR);
$metadata['version'] = 'v' . $version[1]; // Release tags and Packagist retain this prefix.
$package = Php\Pie\DependencyResolver\Package::fromComposerCompletePackage(
    (new Composer\Package\Loader\ArrayLoader())->load($metadata)
);
$windows = str_starts_with($ci['platform'], 'windows-');
$darwin = $ci['platform'] === 'darwin';
$binary = new class ($ci['php']) extends P\TargetPhp\PhpBinaryPath {
    public function __construct(private string $minor) {}
    public function majorMinorVersion(): string { return $this->minor; }
    public function debugMode(): P\DebugBuild { return P\DebugBuild::NoDebug; }
};
$target = new class (
    $windows ? P\OperatingSystem::Windows : P\OperatingSystem::NonWindows,
    $windows ? P\OperatingSystemFamily::Windows : ($darwin ? P\OperatingSystemFamily::Darwin : P\OperatingSystemFamily::Linux),
    $binary,
    $darwin ? P\Architecture::arm64 : P\Architecture::x86_64,
    $ci['ts'] === 'ts' ? P\ThreadSafetyMode::ThreadSafe : P\ThreadSafetyMode::NonThreadSafe,
    1,
    $windows ? constant(P\WindowsCompiler::class . '::' . strtoupper($ci['compiler'])) : null,
    null,
) extends P\TargetPlatform {
    public P\LibcFlavour $libc;
    public function libcFlavour(): P\LibcFlavour { return $this->libc; }
};
$target->libc = $darwin ? P\LibcFlavour::Bsd : ($ci['platform'] === 'linux-musl' ? P\LibcFlavour::Musl : P\LibcFlavour::Gnu);
$names = $windows
    ? P\WindowsExtensionAssetName::zipNames($target, $package)
    : P\PrePackagedBinaryAssetName::packageNames($target, $package);
if (!in_array(basename($archive), $names, true)) {
    throw new RuntimeException('PIE cannot select ' . basename($archive) . '; expected: ' . implode(', ', $names));
}
$zip = new ZipArchive();
if ($zip->open($archive) !== true) {
    throw new RuntimeException("Cannot open $archive");
}
$members = $windows ? P\WindowsExtensionAssetName::dllNames($target, $package) : ['stemmer.so'];
foreach ($members as $member) {
    if ($zip->locateName($member) !== false) {
        echo 'PIE accepts ', basename($archive), ' containing ', $member, PHP_EOL;
        exit(0);
    }
}
throw new RuntimeException('PIE cannot find the extension in ' . basename($archive) . '; expected: ' . implode(', ', $members));
