<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useSessionStore } from '../stores/session'

const route = useRoute()
const session = useSessionStore()
const menu = computed(() => session.user?.MENUS.find((item) => item.KEY === route.meta.menuKey))
const title = computed(() => menu.value?.LABEL)
const description = computed(() => menu.value?.DESCRIPTION)
const section = computed(() => menu.value?.GROUP)
</script>

<template>
  <header v-if="title && !route.meta.hidePageHeader" class="page-header">
    <nav class="breadcrumb" aria-label="현재 위치">
      <RouterLink to="/">홈</RouterLink
      ><template v-if="section"
        ><span>/</span><span>{{ section }}</span></template
      ><span>/</span><span aria-current="page">{{ title }}</span>
    </nav>
    <h1>{{ title }}</h1>
    <p v-if="description">{{ description }}</p>
  </header>
</template>
