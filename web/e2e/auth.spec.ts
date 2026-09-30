import { expect, test } from '@playwright/test'

test.use({ extraHTTPHeaders: { 'X-Dev-User': 'none' } })

test('403과 404 화면은 안내와 문서 목록 이동을 제공한다', async ({ page }) => {
  await page.goto('/auth/error403')
  await expect(page.getByRole('heading', { name: '403' })).toBeVisible()
  await expect(page.getByText('이 페이지에 접근할 권한이 없습니다.')).toBeVisible()
  await expect(page.getByRole('link', { name: '문서 목록으로' })).toHaveAttribute('href', '/manual')

  await page.goto('/auth/error404')
  await expect(page.getByRole('heading', { name: '404' })).toBeVisible()
  await expect(page.getByText('요청한 페이지를 찾을 수 없습니다.')).toBeVisible()
})

test('자격 증명이 제공되면 로그인 후 반환 경로로 이동한다', async ({ page }) => {
  test.skip(!process.env.E2E_USER || !process.env.E2E_PASSWORD, 'E2E_USER와 E2E_PASSWORD가 설정되지 않았습니다.')

  await page.goto('/auth/sign-in?returnUrl=%2Fmanual')
  await page.getByLabel('ID').fill(process.env.E2E_USER!)
  await page.getByLabel('Password').fill(process.env.E2E_PASSWORD!)
  await page.getByRole('button', { name: 'Sign In' }).click()
  await expect(page).toHaveURL(/\/manual$/)
  await expect(page.getByRole('heading', { name: 'Manuals' })).toBeVisible()
})
