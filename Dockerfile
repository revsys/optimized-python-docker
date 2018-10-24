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

FROM gcr.io/google-containers/debian-base-amd64:0.4.0 as runtime

ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.

ENV LANG C.UTF-8

COPY ./init-functions /lib/lsb/

RUN set -ex \
    && apt update \
    && apt-mark unhold apt gnupg libcap2 libsemanage1 passwd  libbz2-1.0 \
    && runDeps='curl gnupg libsqlite3-0 zlib1g libexpat1 bash tcpdump procps less binutils libbz2-1.0 netcat-openbsd git' \
    && apt-get -qq update; apt-get install -y $runDeps \
    && find /usr -type f -name "*.so" -exec strip --strip-unneeded {} + \
    && apt-get remove binutils --purge -y -qq \
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
FROM runtime as build-setup

ADD gnupg/pubring.gpg gnupg/trustdb.gpg /root/.gnupg/

RUN set -ex \
    && mkdir -p /root/.gnupg \
    && chmod 700 /root/.gnupg \
    && buildDeps='libsqlite3-dev zlib1g-dev libexpat1-dev libssl-dev xz-utils dpkg-dev binutils libbz2-dev libreadline-dev libffi-dev' \
    && apt-get -qq update; apt-get -qq -y install ${buildDeps}

ARG PYTHON_VERSION

RUN    curl -L -o /python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
    && curl -L -o /python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
    && gpg --keyserver ha.pool.sks-keyservers.net --refresh-keys 2>&1 | egrep -v 'requesting key|not changed' \
    && gpg --batch --verify /python.tar.xz.asc /python.tar.xz \
    && mkdir -p /usr/src/python \
    && tar -xJC /usr/src/python --strip-components=1 -f /python.tar.xz


LABEL stage BUILD-SETUP
LABEL version ${PYTHON_VERSION}

###############################################################################
FROM build-setup as builder

ARG BUILD_ARGS
ARG PYTHON_VERSION
ENV LANG C.UTF-8

#RUN sleep 6000 || echo "whee"

ENV CFLAGS -I/usr/include/openssl

RUN set -ex \
    && cd /usr/src/python \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && [ $(( ` echo $PYTHON_VERSION | cut -d"." -f1 ` )) -lt 3 ] && BUILD_ARGS="" \
    ; ./configure \
        --build="$gnuArch" \
        --enable-loadable-sqlite-extensions \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
        --without-ensurepip ${BUILD_ARGS} \
    && make -j $(( 1 * $( egrep '^processor[[:space:]]+:' /proc/cpuinfo | wc -l ) )) \
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
ENV PYTHON_PIP_VERSION 18.1


COPY ./ipython_config.py /

RUN set -ex; ldconfig
RUN set -ex; curl -sL -o get-pip.py 'https://bootstrap.pypa.io/get-pip.py';
RUN set -ex; python get-pip.py \
                --disable-pip-version-check \
                --no-cache-dir \
                "pip==$PYTHON_PIP_VERSION"; pip --version


RUN set -ex; pip install pipenv --upgrade

RUN mkdir -p $HOME/.ipython/profile_default ;
RUN mv ipython_config.py $HOME/.ipython/profile_default/. ;
RUN pip install 'ipython<6' ipdb

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
FROM runtime

COPY --from=post-build /usr/local /usr/local
COPY --from=post-build /root /root
RUN /sbin/ldconfig

LABEL stage FINAL
ARG PYTHON_VERSION
LABEL version ${PYTHON_VERSION}

CMD ["ipython"]
