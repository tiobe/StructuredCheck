GRAMMAR_NAME := st
GRAMMAR_SRC  := grammar/$(GRAMMAR_NAME).bnf
GRAMMAR_DEPS := $(wildcard grammar/*.bnf)
BUILD_DIR    := build/tree-sitter-$(GRAMMAR_NAME)
TESTS_DIR    := tests

TS_BNF_TOOL  := ts-bnf-tool
TREE_SITTER  := tree-sitter

.DEFAULT_GOAL := help

.PHONY: help check grammar test test-update clean

help: ## Show this help message
	@echo "StructuredCheck"
	@echo
	@echo "Usage: make <target>"
	@echo
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check: ## Run ts-bnf-tool static checks on the BNF grammar
	$(TS_BNF_TOOL) check $(GRAMMAR_SRC)

grammar: $(BUILD_DIR)/src/parser.c ## Generate the tree-sitter parser from the BNF grammar

$(BUILD_DIR)/src/parser.c: $(GRAMMAR_DEPS)
	rm -rf $(BUILD_DIR)
	$(TS_BNF_TOOL) convert --generate --name $(GRAMMAR_NAME) --output-dir $(BUILD_DIR) $(GRAMMAR_SRC)

test: grammar ## Run the corpus tests in tests/ against the generated parser
	mkdir -p $(BUILD_DIR)/test/corpus
	cp $(TESTS_DIR)/*.txt $(BUILD_DIR)/test/corpus/
	cd $(BUILD_DIR) && $(TREE_SITTER) test

test-update: grammar ## Run the tests, update their expected trees, and copy them back to tests/
	mkdir -p $(BUILD_DIR)/test/corpus
	cp $(TESTS_DIR)/*.txt $(BUILD_DIR)/test/corpus/
	cd $(BUILD_DIR) && $(TREE_SITTER) test --update
	cp $(BUILD_DIR)/test/corpus/*.txt $(TESTS_DIR)/

clean: ## Remove generated build artifacts
	rm -rf build
	find . -name '*~' -delete
