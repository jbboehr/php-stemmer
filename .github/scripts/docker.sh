#!/usr/bin/env bash

set -e -o pipefail
source .github/scripts/fold.sh

# config
export DOCKER_NAME=${DOCKER_NAME:-"alpine"}
export PHP_VERSION=${PHP_VERSION:-"7.4"}
export TEST_PHP_EXECUTABLE=${TEST_PHP_EXECUTABLE:-"/usr/local/bin/php"}
export RUN_TESTS_PHP=${RUN_TESTS_PHP:-"/usr/local/lib/php/build/run-tests.php"}

function docker_build() (
    docker build \
        -f .github/php-${DOCKER_NAME}.Dockerfile \
        -t php-stemmer \
        --build-arg PHP_VERSION=${PHP_VERSION} \
        .
)

function docker_run() (
    set -x
    docker run \
        --env NO_INTERACTION=1 \
        --env REPORT_EXIT_STATUS=1 \
        --env TEST_PHP_EXECUTABLE=${TEST_PHP_EXECUTABLE} \
        -v "$PWD/tests:/mnt" \
        php-stemmer \
        php ${RUN_TESTS_PHP} /mnt
)

function install_apt_packages() (
    ${SUDO} add-apt-repository ppa:ondrej/php
    ${SUDO} apt-get update
    ${SUDO} apt-get install -y php${PHP_VERSION}-dev
)

function generate_tests() (
    php generate_tests.php
)

# cifold "install apt packages" install_apt_packages
# cifold "generate tests" generate_tests
cifold "docker build" docker_build
cifold "docker run" docker_run
