<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import { useSessionStore } from '../stores/session'

const session = useSessionStore()
const router = useRouter()
const isAdmin = computed(() => ['ADMIN', 'SUPPORTER'].includes(session.user?.ROLE ?? ''))
const initials = computed(() => (session.user?.FULL_NAME || 'EX').trim().slice(0, 2))
async function signOut() { await api('/api/auth/logout', { method: 'POST' }); session.clear(); await router.push('/auth/sign-in') }
</script>

<template>
  <div class="shell">
    <aside class="sidebar"><RouterLink class="brand" to="/">EXODUS <small>System Manual</small></RouterLink>
      <nav><RouterLink to="/">Dashboard</RouterLink><RouterLink to="/manual">Manuals</RouterLink>
        <template v-if="isAdmin"><span>Administration</span><RouterLink to="/admin/setting">Settings</RouterLink><RouterLink to="/admin/code">Common Codes</RouterLink><RouterLink v-if="session.user?.ROLE === 'ADMIN'" to="/admin/section-template">Section Templates</RouterLink><RouterLink v-if="session.user?.ROLE === 'ADMIN'" to="/admin/user">Users</RouterLink></template>
      </nav>
    </aside>
    <div class="body"><header><div><b>{{ initials }}</b> {{ session.user?.FULL_NAME }} <small>{{ session.user?.ROLE }}</small></div><button class="ghost" @click="signOut">Sign out</button></header><main><RouterView /></main></div>
  </div>
</template>
