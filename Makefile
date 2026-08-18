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

# auto-app version and build metadata
VERSION ?= 0.1
GIT_REV := $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)

# AutoSD (RHIVOS) image build
AUTOSD_MANIFEST ?= manifests/auto-app.aib.yml
AUTOSD_IMAGE ?= images/auto-app-autosd.qcow2
AUTOSD_TARGET ?= qemu

# Fork of Jumstarter with some patches not yet on upstream
JUMPSTARTER_REPO ?= https://github.com/mickume/jumpstarter
JUMPSTARTER_VERSION ?= develop

# Custom jumpstarter drivers used for this demo
RHAS_STARTER_REPO ?= https://github.com/rhadp-examples/rhas-starter
RHAS_STARTER_VERSION ?= main

.PHONY: clean local-venv build-local build-rpm-local build-starter-container build-exporter-container

clean:
	rm -rf src/build src/CMakeCache.txt src/cmake_install.cmake src/CMakeFiles src/auto-app
	rm -f bin/*.rpm bin/*.tar.gz bin/auto-app src/Makefile src/*.tar.gz src/*.rpm
	rm -rf bin/repodata
	rm -f images/*.qcow2

local-venv:
	uv venv --clear venv
	source venv/bin/activate && \
	uv pip install "git+$(JUMPSTARTER_REPO)@$(JUMPSTARTER_VERSION)#subdirectory=python/packages/jumpstarter-all" && \
	uv pip install \
		"git+$(RHAS_STARTER_REPO)@$(RHAS_STARTER_VERSION)#subdirectory=packages/rhas-driver-qemu" \
		"git+$(RHAS_STARTER_REPO)@$(RHAS_STARTER_VERSION)#subdirectory=packages/rhas-driver-opendal" \
		"git+$(RHAS_STARTER_REPO)@$(RHAS_STARTER_VERSION)#subdirectory=packages/rhas-driver-power"

build-local: clean
	cmake -B src/build src -DAPP_VERSION=$(VERSION) -DAPP_GIT_REV=$(GIT_REV)
	cmake --build src/build
	cp src/build/auto-app bin/

build-rpm-local: clean
	cd /tmp && \
	  NAME=auto-app && \
	  VERSION=$(VERSION) && \
	  RPMBUILD=/tmp/rpmbuild && \
	  cp -r $(CURDIR)/src $${NAME}-$${VERSION} && \
	  tar czf $${NAME}-$${VERSION}.tar.gz $${NAME}-$${VERSION} && \
	  mkdir -p $${RPMBUILD}/{SOURCES,SPECS} && \
	  cp $${NAME}-$${VERSION}.tar.gz $${RPMBUILD}/SOURCES/ && \
	  cp $${NAME}-$${VERSION}/auto-app.spec $${RPMBUILD}/SPECS/ && \
	  rpmbuild --define "_topdir $${RPMBUILD}" -ba $${RPMBUILD}/SPECS/auto-app.spec && \
	  cp $${RPMBUILD}/SOURCES/*.tar.gz $(CURDIR)/bin/ && \
	  cp $${RPMBUILD}/RPMS/*/*.rpm $(CURDIR)/bin/ && \
	  rm -rf $${NAME}-$${VERSION} $${NAME}-$${VERSION}.tar.gz $${RPMBUILD}
	  
build-starter-container:
	$(CONTAINER_TOOL) build $(BUILD_ARGS) \
		-f containers/rhas-starter/Containerfile \
		-t $(STARTER_CONTAINER_IMAGE):$(TAG) \
		containers/rhas-starter/

build-exporter-container:
	$(CONTAINER_TOOL) build $(BUILD_ARGS) \
		-f containers/rhas-exporter/Containerfile \
		-t $(EXPORTER_CONTAINER_IMAGE):$(TAG) \
		containers/rhas-exporter/