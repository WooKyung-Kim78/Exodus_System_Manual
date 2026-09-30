import type { ApiResponse } from './types'

let csrfToken = ''

export class ApiError extends Error {
  constructor(public readonly status: number, message: string) { super(message) }
}

export async function initializeCsrf(): Promise<void> {
  const response = await fetch('/api/auth/csrf', { credentials: 'same-origin' })
  const body = await response.json() as ApiResponse<{ token: string }>
  if (!response.ok || !body.success) throw new ApiError(response.status, body.message ?? 'CSRF 토큰을 받지 못했습니다.')
  csrfToken = body.data.token
}

export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const method = (init.method ?? 'GET').toUpperCase()
  const headers = new Headers(init.headers)
  if (method !== 'GET' && csrfToken) headers.set('RequestVerificationToken', csrfToken)
  if (init.body && !(init.body instanceof FormData)) headers.set('Content-Type', 'application/json')
  const response = await fetch(path, { ...init, method, headers, credentials: 'same-origin' })
  const body = await response.json().catch(() => null) as ApiResponse<T> | null
  if (!response.ok || !body?.success) throw new ApiError(response.status, body?.message ?? '요청을 처리하지 못했습니다.')
  return body.data
}

export function query(path: string, params: Record<string, string | number | boolean | undefined>): string {
  const search = new URLSearchParams()
  Object.entries(params).forEach(([key, value]) => { if (value !== undefined && value !== '') search.set(key, String(value)) })
  const suffix = search.toString()
  return suffix ? `${path}?${suffix}` : path
}
