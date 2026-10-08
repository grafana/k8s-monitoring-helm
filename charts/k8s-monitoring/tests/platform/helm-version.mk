HELM_VERSION ?= 4.1.4
ifneq ($(HELM_VERSION),)
PLATFORM_HELM_MK := $(lastword $(MAKEFILE_LIST))
HELM_REPO_ROOT := $(abspath $(dir $(PLATFORM_HELM_MK))/../../../..)
export HELM_VERSION
export PATH := $(HELM_REPO_ROOT)/scripts/bin:$(PATH)
endif
