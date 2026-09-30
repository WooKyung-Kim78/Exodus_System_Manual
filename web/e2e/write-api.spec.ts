import { expect, request as playwrightRequest, test } from '@playwright/test'

type ApiBody<T> = { success: boolean, data: T }
type Block = { ELE_ID: number, ROW_VER: string, CONTENT_HTML: string }

test('admin은 새 DRAFT 문서·목차·블록을 만들고 충돌을 감지한 뒤 정리한다', async () => {
  const baseURL = test.info().project.use.baseURL as string
  const api = await playwrightRequest.newContext({
    baseURL,
    ignoreHTTPSErrors: true,
    extraHTTPHeaders: { 'X-Dev-User': process.env.E2E_DEV_USER ?? 'admin' },
  })
  let mid: string | undefined

  try {
    const csrf = await api.get('/api/auth/csrf')
    await expect(csrf).toBeOK()
    const token = (await csrf.json() as ApiBody<{ token: string }>).data.token
    const headers = { RequestVerificationToken: token }
    const suffix = Date.now().toString()

    const created = await api.post('/api/manual/create', {
      data: { MODEL_NAME: `E2E-${suffix}`, PAGE_SIZE: 'LETTER', DOC_VERSION: '1.0' },
      headers,
    })
    await expect(created).toBeOK()
    mid = (await created.json() as ApiBody<{ M_ID: string }>).data.M_ID

    const sectionResponse = await api.post('/api/editor/section', {
      data: { M_ID: mid, TITLE: 'E2E section', SEC_LEVEL: 1, TITLE_ALIGN: 'LEFT', SEC_TYPE: 'NORMAL' },
      headers,
    })
    await expect(sectionResponse).toBeOK()
    const secId = Number((await sectionResponse.json() as ApiBody<{ SEC_ID: string }>).data.SEC_ID)
    expect(secId).toBeGreaterThan(0)

    const inserted = await api.post('/api/editor/block', {
      data: {
        M_ID: mid,
        SEC_ID: secId,
        ELE_TYPE: 'TEXT',
        ORDER_NUM: 1,
        WIDTH: 100,
        HEIGHT: 0,
        CONTENT_HTML: '<p>e2e content</p><script>window.e2eInjected=true</script>',
      },
      headers,
    })
    await expect(inserted).toBeOK()
    const first = (await inserted.json() as ApiBody<{ block: Block }>).data.block
    expect(first.CONTENT_HTML).toContain('e2e content')
    expect(first.CONTENT_HTML).not.toContain('<script')

    const updated = await api.post('/api/editor/block', {
      data: {
        M_ID: mid,
        SEC_ID: secId,
        ELE_ID: first.ELE_ID,
        ELE_TYPE: 'TEXT',
        ORDER_NUM: 1,
        WIDTH: 100,
        HEIGHT: 0,
        CONTENT_HTML: '<p>updated by e2e</p>',
        ROW_VER: first.ROW_VER,
      },
      headers,
    })
    await expect(updated).toBeOK()

    const stale = await api.post('/api/editor/block', {
      data: {
        M_ID: mid,
        SEC_ID: secId,
        ELE_ID: first.ELE_ID,
        ELE_TYPE: 'TEXT',
        ORDER_NUM: 1,
        WIDTH: 100,
        HEIGHT: 0,
        CONTENT_HTML: '<p>stale write</p>',
        ROW_VER: first.ROW_VER,
      },
      headers,
    })
    expect(stale.status()).toBe(409)
  } finally {
    if (mid) {
      const csrf = await api.get('/api/auth/csrf')
      const token = (await csrf.json() as ApiBody<{ token: string }>).data.token
      const deleted = await api.delete('/api/manual/delete?mid=' + encodeURIComponent(mid), {
        headers: { RequestVerificationToken: token },
      })
      await expect(deleted).toBeOK()
    }
    await api.dispose()
  }
})
