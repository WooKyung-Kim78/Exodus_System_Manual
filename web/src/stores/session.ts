import { defineStore } from 'pinia'
import { api } from '../api/client'
import type { BootstrapData, CurrentUser } from '../api/types'

type CurrentUserResponse = Omit<CurrentUser, 'BOOTSTRAP'> & { BOOTSTRAP?: BootstrapData }

export const useSessionStore = defineStore('session', {
  state: () => ({ user: null as CurrentUser | null, loaded: false }),
  getters: {
    bootstrap: state => state.user?.BOOTSTRAP ?? null,
  },
  actions: {
    async load() {
      const user = await api<CurrentUserResponse>('/api/auth/me')
      // 새 서버는 /api/auth/me에 포함한다. 이미 실행 중인 이전 서버와의 전환 중에만 기존 서버 API를 사용한다.
      const bootstrap = user.BOOTSTRAP ?? await api<BootstrapData>('/api/bootstrap')
      this.user = { ...user, BOOTSTRAP: bootstrap }
      this.loaded = true
    },
    clear() { this.user = null; this.loaded = true },
  },
})
