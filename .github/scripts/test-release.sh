#!/usr/bin/env bash
set -euo pipefail

package=$1
minor=$2
platform=$3
release_test_dir=$(mktemp -d)
unzip -q "$package"/*.zip -d "$release_test_dir"
cp "$package/test/run-tests.php" "$release_test_dir/"
# The complete suite and Snowball corpus run in Nix.
mkdir -p "$release_test_dir/tests"
for name in arginfo languages phpinfo stem_word; do
    cp "tests/stemmer_$name.phpt" "$release_test_dir/tests/"
done

if [[ "$platform" == linux-* ]]; then
    image="php:$minor-cli-bookworm"
    [[ "$platform" != linux-musl ]] || image="php:$minor-cli-alpine"
    docker run --rm --platform linux/amd64 \
        -v "$PWD:/source:ro" -v "$release_test_dir:/extension" \
        -e NO_INTERACTION=1 -e REPORT_EXIT_STATUS=1 \
        -e TEST_PHP_ARGS='-d extension=/extension/stemmer.so' \
        "$image" sh -ec '
            php -n -d extension=/extension/stemmer.so /source/.github/scripts/check-release.php "$1" nts Linux
            cd /extension
            php -n run-tests.php -n -q --show-diff tests
        ' sh "$minor"
else
    php -n -d "extension=$release_test_dir/stemmer.so" .github/scripts/check-release.php "$minor" nts Darwin
    export NO_INTERACTION=1 REPORT_EXIT_STATUS=1
    export TEST_PHP_ARGS="-d extension=$release_test_dir/stemmer.so"
    cd "$release_test_dir"
    php -n run-tests.php -n -q --show-diff tests
fi
