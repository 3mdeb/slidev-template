---
src: ./base-slides.md#1-14
---

---
layout: two-cols-header
---

<!--
  BROKEN: the same content on the built-in two-cols-header layout, which has no
  column gutter and no two-cols-top class for the assertions to find.
-->

# Two Columns Top

::left::

## Left Side

Left column content, starting directly beneath the header.

::right::

## Right Side

Right column content, separated from the left column by a gutter.

::bottom::

Bottom row spanning both columns, pinned to the slide bottom.

<!--
two-cols-top is a template-local layout, so it has no upstream test coverage.
-->
