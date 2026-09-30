import { expect, test } from '@playwright/test'

test.use({ extraHTTPHeaders: { 'X-Dev-User': process.env.E2E_DEV_USER ?? 'admin' } })

test('스타일가이드 공통 컴포넌트를 표시하고 상호작용한다', async ({ page }) => {
  await page.goto('/dev/styleguide')
  await expect(page.getByRole('heading', { name: 'Styleguide' })).toBeVisible()
  await expect(page.getByRole('tab', { name: '개요' })).toHaveAttribute('aria-selected', 'true')
  await page.getByRole('tab', { name: '이력' }).click()
  await expect(page.getByRole('tab', { name: '이력' })).toHaveAttribute('aria-selected', 'true')

  await page.getByRole('button', { name: 'Drawer 열기' }).click()
  await expect(page.getByRole('dialog')).toContainText('Drawer 예시')
  await page.getByRole('dialog').getByLabel('닫기').click()

  await page.getByRole('button', { name: 'Toast 표시' }).click()
  await expect(page.getByRole('status')).toContainText('작업이 완료되었습니다.')
  await page.getByRole('button', { name: '알림 닫기' }).click()
})
