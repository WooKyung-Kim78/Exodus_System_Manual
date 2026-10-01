import { describe, expect, it, vi } from 'vitest'
import { useOrderMove } from '../src/features/admin/useOrderMove'

interface Item { id: number; order: number }

function createOrderMove(save = vi.fn(async () => undefined), reload = vi.fn(async () => undefined)) {
  const errors: string[] = []
  const orderMove = useOrderMove<Item>({
    getId: item => item.id,
    getOrder: item => item.order,
    setOrder: (item, order) => { item.order = order },
    save,
    reload,
    setError: message => errors.push(message),
    errorMessage: '순서를 저장하지 못했습니다.',
  })
  return { ...orderMove, save, reload, errors }
}

describe('useOrderMove', () => {
  it('인접 항목을 교환하고 연속된 순서를 저장한다', async () => {
    const items = [{ id: 10, order: 1 }, { id: 20, order: 2 }]
    const orderMove = createOrderMove()
    let applied: Item[] = []

    await orderMove.move(items, 0, 1, value => { applied = value })

    expect(applied.map(item => item.id)).toEqual([20, 10])
    expect(applied.map(item => item.order)).toEqual([1, 2])
    expect(orderMove.save).toHaveBeenCalledWith('20:1,10:2')
    expect(orderMove.ordering.value).toBe(false)
  })

  it('저장에 실패하면 오류를 알리고 목록을 다시 불러온다', async () => {
    const save = vi.fn(async () => { throw new Error('failed') })
    const orderMove = createOrderMove(save)

    await orderMove.move([{ id: 10, order: 1 }, { id: 20, order: 2 }], 0, 1, () => undefined)

    expect(orderMove.errors).toEqual(['순서를 저장하지 못했습니다.'])
    expect(orderMove.reload).toHaveBeenCalledOnce()
    expect(orderMove.ordering.value).toBe(false)
  })
})
