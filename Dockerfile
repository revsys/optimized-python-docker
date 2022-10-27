# vim: ft=Dockerfile ts=4 sw=4 expandtab
###############################################################################
#
# Multi-stage Python 3.x build
#
# build-time environment variables:
#   LTO=1                   . enable link-time-optimizations
#   OPTIMAL=1               . enable profile-guided-optimizations (PGO)
#   PYTHON_VERSION=3.5.3
#
#   ** NOTE **:
#       . LTO requires PGO
#       . ensure both variables are unset for typical builds
#
# building:
#   make build-image        . run docker build
#   make build-push         . push image to repository
#   make image              . build + push
#
# Stages:
#    runtime <- debian-base-amd64:0.2
#       common runtime packages go here
#    build-setup <- runtime
#       dev packages, tools, utilities, etc. go here
#    builder <- build-setup
#       ./configure <things> && make && make install
#    post-build <- builder
#       install any common python modules here
#    FINAL <- runtime
#       pip package installation goes here + ENTRYPOINT
#
###############################################################################

#FROM gcr.io/google-containers/debian-base-amd64:v2.0.0 as runtime
FROM debian:buster-slim as base

ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.

ENV LANG C.UTF-8

COPY ./init-functions /lib/lsb/

RUN set -ex \
    && apt update \
    && apt -y upgrade \
    && apt-mark unhold apt libcap2 libsemanage1 passwd  \
    && apt-get install --no-install-recommends -qq -y libsqlite3-0 zlib1g libexpat1 bash procps less libbz2-1.0 netcat-openbsd git binutils \
    && find /usr -type f -name "*.so" -exec strip --strip-unneeded {} + \
    && apt-get remove -qq --allow-remove-essential --purge -y -qq \
        binutils e2fsprogs e2fslibs libx11-6 libx11-data \
    && find /var/lib/apt/lists \
            /usr/share/man \
            /usr/share/doc \
            /var/log \
            -type f -exec rm -f {} + \
    && rm -rf /root/.gnupg \
    && mkdir -p /root/.gnupg \
    && chmod 700 /root/.gnupg

LABEL stage RUNTIME

###############################################################################
FROM scratch as runtime

COPY --from=base / /

###############################################################################
FROM alpine as source-download

ARG PYTHON_VERSION

ENV SRCDIR /python
RUN apk add curl
RUN mkdir -p /python /build \
    && tar -xJC ${SRCDIR} --strip-components=1 -f <( curl -sL "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz" ) 


###############################################################################
FROM runtime as build-setup

WORKDIR /python

ARG PYTHON_VERSION

RUN apt-get update
RUN apt-get -y install --no-install-recommends \ 
           libsqlite3-dev zlib1g-dev libexpat1-dev \
           libssl-dev xz-utils dpkg-dev binutils libbz2-dev \
           libreadline-dev libffi-dev libncurses5 \
           libncurses5-dev libncursesw5 openssl  \
           gcc g++ make autoconf libtool  \
           dpkg-dev

# COPY --from=source-download /${PYTHON_VERSION} /python


LABEL stage BUILD-SETUP

###############################################################################
FROM build-setup as builder

ARG BUILD_ARGS
ARG PYTHON_VERSION
ENV LANG C.UTF-8

ENV CFLAGS -I/usr/include/openssl

WORKDIR /build

RUN --mount=type=bind,from=source-download,target=/python,source=/python \
    --mount=type=cache,target=/tmp \
    --mount=type=cache,target=/var/tmp \
    --mount=type=cache,target=/var/log \
    --mount=type=cache,target=/root \
    set -ex \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && [ $(( ` echo $PYTHON_VERSION | cut -d"." -f1 ` )) -lt 3 ] && BUILD_ARGS="" \
    ; ../python/configure \
        --build="$gnuArch" \
        --enable-loadable-sqlite-extensions \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
        --without-ensurepip ${BUILD_ARGS} 

RUN --mount=type=bind,from=source-download,target=/python,source=/python \
    --mount=type=cache,target=/tmp \
    --mount=type=cache,target=/var/tmp \
    --mount=type=cache,target=/var/log \
    --mount=type=cache,target=/root \
    make -j $(( 1 * $( egrep '^processor[[:space:]]+:' /proc/cpuinfo | wc -l ) )) \
    && make install

RUN set -ex \
        find /usr/local -type f -name "*.so" -exec strip --strip-unneeded {} + \
    &   ldconfig \
    &   find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests -o -name __pycache__ \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
            -o \
            \( -name "idle*" \) \
        \) -exec rm -rf '{}' +  \
    &&  find /var/lib/apt/lists \
             /usr/share/man \
             /usr/share/doc \
             /var/log \
             -type f -exec rm -f {} +

# make some useful symlinks that are expected to exist
RUN ["/bin/bash", "-c", "if [[ $( echo ${PYTHON_VERSION} | cut -d'.' -f1 ) == '3' ]]; then cd /usr/local/bin && ln -sf pydoc3 pydoc && ln -sf python3 python && ln -sf python3-config python-config;  fi"]

LABEL stage BUILDER
LABEL version ${PYTHON_VERSION}

###############################################################################
FROM builder as post-build

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 19.1.1


ADD https://bootstrap.pypa.io/get-pip.py .

RUN set -ex; ldconfig
RUN set -ex; python get-pip.py \
                --disable-pip-version-check \
                --no-cache-dir; \
                pip --version
                # "pip==$PYTHON_PIP_VERSION";


RUN set -ex;  \
    find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests -o -name __pycache__ \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name '*.exe' \) \) \
        \) -exec rm -rf '{}' +;

RUN set -ex; \
    find /usr/share/
RUN rm -rf /root/.cache

ARG PYTHON_VERSION
LABEL stage POST-BUILD
LABEL version ${PYTHON_VERSION}

###############################################################################
FROM runtime as final

COPY --from=post-build /usr/local /usr/local
COPY --from=post-build /root/* /root/
RUN /sbin/ldconfig

LABEL stage FINAL
ARG PYTHON_VERSION
LABEL version ${PYTHON_VERSION}

CMD ["python"]
