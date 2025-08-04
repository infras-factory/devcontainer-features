# DevContainer Features Makefile
# Manages DevContainer features development and testing

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Default shell
SHELL := /bin/bash

# Colors for output
BLUE   := \033[0;34m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
NC     := \033[0m

# Directories
SRC_DIR      := src
TEST_DIR     := test
CLAUDE_DIR   := .claude

# ==============================================================================
# HELP & DEFAULT TARGET
# ==============================================================================

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf "$(BLUE)DevContainer Features Makefile$(NC)\n\n"
	@printf "$(GREEN)Usage:$(NC)\n"
	@printf "  make [target] [VARIABLE=value ...]\n\n"
	@printf "$(GREEN)Feature Management:$(NC)\n"
	@printf "  %-25s %s\n" "list-features" "List all existing features"
	@printf "\n$(GREEN)Testing:$(NC)\n"
	@printf "  %-25s %s\n" "test FEATURE=<name>" "Run tests for a specific feature"
	@printf "  %-25s %s\n" "test-all" "Run tests for all features"
	@printf "  %-25s %s\n" "test-scenario" "Run specific test scenario"
	@printf "  %-25s %s\n" "test-clean" "Clean up test containers and images"
	@printf "\n$(GREEN)Validation:$(NC)\n"
	@printf "  %-25s %s\n" "validate FEATURE=<name>" "Validate feature structure"
	@printf "\n$(GREEN)Documentation:$(NC)\n"
	@printf "  %-25s %s\n" "docs" "Show available documentation"
	@printf "\n$(GREEN)Utilities:$(NC)\n"
	@printf "  %-25s %s\n" "clean" "Clean temporary files"
	@printf "\n$(GREEN)Examples:$(NC)\n"
	@printf "  make test FEATURE=ohmyzsh\n"
	@printf "  make test-scenario FEATURE=ohmyzsh SCENARIO=test-debian\n"
	@printf "  make validate FEATURE=pyenv\n"

# ==============================================================================
# INTERNAL HELPERS (prefix with _)
# ==============================================================================

.PHONY: _check-devcontainer-cli
_check-devcontainer-cli:
	@if ! command -v devcontainer &> /dev/null; then \
		printf "$(RED)Error: devcontainer CLI is not installed. Please install it first.$(NC)\n"; \
		printf "$(YELLOW)Visit: https://github.com/devcontainers/cli$(NC)\n"; \
		exit 1; \
	fi

.PHONY: _check-feature
_check-feature:
	@if [ -z "$(FEATURE)" ]; then \
		printf "$(RED)Error: Please specify a feature. Example: make test FEATURE=ohmyzsh$(NC)\n"; \
		exit 1; \
	fi
	@if [ ! -d "$(SRC_DIR)/$(FEATURE)" ]; then \
		printf "$(RED)Error: Feature '$(FEATURE)' not found in $(SRC_DIR)/$(NC)\n"; \
		exit 1; \
	fi

.PHONY: _check-scenario
_check-scenario:
	@if [ -z "$(SCENARIO)" ]; then \
		printf "$(RED)Error: Please specify a scenario. Example: make test-scenario FEATURE=ohmyzsh SCENARIO=test-debian$(NC)\n"; \
		exit 1; \
	fi

.PHONY: _run-test-with-cleanup
_run-test-with-cleanup:
	@CONTAINERS_BEFORE=$$(docker ps -aq | wc -l); \
	IMAGES_BEFORE=$$(docker images -q | wc -l); \
	printf "$(CYAN)Containers before test: $$CONTAINERS_BEFORE$(NC)\n"; \
	printf "$(CYAN)Images before test: $$IMAGES_BEFORE$(NC)\n"; \
	\
	devcontainer features test --skip-duplicated \
		--features $(FEATURE) \
		--project-folder . \
		--log-level info || TEST_FAILED=1; \
	\
	printf "$(YELLOW)Cleaning up test containers and images...$(NC)\n"; \
	$(MAKE) _cleanup-docker-resources; \
	\
	CONTAINERS_AFTER=$$(docker ps -aq | wc -l); \
	IMAGES_AFTER=$$(docker images -q | wc -l); \
	CONTAINERS_REMOVED=$$((CONTAINERS_BEFORE - CONTAINERS_AFTER)); \
	IMAGES_REMOVED=$$((IMAGES_BEFORE - IMAGES_AFTER)); \
	printf "$(GREEN)Cleanup: Removed $$CONTAINERS_REMOVED containers and $$IMAGES_REMOVED images$(NC)\n"; \
	\
	if [ "$$TEST_FAILED" = "1" ]; then \
		printf "$(RED)Test failed!$(NC)\n"; \
		exit 1; \
	else \
		printf "$(GREEN)Test passed!$(NC)\n"; \
	fi

.PHONY: _run-test-all-with-cleanup
_run-test-all-with-cleanup:
	@CONTAINERS_BEFORE=$$(docker ps -aq | wc -l); \
	IMAGES_BEFORE=$$(docker images -q | wc -l); \
	printf "$(CYAN)Containers before test: $$CONTAINERS_BEFORE$(NC)\n"; \
	printf "$(CYAN)Images before test: $$IMAGES_BEFORE$(NC)\n"; \
	\
	devcontainer features test --skip-duplicated \
		--project-folder . \
		--log-level info || TEST_FAILED=1; \
	\
	printf "$(YELLOW)Cleaning up test containers and images...$(NC)\n"; \
	$(MAKE) _cleanup-docker-resources; \
	\
	CONTAINERS_AFTER=$$(docker ps -aq | wc -l); \
	IMAGES_AFTER=$$(docker images -q | wc -l); \
	CONTAINERS_REMOVED=$$((CONTAINERS_BEFORE - CONTAINERS_AFTER)); \
	IMAGES_REMOVED=$$((IMAGES_BEFORE - IMAGES_AFTER)); \
	printf "$(GREEN)Cleanup: Removed $$CONTAINERS_REMOVED containers and $$IMAGES_REMOVED images$(NC)\n"; \
	\
	if [ "$$TEST_FAILED" = "1" ]; then \
		printf "$(RED)Test failed!$(NC)\n"; \
		exit 1; \
	else \
		printf "$(GREEN)Test passed!$(NC)\n"; \
	fi

.PHONY: _run-test-scenario-with-cleanup
_run-test-scenario-with-cleanup:
	@CONTAINERS_BEFORE=$$(docker ps -aq | wc -l); \
	IMAGES_BEFORE=$$(docker images -q | wc -l); \
	printf "$(CYAN)Containers before test: $$CONTAINERS_BEFORE$(NC)\n"; \
	printf "$(CYAN)Images before test: $$IMAGES_BEFORE$(NC)\n"; \
	\
	devcontainer features test --skip-duplicated \
		--features $(FEATURE) \
		--filter $(SCENARIO) \
		--project-folder . \
		--log-level info || TEST_FAILED=1; \
	\
	printf "$(YELLOW)Cleaning up test containers and images...$(NC)\n"; \
	$(MAKE) _cleanup-docker-resources; \
	\
	CONTAINERS_AFTER=$$(docker ps -aq | wc -l); \
	IMAGES_AFTER=$$(docker images -q | wc -l); \
	CONTAINERS_REMOVED=$$((CONTAINERS_BEFORE - CONTAINERS_AFTER)); \
	IMAGES_REMOVED=$$((IMAGES_BEFORE - IMAGES_AFTER)); \
	printf "$(GREEN)Cleanup: Removed $$CONTAINERS_REMOVED containers and $$IMAGES_REMOVED images$(NC)\n"; \
	\
	if [ "$$TEST_FAILED" = "1" ]; then \
		printf "$(RED)Test failed!$(NC)\n"; \
		exit 1; \
	else \
		printf "$(GREEN)Test passed!$(NC)\n"; \
	fi

.PHONY: _cleanup-docker-resources
_cleanup-docker-resources:
	@docker ps -a --filter "label=devcontainer.is_test_run=true" -q | xargs -r docker rm -f 2>/dev/null || true
	@docker ps -a --filter "name=vsc-" -q | xargs -r docker rm -f 2>/dev/null || true
	@docker ps -a --filter "name=test-" -q | xargs -r docker rm -f 2>/dev/null || true
	@docker images --filter "reference=vsc-*" -q | xargs -r docker rmi -f 2>/dev/null || true
	@docker images --filter "reference=test-*" -q | xargs -r docker rmi -f 2>/dev/null || true
	@docker image prune -f >/dev/null 2>&1 || true

.PHONY: _validate-files
_validate-files:
	@[ -f "$(SRC_DIR)/$(FEATURE)/install.sh" ] && \
		printf "$(GREEN)✓ install.sh found$(NC)\n" || \
		printf "$(RED)✗ install.sh missing$(NC)\n"
	@[ -f "$(SRC_DIR)/$(FEATURE)/README.md" ] && \
		printf "$(GREEN)✓ README.md found$(NC)\n" || \
		printf "$(RED)✗ README.md missing$(NC)\n"
	@[ -d "$(SRC_DIR)/$(FEATURE)/scripts" ] && \
		printf "$(GREEN)✓ scripts directory found$(NC)\n" || \
		printf "$(RED)✗ scripts directory missing$(NC)\n"
	@[ -d "$(TEST_DIR)/$(FEATURE)" ] && \
		printf "$(GREEN)✓ test directory found$(NC)\n" || \
		printf "$(RED)✗ test directory missing$(NC)\n"

.PHONY: _validate-json
_validate-json:
	@python3 -m json.tool "$(SRC_DIR)/$(FEATURE)/devcontainer-feature.json" > /dev/null && \
		printf "$(GREEN)✓ devcontainer-feature.json is valid$(NC)\n" || \
		printf "$(RED)✗ devcontainer-feature.json is invalid$(NC)\n"

# ==============================================================================
# FEATURE MANAGEMENT
# ==============================================================================

.PHONY: list-features
list-features:
	@printf "$(BLUE)Existing features:$(NC)\n"
	@if [ -d "$(SRC_DIR)" ]; then \
		for feature in $(SRC_DIR)/*/; do \
			if [ -d "$$feature" ] && [ -f "$$feature/devcontainer-feature.json" ]; then \
				feature_name=$$(basename $$feature); \
				printf "  $(GREEN)•$(NC) $$feature_name\n"; \
			fi; \
		done; \
	else \
		printf "$(YELLOW)No features found.$(NC)\n"; \
	fi

# ==============================================================================
# TESTING
# ==============================================================================

.PHONY: test
test: _check-feature _check-devcontainer-cli
	@printf "$(BLUE)Running tests for feature: $(FEATURE)$(NC)\n"
	@$(MAKE) _run-test-with-cleanup

.PHONY: test-all
test-all: _check-devcontainer-cli
	@printf "$(BLUE)Running tests for all features...$(NC)\n"
	@$(MAKE) _run-test-all-with-cleanup

.PHONY: test-scenario
test-scenario: _check-feature _check-scenario _check-devcontainer-cli
	@printf "$(BLUE)Running scenario '$(SCENARIO)' for feature: $(FEATURE)$(NC)\n"
	@$(MAKE) _run-test-scenario-with-cleanup

.PHONY: test-clean
test-clean:
	@printf "$(YELLOW)Cleaning up all test containers and images...$(NC)\n"
	@$(MAKE) _cleanup-docker-resources
	@printf "$(GREEN)Cleanup complete!$(NC)\n"

# ==============================================================================
# VALIDATION
# ==============================================================================

.PHONY: validate
validate: _check-feature
	@printf "$(BLUE)Validating feature: $(FEATURE)$(NC)\n"
	@printf "$(YELLOW)Checking file structure...$(NC)\n"
	@$(MAKE) _validate-files
	@printf "$(YELLOW)Validating JSON...$(NC)\n"
	@$(MAKE) _validate-json

# ==============================================================================
# DOCUMENTATION
# ==============================================================================

.PHONY: docs
docs:
	@printf "$(BLUE)Available documentation:$(NC)\n"
	@if [ -d "$(CLAUDE_DIR)" ]; then \
		for doc in $(CLAUDE_DIR)/*.md; do \
			if [ -f "$$doc" ]; then \
				doc_name=$$(basename $$doc); \
				printf "  $(GREEN)•$(NC) $$doc_name\n"; \
			fi; \
		done; \
	else \
		printf "$(YELLOW)No documentation found in $(CLAUDE_DIR)/$(NC)\n"; \
	fi
	@printf "\n$(CYAN)To create a new feature, ask Claude to generate it based on the documentation.$(NC)\n"

# ==============================================================================
# UTILITIES
# ==============================================================================

.PHONY: clean
clean:
	@printf "$(BLUE)Cleaning temporary files...$(NC)\n"
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".DS_Store" -delete 2>/dev/null || true
	@printf "$(GREEN)✓ Cleaned!$(NC)\n"
