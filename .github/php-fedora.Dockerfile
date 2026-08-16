
ARG BASE_IMAGE=fedora:latest

# Build the extension.
FROM ${BASE_IMAGE}
WORKDIR /build

RUN dnf groupinstall 'Development Tools' -y
RUN dnf install \
    git-all \
    gcc \
    automake \
    autoconf \
    libtool \
    php-devel \
    libstemmer-devel \
    -y

WORKDIR /build
ADD . .
RUN phpize
RUN ./configure
RUN make
RUN make install

# Create the runtime image.
FROM ${BASE_IMAGE}
RUN dnf install php-cli libstemmer -y
# Fedora installs PHP extensions in an architecture-specific lib64 directory.
COPY --from=0 /usr/lib64/php/modules/stemmer.so /usr/lib64/php/modules/stemmer.so
COPY --from=0 /usr/lib64/php/build/run-tests.php /usr/local/lib/php/build/run-tests.php
RUN echo extension=stemmer.so > /etc/php.d/90-stemmer.ini
