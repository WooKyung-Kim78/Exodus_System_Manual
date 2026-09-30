import { expect, test } from '@playwright/test'

test.use({ extraHTTPHeaders: { 'X-Dev-User': 'none' } })

test('admin이 실제 로그인한 뒤 문서와 관리자 화면을 순회한다', async ({ page }) => {
  test.skip(!process.env.E2E_USER || !process.env.E2E_PASSWORD, 'E2E_USER와 E2E_PASSWORD가 설정되지 않았습니다.')

  await page.goto('/auth/sign-in')
  await page.getByLabel('ID').fill(process.env.E2E_USER!)
  await page.getByLabel('Password').fill(process.env.E2E_PASSWORD!)
  await page.getByRole('button', { name: 'Sign In' }).click()
  await expect(page).toHaveURL(/\/$/)
  await expect(page.getByRole('heading', { name: /안녕하세요,/ })).toBeVisible()
  await page.getByRole('link', { name: '매뉴얼 목록 열기' }).click()
  await expect(page.getByRole('heading', { name: 'Manuals' })).toBeVisible()
  await page.getByRole('button', { name: 'New Manual' }).click()
  await expect(page.getByRole('dialog', { name: 'New System Manual' })).toBeVisible()
  const newDialog = page.getByRole('dialog', { name: 'New System Manual' })
  await expect(newDialog.getByRole('textbox', { name: 'Model Name' })).toBeVisible()
  await expect(newDialog.getByRole('combobox', { name: /Job Number/ })).toBeVisible()
  await expect(newDialog.locator('select').nth(1)).toBeVisible() // Label
  await expect(newDialog.locator('select').nth(2)).toBeVisible() // Cooling
  await expect(newDialog.getByRole('textbox', { name: 'Option' })).toBeVisible()
  await expect(newDialog.getByRole('textbox', { name: 'Version' })).toBeVisible()
  await expect(newDialog.getByRole('combobox', { name: 'Page Size' })).toBeVisible()
  await page.getByRole('dialog').getByRole('button', { name: '취소' }).click()

  // 병렬 쓰기 API 검증이 만드는 E2E 임시 문서는 finally에서 삭제되므로, 기존 문서를 순회한다.
  await page.locator('tbody a').filter({ hasNotText: 'E2E-' }).first().click()
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible()
  await page.getByRole('link', { name: '미리보기' }).click()
  await expect(page.getByRole('heading', { name: '미리보기' })).toBeVisible()
  await expect(page.frameLocator('iframe[title="문서 미리보기"]').locator('#docSheet')).toBeVisible()
  await expect(page.getByRole('link', { name: '문서 정보' })).toBeVisible()
  await expect(page.getByRole('button', { name: '인쇄' })).toBeVisible()
  await page.getByRole('button', { name: '페이지 보기' }).click()
  await expect(page.locator('iframe[title="페이지 보기"]')).toBeVisible()
  await page.getByRole('button', { name: '연속 보기' }).click()
  await page.getByRole('link', { name: '편집기' }).click()
  await expect(page.getByRole('heading', { name: '문서 편집기' })).toBeVisible()

  for (const item of [
    { path: '/admin/user', heading: '사용자 관리' },
    { path: '/admin/code', heading: '공통 코드 관리' },
    { path: '/admin/setting', heading: '메일 설정' },
    { path: '/admin/section-template', heading: '목차 템플릿' },
  ]) {
    await page.goto(item.path)
    await expect(page.getByRole('heading', { name: item.heading })).toBeVisible()
  }
})
