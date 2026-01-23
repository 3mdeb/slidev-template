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

## Testing

Visual regression and smoke tests use Playwright to verify template rendering.
Tests run entirely in Docker containers for consistent results.

### Quick Start

```sh
# Run all tests (single command - starts server, runs tests, cleans up)
./scripts/run-tests.sh

# Or use a specific port
SLIDEV_PORT=8002 ./scripts/run-tests.sh
```

### Commands

| Command | Description |
|---------|-------------|
| `./scripts/run-tests.sh` | Run all tests (default) |
| `./scripts/run-tests.sh test` | Same as above |
| `./scripts/run-tests.sh update` | Update visual regression baselines |
| `./scripts/run-tests.sh dev` | Start dev server for manual testing |
| `./scripts/run-tests.sh clean` | Remove test artifacts and containers |

### Developer Workflow

1. **Make changes** to theme, layouts, or components
2. **Run tests** to verify nothing broke:
   ```sh
   ./scripts/run-tests.sh
   ```
3. **If visual changes are intentional**, update baselines:
   ```sh
   ./scripts/run-tests.sh update
   ```
4. **Review baseline changes** in `tests/visual-regression.spec.ts-snapshots/`
5. **Commit** both code changes and updated baselines

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SLIDEV_PORT` | 8000 | Port for dev server |
| `SLIDEV_NODE_MAX_OLD_SPACE` | 4096 | Node.js memory limit (MB) |

### Manual Browser Testing

For debugging or exploratory testing:

```sh
# Start dev server (keeps running until Ctrl+C)
./scripts/run-tests.sh dev

# Open in browser
# http://localhost:8000     - Slide view
# http://localhost:8000/presenter/1  - Presenter mode
# http://localhost:8000/overview     - Overview mode
```

### Test Coverage

Tests verify production-used features based on real presentation analysis:

**Layouts tested:**
- `cover` (100+ uses in production)
- `two-cols` (19 uses)
- `two-cols-header` (6 uses)
- `quote` (1 use)

**Components tested:**
- Footer (global-top.vue) - visibility on cover vs content slides
- Footnotes component
- Figure/figcaption styling
- Tables with inline styles
- Speaker notes (hidden in slides, visible in presenter)

### Test Structure

| File | Purpose |
|------|---------|
| `tests/fixtures/test-slides.md` | Sample slides for all layouts |
| `tests/smoke.spec.ts` | Basic functionality (server, navigation, assets) |
| `tests/visual-regression.spec.ts` | Screenshot comparison for layouts/components |
| `playwright.config.ts` | Test configuration |
| `scripts/run-tests.sh` | Container-based test runner |
| `tests/*.spec.ts-snapshots/` | Baseline screenshots (commit these) |

## Features

A set of common styles we should be following.

### Images

Use `figure` class, and `figcaption` class if image comes from an external source.

```
<figure>
  <img src="/@fs/repo/img/arch5141/bsf_uefi_event_log.png" width="800px">
  <figcaption>
    "Building Secure Firmware", Jiewen Yao, Vincent Zimmer, 2020
  </figcaption>
</figure>
```
