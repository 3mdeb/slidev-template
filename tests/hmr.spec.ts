import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

/**
 * HMR (Hot Module Replacement) test for slidev-template.
 *
 * Verifies that file changes are reflected in the browser without
 * requiring a manual restart of the dev server.
 *
 * This test addresses the concern from PR #23 review where disabling
 * file polling (usePolling: false in vite.config.ts) broke HMR for
 * some users — even simple letter changes required restarting slidev.
 *
 * The test modifies test-slides.md on disk and verifies the browser
 * picks up the change via Vite's HMR WebSocket connection.
 */

const TEST_REPO_DIR = process.env.TEST_REPO_DIR || '/test-repo';
const SLIDES_FILE = path.join(TEST_REPO_DIR, 'test-slides.md');

test.describe('Hot Module Replacement', () => {
  test('slide content updates after file change without reload', async ({ page }) => {
    // Navigate to slide 2 (Default Layout from test-slides.md)
    await page.goto('/2');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(500);

    // Verify initial content
    const initialText = await page.textContent('body');
    expect(initialText).toContain('Default Layout');
    expect(initialText).not.toContain('HMR_TEST_MARKER');

    // Read current file
    const original = fs.readFileSync(SLIDES_FILE, 'utf-8');

    // Modify: add unique marker text to the Default Layout slide
    const modified = original.replace(
      'This is the default layout with common elements:',
      'This is the default layout with common elements:\n\nHMR_TEST_MARKER'
    );
    fs.writeFileSync(SLIDES_FILE, modified, 'utf-8');

    try {
      // Wait for HMR to propagate (Vite typically updates within 1-2s)
      // We poll the page content rather than reloading
      await expect(async () => {
        const text = await page.textContent('body');
        expect(text).toContain('HMR_TEST_MARKER');
      }).toPass({ timeout: 10000, intervals: [500, 1000, 1000, 1000, 1000] });
    } finally {
      // Always restore original file
      fs.writeFileSync(SLIDES_FILE, original, 'utf-8');
    }
  });
});
