import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for slidev-template visual regression tests.
 *
 * Tests run inside mcr.microsoft.com/playwright:v1.57.0-noble container
 * against a local Slidev dev server started by scripts/run-tests.sh.
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: false, // Run sequentially for consistent screenshots
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [['html', { open: 'never' }], ['list']],

  use: {
    baseURL: process.env.SLIDEV_BASE_URL || 'http://localhost:8000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  // Expect settings for visual regression
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.001, // Allow 0.1% pixel difference
      animations: 'disabled',
    },
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // Dev server is started externally via render-slides.sh
  // No webServer config needed as container manages it
});
