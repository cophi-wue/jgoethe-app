import { test, expect } from '@playwright/test';

test('navigation to Belsazar', async ({ page }) => {
  await page.goto('http://localhost:8081/exist/jgoethe/edition.xql?c=/db/jgoethe');
  await page.locator('input[value="DRAMA"]').check();
  await page.locator('input[name="action"][value="go"]').click();

  const contentFrame = page.frame({ name: 'content' });
  // Wait for the list to load
  await expect(contentFrame.getByText('Belsazar')).toBeVisible({ timeout: 15000 });
  // Click on Belsazar in the list
  await contentFrame.getByText('Belsazar').first().click();
  
  // Verify actual work content loaded
  await expect(contentFrame.locator('div.heading1').getByText('Belsazar')).toBeVisible({ timeout: 15000 });
  await expect(contentFrame.getByText('Werkkommentar')).toBeVisible();
});

test('navigation to Götz von Berlichingen', async ({ page }) => {
  await page.goto('http://localhost:8081/exist/jgoethe/edition.xql?c=/db/jgoethe');
  await page.locator('input[value="DRAMA"]').check();
  await page.locator('input[name="action"][value="go"]').click();

  const contentFrame = page.frame({ name: 'content' });
  // In the list, it's "Götz von Berlichingen mit der eisernen Hand"
  await expect(contentFrame.getByText('Götz von Berlichingen mit der eisernen Hand')).toBeVisible({ timeout: 15000 });
  await contentFrame.getByText('Götz von Berlichingen mit der eisernen Hand').first().click();
  
  // Verify content
  // Inside the work, it might have a shorter title or different casing
  await expect(contentFrame.getByText('Götz von Berlichingen mit der eisernen Hand')).toBeVisible({ timeout: 15000 });
});

test('navigation to KONTEXTE - Stoffe', async ({ page }) => {
  await page.goto('http://localhost:8081/exist/jgoethe/edition.xql?c=/db/jgoethe');
  await page.locator('input[value="STOFFEUNDVORLAGEN"]').check();
  await page.locator('input[name="action"][value="go"]').click();

  const contentFrame = page.frame({ name: 'content' });
  // In the list, it's "Stoffe und Vorlagen einzelner Werke"
  await expect(contentFrame.getByText('Stoffe und Vorlagen einzelner Werke')).toBeVisible({ timeout: 15000 });
  await contentFrame.getByText('Stoffe und Vorlagen einzelner Werke').first().click();
  
  // Verify actual content loaded
  await expect(contentFrame.getByText('Paolo Rolli: La Lontananza')).toBeVisible({ timeout: 15000 });
});

test('full-text search for Götz', async ({ page }) => {
  await page.goto('http://localhost:8081/exist/jgoethe/edition.xql?c=/db/jgoethe');
  
  // Switch to Suchemodus
  await page.locator('#btn_query').click();
  
  // Search for "Götz" in DRAMA
  await page.locator('#i_simple').fill('Götz');
  await page.locator('input[value="DRAMA"]').check();
  await page.locator('input[name="action"][value="go"]').click();

  // Wait for hits frame to load
  const hitsFrame = page.frame({ name: 'hits' });
  await expect(hitsFrame.getByText('Treffer gefunden').first()).toBeVisible({ timeout: 15000 });
  
  // Click on the 3rd hit link (first few are hierarchy)
  const hits = hitsFrame.locator('a');
  await expect(hits.nth(2)).toBeVisible({ timeout: 15000 });
  await hits.nth(2).click();
  
  // Verify content frame shows the hit
  const contentFrame = page.frame({ name: 'content' });
  await expect(contentFrame.getByText('Götz von Berlichingen').first()).toBeVisible({ timeout: 15000 });
  await expect(contentFrame.getByText('Werkkommentar')).toBeVisible();
});
