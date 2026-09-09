<?php

// Run with the extracted release extension and a PHP installation outside Nix.
$minor = $argv[1];
$zts = $argv[2] === 'ts';
$family = $argv[3];
preg_match('/#define PHP_STEMMER_VERSION "([^"]+)"/', file_get_contents(__DIR__ . '/../../php_stemmer.h'), $version);
if (PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION !== $minor
    || (bool) PHP_ZTS !== $zts || PHP_DEBUG || PHP_INT_SIZE !== 8
    || PHP_OS_FAMILY !== $family || phpversion('stemmer') !== $version[1]) {
    fwrite(STDERR, "Release binary does not match the requested PHP configuration\n");
    exit(1);
}
if (stemmer_stem_word('running', 'english', 'UTF_8') !== 'run'
    || count(stemmer_languages()) !== 29) {
    fwrite(STDERR, "Release binary failed the stemming smoke test\n");
    exit(1);
}
