
ARG BASE_IMAGE=fedora:latest

# image0
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

# image1
FROM ${BASE_IMAGE}
RUN dnf install php-cli libstemmer -y
# this probably won't work on other arches
COPY --from=0 /usr/lib64/php/modules/stemmer.so /usr/lib64/php/modules/stemmer.so
# please forgive me
COPY --from=0 /usr/lib64/php/build/run-tests.php /usr/local/lib/php/build/run-tests.php
RUN echo extension=stemmer.so | sudo tee /etc/php.d/90-stemmer.ini
