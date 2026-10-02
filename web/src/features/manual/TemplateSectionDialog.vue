<script setup lang="ts">
import { ref, watch } from 'vue'
import { api, formData, query } from '../../api/client'
import type { SectionTemplateOption } from '../../api/types'
import AppDialog from '../../design-system/AppDialog.vue'

const props = defineProps<{ mid: string; canEdit: boolean }>()
const open = defineModel<boolean>('open', { required: true })
const emit = defineEmits<{ changed: [sectionId: number] }>()
const loading = ref(false)
const adding = ref<number | 'pagebreak' | null>(null)
const error = ref('')
const templates = ref<SectionTemplateOption[]>([])

async function load() {
  if (!props.mid) return
  loading.value = true
  error.value = ''
  try {
    templates.value = (
      await api<{ list: SectionTemplateOption[] }>(query('/api/editor/template-options', { mid: props.mid }))
    ).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '템플릿 목차를 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
}
async function addTemplate(template: SectionTemplateOption) {
  adding.value = template.TPL_ID
  try {
    const result = await api<{ SEC_ID: string }>('/api/editor/template-section', {
      method: 'POST',
      body: formData({ mid: props.mid, tplId: template.TPL_ID }),
    })
    if (template.SEC_TYPE !== 'PAGEBREAK') template.IS_ADDED = 'Y'
    emit('changed', Number(result.SEC_ID))
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '목차를 추가하지 못했습니다.'
  } finally {
    adding.value = null
  }
}
async function addPageBreak() {
  adding.value = 'pagebreak'
  try {
    const result = await api<{ SEC_ID: string }>('/api/editor/section', {
      method: 'POST',
      body: JSON.stringify({
        M_ID: props.mid,
        TITLE: '페이지 나눔',
        SEC_LEVEL: 1,
        TITLE_ALIGN: 'LEFT',
        SEC_TYPE: 'PAGEBREAK',
      }),
    })
    open.value = false
    emit('changed', Number(result.SEC_ID))
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '페이지 나눔을 추가하지 못했습니다.'
  } finally {
    adding.value = null
  }
}
watch(open, (isOpen) => {
  if (isOpen) void load()
})
</script>

<template>
  <AppDialog v-model:open="open" title="템플릿에서 목차 추가" large>
    <div class="template-toolbar">
      <p>이 문서의 Label·Cooling 에 맞는 항목입니다. 지운 목차는 여기서 다시 추가할 수 있습니다.</p>
      <button
        class="template-pagebreak-button"
        type="button"
        :disabled="!canEdit || adding === 'pagebreak'"
        @click="addPageBreak"
      >
        + 페이지 나눔
      </button>
    </div>
    <p v-if="loading">불러오는 중…</p>
    <p v-else-if="error" class="error">{{ error }}</p>
    <table v-else-if="templates.length" class="template-options-table">
      <tbody>
        <tr
          v-for="template in templates"
          :key="template.TPL_ID"
          :class="{ 'template-option-added': template.IS_ADDED === 'Y' }"
        >
          <td class="template-option-kind">
            <span
              class="template-badge"
              :class="template.IS_MANDATORY === 'Y' ? 'template-badge-required' : 'template-badge-optional'"
              >{{ template.IS_MANDATORY === 'Y' ? '필수' : '옵션' }}</span
            >
          </td>
          <td class="template-option-title">
            <span v-if="template.SEC_TYPE === 'PAGEBREAK'" class="template-pagebreak">— 페이지 나눔 —</span
            ><span v-else>{{ template.TITLE }}</span>
          </td>
          <td class="template-option-action">
            <span v-if="template.IS_ADDED === 'Y'" class="template-badge template-badge-added">추가됨</span
            ><button
              v-else
              class="inline action-info"
              type="button"
              :disabled="!canEdit || adding === template.TPL_ID"
              @click="addTemplate(template)"
            >
              추가
            </button>
          </td>
        </tr>
      </tbody>
    </table>
    <p v-else>등록된 템플릿 목차가 없습니다.</p>
    <template #footer><button class="secondary" type="button" @click="open = false">닫기</button></template>
  </AppDialog>
</template>

<style scoped>
.template-toolbar {
  display: flex;
  align-items: center;
  gap: var(--ex-space-3);
  margin-bottom: var(--ex-space-4);
}
.template-toolbar p {
  margin: 0;
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
  line-height: 1.5;
}
.template-pagebreak-button {
  min-height: 2rem;
  margin-left: auto;
  border: 0;
  border-radius: var(--ex-radius-sm);
  background: #f4f0ff;
  color: #6d52c9;
  padding: 0.3rem 0.75rem;
  font-size: 0.75rem;
  font-weight: 650;
  white-space: nowrap;
}
.template-pagebreak-button:hover:not(:disabled) {
  background: #e9e1ff;
  transform: none;
}
.template-options-table {
  width: 100%;
  border-collapse: collapse;
}
.template-options-table tr {
  border-top: 1px solid var(--ex-color-border);
}
.template-options-table tr:last-child {
  border-bottom: 1px solid var(--ex-color-border);
}
.template-options-table td {
  padding: 0.625rem 0;
  vertical-align: middle;
}
.template-option-kind {
  width: 5rem;
}
.template-option-title {
  color: var(--ex-color-text-muted);
  font-size: 0.8125rem;
}
.template-option-action {
  width: 6.25rem;
  text-align: right;
}
.template-option-added {
  opacity: 0.5;
}
.template-badge-added {
  background: #f2f4f7;
  color: var(--ex-color-text-muted);
}
.template-option-action .inline {
  min-height: 1.875rem;
  border: 0;
  background: #e8f5fb;
  color: #287aab;
  padding: 0.25rem 0.75rem;
  font-weight: 650;
}
.template-option-action .inline:hover:not(:disabled) {
  background: #d6eef9;
  transform: none;
}
@media (max-width: 680px) {
  .template-toolbar {
    align-items: flex-start;
    flex-direction: column;
  }
  .template-pagebreak-button {
    margin-left: 0;
  }
  .template-option-kind {
    width: 4rem;
  }
  .template-option-action {
    width: 4.75rem;
  }
}
</style>
