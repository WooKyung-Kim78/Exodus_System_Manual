<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import { useSessionStore } from '../stores/session'
import AppIcon from '../design-system/AppIcon.vue'

const session = useSessionStore()
const router = useRouter()
const initials = computed(() => (session.user?.FULL_NAME || 'EX').trim().slice(0, 2))
const menuLabels: Record<string, string> = { dashboard: 'Dashboard', manual: 'Manuals', 'admin.setting': 'Settings', 'admin.code': 'Common Codes', 'admin.section-template': 'Section Templates', 'admin.user': 'Users' }
const menus = computed(() => session.user?.MENUS ?? [])
const navOpen = ref(false)
const menuIcons: Record<string, string> = { dashboard: 'view-dashboard-outline', manual: 'file-document-outline', 'admin.setting': 'cog-outline', 'admin.code': 'code-tags', 'admin.section-template': 'format-list-bulleted-square', 'admin.user': 'account-group-outline' }
async function signOut() { await api('/api/auth/logout', { method: 'POST' }); session.clear(); await router.push('/auth/sign-in') }
</script>

<template>
  <div class="shell">
    <button v-if="navOpen" class="nav-backdrop" type="button" aria-label="메뉴 닫기" @click="navOpen = false" />
    <aside class="sidebar" :class="{ 'is-open': navOpen }"><button class="sidebar-close" type="button" aria-label="메뉴 닫기" @click="navOpen = false"><AppIcon name="close" /></button><RouterLink class="brand" to="/" @click="navOpen = false"><span class="brand-mark"><AppIcon name="book-open-page-variant-outline" /></span><span>EXODUS <small>System Manual</small></span></RouterLink>
      <nav><template v-for="item in menus" :key="item.KEY"><span v-if="item.KEY === 'admin.setting'">Administration</span><RouterLink :to="item.PATH" @click="navOpen = false"><AppIcon class="nav-icon" :name="menuIcons[item.KEY] ?? 'circle-small'" />{{ menuLabels[item.KEY] ?? item.KEY }}</RouterLink></template>
      </nav>
      <div class="sidebar-account"><div class="sidebar-profile"><span class="avatar">{{ initials }}</span><span class="user-meta">{{ session.user?.FULL_NAME }}<small>{{ session.user?.ROLE }}</small></span></div><button class="sidebar-signout" @click="signOut"><AppIcon name="logout-variant" /><span>Sign out</span></button></div>
    </aside>
    <div class="body"><div v-if="!navOpen" class="mobile-nav-bar"><button class="mobile-nav-toggle" type="button" aria-label="메뉴 열기" @click="navOpen = true"><AppIcon name="menu" /></button></div><main><RouterView /></main></div>
  </div>
</template>
