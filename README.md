Greetings, a Lua Filter Template
==================================================================

[![GitHub build status][CI badge]][CI workflow]

Greetings is a friendly Lua filter that adds a welcoming message
to the document.

[CI badge]: https://img.shields.io/github/workflow/status/tarleb/lua-filter-template/CI?logo=github
[CI workflow]: https://github.com/tarleb/lua-filter-template/actions/workflows/ci.yaml

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

This repository serves as a template intended to make publishing
of pandoc [Lua filters][] easy and convenient. Just click "use
this template" and then make modifications in your new repository.
See also the GitHub documentation on [creating a repository from a
template][from template].

[Lua filters]: https://pandoc.org/lua-filters.html
[from template]: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template

Template Usage
------------------------------------------------------------------

This section describes how to use the template.

### Checklist

A few things should be updated in the repository after cloning
this template. You can use the checklist below to ensure that you
get the most out of it. We recommend that you perform at least the
first two steps, everything else is up to you.

0. [ ] **Use template**: Create a new repo from
   this template. Use the name that you want to give your filter
   as a repository name. E.g., a repository for filter
   `greetings.lua` should be named `greetings`.
1. [ ] **Clone your new repository**: Run `git clone` to fetch
   your new repository.
2. [ ] **Setup the filter**: the easiest way to setup the
   repository is to run

   ``` bash
   make setup
   ```

   This will update the README, remove the template-specific
   documentation, and rename the filter; the repository name is
   used to determine the new filter name.

3. [ ] **Update the README**: Describe your filter, so people
   will know what to expect. You may also want to update the URLs
   in the links above to match your repository.

4. [ ] (optional) **Setup Quarto extension**: This step is
   recommended if you want to make it easy for [Quarto][] users to
   install and use your filter: Quarto expects the filter to be
   placed in the `_extensions` folder, packed together with a YAML
   file containing relevant metadata. Run

   ``` bash
   make quarto-extension
   ```

   to generate the necessary files and directories. You should
   commit the generated files to source control. See also the
   [`quarto-extension` documentation](quarto-extension) below.

5. [ ] (optional) **Tag a release**: The easiest way to create a
   new release is to run `make release VERSION=0.0.1`. This will
   update the Quarto extension, commit the changes, then tag the
   resulting commit with the given VERSION. This step is
   recommended if the filter is distributed as a Quarto extension.

### Development

The repository comes with a `Makefile` intended to make developing
a filter a pleasant experience. You may want to adjust some of the
targets while keeping the general structure.

Use the Makefile with `make ...`, where `...` denotes one of the
targets listed in this section.

#### `test`

Tests the filter. This target runs your filter on file
`test/input.md` and compares the result with
`test/expected.native`. The latter file is also a valid make
target; invoke it to regenerate the expected output.

You may want to modify this target if your filter is intended for
a specific output format. E.g., if the filter only works for HTML
output, you may choose to replace `test/expected.native` with
`test/expected.html`, and to compare that file instead.

The test configs are kept in file `test/test.yaml`. The file is
generated on demand, but you may want to check it into source
control and modify it as needed.

#### `quarto-extension`

This target sets the repository up to be used as a [Quarto][]
extension. The target will create the directory structure expected
by quarto. It will also generate a `_extension.yml` metadata file.
Invoking this target will move the main `.lua` file below the
`_extensions` directory; the the original file will be replaced
with a symlink.

[Quarto]: https://quarto.org

#### `release`

Creates a new release for the given version. The version must be
passed as a variable:

``` bash
make release VERSION=1.0.0
```

The `release` target depends on `quarto-extension`.

### `update-name`

Run this target after renaming the filter file. It will update the
name in all other files.

#### `website`

Generates a website for this filter. The website will contain the
contents of this README, an example generated from the test input,
as well as the full filter code. The page components are combined
with the `.tools/docs.lua` filter.

### Website

The repository template comes with a GitHub Action to publish a
website via GitHub pages. It expects the new "GitHub Actions"
source to be used for Pages.

Remove the file `.github/workflows/website.lua` to disable this
feature.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Usage
------------------------------------------------------------------

The filter modifies the internal document representation; it can
be used with many publishing systems that are based on pandoc.

### Plain pandoc

Pass the filter to pandoc via the `--lua-filter` (or `-L`) command
line option.

    pandoc --lua-filter greetings.lua ...

### Quarto

Users of Quarto can install this filter as an extension with

    quarto install extension tarleb/greetings

and use it by adding `greetings` to the `filters` entry
in their YAML header.

``` yaml
---
filters:
  - greetings
---
```

### R Markdown

Use `pandoc_args` to invoke the filter. See the [R Markdown
Cookbook](https://bookdown.org/yihui/rmarkdown-cookbook/lua-filters.html)
for details.

``` yaml
---
output:
  word_document:
    pandoc_args: ['--lua-filter=greetings.lua']
---
```

License
------------------------------------------------------------------

This pandoc Lua filter is published under the MIT license, see
file `LICENSE` for details.
