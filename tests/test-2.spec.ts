import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('http://localhost:8765/index.html');
  await page.getByRole('link', { name: 'Der junge Goethe in seiner' }).click();
  await page.locator('#WERKE').getByRole('checkbox').check();
  await page.getByRole('checkbox', { name: 'Weiterführendes' }).check();
  await page.locator('#ygtvt1').click();
  await expect(page.locator('#ygtvlabelel150')).toContainText('Götz von Berlichingen mit der eisernen Hand.');
});