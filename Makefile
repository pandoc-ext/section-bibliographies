# Name of the filter file, *with* `.lua` file extension.
FILTER_FILE := $(wildcard *.lua)
# Name of the filter, *without* `.lua` file extension
FILTER_NAME = $(patsubst %.lua,%,$(FILTER_FILE))

# Allow to use a different pandoc binary, e.g. when testing.
PANDOC ?= pandoc
# Allow to adjust the diff command if necessary
DIFF = diff

# Directory containing the Quarto extension
QUARTO_EXT_DIR = _extensions/$(FILTER_NAME)
# The extension's name. Used in the Quarto extension metadata
EXT_NAME = $(FILTER_NAME)
# Current version, i.e., the latest tag. Used to version the quarto
# extension.
VERSION = $(shell git tag --sort=-version:refname --merged | head -n1 | \
						 sed -e 's/^v//' | tr -d "\n")
ifeq "$(VERSION)" ""
VERSION = 0.0.0
endif

# GitHub repository; used to setup the filter.
REPO_PATH = $(shell git remote get-url origin | sed -e 's%.*github\.com[/:]%%')
REPO_NAME = $(shell git remote get-url origin | sed -e 's%.*/%%')
USER_NAME = $(shell git config user.name)

# Test that running the filter on the sample input document yields
# the expected output.
#
# The automatic variable `$<` refers to the first dependency
# (i.e., the filter file).
test: $(FILTER_FILE) test/input.md test/test.yaml
	$(PANDOC) --defaults test/test.yaml | \
		$(DIFF) test/expected.native -

# Ensure that the `test` target is run each time it's called.
.PHONY: test

# Re-generate the expected output. This file **must not** be a
# dependency of the `test` target, as that would cause it to be
# regenerated on each run, making the test pointless.
test/expected.native: $(FILTER_FILE) test/input.md test/test.yaml
	$(PANDOC) --defaults test/test.yaml --output=$@

#
# Website
#
.PHONY: website
website: _site/index.html _site/$(FILTER_FILE)

_site/index.html: README.md test/input.md $(FILTER_FILE) .tools/docs.lua \
		_site/output.md _site/style.css
	@mkdir -p _site
	$(PANDOC) \
	    --standalone \
	    --lua-filter=.tools/docs.lua \
	    --metadata=sample-file:test/input.md \
	    --metadata=result-file:_site/output.md \
	    --metadata=code-file:$(FILTER_FILE) \
	    --css=style.css \
	    --toc \
	    --output=$@ $<

_site/style.css:
	@mkdir -p _site
	curl \
	    --output $@ \
	    'https://cdn.jsdelivr.net/gh/kognise/water.css@latest/dist/light.css'

_site/output.md: $(FILTER_FILE) test/input.md test/test.yaml
	@mkdir -p _site
	$(PANDOC) \
	    --defaults=test/test.yaml \
	    --to=markdown \
	    --output=$@

_site/$(FILTER_FILE): $(FILTER_FILE)
	@mkdir -p _site
	(cd _site && ln -sf ../$< $<)

#
# Quarto extension
#

# Creates or updates the quarto extension
.PHONY: quarto-extension
quarto-extension: $(QUARTO_EXT_DIR)/_extension.yml \
		$(QUARTO_EXT_DIR)/$(FILTER_FILE)

$(QUARTO_EXT_DIR):
	mkdir -p $@

## This may change, so re-create the file every time
.PHONY: $(QUARTO_EXT_DIR)/_extension.yml
$(QUARTO_EXT_DIR)/_extension.yml: _extensions/$(FILTER_NAME)
	@printf 'Creating %s\n' $@
	@printf 'name: %s\n' "$(EXT_NAME)" > $@
	@printf 'author: %s\n' "$(USER_NAME)" >> $@
	@printf 'version: %s\n'  "$(VERSION)" >> $@
	@printf 'contributes:\n  filters:\n    - %s\n' $(FILTER_FILE) >> $@

## The filter file must be below the quarto _extensions folder: a
## symlink in the extension would not work due to the way in which
## quarto installs extensions.
$(QUARTO_EXT_DIR)/$(FILTER_FILE): $(FILTER_FILE) $(QUARTO_EXT_DIR)
	if [ ! -L $(FILTER_FILE) ]; then \
	    mv $(FILTER_FILE) $(QUARTO_EXT_DIR)/$(FILTER_FILE) && \
	    ln -s $(QUARTO_EXT_DIR)/$(FILTER_FILE) $(FILTER_FILE); \
	fi

#
# Release
#
.PHONY: release
release: quarto-extension
	git commit -am "Release $(FILTER_NAME) $(VERSION)"
	git tag v$(VERSION) -m "$(FILTER_NAME) $(VERSION)"

#
# Update filter name
#
.PHONY: update-name
update-name:
	sed -i'' -e 's/greetings/$(FILTER_NAME)/g' README.md
	sed -i'' -e 's/greetings/$(FILTER_NAME)/g' test/test.yaml

setup:
	git mv greetings.lua $(REPO_NAME).lua
	@# Crude method to updates the examples and links; removes the
	@# template instructions from the README.
	sed -i'' \
	    -e 's/greetings/$(REPO_NAME)/g' \
	    -e 's#tarleb/lua-filter-template#$(REPO_PATH)#g' \
      -e '/^\* \*/,/^\* \*/d' \
	    README.md
	sed -i'' -e 's/greetings/$(REPO_NAME)/g' test/test.yaml
	sed -i'' -e 's/Albert Krewinkel/$(USER_NAME)' LICENSE

#
# Clean
#
.PHONY: clean
clean:
	rm -f _site/output.md _site/index.html _site/style.css
