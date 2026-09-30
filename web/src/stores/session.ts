import { defineStore } from 'pinia'
import { api } from '../api/client'
import type { CurrentUser } from '../api/types'

export const useSessionStore = defineStore('session', {
  state: () => ({ user: null as CurrentUser | null, loaded: false }),
  actions: {
    async load() { this.user = await api<CurrentUser>('/api/auth/me'); this.loaded = true },
    clear() { this.user = null; this.loaded = true },
  },
})
