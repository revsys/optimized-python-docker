.PHONY: image push-image build-image optimal buil-builder

include .version

PYTHON_VERSION ?= 3.6.2

TAG = ${PYTHON_VERSION}-wee

IMAGE_TAG = ${IMAGE}:${TAG}${TAG_SUFFIX}
LATEST = ${IMAGE}:latest


PLATFORMS ?= linux/amd64

TARGETS := --platform ${PLATFORMS}

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


ifndef DOCKERFILE
	DOCKERFILE := ./Dockerfile
endif

TAG_SUFFIX ?=

build-builder: 
	docker buildx build ${PROXY_ARGS} ${TARGETS} --cache-from=type=registry,ref=${LATEST} --cache-to=type=registry,ref=${LATEST},mode=max -f ${DOCKERFILE} --build-arg=PYTHON_VERSION=${PYTHON_VERSION} --build-arg=BUILD_ARGS="${BUILD_ARGS}" --target builder -t ${IMAGE_TAG}  .

build-image: build-builder
	@echo building ${IMAGE_TAG}
	docker buildx build ${PROXY_ARGS} ${TARGETS} --cache-from=type=registry,ref=${LATEST} -f ${DOCKERFILE} --build-arg=PYTHON_VERSION=${PYTHON_VERSION} --build-arg=BUILD_ARGS="${BUILD_ARGS}" --load -t ${IMAGE_TAG} .

push-image:
	@echo pushing ${IMAGE_TAG}
	docker buildx build ${PROXY_ARGS} ${TARGETS} --cache-from=type=registry,ref=${LATEST}  -f ${DOCKERFILE} --build-arg=PYTHON_VERSION=${PYTHON_VERSION} --build-arg=BUILD_ARGS="${BUILD_ARGS}" --push -t ${IMAGE_TAG} .

image: push-image
