<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api/client'
import type { ManualHeader, ManualSection } from '../api/types'
const route = useRoute(); const mid = computed(() => typeof route.query.mid === 'string' ? route.query.mid : '')
const header = ref<ManualHeader | null>(null); const sections = ref<ManualSection[]>([]); const error = ref('')
onMounted(async () => { if (!mid.value) return; try { const data = await api<{ header: ManualHeader; sections: ManualSection[] }>(`/api/editor/data?mid=${encodeURIComponent(mid.value)}`); header.value = data.header; sections.value = data.sections } catch (e) { error.value = e instanceof Error ? e.message : '편집기를 불러오지 못했습니다.' } })
</script>
<template><section><div class="page-title"><div><h1>문서 편집기</h1><p>{{ header?.MODEL_NAME }}</p></div><RouterLink class="button secondary" :to="{ path: '/manual/preview', query: { mid } }">미리보기</RouterLink></div><p v-if="error" class="error">{{ error }}</p><p v-else-if="!header">불러오는 중…</p><div v-else class="editor-grid"><aside><h2>목차</h2><ul><li v-for="s in sections" :key="s.SEC_ID">{{ s.SEC_NO }} {{ s.TITLE }}</li></ul></aside><div class="empty"><h2>블록 편집</h2><p>CKEditor 기반 블록 편집 UI는 다음 전환 단계에서 이 영역에 연결됩니다.</p></div></div></section></template>
