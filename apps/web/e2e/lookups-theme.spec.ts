import { expect, test } from '@playwright/test';

test.describe('主檔與外觀', () => {
  test('商品類別主檔顯示種子項目', async ({ page }) => {
    await page.goto('/more/lookups/category');
    await expect(page.getByText('美妝')).toBeVisible();
    await expect(page.getByText('3C')).toBeVisible();
  });

  test('付款方式顯示無卡/銀行匯款/貨到付款徽章', async ({ page }) => {
    await page.goto('/more/lookups/payment-method');
    await expect(page.getByText('無卡分期')).toBeVisible();
    await expect(page.getByText('銀行轉帳')).toBeVisible();
    await expect(page.getByText('貨到付款').first()).toBeVisible();
  });

  test('設定可切換深色外觀', async ({ page }) => {
    await page.goto('/more/settings');
    await expect(page.getByRole('heading', { name: '設定' })).toBeVisible();
    await page.getByRole('button', { name: '深色', exact: true }).click();
    await expect(page.locator('html')).toHaveClass(/dark/);
  });
});
