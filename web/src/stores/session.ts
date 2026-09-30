import { defineStore } from 'pinia'
import { api } from '../api/client'
import type { BootstrapData, CurrentUser } from '../api/types'

export const useSessionStore = defineStore('session', {
  state: () => ({ user: null as CurrentUser | null, bootstrap: null as BootstrapData | null, loaded: false }),
  actions: {
    async load() { this.user = await api<CurrentUser>('/api/auth/me'); this.bootstrap = await api<BootstrapData>('/api/bootstrap'); this.loaded = true },
    clear() { this.user = null; this.bootstrap = null; this.loaded = true },
  },
})
