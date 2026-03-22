# Delegates to root Makefile. Prefer running 'make' from the repo root.
ROOT := $(shell git rev-parse --show-toplevel)

.PHONY: all
all:
	@$(MAKE) -C $(ROOT)

%:
	@$(MAKE) -C $(ROOT) $@
