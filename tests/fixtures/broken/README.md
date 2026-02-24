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

## Available Fixtures (12)

| Fixture File | Breaks Test | What's Broken |
|--------------|-------------|---------------|
| `test-slides-no-default-text.md` | src: directive renders content | "Default Layout" text removed |
| `test-slides-broken-images.md` | images load without errors | References non-existent images |
| `test-slides-no-cover.md` | Layouts › cover | Cover layout removed |
| `test-slides-no-twocols.md` | Layouts › two-cols | two-cols layout removed |
| `test-slides-no-twocolsheader.md` | Layouts › two-cols-header | two-cols-header layout removed |
| `test-slides-no-quote.md` | Layouts › quote | Quote layout removed |
| `test-slides-no-figure.md` | Components › figure | figure/figcaption elements removed |
| `test-slides-no-footnotes.md` | Components › Footnotes | Footnotes component removed |
| `test-slides-no-table.md` | Components › table | Table element removed |
| `test-slides-no-footer-visible.md` | Footer › visible | Slide 2 uses cover (hides footer) |
| `test-slides-footer-on-cover.md` | Footer › hidden | Cover slide uses default (shows footer) |
| `vite-config-hmr-disabled.ts` | HMR › slide content updates | `hmr: false` in vite.config.ts |

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
./scripts/run-tests.sh broken footnotes
./scripts/run-tests.sh broken table
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
