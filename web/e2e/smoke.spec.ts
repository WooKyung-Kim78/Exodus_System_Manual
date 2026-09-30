import { expect, test } from '@playwright/test'

test.use({ extraHTTPHeaders: { 'X-Dev-User': process.env.E2E_DEV_USER ?? 'admin' } })

test('문서 목록과 미리보기 진입', async ({ page }) => {
  await page.goto('/manual')
  await expect(page.getByRole('heading', { name: 'Manuals' })).toBeVisible()
  await expect(page).toHaveTitle(/EXODUS System Manual/)
})
