SHELL = /bin/sh
.DEFAULT_GOAL := help
VERSION := 1.3.0

# Versioning -------------------------------------------------------------------------------------------
define _bumpversion
	# upgrades as $(subst $(1),,$@) version, commits and tags
	@docker run -it --rm -v $(PWD):/build \
		-u $(shell id -u):$(shell id -g) \
		itisfoundation/ci-service-integration-library:v2.2.1 \
		sh -c "cd /build && bump2version --verbose --list --config-file $(1) $(subst $(2),,$@)"
endef

.PHONY: version-patch version-minor version-major
version-patch version-minor version-major: .bumpversion.cfg ## increases service's version
	@$(call _bumpversion,$<,version-)

# Building ---------------------------------------------------------------------------------------------
.PHONY: build
build:
	@if [ -z "$(SERVICE)" ]; then echo "Error: SERVICE is not defined."; exit 1; fi
	@echo "Building Service: $(SERVICE) Version: $(VERSION)"
	docker build -t simcore/services/comp/$(SERVICE):$(VERSION) -t simcore/services/comp/$(SERVICE):latest -f services/$(SERVICE)/Dockerfile .

.PHONY: build-all
build-all: ## builds all services
	$(MAKE) build SERVICE=jupyter-freesurfer
	$(MAKE) build SERVICE=jupyter-fsl-synb0
	$(MAKE) build SERVICE=osparc-freesurfer
	$(MAKE) build SERVICE=osparc-freesurfer-min
	$(MAKE) build SERVICE=osparc-fsl-synb0
	$(MAKE) build SERVICE=osparc-fsl-synb0-min

.PHONY: help
help:
	@echo "Usage: make build SERVICE=<name>"
	@echo 