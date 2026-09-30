<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../api/client'

const route = useRoute()
const mid = computed(() => typeof route.query.mid === 'string' ? route.query.mid : '')
const source = computed(() => `/api/manual/document-html?mid=${encodeURIComponent(mid.value)}&mode=preview`)
const flowFrame = ref<HTMLIFrameElement>()
const pageFrame = ref<HTMLIFrameElement>()
const pageMode = ref(false)
const loadingPdf = ref(false)
const state = ref('')
let pdfUrl = ''

function releasePdf() { if (pdfUrl) { URL.revokeObjectURL(pdfUrl); pdfUrl = '' } }
async function loadPdf() {
  if (pdfUrl) return pdfUrl
  loadingPdf.value = true; state.value = 'PDF 만드는 중…'
  try {
    const response = await fetch(`/api/manual/pdf?mid=${encodeURIComponent(mid.value)}`, { credentials: 'same-origin' })
    if (!response.ok) {
      const body = await response.json().catch(() => ({})) as { message?: string }
      throw new Error(body.message || 'PDF 생성에 실패했습니다.')
    }
    pdfUrl = URL.createObjectURL(await response.blob())
    state.value = ''
    return pdfUrl
  } catch (error) {
    state.value = '실패'
    throw error
  } finally { loadingPdf.value = false }
}
async function showPages() {
  if (!mid.value) return
  const url = await loadPdf()
  if (pageFrame.value) pageFrame.value.src = url
  pageMode.value = true
}
function showFlow() { pageMode.value = false }
function printFlow() { flowFrame.value?.contentWindow?.print() }
async function downloadPdf() {
  const url = await loadPdf()
  const link = document.createElement('a'); link.href = url; link.download = 'manual.pdf'; link.click()
  state.value = '완료'; window.setTimeout(() => { if (state.value === '완료') state.value = '' }, 2000)
}
onBeforeUnmount(releasePdf)
</script>
<template><section class="preview"><div class="page-title"><div><h1>미리보기</h1><p>PDF와 같은 서버 문서 HTML을 표시합니다.</p></div><div class="actions"><RouterLink class="button secondary" :to="{ path: '/editor', query: { mid } }">← 편집기</RouterLink><RouterLink class="button secondary" :to="{ path: '/manual/detail', query: { mid } }">문서 정보</RouterLink><div class="button-group"><button class="secondary" :class="{ active: !pageMode }" type="button" @click="showFlow">연속 보기</button><button class="secondary" :class="{ active: pageMode }" type="button" :disabled="loadingPdf" @click="showPages">페이지 보기</button></div><span class="pdf-state">{{ state }}</span><button class="secondary" type="button" @click="printFlow">인쇄</button><button type="button" :disabled="loadingPdf" @click="downloadPdf">PDF 다운로드</button></div></div><iframe v-show="!pageMode && mid" ref="flowFrame" :src="source" title="문서 미리보기" /><iframe v-show="pageMode" ref="pageFrame" title="페이지 보기" /></section></template>
