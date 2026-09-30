import { expect, test } from '@playwright/test'

test.use({ extraHTTPHeaders: { 'X-Dev-User': process.env.E2E_ADMIN_USER ?? 'admin' } })

const pages = [
  { path: '/admin/user', heading: '사용자 관리' },
  { path: '/admin/code', heading: '공통 코드 관리' },
  { path: '/admin/setting', heading: '메일 설정' },
  { path: '/admin/section-template', heading: '목차 템플릿' },
]

for (const item of pages) {
  test(`관리자는 ${item.heading} 화면을 조회할 수 있다`, async ({ page }) => {
    await page.goto(item.path)
    await expect(page.getByRole('heading', { name: item.heading })).toBeVisible()
  })
}
