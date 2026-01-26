# Welcome to [Slidev](https://github.com/slidevjs/slidev)!

## Preparation

This repository is supposed to be used as a submodule to repository with slides.
Minimal slides repository structure should look like this

```text
slides
├── slides.metadata
├── slides-template.md
└── slidev-template
```

With `slides.metadata` and `slides-template.md` copied from this repository.
`slides-template.md` is used by `render-slides.sh` and `gen_slides.sh` scripts
and needs to be modified before use. You need to, at minimum, replace `<TITLE>`.
There are 2 other variables, that are replaced dynamically by scripts:

- `<DAY>` - replaced with first character in slide filename e.g. `1-slides.md`
  would result in `<DAY>` being replaced with `1`. You can remove line
  containing this variable if you don't need it.
- `<SRC>` - path to slide we are trying to render.

`slides.metadata` is a `yaml` file containing information needed for slides
generation and is needed by `gen_slides.sh` script.

Example:

```yml
slides:
  - input_file: "path/to/slides.md"
    range: "1-10"
    output_file: "1.pdf"
  - input_file: "path/to/presentation.md"
    range: "3-"
    output_file: "2.pdf"
```

- `input_file` - path to `.md` file you want to convert to PDF
- `range` - which pages to include. Leave empty to include all pages
- `output_file` - output PDF filename.

## Relative paths

Scripts run `slidev` from the `slidev-template` directory and create a symlink
at `slidev-template/slides` pointing to your presentation repository. This
enables consistent path handling:

- `/` maps to the `slidev-template` directory
- `/slides/` maps to your presentation repository (parent of `slidev-template`)

**Recommended**: Use `/slides/` prefix for all asset paths in your slides:

```markdown
![Logo](/slides/img/logo.png)
```

This approach works reliably regardless of the slide file's location within
your presentation repository.

## Local preview

Usage:

```sh
./slidev-template/scripts/render-slides.sh <path/to/slides.md>
```

Example:

```text
./slidev-template/scripts/render-slides.sh pages/presentation.md
(...)
  ●■▲
  Slidev  v52.0.0

  theme       ./theme
  css engine  unocss
  entry       /repo/slidev-template/slides.md

  public slide show   > http://localhost:8000/
  presenter mode      > http://localhost:8000/presenter/
  slides overview     > http://localhost:8000/overview/
  export slides       > http://localhost:8000/export/
  remote control      > http://172.17.0.3:8000/entry/

  shortcuts           > restart | open | edit | quit | qrcode
```

You can then open given links to e.g. preview your presentation.

You can override the default copyright string using an `COPYRIGHT`
environment variable:

```bash
COPYRIGHT="All Rights Reserved by 3mdeb Sp. z o.o." \
  ./slidev-template/scripts/render-slides.sh <path/to/slides.md>
```

Default copyright is `3mdeb Sp. z o.o. Licensed under the CC BY-SA 4.0`.

## Export presentation

To export slides to PDF use

```sh
./slidev-template/scripts/ci/gen_slides.sh <path/to/slides.metadata>
```

Generated slides will be in `slidev-template/output` directory.

You can override the default copyright string using an `COPYRIGHT`
environment variable:

```bash
COPYRIGHT="All Rights Reserved by 3mdeb Sp. z o.o." \
  ./slidev-template/scripts/ci/gen_slides.sh <path/to/slides.metadata>
```

Default copyright is `3mdeb Sp. z o.o. Licensed under the CC BY-SA 4.0`.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `COPYRIGHT` | `3mdeb Sp. z o.o. Licensed under the CC BY-SA 4.0` | Copyright string for slide footer |
| `SLIDEV_PORT` | `8000` | Port for development server |
| `SLIDEV_NODE_MAX_OLD_SPACE` | `4096` | Node.js max heap size in MB |
| `SLIDES_TITLE` | `3mdeb Presentation` | Presentation title |
| `PLAYWRIGHT_IMAGE` | `mcr.microsoft.com/playwright:v1.57.0-noble` | Docker image for Slidev operations |

Example overriding multiple variables:

```bash
SLIDEV_PORT=8080 PLAYWRIGHT_IMAGE=mcr.microsoft.com/playwright:v1.50.0-noble \
  ./slidev-template/scripts/render-slides.sh slides.md
```
