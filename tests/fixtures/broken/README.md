# Broken Fixtures for Regression Proof

This directory contains intentionally broken test fixtures that prove each
Playwright test independently detects its specific regression.

## How It Works

Each broken fixture modifies exactly one aspect of `test-slides.md` to break
a specific test while keeping other tests passing. When run with a broken
fixture, the corresponding test should **FAIL**, proving it catches the
regression.

Most fixtures use Slidev's `src:` frontmatter with hash range notation to
minimize duplication - they import unchanged slides from `base-slides.md`
and only inline the specific slide that needs to be broken.

## Available Fixtures (14)

| Fixture File | Breaks Test | What's Broken |
|--------------|-------------|---------------|
| `test-slides-no-default-text.md` | src: directive renders content | "Default Layout" text removed |
| `test-slides-broken-images.md` | images load without errors | References non-existent images |
| `test-slides-no-cover.md` | Layouts › cover | Cover layout removed |
| `test-slides-no-twocols.md` | Layouts › two-cols | two-cols layout removed |
| `test-slides-no-twocolsheader.md` | Layouts › two-cols-header | two-cols-header layout removed |
| `test-slides-no-twocolstop.md` | Layouts › two-cols-top, two-cols-top geometry | two-cols-top slide moved to the built-in two-cols-header layout |
| `test-slides-no-quote.md` | Layouts › quote | Quote layout removed |
| `test-slides-no-figure.md` | Components › figure | figure/figcaption elements removed |
| `test-slides-no-footnotes.md` | Components › Footnotes | Footnotes component removed |
| `test-slides-no-table.md` | Components › table | Table element removed |
| `test-slides-no-footer-visible.md` | Footer › visible | Slide 2 uses cover (hides footer) |
| `test-slides-footer-on-cover.md` | Footer › hidden | Cover slide uses default (shows footer) |
| `vite-config-hmr-disabled.ts` | HMR › slide content updates | `hmr: false` in vite.config.ts |
| `test-slides-no-plantuml.md` | Diagrams › PlantUML | PlantUML diagram removed, replaced with plain text |

## Broken `env.sh` Fixtures (4)

These break the `.slidev.conf` configuration loader instead of the slide
content, and are exercised by `scripts/test-slidev-conf.sh` rather than
Playwright. Each one must make the listed tests fail.

| Fixture File | Breaks Test | What's Broken |
|--------------|-------------|---------------|
| `env-no-conf.sh` | config file sets COPYRIGHT / reaches slides.md | `.slidev.conf` never read (pre-feature behaviour) |
| `env-no-precedence.sh` | env COPYRIGHT overrides/beats config | Config clobbers environment variables |
| `env-no-slidev-conf-var.sh` | SLIDEV_CONF selects/honours a different file | `SLIDEV_CONF` ignored, path hardcoded |
| `env-set-e-abort.sh` | does not abort under `set -e` / gen_slides.sh survives | Loader returns non-zero, killing `set -e` callers |

Run them with:

```bash
./scripts/test-slidev-conf.sh broken
./scripts/test-slidev-conf.sh broken set-e-abort
```

## Tests Not Fixture-Breakable (6)

These tests can't be broken by fixture changes alone:

| Test | Why Not Breakable |
|------|-------------------|
| responds on configured port | Tests HTTP response, not content |
| theme loads without console errors | Slidev handles invalid components gracefully |
| all slides load without OOM | Slidev shows last slide for missing numbers |
| presenter mode accessible | Tests route exists |
| overview mode accessible | Tests route exists |
| renders with notes panel | Screenshot doesn't verify notes content |

## Usage

```bash
# Test ALL broken fixtures
./scripts/run-tests.sh broken

# Test specific fixture
./scripts/run-tests.sh broken cover
./scripts/run-tests.sh broken two-cols-top
./scripts/run-tests.sh broken footnotes
./scripts/run-tests.sh broken table

# .slidev.conf tests + their regression proof (shell only, no Docker)
./scripts/run-tests.sh conf
```

## Expected Output

When a broken fixture test **passes** (test correctly fails):
```
✓ PASS: Test correctly FAILED when footnotes was broken
PROOF COMPLETE: footnotes test detects regressions ✓
```

When a broken fixture test **fails** (test didn't catch the regression):
```
✗ FAIL: Test PASSED but should have FAILED
  Test does NOT detect regressions!
```

## Slidev src: Import Syntax

Most fixtures use this pattern to minimize duplication:

```yaml
---
src: ./base-slides.md#2-5
---
```

This imports slides 2-5 from `base-slides.md`. The `run-tests.sh` script
automatically copies `test-slides.md` to `base-slides.md` during setup.
