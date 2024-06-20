
ARG PHP_VERSION=8.1
ARG PHP_TYPE=bookworm
ARG BASE_IMAGE=php:$PHP_VERSION-cli-$PHP_TYPE

# image0
FROM ${BASE_IMAGE}
ENV DEV_PACKAGES="libstemmer-dev"
WORKDIR /build
RUN apt-get update && apt-get install -y ${DEV_PACKAGES}
ADD . .
RUN phpize
RUN ./configure
RUN make
RUN make install

# image1
FROM ${BASE_IMAGE}
ENV BIN_PACKAGES="libstemmer0d"
RUN apt-get update && apt-get install -y ${BIN_PACKAGES}
COPY --from=0 /usr/local/lib/php/extensions /usr/local/lib/php/extensions
RUN docker-php-ext-enable stemmer
ENTRYPOINT ["docker-php-entrypoint"]
