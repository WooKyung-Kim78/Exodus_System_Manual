import { ref } from 'vue'

interface OrderMoveOptions<T> {
  getId: (item: T) => number
  getOrder: (item: T) => number
  reload: () => Promise<void>
  save: (orders: string) => Promise<void>
  setError: (message: string) => void
  errorMessage: string
  setOrder: (item: T, order: number) => void
}

export function useOrderMove<T>(options: OrderMoveOptions<T>) {
  const ordering = ref(false)

  async function move(items: T[], index: number, direction: -1 | 1, apply: (items: T[]) => void) {
    const target = index + direction
    if (ordering.value || index < 0 || target < 0 || target >= items.length) return

    const reordered = [...items]
    const current = reordered[index]
    reordered[index] = reordered[target]
    reordered[target] = current
    reordered.forEach((item, order) => options.setOrder(item, order + 1))
    apply(reordered)

    ordering.value = true
    try {
      await options.save(reordered.map(item => `${options.getId(item)}:${options.getOrder(item)}`).join(','))
    } catch {
      options.setError(options.errorMessage)
      await options.reload()
    } finally {
      ordering.value = false
    }
  }
  return { ordering, move }
}
