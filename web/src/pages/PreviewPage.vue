<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const mid = computed(() => (typeof route.query.mid === 'string' ? route.query.mid : ''))
const source = computed(() => `/api/manual/document-html?mid=${encodeURIComponent(mid.value)}&mode=preview`)
const flowFrame = ref<HTMLIFrameElement>()
const pageFrame = ref<HTMLIFrameElement>()
const pageMode = ref(false)
const loadingPdf = ref(false)
const state = ref('')
let pdfUrl = ''

function releasePdf() {
  if (pdfUrl) {
    URL.revokeObjectURL(pdfUrl)
    pdfUrl = ''
  }
}
async function loadPdf() {
  if (pdfUrl) return pdfUrl
  loadingPdf.value = true
  state.value = 'PDF 만드는 중…'
  try {
    const response = await fetch(`/api/manual/pdf?mid=${encodeURIComponent(mid.value)}`, { credentials: 'same-origin' })
    if (!response.ok) {
      const body = (await response.json().catch(() => ({}))) as { message?: string }
      throw new Error(body.message || 'PDF 생성에 실패했습니다.')
    }
    pdfUrl = URL.createObjectURL(await response.blob())
    state.value = ''
    return pdfUrl
  } catch (error) {
    state.value = '실패'
    throw error
  } finally {
    loadingPdf.value = false
  }
}
async function showPages() {
  if (!mid.value) return
  const url = await loadPdf()
  if (pageFrame.value) pageFrame.value.src = url
  pageMode.value = true
}
function showFlow() {
  pageMode.value = false
}
function printPreview() {
  ;(pageMode.value ? pageFrame.value : flowFrame.value)?.contentWindow?.print()
}
async function downloadPdf() {
  const url = await loadPdf()
  const link = document.createElement('a')
  link.href = url
  link.download = 'manual.pdf'
  link.click()
  state.value = '완료'
  window.setTimeout(() => {
    if (state.value === '완료') state.value = ''
  }, 2000)
}
onBeforeUnmount(releasePdf)
</script>
<template>
  <section class="preview">
    <nav class="preview-toolbar" aria-label="미리보기 도구">
      <div class="preview-toolbar-main">
        <RouterLink class="secondary" :to="{ path: '/editor', query: { mid } }">← 편집기</RouterLink>
        <RouterLink class="secondary" :to="{ path: '/manual/detail', query: { mid } }">문서 정보</RouterLink>
        <div class="button-group" role="group" aria-label="보기 방식">
          <button class="secondary" :class="{ active: !pageMode }" type="button" @click="showFlow">연속 보기</button
          ><button
            class="secondary"
            :class="{ active: pageMode }"
            type="button"
            :disabled="loadingPdf"
            @click="showPages"
          >
            페이지 보기
          </button>
        </div>
      </div>
      <div class="preview-toolbar-actions">
        <span class="pdf-state" aria-live="polite">{{ state }}</span
        ><button class="secondary" type="button" @click="printPreview">인쇄</button
        ><button type="button" :disabled="loadingPdf" @click="downloadPdf">PDF 다운로드</button>
      </div>
    </nav>
    <iframe v-show="!pageMode && mid" ref="flowFrame" :src="source" title="문서 미리보기" />
    <iframe v-show="pageMode" ref="pageFrame" title="페이지 보기" />
  </section>
</template>

<style scoped>
.preview {
  display: grid;
  min-height: 0;
}
.preview-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--ex-space-3);
  margin-bottom: var(--ex-space-4);
  border-bottom: 1px solid var(--ex-color-border);
  background: var(--ex-color-surface);
  padding: var(--ex-space-3);
}
.preview-toolbar-main,
.preview-toolbar-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--ex-space-2);
}
.preview-toolbar :deep(a),
.preview-toolbar button {
  min-height: 2.125rem;
  padding: 0.3rem 0.75rem;
  font-size: 0.75rem;
  text-decoration: none;
}
.preview-toolbar .button-group {
  margin-left: var(--ex-space-2);
}
.preview-toolbar-actions {
  margin-left: auto;
}
.preview-toolbar .pdf-state {
  min-width: 2.5rem;
}
@media (max-width: 680px) {
  .preview-toolbar {
    align-items: stretch;
    flex-direction: column;
  }
  .preview-toolbar-actions {
    margin-left: 0;
    justify-content: flex-end;
  }
}
</style>
