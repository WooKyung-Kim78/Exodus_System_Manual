import { describe, expect, it, vi } from 'vitest'
import { useConfirmDialog } from '../src/design-system/useConfirmDialog'

describe('useConfirmDialog', () => {
  it('확인할 작업을 보관했다가 확인 시 한 번 실행한다', async () => {
    const dialog = useConfirmDialog()
    const action = vi.fn(async () => undefined)

    dialog.request({ message: '삭제합니다.', confirmLabel: '삭제', danger: true, action })

    expect(dialog.open).toBe(true)
    expect(dialog.confirmLabel).toBe('삭제')
    expect(dialog.danger).toBe(true)
    await dialog.confirm()
    await dialog.confirm()

    expect(action).toHaveBeenCalledTimes(1)
  })

  it('취소하면 보관한 작업을 실행하지 않는다', async () => {
    const dialog = useConfirmDialog()
    const action = vi.fn(async () => undefined)

    dialog.request({ message: '삭제합니다.', action })
    dialog.cancel()
    await dialog.confirm()

    expect(action).not.toHaveBeenCalled()
  })
})
