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

Make sure to use relative paths in slides e.g. `../img/` instead of `/img` as
scripts run `slidev` from `slidev-template` directory.

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

## Export presentation

To export slides to PDF use

```sh
./slidev-template/scripts/ci/gen_slides.sh <path/to/slides.metadata>
```

Generated slides will be in `slidev-template/output` directory.
