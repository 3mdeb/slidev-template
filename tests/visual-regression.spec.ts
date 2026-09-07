import { test, expect, type Page } from '@playwright/test';

/**
 * Visual regression tests for slidev-template custom theme.
 *
 * Tests production-used features (based on mastering-uefi-and-intel-rot analysis):
 * - Layouts: cover (100x), two-cols (19x), two-cols-header (6x), quote (1x)
 * - Layouts defined here: two-cols-top (screenshot plus grid geometry)
 * - Components: Footnotes, figure/figcaption, tables
 * - Features: Footer visibility, presenter mode
 */

/** Bounding box of a single element, in screen coordinates. */
async function box(page: Page, selector: string) {
  const rect = await page.locator(selector).boundingBox();
  if (!rect) {
    throw new Error(`${selector} has no bounding box (missing or hidden)`);
  }
  return rect;
}

test.describe('Layouts', () => {
  test('cover', async ({ page }) => {
    await page.goto('/3');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page).toHaveScreenshot('layout-cover.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });

  test('two-cols', async ({ page }) => {
    await page.goto('/4');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page).toHaveScreenshot('layout-two-cols.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });

  test('two-cols-header', async ({ page }) => {
    await page.goto('/5');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page).toHaveScreenshot('layout-two-cols-header.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });

  test('two-cols-top', async ({ page }) => {
    await page.goto('/16');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page).toHaveScreenshot('layout-two-cols-top.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });

  test('quote', async ({ page }) => {
    await page.goto('/9');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page).toHaveScreenshot('layout-quote.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });
});

test.describe('Components', () => {
  test('figure with figcaption', async ({ page }) => {
    await page.goto('/6');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page.locator('figure')).toBeVisible();
    await expect(page.locator('figcaption')).toContainText('3mdeb Logo');
    await expect(page).toHaveScreenshot('component-figure.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });

  test('Footnotes', async ({ page }) => {
    await page.goto('/7');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page.locator('.footnote')).toBeVisible();
    await expect(page).toHaveScreenshot('component-footnotes.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });

  test('table', async ({ page }) => {
    await page.goto('/8');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page.locator('table')).toBeVisible();
    await expect(page).toHaveScreenshot('component-table.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });
});

test.describe('Footer', () => {
  test('visible on content slides', async ({ page }) => {
    await page.goto('/2');
    await page.waitForLoadState('networkidle');
    const footer = page.locator('footer');
    await expect(footer).toBeVisible();
    await expect(footer).toContainText('Copyright');
  });

  test('hidden on cover slides', async ({ page }) => {
    await page.goto('/3');
    await page.waitForLoadState('networkidle');
    await expect(page.locator('footer')).not.toBeVisible();
  });
});

test.describe('Presenter Mode', () => {
  test('renders with notes panel', async ({ page }) => {
    await page.goto('/presenter/2');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page).toHaveScreenshot('presenter-with-notes.png', {
      maxDiffPixelRatio: 0.02,
      fullPage: true,
    });
  });
});

test.describe('Font Size Classes', () => {
  test('code-10px and code-12px apply correctly', async ({ page }) => {
    await page.goto('/13'); // Font Size Classes slide
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
    await expect(page).toHaveScreenshot('font-size-classes.png', {
      maxDiffPixelRatio: 0.01,
      fullPage: true,
    });
  });
});

/**
 * two-cols-top lives in this repo (theme/layouts/two-cols-top.vue), so its
 * geometry is asserted directly instead of resting on a screenshot alone: the
 * header row is sized to its content, the columns are separated by a gutter,
 * and a bottom slot spans both columns at the slide bottom.
 *
 * Boxes are measured in screen coordinates, after Slidev's scaling transform,
 * so assertions compare positions against each other or against a fraction of
 * the slide, never against raw CSS lengths.
 */
test.describe('two-cols-top geometry', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/16');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);
  });

  test('routes slot content to header, columns and bottom', async ({ page }) => {
    const layout = page.locator('.slidev-layout.two-cols-top');
    await expect(layout).toHaveCount(1);
    await expect(layout.locator('.col-header')).toContainText('Two Columns Top');
    await expect(layout.locator('.col-left')).toContainText('Left Side');
    await expect(layout.locator('.col-right')).toContainText('Right Side');
    await expect(layout.locator('.col-bottom')).toContainText(
      'Bottom row spanning both columns'
    );
  });

  test('header is sized to its content and spans both columns', async ({ page }) => {
    const layout = await box(page, '.slidev-layout.two-cols-top');
    const header = await box(page, '.two-cols-top .col-header');
    const left = await box(page, '.two-cols-top .col-left');
    const right = await box(page, '.two-cols-top .col-right');

    // The columns start where the header ends, so the header row takes only
    // the height of its content.
    expect(Math.abs(left.y - (header.y + header.height))).toBeLessThan(2);
    expect(Math.abs(right.y - left.y)).toBeLessThan(2);

    // A 50%/50% row split would push the columns to the vertical middle
    // instead.
    expect(left.y).toBeLessThan(layout.y + layout.height * 0.4);

    // Header spans the full width of both columns.
    expect(Math.abs(header.x - left.x)).toBeLessThan(2);
    expect(Math.abs(header.x + header.width - (right.x + right.width))).toBeLessThan(2);
  });

  test('columns are separated by a gutter and stay equal width', async ({ page }) => {
    const left = await box(page, '.two-cols-top .col-left');
    const right = await box(page, '.two-cols-top .col-right');

    const gutter = right.x - (left.x + left.width);
    expect(gutter).toBeGreaterThan(8);
    expect(Math.abs(right.width - left.width)).toBeLessThan(2);
  });

  test('bottom slot spans both columns and is pinned to the slide bottom', async ({
    page,
  }) => {
    const layout = await box(page, '.slidev-layout.two-cols-top');
    const left = await box(page, '.two-cols-top .col-left');
    const right = await box(page, '.two-cols-top .col-right');
    const bottom = await box(page, '.two-cols-top .col-bottom');

    // Below both columns, spanning their combined width.
    expect(bottom.y).toBeGreaterThanOrEqual(left.y + left.height - 2);
    expect(Math.abs(bottom.x - left.x)).toBeLessThan(2);
    expect(Math.abs(bottom.x + bottom.width - (right.x + right.width))).toBeLessThan(2);

    // Pinned to the bottom rather than following the column content.
    expect(bottom.y + bottom.height).toBeGreaterThan(layout.y + layout.height * 0.8);
  });
});
