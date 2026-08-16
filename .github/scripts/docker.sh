#!/usr/bin/env bash

set -euxo pipefail

: "${DOCKER_NAME:?set DOCKER_NAME to debian or fedora}"

export TEST_PHP_EXECUTABLE="${TEST_PHP_EXECUTABLE:-"/usr/local/bin/php"}"
export RUN_TESTS_PHP="${RUN_TESTS_PHP:-"/usr/local/lib/php/build/run-tests.php"}"
# The image must already be built and loaded before this test runner is called.
export IMAGE_TAG="${IMAGE_TAG:-"php-stemmer-${DOCKER_NAME}"}"

catch() {
    find tests -name '*.log' -print0 | xargs -0 -r -n1 cat
}

trap catch ERR

docker run \
    --env NO_INTERACTION=1 \
    --env REPORT_EXIT_STATUS=1 \
    --env "TEST_PHP_EXECUTABLE=${TEST_PHP_EXECUTABLE}" \
    -v "${PWD}/tests:/mnt" \
    "${IMAGE_TAG}" \
    php "${RUN_TESTS_PHP}" /mnt
