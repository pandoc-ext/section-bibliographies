Section Bibliographies Filter
==================================================================

[![GitHub build status][CI badge]][CI workflow]

Pandoc filter that generates a bibliography for each top-level
section / chapter.

The filter allows the user to put bibliographies at the end of
each section, containing only those references in the section. It
works by splitting the document up into sections, and then
treating each section as a separate document for *citeproc* to
process.

[CI badge]: https://img.shields.io/github/actions/workflow/status/pandoc-ext/section-bibliographies/ci.yaml?branch=main&logo=github
[CI workflow]: https://github.com/pandoc-ext/section-bibliographies/actions/workflows/ci.yaml


Usage
------------------------------------------------------------------

The filter modifies the internal document representation; it can
be used with many publishing systems that are based on pandoc.

Most users will want to set the `reference-section-title` metadata
value to add a section heading to the reference section.

### Plain pandoc

This filter interferes with the default operation of citeproc. The
`citeproc` filter must either be run *before* this filter, or not
at all. The `section-bibliographies.lua` filter calls `citeproc`
as necessary. For example:

    pandoc input.md --citeproc --lua-filter section-bibliographies.lua

or

    pandoc input.md --lua-filter section-bibliographies.lua


### Quarto

Users of Quarto can install this filter as an extension with

    quarto install extension pandoc-ext/section-bibliographies

and use it by adding `section-bibliographies` to the `filters`
entry in their YAML header. This filter should run *after*
Quarto's default filters.

It is recommended to set `citeproc: false` in the YAML header, as
this minimizes interference with Quarto's default citation
handling.

``` yaml
---
filters:
  # Run Quarto's default filters first
  - quarto
  - section-bibliographies
bibliography: my-bibliography.bib
reference-section-title: References
citeproc: false
---
```

**Please Note**: In some OS environments it might be necessary to
use the complete absolute path to the `.lua` file for the filter,
e.g.

```
filters:
  - /home/user/_extensions/pandoc-ext/section-bibliographies/section-bibliographies.lua
```

### R Markdown

Use `pandoc_args` to invoke the filter. See the [R Markdown
Cookbook](https://bookdown.org/yihui/rmarkdown-cookbook/lua-filters.html)
for details.

``` yaml
---
reference-section-title: References
output:
  word_document:
    pandoc_args: ['--lua-filter=section-bibliographies.lua']
---
```

Configuration
------------------------------------------------------------------

The filter allows customization through metadata fields, all
nested below the `section-bibliographies` value:

`section-bibiliograpies.cleanup-first`
:   Remove the reference section added by a previous `citeproc`
    run. The default is `false`.

`section-bibiliograpies.level`
:   This variable controls what level the biblography will occur
    at the end of. The header of the generated references section
    will be one level lower than the section that it appears on
    (so if it occurs at the end of a level-1 section, it will
    receive a level-2 header, and so on).

`section-bibiliograpies.minlevel`
:   Sets the minimum section level at which bibliographies will be
    produced. The default is 1. Higher numbers will leave
    top-level sections unprocessed.

`section-bibliographies.bibliography`
:   Behaves like `bibliography` in the context of this filter.
    This variable exists because pandoc automatically invokes
    `citeproc` as the final filter if it is called with either
    `--bibliography`, or if the `bibliography` metadata is given
    via a command line option. Using `section-bibs-bibliography`
    on the command line avoids this unwanted invocation.

`section-bibliographies.references`
:   Behaves like `references` in the context of this filter.

The metadata fields `section-bibs-level` and
`section-bibs-bibliography` have the same effect as the nested
`level` and `bibliography` values, respectively. This is for for
backwards compatibility. The old names are deprecated and should
no longer be used.


Bibliography placement
------------------------------------------------------------------

Div elements with class `sectionrefs` can be used to manually
place the bibliography. The filter will use the div as the
container for the list of references, similar to how Div's with
identifier `refs` are be used by plain citeproc.

If the `sectionrefs` div is nested below another heading, then
that heading must be marked with the `sectionbibliography` class,
or otherwise it might be ignored.

``` markdown
# Here is one section

This reference to [@cohen:jokes] will be listed under [my refs].

## A subsection

Here is a not very interesting subsection.

## Bibliography {.sectionbibliography}

Some extra comments on the bibliography can go here.

::: {.sectionrefs}
:::
```


License
------------------------------------------------------------------

This pandoc Lua filter is published under the MIT license, see
file `LICENSE` for details.
