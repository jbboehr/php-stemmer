#!/usr/bin/env bash
set -euo pipefail

package=$1
minor=$2
platform=$3
release_test_dir=$(mktemp -d)
unzip -q "$package"/*.zip -d "$release_test_dir"
cp "$package/test/run-tests.php" "$release_test_dir/"

if [[ "$platform" == linux-* ]]; then
    image="php:$minor-cli-bookworm"
    [[ "$platform" != linux-musl ]] || image="php:$minor-cli-alpine"
    docker run --rm --platform linux/amd64 \
        -v "$PWD:/source:ro" -v "$release_test_dir:/extension" \
        -v "$(realpath "$package/test/corpus"):/corpus:ro" \
        -e STEMMER_CORPUS_DIR=/corpus -e STEMMER_CORPUS_MARKER=/extension/corpus-passed \
        -e NO_INTERACTION=1 -e REPORT_EXIT_STATUS=1 -e TEST_TIMEOUT=600 \
        -e TEST_PHP_ARGS='-d extension=/extension/stemmer.so' \
        "$image" sh -ec '
            php -n -d extension=/extension/stemmer.so /source/.github/scripts/check-release.php "$1" nts Linux
            cp -r /source/tests /extension/tests
            cd /extension
            php -n run-tests.php -n -q --show-diff tests
            test -f corpus-passed
        ' sh "$minor"
else
    php -n -d "extension=$release_test_dir/stemmer.so" .github/scripts/check-release.php "$minor" nts Darwin
    cp -r tests "$release_test_dir/"
    export STEMMER_CORPUS_DIR
    STEMMER_CORPUS_DIR=$(realpath "$package/test/corpus")
    export STEMMER_CORPUS_MARKER="$release_test_dir/corpus-passed"
    export NO_INTERACTION=1 REPORT_EXIT_STATUS=1 TEST_TIMEOUT=600
    export TEST_PHP_ARGS="-d extension=$release_test_dir/stemmer.so"
    cd "$release_test_dir"
    php -n run-tests.php -n -q --show-diff tests
    test -f corpus-passed
fi
