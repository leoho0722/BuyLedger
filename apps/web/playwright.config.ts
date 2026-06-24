import { defineConfig, devices } from '@playwright/test';

// Playwright 驗收設定：對 docker compose 起的前端 (:3000) 跑端對端測試
export default defineConfig({
  testDir: './e2e',
  timeout: 40_000,
  expect: { timeout: 12_000 },
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: [['list']],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
    locale: 'zh-TW',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
