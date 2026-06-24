import { expect, test } from '@playwright/test';

test.describe('訂單流程', () => {
  test('開啟訂單詳情顯示財務摘要與收款狀態', async ({ page }) => {
    await page.goto('/orders');
    await page.getByText('王小明').first().click();
    await expect(page.getByText('財務摘要')).toBeVisible();
    await expect(page.getByText('收款狀態')).toBeVisible();
  });

  test('狀態快篩可切換', async ({ page }) => {
    await page.goto('/orders');
    await expect(page.getByText('王小明').first()).toBeVisible();
    // 狀態快篩 chip 在最前 (列表訂單列亦含狀態字樣，故取第一個)
    await page.getByRole('button', { name: /已交付/ }).first().click();
    // 已交付狀態的訂單仍在 (王小明 BL-0001)
    await expect(page.getByText('王小明').first()).toBeVisible();
  });

  test('新增訂單並導向詳情', async ({ page }) => {
    await page.goto('/orders/new');
    await expect(page.getByRole('heading', { name: '新增訂單' })).toBeVisible();
    await page.getByLabel('客戶名稱').fill('端對端測試客戶');

    // 選擇商品類別 (BLSelectRow：label span 後的 button)
    await page.getByText('商品類別 (至少一個)').locator('xpath=following-sibling::button').click();
    await page.getByRole('button', { name: '美妝', exact: true }).click();

    await page.getByLabel('收款金額 (TWD)').fill('1500');
    await page.getByRole('button', { name: '儲存' }).click();

    await expect(page.getByText('端對端測試客戶')).toBeVisible();
    await expect(page.getByText('財務摘要')).toBeVisible();
  });
});
