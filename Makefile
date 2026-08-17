# Default registry and namespace
REGISTRY ?= ghcr.io
NAMESPACE ?= rhadp-examples

# Build tool
CONTAINER_TOOL ?= podman

# Image name and tag
STARTER_CONTAINER_IMAGE := ghcr.io/rhadp-examples/rhas-starter
EXPORTER_CONTAINER_IMAGE := ghcr.io/rhadp-examples/rhas-exporter
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

.PHONY: local-venv build-starter-container build-exporter-container

local-venv:
	uv venv --clear venv
	source venv/bin/activate && \
	uv pip install "git+$(JUMPSTARTER_REPO)@$(JUMPSTARTER_VERSION)#subdirectory=python/packages/jumpstarter-all" && \
	uv pip install packages/rhas-driver-qemu

build-starter-container:
	$(CONTAINER_TOOL) build $(BUILD_ARGS) \
		-f containers/rhas-starter/Containerfile \
		-t $(STARTER_CONTAINER_IMAGE):$(TAG) \
		containers/rhas-starter/

build-exporter-container:
	$(CONTAINER_TOOL) build $(BUILD_ARGS) \
		-f containers/rhas-exporter/Containerfile \
		-t $(EXPORTER_CONTAINER_IMAGE):$(TAG) \
		.