SHELL:=/bin/bash

# Keep in sync with .github/workflows/chart-testing.yaml
HELM_DOCS_VERSION:=1.14.2

.PHONY: help
help: ## Display help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: docs
docs:  ## Regenerate charts/*/README.md from Chart.yaml and values.yaml
	helm-docs --chart-search-root=charts

.PHONY: docs-check
docs-check: docs  ## Fail if the generated READMEs are out of date
	@# git-status, not git-diff: diff ignores untracked files, so a brand new
	@# chart whose README was never generated would pass silently.
	@out="$$(git status --porcelain -- 'charts/*/README.md')"; \
	if [ -n "$$out" ]; then \
		echo "$$out"; \
		echo; \
		echo "charts/*/README.md is out of date or uncommitted."; \
		echo "Run 'make docs' and commit the result."; \
		exit 1; \
	fi

.PHONY: lint
lint:  ## Lint charts
	ct lint --config .ct.yaml
