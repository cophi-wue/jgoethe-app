import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  // Recording..
  await page.goto('http://localhost:8765/index.html');
  await page.getByRole('link', { name: 'Der junge Goethe in seiner' }).click();
  await page.locator('#WERKE').getByRole('checkbox').check();
  await page.getByRole('checkbox', { name: 'Weiterführendes' }).check();
  await page.getByRole('link', { name: 'Dramatische Schriften' }).click();
  await expect(page.locator('iframe[name="content"]').contentFrame().locator('div')).toContainText('Dramatische Schriften');
  await expect(page.locator('#ygtvlabelel150')).toContainText('Götz von Berlichingen mit der eisernen Hand.');
  await page.getByRole('link', { name: 'Götz von Berlichingen mit der' }).click();
  await expect(page.locator('iframe[name="content"]').contentFrame().locator('body')).toContainText('Götz von Berlichingenmit dereisernen Hand.');
  await page.getByRole('link').filter({ hasText: /^$/ }).nth(3).click();
  await expect(page.locator('iframe[name="content"]').contentFrame().locator('#JG5180')).toContainText('Schwarzenberg in Franken.Herberge.');;
})
