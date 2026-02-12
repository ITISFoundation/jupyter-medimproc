SHELL = /bin/sh
.DEFAULT_GOAL := help

# Project Configuration
PROJECT_NAME := jupyter-medimproc
VERSION := 1.3.3

# Variant can be: jupyter, runner, or runner-slim
VARIANT ?= jupyter

# Docker Image Names (simcore registry paths)
JUPYTER_IMAGE := simcore/services/dynamic/jupyter-medimproc
RUNNER_IMAGE := simcore/services/comp/runner-medimproc
RUNNER_SLIM_IMAGE := simcore/services/comp/runner-medimproc-slim

# Select the appropriate image based on VARIANT
ifeq ($(VARIANT),jupyter)
    IMAGE_NAME := $(JUPYTER_IMAGE)
    DOCKERFILE := services/jupyter/Dockerfile
else ifeq ($(VARIANT),runner)
    IMAGE_NAME := $(RUNNER_IMAGE)
    DOCKERFILE := services/runner/Dockerfile
else ifeq ($(VARIANT),runner-slim)
    IMAGE_NAME := $(RUNNER_SLIM_IMAGE)
    DOCKERFILE := services/runner-slim/Dockerfile
else
    $(error Invalid VARIANT: $(VARIANT). Must be one of: jupyter, runner, runner-slim)
endif

# ============================================================================
# Build Targets
# ============================================================================

.PHONY: compose-spec
compose-spec: ## runs ooil to assemble the docker-compose.yml file
	@docker run -it --rm -v $(PWD):/medimproc \
		-u $(shell id -u):$(shell id -g) \
		-e VERSION=$(VERSION) \
		itisfoundation/ci-service-integration-library:v2.2.1 \
		sh -c "cd /medimproc && ooil compose"

build: | compose-spec	## build docker image
	docker compose -f docker-compose-local.yml build

# ============================================================================
# Testing
# ============================================================================

.PHONY: test
test:
	@echo "To test the images, please execute one of the 'test-...' make commands in the 'tests' subfolder"
	@echo "If you do not have it, you can clone it from https://git.speag.com/ordonez/medimproc-testing-pipelines"

.PHONY: shell
shell: ## Run interactive shell in the image
	docker run -it --rm $(IMAGE_NAME):$(VERSION) /bin/bash

.PHONY: shell-jupyter
shell-jupyter: ## Run interactive shell in jupyter variant
	$(MAKE) shell VARIANT=jupyter

.PHONY: shell-runner
shell-runner: ## Run interactive shell in runner variant
	$(MAKE) shell VARIANT=jupyter

.PHONY: shell-runner-slim
shell-runner-slim: ## Run interactive shell in runner-slim variant
	$(MAKE) shell VARIANT=runner-slim

# ============================================================================
# Local Development
# ============================================================================

.PHONY: up
up: ## Start docker-compose services
	docker compose -f docker-compose-local.yml up -d

.PHONY: down
down: ## Stop docker-compose services
	docker compose -f docker-compose-local.yml down

.PHONY: logs
logs: ## View docker-compose logs
	docker compose -f docker-compose-local.yml logs -f

.PHONY: push
push: # push to both remotes
	git push gitlab
	git push github
# ============================================================================
# Cleanup
# ============================================================================

.PHONY: clean
clean: ## Remove built images
	docker rmi $(JUPYTER_IMAGE):$(VERSION) || true
	docker rmi $(RUNNER_IMAGE):$(VERSION) || true
	docker rmi $(RUNNER_SLIM_IMAGE):$(VERSION) || true

# ============================================================================
# Versioning
# ============================================================================

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

# ============================================================================
# Help
# ============================================================================

.PHONY: help
help: ## This help message
	@echo "$(PROJECT_NAME) - Medical Image Processing Service"
	@echo ""
	@echo "Available variants:"
	@echo "  - jupyter:       Interactive Jupyter notebook with FreeSurfer + FSL"
	@echo "  - runner:        Headless runner (standard, not optimized)"
	@echo "  - runner-slim:   Headless runner (optimized/slim version)"
	@echo ""
	@echo "Usage:"
	@echo "  make build VARIANT=<variant>       - Build specific variant"
	@echo "  make build-all                     - Build all variants"
	@echo "  make shell VARIANT=<variant>       - Run interactive shell"
	@echo "  make test VARIANT=<variant>        - Test specific variant"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) 