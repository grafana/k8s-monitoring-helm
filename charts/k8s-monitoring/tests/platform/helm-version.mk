HELM_VERSION ?= 4.1.4
ifneq ($(HELM_VERSION),)
PLATFORM_HELM_MK := $(lastword $(MAKEFILE_LIST))
HELM_REPO_ROOT := $(abspath $(dir $(PLATFORM_HELM_MK))/../../../..)
HELM_BIN := $(shell $(HELM_REPO_ROOT)/scripts/helm-with-version which $(HELM_VERSION))
ifneq ($(HELM_BIN),)
export PATH := $(dir $(HELM_BIN)):$(PATH)
endif
endif
