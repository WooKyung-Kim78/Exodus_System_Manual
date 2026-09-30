import { reactive } from 'vue'

export interface ConfirmRequest {
  action: () => Promise<void>
  confirmLabel?: string
  danger?: boolean
  message: string
  title?: string
}

export function useConfirmDialog() {
  const state = reactive({ open: false, title: '확인', message: '', confirmLabel: '확인', danger: false })
  let action: (() => Promise<void>) | null = null

  function request(options: ConfirmRequest) {
    state.title = options.title ?? '확인'
    state.message = options.message
    state.confirmLabel = options.confirmLabel ?? '확인'
    state.danger = options.danger ?? false
    action = options.action
    state.open = true
  }

  function cancel() {
    action = null
  }

  async function confirm() {
    const requestedAction = action
    action = null
    await requestedAction?.()
  }

  return Object.assign(state, { request, cancel, confirm })
}
