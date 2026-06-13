import { expect, test } from '@playwright/test';

// 導覽與讀取：各主要頁面載入並顯示種子內容 (或正確的空狀態)。
test.describe('導覽與讀取', () => {
  test('儀表板顯示本月淨獲利', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByText('本月淨獲利')).toBeVisible();
  });

  test('訂單列表顯示種子訂單', async ({ page }) => {
    await page.goto('/orders');
    await expect(page.getByRole('heading', { name: '訂單' })).toBeVisible();
    await expect(page.getByText('王小明').first()).toBeVisible();
  });

  test('分析頁顯示獲利走勢', async ({ page }) => {
    await page.goto('/insights');
    await expect(page.getByText('獲利走勢')).toBeVisible();
  });

  test('客戶名單顯示客戶', async ({ page }) => {
    await page.goto('/more/customers');
    await expect(page.getByRole('heading', { name: '客戶名單' })).toBeVisible();
    await expect(page.getByText('王小明').first()).toBeVisible();
  });

  test('匯率工具正確渲染 (有金鑰顯示換算、無金鑰顯示空狀態)', async ({ page }) => {
    await page.goto('/more/fx');
    await expect(page.getByRole('heading', { name: '匯率工具' })).toBeVisible();
    // 視環境有無金鑰，settle 成「換算結果」或「空狀態」；不會閃現空狀態後再變、也不偽造資料。
    await expect(page.getByText(/= 新台幣|尚無可用匯率資料/).first()).toBeVisible();
  });

  test('更多選單可進入主檔管理', async ({ page }) => {
    await page.goto('/more');
    await expect(page.getByText('商品類別')).toBeVisible();
    await expect(page.getByText('付款方式')).toBeVisible();
  });
});
