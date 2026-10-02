import type { ApiResponse } from './types'

let csrfToken = ''
let csrfLoading: Promise<void> | null = null

export function csrfHeader(): Record<string, string> {
  return csrfToken ? { RequestVerificationToken: csrfToken } : {}
}

export class ApiError extends Error {
  constructor(public readonly status: number, message: string) { super(message) }
}

export function initializeCsrf(): Promise<void> {
  if (csrfToken) return Promise.resolve()
  csrfLoading ??= (async () => {
    const response = await fetch('/api/auth/csrf', { credentials: 'same-origin' })
    const body = await response.json() as ApiResponse<{ token: string }>
    if (!response.ok || !body.success) throw new ApiError(response.status, body.message ?? 'CSRF 토큰을 받지 못했습니다.')
    csrfToken = body.data.token
  })().finally(() => { csrfLoading = null })
  return csrfLoading
}

export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const method = (init.method ?? 'GET').toUpperCase()
  if (method !== 'GET' && !csrfToken) await initializeCsrf()
  const headers = new Headers(init.headers)
  if (method !== 'GET' && csrfToken) headers.set('RequestVerificationToken', csrfToken)
  if (init.body && !(init.body instanceof FormData) && !(init.body instanceof URLSearchParams)) headers.set('Content-Type', 'application/json')
  const response = await fetch(path, { ...init, method, headers, credentials: 'same-origin' })
  const body = await response.json().catch(() => null) as ApiResponse<T> | null
  if (response.status === 401) {
    const returnUrl = `${window.location.pathname}${window.location.search}`
    window.location.assign(`/auth/sign-in?returnUrl=${encodeURIComponent(returnUrl)}`)
  }
  if (response.status === 403) window.location.assign('/auth/error403')
  if (!response.ok || !body?.success) throw new ApiError(response.status, body?.message ?? '요청을 처리하지 못했습니다.')
  return body.data
}

export function query(path: string, params: Record<string, string | number | boolean | undefined>): string {
  const search = new URLSearchParams()
  Object.entries(params).forEach(([key, value]) => { if (value !== undefined && value !== '') search.set(key, String(value)) })
  const suffix = search.toString()
  return suffix ? `${path}?${suffix}` : path
}

export function formData(values: Record<string, string | number | boolean | null | undefined>): URLSearchParams {
  const body = new URLSearchParams()
  Object.entries(values).forEach(([key, value]) => { if (value !== null && value !== undefined) body.set(key, String(value)) })
  return body
}
