import { expect, test } from '@playwright/test'

test.use({ extraHTTPHeaders: { 'X-Dev-User': process.env.E2E_ADMIN_USER ?? 'admin' } })

const pages = [
  { path: '/admin/user', heading: 'Users' },
  { path: '/admin/code', heading: 'Common Codes' },
  { path: '/admin/setting', heading: 'Settings' },
  { path: '/admin/section-template', heading: 'Section Templates' },
]

for (const item of pages) {
  test(`관리자는 ${item.heading} 화면을 조회할 수 있다`, async ({ page }) => {
    await page.goto(item.path)
    await expect(page.getByRole('heading', { name: item.heading })).toBeVisible()
  })
}
