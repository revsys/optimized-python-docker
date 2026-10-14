# vim: ft=just ts=4 sw=4
set dotenv-load := false

PLATFORMS := env_var_or_default('PY_PLATFORMS', 'linux/amd64,linux/arm64,linux/arm/v8')
REGISTRY := 'revolutionsystems/python:'
CACHE := 'registry.revsys.com/python:'
PYVER := env_var('PYTHON_VERSION')
TARGETS := env_var_or_default('TARGETS', 'linux/amd64,linux/arm64,linux/arm/v8,linux/arm/v7')

# all this to turn 3.11.something into 3.11
PYMIN := replace(parent_directory(replace(PYVER, '.', '/')), '/', '.') 
CACHE_TAG := CACHE + PYMIN + '-cache'

__TAG := REGISTRY + PYVER + '-wee'
_TAG := __TAG + if env_var_or_default('LTO', '') != '' { '-lto' } else { '' }
TAG := _TAG + if env_var_or_default('OPTIMAL', '') != '' { '-optimized' } else { '' }

___BA := '--build-arg=BUILD_ARGS="'
__BA := ___BA + if env_var_or_default('LTO', '') != '' { '--with-lto '} else { '' }
_BA := __BA + if env_var_or_default('OPTIMAL', '') != '' { '--with-optimizations'} else { '' }
BUILD_ARGS := _BA + '"'


test:
	#!/usr/bin/env bash
	set +o xtrace verbose
	echo Targets: {{TARGETS}}
	echo Pymin: {{PYMIN}}
	echo Tag: {{TAG}}
	echo Cache Tag: {{CACHE_TAG}}
	echo Build Args: "{{BUILD_ARGS}}"

_list:
	@just --list --unsorted


# build image stage
build step='release' targets=TARGETS aux='':
	#!/usr/bin/env bash
	set -xo pipefail
	echo "step={{ step }}"

	if [[ "{{ step }}" == "release" ]];
	then
		just build post-build
		tag={{TAG}} 
		cacheTo="--cache-to=type=registry,ref={{CACHE_TAG}}-latest,mode=max"
		cacheFrom="--cache-from=type=registry,ref={{CACHE_TAG}}-latest"
	else
		tag={{TAG}}-{{ step }}
		cacheTo="--cache-to=type=registry,ref={{CACHE_TAG}}-{{step}},mode=max"
		cacheFrom="--cache-from=type=registry,ref={{CACHE_TAG}}-{{step}}"
	fi


	if [[ "{{aux}}" == 'load' ]];
	then
		aux='--load' && platforms = '' 
		platforms=''
	else
		platforms='--platform {{targets}}'
	fi

	docker buildx build \
		--build-arg=PYTHON_VERSION={{PYVER}} \
		{{BUILD_ARGS}} \
		--progress plain \
		-t ${tag} \
		--target {{step}} .

# docker exec to running "step" container
exec step='tester':
	#!/usr/bin/env bash
	DOCKER_HOST=
	docker exec -it runner-{{step}} /bin/sh

push step: (build step TARGETS "--push")
	@echo "pushing {{PYVER}} {{step}} to registry"


# build and push, then deploy to your current kubernetes/kubectl context
go:
	#!/usr/bin/env bash
	just build release &&
	just push release &&
	pushd tf &&
	terraform apply -auto-approve -var imageRepo=$REGISTRY || just helm


# move image to system docker
_drop step='tester':
	#!/usr/bin/env bash
	ITAG="${REGISTRY}:${IVERSION}-{{step}}"
	docker save ${ITAG} | DOCKER_HOST= docker load



# delete/untag project image
_rmi step='tester':
	docker rmi $REGISTRY:{{TAG}}-{{step}} 2> /dev/null || docker rmi $REGISTRY:{{TAG}}


version:
	@echo {{TAG}}

tag:
	@echo $REGISTRY:{{TAG}}

# bump2version
bv level='patch':
	bumpversion {{level}}


# dispose of terraform state files
clean:
	@rm -rfv tf/*tfstate*

# setup buildkit runner
@buildkit-up:
    #!/bin/bash
    set -o pipefail
    [[ -n $( docker buildx ls | grep 'default.*docker' ) ]] &&
        docker buildx create --platform linux/amd64 --bootstrap --name nuremberg-builder >& /dev/null
        docker buildx use nuremberg-builder

# take down buildkit runner & configure local docker for default builds
@buildkit-down:
    docker buildx use default
    docker buildx stop nuremberg-builder

