import { expect, request as playwrightRequest, test } from '@playwright/test'

const readerId = process.env.E2E_READER_USER ?? 'han.reader'
const crossTeamUserId = process.env.E2E_CROSS_TEAM_USER ?? 'kim.rf'

test('READER는 문서를 읽지만 편집 UI와 직접 쓰기 API가 차단된다', async ({ browser }) => {
  const baseURL = test.info().project.use.baseURL as string
  const readerApi = await playwrightRequest.newContext({ baseURL, ignoreHTTPSErrors: true, extraHTTPHeaders: { 'X-Dev-User': readerId } })
  try {
    const me = await readerApi.get('/api/auth/me')
    test.skip(me.status() === 401, 'READER E2E 계정이 없어 권한 분기 검증을 건너뜁니다. (' + readerId + ')')
    await expect(me).toBeOK()

    const list = await readerApi.get('/api/manual/list')
    await expect(list).toBeOK()
    const manuals = (await list.json() as { data: { list: Array<{ M_ID: string }> } }).data.list
    test.skip(manuals.length === 0, '읽을 수 있는 문서가 없어 READER 권한을 검증할 수 없습니다.')
    const mid = manuals[0].M_ID

    const context = await browser.newContext({ baseURL, ignoreHTTPSErrors: true, extraHTTPHeaders: { 'X-Dev-User': readerId } })
    const page = await context.newPage()
    await page.goto('/manual/detail?mid=' + encodeURIComponent(mid))
    await expect(page.getByText('읽기 전용입니다. 수정 기능은 사용할 수 없습니다.')).toBeVisible()
    await expect(page.getByRole('button', { name: '문서 스타일' })).toBeDisabled()
    await expect(page.getByRole('button', { name: '작성 요청 보내기' })).toBeDisabled()

    const csrf = await readerApi.get('/api/auth/csrf')
    await expect(csrf).toBeOK()
    const token = (await csrf.json() as { data: { token: string } }).data.token
    const write = await readerApi.post('/api/editor/heading-style', {
      form: { mid, style: '{}', bodyFont: 'CARLITO', lineHeight: '1.2', letterSpacing: '0' },
      headers: { RequestVerificationToken: token },
    })
    expect(write.status()).toBe(403)
    await context.close()
  } finally {
    await readerApi.dispose()
  }
})

test('타 팀 USER는 권한 없는 문서를 직접 조회할 수 없다', async () => {
  const baseURL = test.info().project.use.baseURL as string
  const adminApi = await playwrightRequest.newContext({ baseURL, ignoreHTTPSErrors: true, extraHTTPHeaders: { 'X-Dev-User': 'admin' } })
  const userApi = await playwrightRequest.newContext({ baseURL, ignoreHTTPSErrors: true, extraHTTPHeaders: { 'X-Dev-User': crossTeamUserId } })
  try {
    const adminList = await adminApi.get('/api/manual/list')
    await expect(adminList).toBeOK()
    const userList = await userApi.get('/api/manual/list')
    await expect(userList).toBeOK()
    const allIds = (await adminList.json() as { data: { list: Array<{ M_ID: string }> } }).data.list.map(item => item.M_ID)
    const readableIds = new Set((await userList.json() as { data: { list: Array<{ M_ID: string }> } }).data.list.map(item => item.M_ID))
    const inaccessibleId = allIds.find(mid => !readableIds.has(mid))
    test.skip(!inaccessibleId, '타 팀 USER에게 열람이 차단된 문서가 없어 직접 API 차단을 검증할 수 없습니다.')

    const response = await userApi.get('/api/manual/find?mid=' + encodeURIComponent(inaccessibleId!))
    expect(response.status()).toBe(403)
  } finally {
    await Promise.all([adminApi.dispose(), userApi.dispose()])
  }
})

test('서버가 내린 메뉴만 역할별 사이드바에 표시한다', async ({ browser }) => {
  const baseURL = test.info().project.use.baseURL as string
  const adminContext = await browser.newContext({ baseURL, ignoreHTTPSErrors: true, extraHTTPHeaders: { 'X-Dev-User': 'admin' } })
  const userContext = await browser.newContext({ baseURL, ignoreHTTPSErrors: true, extraHTTPHeaders: { 'X-Dev-User': crossTeamUserId } })
  try {
    const adminPage = await adminContext.newPage()
    await adminPage.goto('/')
    await expect(adminPage.getByRole('link', { name: 'Dashboard' })).toBeVisible()
    await adminPage.goto('/manual')
    await expect(adminPage.getByRole('button', { name: 'New Manual' })).toBeVisible()
    await expect(adminPage.getByRole('link', { name: 'Settings' })).toBeVisible()
    await expect(adminPage.getByRole('link', { name: 'Users' })).toBeVisible()

    const userPage = await userContext.newPage()
    await userPage.goto('/')
    await expect(userPage.getByRole('link', { name: 'Dashboard' })).toBeVisible()
    await userPage.goto('/manual')
    await expect(userPage.getByRole('link', { name: 'Manuals' })).toBeVisible()
    await expect(userPage.getByRole('button', { name: 'New Manual' })).toBeVisible()
    await expect(userPage.getByRole('link', { name: 'Settings' })).toHaveCount(0)
    await expect(userPage.getByRole('link', { name: 'Users' })).toHaveCount(0)
    await userPage.goto('/admin/code')
    await expect(userPage.getByRole('heading', { name: '403' })).toBeVisible()
  } finally {
    await Promise.all([adminContext.close(), userContext.close()])
  }
})
