<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
const route = useRoute(); const mid = computed(() => typeof route.query.mid === 'string' ? route.query.mid : '')
const source = computed(() => `/api/manual/document-html?mid=${encodeURIComponent(mid.value)}&mode=preview`)
</script>
<template><section class="preview"><div class="page-title"><div><h1>미리보기</h1><p>PDF와 같은 서버 문서 HTML을 표시합니다.</p></div><div class="actions"><RouterLink class="button secondary" :to="{ path: '/editor', query: { mid } }">편집기</RouterLink><a class="button" :href="`/api/manual/pdf?mid=${encodeURIComponent(mid)}`">PDF 다운로드</a></div></div><iframe v-if="mid" :src="source" title="문서 미리보기" /></section></template>
