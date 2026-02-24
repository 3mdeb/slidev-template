import { test, expect } from '@playwright/test';

/**
 * Visual regression tests for slidev-template custom theme.
 *
 * Tests production-used features (based on mastering-uefi-and-intel-rot analysis):
 * - Layouts: cover (100x), two-cols (19x), two-cols-header (6x), quote (1x)
 * - Components: Footnotes, figure/figcaption, tables
 * - Features: Footer visibility, presenter mode
 */

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
