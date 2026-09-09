# php-stemmer

[![ci](https://github.com/jbboehr/php-stemmer/actions/workflows/ci.yml/badge.svg)](https://github.com/jbboehr/php-stemmer/actions/workflows/ci.yml)
[![Codecov](https://codecov.io/gh/jbboehr/php-stemmer/graph/badge.svg?token=DSLDXIWHC5)](https://codecov.io/gh/jbboehr/php-stemmer)
[![Coveralls](https://coveralls.io/repos/github/jbboehr/php-stemmer/badge.svg?branch=master)](https://coveralls.io/github/jbboehr/php-stemmer?branch=master)

This PHP extension provides stemming for a variety of languages through
Dr. M.F. Porter's Snowball API. It uses Snowball's `libstemmer` library and
offers a small API for discovering languages and stemming words.

This is a maintained version of the original
[php-stemmer](https://code.google.com/p/php-stemmer/) project. The extension's
functions use a `stemmer_` prefix.

## Requirements

- PHP 8.1 through PHP 8.5
- Source builds also need a C compiler, PHP development tools, and the
  development files for the system `libstemmer` library

Prebuilt PIE downloads include statically linked Snowball 2.2.0. For source
builds, the available languages and algorithms depend on the system
`libstemmer` version.

## Installation

### PIE

Install the extension with [PIE](https://github.com/php/pie):

```bash
pie install jbboehr/php-stemmer
```

The prebuilt download targets are non-debug PHP 8.1–8.5: x64 Linux (glibc or
musl) and arm64 macOS with NTS, and x64 Windows with NTS or ZTS. When available for the
selected release, these downloads do not require a system `libstemmer` installation.

On Unix, PIE falls back to a source build when no matching binary is available.
Install the source-build requirements first; PIE does not install the system
`libstemmer` dependency automatically:

```bash
# Debian or Ubuntu
sudo apt-get install libstemmer-dev

# Fedora
sudo dnf install libstemmer-devel
```

### Manual build on Ubuntu

```bash
sudo apt-get install libstemmer-dev
git clone https://github.com/jbboehr/php-stemmer.git
cd php-stemmer
phpize
./configure
make
make test
sudo make install
```

Enable the extension in the relevant `php.ini` or `conf.d` file:

```ini
extension=stemmer.so
```

## API

```php
stemmer_languages(): array
stemmer_stem_word(mixed $arg, string $lang, string $enc): array|string|null
```

`stemmer_languages()` returns the language names supported by the installed
`libstemmer`. `stemmer_stem_word()` accepts either one value or an array. When
given an array, it preserves input order but returns a list with sequential
integer keys, stems string values, and returns `null` for non-string entries.
Non-array values are converted to strings using PHP's normal conversion rules.
The function returns `null` when the requested language or encoding is not
available.

## Usage

```php
$languages = stemmer_languages();
$word = stemmer_stem_word('cats', 'english', 'UTF_8');
$words = stemmer_stem_word(['cats', 'stemming'], 'english', 'UTF_8');

var_dump($languages, $word, $words);
```

## Nix Development

The default development shell and package use PHP 8.5 with GCC:

```bash
nix develop
phpize
./configure
make
make test
```

Development shells and packages are also available for every supported PHP
version with GCC or Clang. For example:

```bash
nix develop .#php81-clang
nix build -L .#php85-gcc
```

PHP 8.1 is supplied by
[nix-phps](https://github.com/fossar/nix-phps); newer versions come from
Nixpkgs.

## Testing

Run the extension's PHPT suite after building it:

```bash
make test
```

Run the full Snowball 2.2.0 compatibility corpus locally with Nix:

```bash
nix build -L .#corpus
```

This checks about 11 million words using PHP 8.5 and the matching pinned
versions of `libstemmer` and `snowball-data`. The corpus is also a dedicated
entry in the generated Nix CI matrix.

Without Nix, build the extension against `libstemmer` 2.2.0, check out the
matching corpus revision, and pass its path to the regular test command:

```bash
git clone https://github.com/snowballstem/snowball-data.git /path/to/snowball-data
git -C /path/to/snowball-data checkout 0703f1d6a21802c3ff00c2c8b31bd255b74b2aec
STEMMER_CORPUS_DIR=/path/to/snowball-data make test
```

`make test` skips the corpus when `STEMMER_CORPUS_DIR` is not set.

Run the formatting, linting, and complete Nix build matrix with:

```bash
nix flake check -L
```

CI additionally builds and tests the Debian images for PHP 8.1 through 8.5
and a Fedora image.

To reproduce a Debian Docker job locally, build and load the image before
running the test helper:

```bash
docker build \
    --build-arg PHP_VERSION=8.5 \
    --file .github/php-debian.Dockerfile \
    --tag php-stemmer-debian \
    .
DOCKER_NAME=debian .github/scripts/docker.sh
```

## License

This project is licensed under the
[New BSD License](https://opensource.org/license/bsd-3-clause).
