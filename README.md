# php-stemmer

[![ci](https://github.com/jbboehr/php-stemmer/actions/workflows/ci.yml/badge.svg)](https://github.com/jbboehr/php-stemmer/actions/workflows/ci.yml)
[![Codecov](https://codecov.io/gh/jbboehr/php-stemmer/graph/badge.svg?token=DSLDXIWHC5)](https://codecov.io/gh/jbboehr/php-stemmer)
[![Coveralls](https://coveralls.io/repos/github/jbboehr/php-stemmer/badge.svg?branch=master)](https://coveralls.io/github/jbboehr/php-stemmer?branch=master)

This stem extension for PHP provides stemming capability for a variety of
languages using Dr. M.F. Porter's Snowball API. It has a much simpler API
than the stem extension found in pecl.

This is a cleanup of [php-stemmer](https://code.google.com/p/php-stemmer/).
Tests have been added and the bundled libstemmer has been removed. Functions
have been prefixed with the extension name. If you
need features not provided by your system's default version of libstemmer, you
can recompile libstemmer for your particular system.

## Installation

### Ubuntu

```bash
sudo apt-get install libstemmer-dev
git clone https://github.com/jbboehr/php-stemmer.git
cd php-stemmer
phpize
./configure
make
# make test
sudo make install
```

## Usage

```php
echo stemmer_stem_word('cats', 'english', 'UTF_8');  # cat
echo stemmer_stem_word('stemming', 'english', 'UTF_8');  # stem
var_dump(stemmer_languages()); # array(...)
```

## License

This project is licensed under the [New BSD License](http://opensource.org/licenses/BSD-3-Clause).
