---
layout: cover
background: /intro.png
---

<!-- BROKEN: First slide uses cover layout, so footer won't be visible on slide 2 -->
<!-- This breaks the "footer visible on content slides" test -->

# Default Layout Made Cover

This slide uses cover layout instead of default.
Footer should be hidden on cover slides.

<!--
Speaker notes are heavily used in real presentations.
This tests that notes don't appear in slide view.
-->

---
layout: cover
background: /intro.png
---

# Cover Layout

Most frequently used layout (100+ times in mastering repo)

<!--
Cover slides are used for section headers throughout presentations.
-->

---
layout: two-cols
---

# Two Columns Layout

Left column content with text.

- Point one
- Point two
- Point three

::right::

# Right Column

Right column content.

- More points
- Additional info

<!--
two-cols is the second most used layout (19 times in real usage).
-->

---
layout: two-cols-header
---

# Two Columns with Header

::left::

## Left Side

Content on the left side of the slide.

::right::

## Right Side

Content on the right side.

<!--
two-cols-header used 6 times in production.
-->

---

# Figure with Caption

<figure>
  <img src="/3mdeb-logo.png" width="200">
  <figcaption>
    3mdeb Logo - Testing figure/figcaption styling
  </figcaption>
</figure>

Figure styling is defined in theme/styles/slides.css

---

# Footnotes Component

This slide tests the custom Footnotes component.<sup>1</sup>

Another point with a footnote.<sup>2</sup>

<Footnotes separator x="l" y="col">
  <Footnote :number=1>First footnote reference - Footnotes.vue component</Footnote>
  <Footnote :number=2>Second footnote reference - tests numbering</Footnote>
</Footnotes>

---

# Table Styling

<style>
table, th, td { font-size: 0.8rem !important; }
th { text-align: left !important; }
</style>

| Feature | Status | Notes |
|---------|--------|-------|
| Footer | ✓ | global-top.vue |
| Footnotes | ✓ | Custom component |
| Figure styles | ✓ | CSS in theme |
| Tables | ✓ | Remark-style CSS |

Inline styles are commonly used to customize tables.

---
layout: quote
---

# "The only layout besides cover and two-cols actually used"

Testing the quote layout (used 1 time in real slides)

---

# Code Blocks

```typescript
// Code highlighting test
interface SlideConfig {
  theme: string
  layout: string
  copyright?: string
}

function loadSlide(config: SlideConfig): void {
  console.log(`Loading: ${config.theme}`)
}
```

---

# Centered Image

<center>
  <img src="/dasharo-sygnet.svg" width="150" alt="Dasharo">
</center>

Images are often wrapped in `<center>` tags in real slides.

---

# Multiple Assets

<div class="flex gap-4 justify-center items-center">
  <img src="/3mdeb-logo.png" width="100" alt="3mdeb">
  <img src="/dasharo-sygnet.svg" width="100" alt="Dasharo">
  <img src="/logo.png" width="100" alt="Logo">
</div>

Testing that public assets load correctly from /public/ directory.

---
layout: cover
background: /intro.png
---

## Final Cover Slide

Testing cover layout at end of presentation
