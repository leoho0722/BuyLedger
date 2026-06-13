import { expect, test } from '@playwright/test';

test.describe('開團', () => {
  test('開團列表顯示種子開團', async ({ page }) => {
    await page.goto('/campaigns');
    await expect(page.getByRole('heading', { name: '開團' })).toBeVisible();
    await expect(page.getByText('六月日本團')).toBeVisible();
  });

  test('開團詳情顯示結團結算與客戶分貨', async ({ page }) => {
    await page.goto('/campaigns');
    await page.getByText('六月日本團').first().click();
    await expect(page.getByText('結團結算').first()).toBeVisible();
    await expect(page.getByText('客戶分貨')).toBeVisible();
    await expect(page.getByText('應收金額')).toBeVisible();
  });
});
