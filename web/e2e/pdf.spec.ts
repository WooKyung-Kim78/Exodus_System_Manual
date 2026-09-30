import { expect, request as playwrightRequest, test } from '@playwright/test'

test('읽기 권한이 있는 문서의 PDF를 생성한다', async () => {
  const baseURL = test.info().project.use.baseURL as string
  const api = await playwrightRequest.newContext({ baseURL, ignoreHTTPSErrors: true, extraHTTPHeaders: { 'X-Dev-User': process.env.E2E_DEV_USER ?? 'admin' } })
  try {
    const list = await api.get('/api/manual/list')
    await expect(list).toBeOK()
    const manuals = (await list.json() as { data: { list: Array<{ M_ID: string }> } }).data.list
    test.skip(manuals.length === 0, 'PDF를 생성할 문서가 없습니다.')

    const response = await api.get('/api/manual/pdf?mid=' + encodeURIComponent(manuals[0].M_ID), { timeout: 60_000 })
    expect(response.status()).toBe(200)
    expect(response.headers()['content-type']).toContain('application/pdf')
    expect((await response.body()).subarray(0, 4).toString()).toBe('%PDF')
  } finally {
    await api.dispose()
  }
})
