# langdev Makefile — portable lifecycle for a <language>dev image.
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Auto-detects docker or podman. Targets are disposable-first.
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

IMAGE ?= $(notdir $(CURDIR))
TAG   ?= local
REF   := $(IMAGE):$(TAG)
PLATFORMS ?= linux/amd64,linux/arm64
PORT  ?= 7681
AUTH  ?= dev:langdev

# --- Engine autodetection (docker preferred, podman fallback) ----------------
ENGINE ?= $(shell command -v docker >/dev/null 2>&1 && echo docker || echo podman)
# Podman wants :Z on SELinux bind mounts; docker does not.
ifeq ($(ENGINE),podman)
  MOUNT_FLAG := :Z
else
  MOUNT_FLAG :=
endif
RUN_FLAGS := --rm -it \
  --user 1000:1000 \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --pids-limit 512 --memory 2g \
  --tmpfs /tmp:mode=1777 \
  --tmpfs /home/dev/.cache:uid=1000,gid=1000 \
  --tmpfs /home/dev/.local/state:uid=1000,gid=1000 \
  -v "$(CURDIR)/work:/work$(MOUNT_FLAG)" \
  $(if $(wildcard .env),--env-file .env,)

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'
	@echo ""
	@echo "Engine: $(ENGINE)   Image: $(REF)"

.PHONY: build
build: ## Build the image for the host arch
	$(ENGINE) build -t $(REF) -f Containerfile .

.PHONY: buildx
buildx: ## Build a multi-arch image ($(PLATFORMS))
ifeq ($(ENGINE),docker)
	docker buildx build --platform $(PLATFORMS) -t $(REF) -f Containerfile .
else
	podman build --platform $(PLATFORMS) --manifest $(REF) -f Containerfile .
endif

.PHONY: up shell
up: shell ## Alias for `shell`
shell: build ## Start an interactive dev shell in a fresh container
	mkdir -p work
	$(ENGINE) run $(RUN_FLAGS) $(REF)

.PHONY: web
web: build ## Start WebTTY on port 7681 (iPad/browser access: make web PORT=7681)
	mkdir -p work
	$(ENGINE) run $(RUN_FLAGS) -p $(PORT):$(PORT) $(REF) ttyd -p $(PORT) -t fontSize=15 -t theme='{"background": "#1a1b26"}' tmux-ide --launch

.PHONY: web-auth
web-auth: build ## Start WebTTY with auth: make web-auth AUTH="user:pass"
	mkdir -p work
	$(ENGINE) run $(RUN_FLAGS) -p $(PORT):$(PORT) $(REF) ttyd -p $(PORT) -c $(AUTH) -t fontSize=15 -t theme='{"background": "#1a1b26"}' tmux-ide --launch

.PHONY: mosh
mosh: build ## Start container with UDP port range for Mosh roaming
	mkdir -p work
	$(ENGINE) run $(RUN_FLAGS) -p 60000-60010:60000-60010/udp $(REF)

.PHONY: doctor
doctor: ## Run system & container runtime health checks
	@./common/doctor.sh

.PHONY: run
run: build ## Run a one-shot command: make run CMD="..."
	mkdir -p work
	$(ENGINE) run $(RUN_FLAGS) $(REF) bash -lc '$(CMD)'

.PHONY: trash
trash: ## Remove the image and any dangling build cache
	-$(ENGINE) rmi -f $(REF)
	-$(ENGINE) image prune -f

.PHONY: lint
lint: ## Lint Containerfile + shell scripts (needs hadolint/shellcheck)
	@command -v hadolint  >/dev/null && hadolint Containerfile || echo "hadolint not installed — skipping"
	@command -v shellcheck >/dev/null && shellcheck common/entrypoint.sh $$(git ls-files '*.sh') || echo "shellcheck not installed — skipping"

.PHONY: scan
scan: build ## Vulnerability-scan the built image (needs trivy)
	@command -v trivy >/dev/null && trivy image --exit-code 1 --severity HIGH,CRITICAL $(REF) || echo "trivy not installed — skipping"

.PHONY: sbom
sbom: build ## Generate a CycloneDX SBOM (needs syft)
	@command -v syft >/dev/null && syft $(REF) -o cyclonedx-json > sbom.cdx.json && echo "wrote sbom.cdx.json" || echo "syft not installed — skipping"

.PHONY: test
test: ## Run the bats unit tests under kcov, fail if coverage < 95%
	@./test/run.sh

.PHONY: coverage
coverage: test ## Alias for `test`; the HTML report lands in coverage/
	@echo "coverage report: coverage/index.html"

.PHONY: sync-common
sync-common: ## Refresh common/ from the langdev source (LANGDEV=path-or-url)
	@./bin/langdev-sync $(if $(LANGDEV),--source "$(LANGDEV)",)

.PHONY: site
site: ## Build static documentation and landing site with SSG
	@command -v ssg >/dev/null 2>&1 && (cd website && ssg build -f ssg.toml) || echo "SSG not installed. Run: cargo install ssg"

.PHONY: serve
serve: site ## Serve static documentation locally on port 8000
	@command -v ssg >/dev/null 2>&1 && (cd website && ssg serve -f ssg.toml) || python3 -m http.server 8000 -d website/public
