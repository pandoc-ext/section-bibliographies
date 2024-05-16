# section-bibliographies

The section-bibliographies filter is versioned using [Semantic
Versioning][].

[Semantic Versioning]: https://semver.org/

## v1.0.0

Release pending.

-   Rewrote and restructured filter, making use of newer pandoc
    features.

-   Allow configuration via `section-bibliographies` metadata map.

-   The bibliography files are read just once, and not repeatedly
    for each section.

-   Disambiguate reference identifiers. This avoids problems when
    the same reference is cited in different sections.

-   No longer cleanup previous citeproc runs by default. Set
    `section-bibliographies.cleanup-first` to true to restore the
    previous behavior.

## v0.0.1

Released 2023-08-10.

-   Released into the wild. May it live long and prosper.
