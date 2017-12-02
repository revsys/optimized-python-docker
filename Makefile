.PHONY: image push-image build-image optimal

include .version

PYTHON_VERSION ?= 3.6.2
FUCKOFF = ${MAJOR_VERSION}

TAG = ${PYTHON_VERSION}-wee

IMAGE_TAG = ${IMAGE}:${TAG}

BUILD_ARGS = 


ifdef PKG_PROXY
	PROXY_ARGS := --build-arg=http_proxy=${PKG_PROXY} --build-arg=https_proxy=${PKG_PROXY}
else
	PROXY_ARGS :=
endif

ifdef PIP_PROXY_HOST
	PIP_PROXY_ARGS := --add-host=pypi.python.org=${PIP_PROXY_HOST}
else
	PIP_PROXY_ARGS :=
endif


ifdef OPTIMAL
	BUILD_ARGS += --enable-optimizations
	TAG := ${TAG}-optimized
endif

ifdef LTO
	BUILD_ARGS += --with-lto
	TAG := ${TAG}-lto
endif


build-image:
	@echo building ${IMAGE_TAG}
	@docker build ${PROXY_ARGS} --build-arg=PYTHON_VERSION=${PYTHON_VERSION} --build-arg=BUILD_ARGS="${BUILD_ARGS}" -t ${IMAGE_TAG} --compress .

push-image:
	@echo pushing ${IMAGE_TAG}
	@docker push ${IMAGE_TAG}

image: build-image push-image
