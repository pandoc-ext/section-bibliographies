# Name of the filter file, *with* `.lua` file extension.
FILTER_FILE := $(wildcard *.lua)
# Name of the filter, *without* `.lua` file extension
FILTER_NAME = $(patsubst %.lua,%,$(FILTER_FILE))

# Allow to use a different pandoc binary, e.g. when testing.
PANDOC ?= pandoc
# Allow to adjust the diff command if necessary
DIFF = diff

# Current version, i.e., the latest tag. Used to version the quarto
# extension.
VERSION = $(shell git tag --sort=-version:refname --merged | head -n1 | \
						 sed -e 's/^v//' | tr -d "\n")
ifeq "$(VERSION)" ""
VERSION = 0.0.0
endif

# Ensure that the `test` target is run each time it's called.
.PHONY: test
test: test-default test-no-citeproc test-refs-name test-section-level \
	test-unnumbered-section test-minlevel

# Test that running the filter on the sample input document yields
# the expected output.
test-%: $(FILTER_FILE) test/input.md test/input-unnumbered-section.md \
		test/test.yaml \
		test/test-%.yaml
	$(PANDOC) --defaults test/test.yaml --defaults test/test-$*.yaml | \
		$(DIFF) test/expected-$*.native -

# Update files that contain the expected test output
.PHONY: update-expected update-%
update-expected: update-default update-no-citeproc update-refs-name \
	update-section-level update-unnumbered-section update-minlevel
update-%: $(FILTER_FILE) \
		test/input.md \
		test/input-unnumbered-section.md \
		test/test.yaml \
		test/test-%.yaml
	$(PANDOC) \
	    --defaults=test/test.yaml \
	    --defaults=test/test-$*.yaml \
	    --output=test/expected-$*.native

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
# Release
#
.PHONY: release
release:
	git commit --amend --message "Release $(FILTER_NAME) $(VERSION)"
	git tag --sign v$(VERSION) --message "$(FILTER_NAME) $(VERSION)"

#
# Clean
#
.PHONY: clean
clean:
	rm -f _site/output.md _site/index.html _site/style.css
