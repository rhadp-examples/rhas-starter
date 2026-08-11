# Default registry and namespace
REGISTRY ?= ghcr.io
NAMESPACE ?= rhadp-examples

# Build tool
CONTAINER_TOOL ?= podman

# Image name and tag
CONTAINER_IMAGE := ghcr.io/rhadp-examples/rhas-starter
TAG ?= latest

# Build arguments
BUILD_ARGS ?= --build-arg TARGETARCH=$(shell uname -m | sed 's/x86_64/amd64/')
PROJECT_DIR := /projects

# AutoSD (RHIVOS) image build
AUTOSD_MANIFEST ?= manifests/auto-app.aib.yml
AUTOSD_IMAGE ?= images/auto-app-autosd.qcow2
AUTOSD_TARGET ?= qemu

JUMPSTARTER_REPO ?= https://github.com/mickume/jumpstarter
JUMPSTARTER_VERSION ?= develop

.PHONY: local-venv build-container

local-venv:
	uv venv --clear venv
	source venv/bin/activate && \
	uv pip install "git+$(JUMPSTARTER_REPO)@$(JUMPSTARTER_VERSION)#subdirectory=python/packages/jumpstarter-all"

build-container:
	$(CONTAINER_TOOL) build $(BUILD_ARGS) \
		-f containers/rhas-starter/Containerfile \
		-t $(CONTAINER_IMAGE):$(TAG) \
		containers/rhas-starter/
