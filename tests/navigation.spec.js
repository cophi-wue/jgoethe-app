import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('http://localhost:8765/index.html');
  await page.getByRole('link', { name: 'Der junge Goethe in seiner' }).click();
  await page.locator('#WERKE').getByRole('checkbox').check();
  await page.getByRole('checkbox', { name: 'Weiterführendes' }).check();
  await page.locator('#ygtvt1').click();
  await page.getByRole('link', { name: 'Götz von Berlichingen mit der' }).click();
  await page.getByRole('link', { name: 'Götz von Berlichingen mit der' }).press('ControlOrMeta+Shift+J');
  await page.getByRole('link', { name: 'Götz von Berlichingen mit der' }).press('ControlOrMeta+Shift+K');
  await page.locator('iframe[name="content"]').contentFrame().getByText('Götz von Berlichingenmit').click();
  await page.locator('iframe[name="content"]').contentFrame().getByText('Götz von Berlichingenmit dereisernen Hand. Werkkommentar Ein Schauspiel.').press('Escape');
  await page.getByRole('heading', { name: 'Götz von Berlichingen mit der' }).click();
});