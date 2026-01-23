import { test, expect } from '@playwright/test';

/**
 * Smoke tests for slidev-template infrastructure.
 *
 * Validates that wrapper scripts and core functionality work:
 * - Dev server responds correctly
 * - Theme loads without errors
 * - src: directive includes slide content
 * - All slides load without memory issues
 *
 * Note: Slidev keeps multiple slides in DOM for transitions,
 * so we verify content rather than specific element visibility.
 */

test.describe('Dev Server', () => {
  test('responds on configured port', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBe(200);
  });

  test('theme loads without console errors', async ({ page }) => {
    const errors: string[] = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.goto('/1');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);

    const criticalErrors = errors.filter(
      (e) =>
        !e.includes('favicon') &&
        !e.includes('404') &&
        !e.includes('analytics') &&
        !e.includes('WebSocket')
    );
    expect(criticalErrors).toHaveLength(0);
  });

  test('src: directive renders content', async ({ page }) => {
    await page.goto('/2');
    await page.waitForLoadState('networkidle');

    const pageText = await page.textContent('body');
    expect(pageText).toContain('Default Layout');
    expect(pageText).not.toContain('src:');
  });
});

test.describe('Navigation', () => {
  test('all slides load without OOM', async ({ page }) => {
    // 13 slides: 1 cover + 12 from test-slides.md
    for (let i = 1; i <= 13; i++) {
      await page.goto(`/${i}`);
      await page.waitForLoadState('networkidle', { timeout: 15000 });
      expect(await page.textContent('body')).toBeTruthy();
    }
  });

  test('presenter mode accessible', async ({ page }) => {
    const response = await page.goto('/presenter/1');
    expect(response?.status()).toBe(200);
  });

  test('overview mode accessible', async ({ page }) => {
    const response = await page.goto('/overview');
    expect(response?.status()).toBe(200);
  });
});

test.describe('Assets', () => {
  test('images load without errors', async ({ page }) => {
    await page.goto('/12');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    const brokenImages = await page.evaluate(() => {
      const images = document.querySelectorAll('img');
      return Array.from(images).filter(
        (img) => !img.complete || img.naturalHeight === 0
      ).length;
    });
    expect(brokenImages).toBe(0);
  });
});
