<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { api, query } from '../api/client'
import type { ManualListItem } from '../api/types'
const list = ref<ManualListItem[]>([]); const loading = ref(true); const error = ref(''); const status = ref('')
async function load() { loading.value = true; error.value = ''; try { list.value = (await api<{ list: ManualListItem[] }>(query('/api/manual/list', { status: status.value }))).list } catch (e) { error.value = e instanceof Error ? e.message : '목록을 불러오지 못했습니다.' } finally { loading.value = false } }
onMounted(load)
</script>
<template><section><div class="page-title"><div><h1>Manuals</h1><p>시스템 매뉴얼을 조회하고 관리합니다.</p></div><RouterLink class="button" to="/manual/detail">새 문서</RouterLink></div><div class="toolbar"><label>상태 <select v-model="status" @change="load"><option value="">전체</option><option value="DRAFT">DRAFT</option><option value="REVIEW">REVIEW</option><option value="APPROVED">APPROVED</option><option value="PUBLISHED">PUBLISHED</option></select></label></div><p v-if="error" class="error">{{ error }}</p><p v-else-if="loading">불러오는 중…</p><table v-else><thead><tr><th>문서</th><th>Job Number</th><th>Rev.</th><th>상태</th><th>작성자</th></tr></thead><tbody><tr v-for="item in list" :key="item.M_ID"><td><RouterLink :to="{ path: '/manual/detail', query: { mid: item.M_ID } }">{{ item.MODEL_NAME }}</RouterLink><small>{{ item.DOC_NUM }}</small></td><td>{{ item.JOB_NUMBER }}</td><td>{{ item.REVISION }}</td><td><span class="badge">{{ item.STATUS }}</span></td><td>{{ item.REQUESTER_NAME }}</td></tr><tr v-if="list.length === 0"><td colspan="5">표시할 문서가 없습니다.</td></tr></tbody></table></section></template>
