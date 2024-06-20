#!/usr/bin/env bash

set -ex -o pipefail

# config
export PHP_VERSION="${PHP_VERSION:-"8.1"}"
export TEST_PHP_EXECUTABLE="${TEST_PHP_EXECUTABLE:-"/usr/local/bin/php"}"
export RUN_TESTS_PHP="${RUN_TESTS_PHP:-"/usr/local/lib/php/build/run-tests.php"}"
export IMAGE_TAG="${IMAGE_TAG:-"php-stemmer-${DOCKER_NAME}"}"

docker build \
    -f ".github/php-${DOCKER_NAME}.Dockerfile" \
    -t "${IMAGE_TAG}" \
    --build-arg "PHP_VERSION=${PHP_VERSION}" \
    .

trap 'catch' ERR

catch() {
  find tests -print0 -name '*.log'  | xargs -0 -n1 cat
}

docker run \
    --env NO_INTERACTION=1 \
    --env REPORT_EXIT_STATUS=1 \
    --env "TEST_PHP_EXECUTABLE=${TEST_PHP_EXECUTABLE}" \
    -v "${PWD}/tests:/mnt" \
    "${IMAGE_TAG}" \
    php "${RUN_TESTS_PHP}" /mnt
