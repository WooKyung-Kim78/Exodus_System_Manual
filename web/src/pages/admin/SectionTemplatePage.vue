<script setup lang="ts">
import { computed, onMounted, ref, type CSSProperties } from 'vue'
import { api, query } from '../../api/client'
import type { TeamOption } from '../../api/types'
import AppDialog from '../../design-system/AppDialog.vue'
import AppTable from '../../design-system/AppTable.vue'
import ListCard from '../../design-system/ListCard.vue'
import ConfirmDialog from '../../design-system/ConfirmDialog.vue'
import { useConfirmDialog } from '../../design-system/useConfirmDialog'
import BlockEditor from '../../features/editor/BlockEditor.vue'
import { useOrderMove } from '../../features/admin/useOrderMove'

interface Template {
  TPL_ID: number
  LABEL?: string
  COOLING?: string
  SEC_LEVEL: number
  SEC_NO?: string
  TITLE: string
  IS_MANDATORY: string
  ORDER_NUM: number
  ASSIGNED_TEAM?: string
  CONTENT_HTML?: string
  TITLE_ALIGN: string
  SEC_TYPE: string
  SHOW_IN_TOC: string
  TITLE_UNDERLINE: string
}
type TemplateInput = Omit<Template, 'TPL_ID'> & { TPL_ID?: number }
const list = ref<Template[]>([])
const teams = ref<TeamOption[]>([])
const label = ref('')
const cooling = ref('')
const form = ref<TemplateInput | null>(null)
const error = ref('')
const formError = ref('')
const saving = ref(false)
const confirmation = useConfirmDialog()
const normalTemplates = computed(() => list.value.filter((item) => item.SEC_TYPE !== 'PAGEBREAK'))
const isPageBreak = computed(() => form.value?.SEC_TYPE === 'PAGEBREAK')
const titlePreviewStyle = computed<CSSProperties>(() => ({
  textAlign: form.value?.TITLE_ALIGN === 'CENTER' ? 'center' : form.value?.TITLE_ALIGN === 'RIGHT' ? 'right' : 'left',
  textDecoration: form.value?.TITLE_UNDERLINE === 'Y' ? 'underline' : 'none',
}))
function scopeOf(item: Template) {
  const labelName = item.LABEL === 'EXODUS' ? 'Exodus' : item.LABEL === 'OEM' ? 'OEM' : '모든 Label'
  const coolingName = item.COOLING === 'AIR' ? 'Air' : item.COOLING === 'LIQUID' ? 'Liquid' : '모든 Cooling'
  return `${labelName} · ${coolingName}`
}
function levelName(level: number) {
  return level === 1 ? '대제목' : level === 2 ? '중제목' : '소제목'
}
function alignName(align: string) {
  return align === 'CENTER' ? '가운데' : align === 'RIGHT' ? '오른쪽' : '왼쪽'
}
async function load() {
  try {
    list.value = (
      await api<{ list: Template[] }>(
        query('/api/admin/section-template/list', { label: label.value, cooling: cooling.value }),
      )
    ).list
  } catch (e) {
    error.value = e instanceof Error ? e.message : '목차 템플릿을 불러오지 못했습니다.'
  }
}
async function loadTeams() {
  try {
    teams.value = (await api<{ teams: TeamOption[] }>('/api/manual/teams')).teams
  } catch {
    teams.value = []
  }
}
const { ordering, move: moveOrder } = useOrderMove<Template>({
  getId: (item) => item.TPL_ID,
  getOrder: (item) => item.ORDER_NUM,
  setOrder: (item, order) => {
    item.ORDER_NUM = order
  },
  save: (orders) => api(query('/api/admin/section-template/order', { orders }), { method: 'POST' }),
  reload: load,
  setError: (message) => {
    error.value = message
  },
  errorMessage: '순서를 저장하지 못했습니다.',
})
function open(item?: Template) {
  formError.value = ''
  form.value = item
    ? { ...item }
    : {
        LABEL: label.value,
        COOLING: cooling.value,
        SEC_LEVEL: 1,
        SEC_NO: '',
        TITLE: '',
        IS_MANDATORY: 'Y',
        ORDER_NUM: list.value.length + 1,
        ASSIGNED_TEAM: '',
        CONTENT_HTML: '',
        TITLE_ALIGN: 'LEFT',
        SEC_TYPE: 'NORMAL',
        SHOW_IN_TOC: 'Y',
        TITLE_UNDERLINE: 'N',
      }
}
function closeForm() {
  form.value = null
}
async function save() {
  if (!form.value) return
  if (form.value.SEC_TYPE === 'PAGEBREAK') form.value.TITLE = '페이지 나눔'
  saving.value = true
  formError.value = ''
  try {
    await api('/api/admin/section-template', { method: 'POST', body: JSON.stringify(form.value) })
    closeForm()
    await load()
  } catch (e) {
    formError.value = e instanceof Error ? e.message : '템플릿을 저장하지 못했습니다.'
  } finally {
    saving.value = false
  }
}
function remove(item: Template) {
  confirmation.request({
    title: '템플릿 삭제',
    message: `“${item.TITLE}” 항목을 삭제합니다.`,
    confirmLabel: '삭제',
    danger: true,
    action: async () => {
      try {
        await api(query('/api/admin/section-template', { tplId: item.TPL_ID }), { method: 'DELETE' })
        await load()
      } catch (e) {
        error.value = e instanceof Error ? e.message : '템플릿을 삭제하지 못했습니다.'
      }
    },
  })
}
async function move(index: number, direction: -1 | 1) {
  await moveOrder(list.value, index, direction, (reordered) => {
    list.value = reordered
  })
}
onMounted(() => {
  void load()
  void loadTeams()
})
</script>
<template>
  <section>
    <p v-if="error" class="error">{{ error }}</p>
    <ListCard title="목차 목록">
      <template #header-actions><button @click="open()">목차 추가</button></template>
      <template #filters
        ><div class="template-filter">
          <label
            >Label<select v-model="label" @change="load">
              <option value="">전체</option>
              <option value="EXODUS">Exodus</option>
              <option value="OEM">OEM</option>
            </select></label
          ><label
            >Cooling<select v-model="cooling" @change="load">
              <option value="">전체</option>
              <option value="AIR">Air</option>
              <option value="LIQUID">Liquid</option>
            </select></label
          >
          <p>조합을 고르면 그 조합의 문서에 실제로 들어갈 목차만 보입니다. (공통 항목 포함)</p>
        </div></template
      >
      <AppTable min-width="68rem">
        <thead>
          <tr>
            <th>순서</th>
            <th>구분</th>
            <th>적용 범위</th>
            <th>제목</th>
            <th>정렬</th>
            <th>목차 표시</th>
            <th>담당 팀</th>
            <th>관리</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(item, index) in list" :key="item.TPL_ID">
            <td class="cell-nowrap">{{ index + 1 }}</td>
            <td class="cell-nowrap">
              <span
                class="template-badge"
                :class="item.IS_MANDATORY === 'Y' ? 'template-badge-required' : 'template-badge-optional'"
                >{{ item.IS_MANDATORY === 'Y' ? '필수' : '옵션' }}</span
              >
            </td>
            <td>{{ scopeOf(item) }}</td>
            <td>
              <div v-if="item.SEC_TYPE === 'PAGEBREAK'" class="template-pagebreak">— 페이지 나눔 —</div>
              <div v-else class="template-title" :style="{ paddingLeft: `${(item.SEC_LEVEL - 1) * 1.25}rem` }">
                <span>{{ item.SEC_NO ? `${item.SEC_NO} ` : '' }}{{ item.TITLE }}</span
                ><small>{{ levelName(item.SEC_LEVEL) }}</small>
              </div>
            </td>
            <td class="cell-nowrap">{{ item.SEC_TYPE === 'PAGEBREAK' ? '-' : alignName(item.TITLE_ALIGN) }}</td>
            <td class="cell-nowrap">
              <span
                v-if="item.SEC_TYPE !== 'PAGEBREAK'"
                class="template-badge"
                :class="item.SHOW_IN_TOC === 'Y' ? 'template-badge-visible' : 'template-badge-hidden'"
                >{{ item.SHOW_IN_TOC === 'Y' ? '표시' : '숨김' }}</span
              ><span v-else>-</span>
            </td>
            <td class="cell-nowrap">{{ item.SEC_TYPE === 'PAGEBREAK' ? '-' : item.ASSIGNED_TEAM || '미지정' }}</td>
            <td class="row-actions">
              <button class="inline action-move" :disabled="ordering || index === 0" @click="move(index, -1)">↑</button
              ><button
                class="inline action-move"
                :disabled="ordering || index === list.length - 1"
                @click="move(index, 1)"
              >
                ↓</button
              ><button class="inline action-edit" @click="open(item)">수정</button
              ><button class="inline danger" @click="remove(item)">삭제</button>
            </td>
          </tr>
        </tbody>
      </AppTable>
    </ListCard>
    <AppDialog
      :open="form !== null"
      :title="form?.TPL_ID ? '목차 수정' : '목차 추가'"
      wide
      @update:open="
        (open) => {
          if (!open) closeForm()
        }
      "
    >
      <form v-if="form" id="section-template-form" class="template-form" @submit.prevent="save">
        <p v-if="formError" class="error">{{ formError }}</p>
        <div class="template-form-layout">
          <div class="template-form-settings">
            <label
              ><span class="field-label">종류<strong>*</strong></span
              ><select v-model="form.SEC_TYPE" :disabled="Boolean(form.TPL_ID)">
                <option value="NORMAL">일반 목차</option>
                <option value="PAGEBREAK">페이지 나눔</option>
              </select></label
            >
            <p class="field-help">
              페이지 나눔은 제목과 내용 없이 PDF 에서 그 자리를 새 페이지로 끊습니다. 종류는 만든 뒤에 바꿀 수 없습니다.
            </p>
            <div class="template-form-grid">
              <label
                >Label<select v-model="form.LABEL">
                  <option value="">전체 공통</option>
                  <option value="EXODUS">Exodus</option>
                  <option value="OEM">OEM</option>
                </select></label
              >
              <label
                >Cooling<select v-model="form.COOLING">
                  <option value="">전체 공통</option>
                  <option value="AIR">Air</option>
                  <option value="LIQUID">Liquid</option>
                </select></label
              >
              <label v-if="!isPageBreak"
                ><span class="field-label">제목 단계<strong>*</strong></span
                ><select v-model.number="form.SEC_LEVEL">
                  <option :value="1">대제목</option>
                  <option :value="2">중제목</option>
                  <option :value="3">소제목</option>
                </select></label
              >
              <label
                ><span class="field-label">구분<strong>*</strong></span
                ><select v-model="form.IS_MANDATORY">
                  <option value="Y">필수 (자동 삽입)</option>
                  <option value="N">옵션 (직접 추가)</option>
                </select></label
              >
            </div>
            <template v-if="!isPageBreak">
              <label
                ><span class="field-label">제목<strong>*</strong></span
                ><input v-model.trim="form.TITLE" maxlength="200" required
              /></label>
              <div class="template-form-grid">
                <label
                  ><span class="field-label">제목 가로 정렬<strong>*</strong></span
                  ><select v-model="form.TITLE_ALIGN">
                    <option value="LEFT">왼쪽</option>
                    <option value="CENTER">가운데</option>
                    <option value="RIGHT">오른쪽</option>
                  </select></label
                >
                <label
                  ><span class="field-label">제목 밑줄<strong>*</strong></span
                  ><select v-model="form.TITLE_UNDERLINE">
                    <option value="N">없음</option>
                    <option value="Y">사용</option>
                  </select></label
                >
              </div>
              <p class="field-help">문서 제목 스타일(크기·글자색·굵기)과 별개로 동작합니다.</p>
              <p class="template-title-preview" :style="titlePreviewStyle">{{ form.TITLE || '미리보기' }}</p>
              <label
                ><span class="field-label">목차 페이지 표시<strong>*</strong></span
                ><select v-model="form.SHOW_IN_TOC">
                  <option value="Y">목차에 보임</option>
                  <option value="N">목차에서 숨김</option>
                </select></label
              >
              <p class="field-help">숨겨도 본문에는 그대로 나옵니다.</p>
              <div class="template-form-divider"></div>
              <label
                >담당 팀<select v-model="form.ASSIGNED_TEAM">
                  <option value="">미지정</option>
                  <option v-for="team in teams" :key="`${team.DIVISION}/${team.TEAM}`" :value="team.TEAM">
                    {{ team.DIVISION }} / {{ team.TEAM }}
                  </option>
                </select></label
              >
              <p class="field-help">지정한 팀은 문서가 생길 때 목차 담당 팀으로 복사됩니다.</p>
            </template>
          </div>
          <div v-if="!isPageBreak" class="template-form-content">
            <label>기본 내용</label>
            <BlockEditor
              class="template-content-editor"
              :model-value="form.CONTENT_HTML ?? ''"
              upload-url="/api/admin/section-template/image"
              @update:model-value="form.CONTENT_HTML = $event"
            />
            <p class="field-help">입력한 내용은 이 템플릿으로 생성하거나 추가한 목차에 자동으로 들어갑니다.</p>
          </div>
        </div>
      </form>
      <template #footer
        ><button class="secondary" type="button" @click="closeForm">취소</button
        ><button form="section-template-form" type="submit" :disabled="saving">
          {{ saving ? '저장 중…' : '저장' }}
        </button></template
      >
    </AppDialog>
    <ConfirmDialog
      v-model:open="confirmation.open"
      :title="confirmation.title"
      :message="confirmation.message"
      :confirm-label="confirmation.confirmLabel"
      :danger="confirmation.danger"
      @confirm="confirmation.confirm"
      @cancel="confirmation.cancel"
    />
  </section>
</template>

<style scoped>
.template-form {
  display: grid;
  gap: var(--ex-space-4);
}
.template-form-layout {
  display: grid;
  grid-template-columns: minmax(0, 5fr) minmax(0, 7fr);
  gap: clamp(1.5rem, 3vw, 2.5rem);
}
.template-form-settings,
.template-form-content {
  display: grid;
  align-content: start;
  gap: var(--ex-space-4);
  min-width: 0;
}
.template-form-content {
  border-left: 1px solid var(--ex-color-border);
  padding-left: clamp(1.5rem, 3vw, 2.5rem);
}
.template-form-settings > label,
.template-form-content > label {
  margin: 0;
}
.template-form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--ex-space-4);
}
.template-form-grid > label {
  margin: 0;
}
.template-form .field-help {
  margin: -0.45rem 0 0;
  color: var(--ex-color-text-subtle);
  font-size: 0.75rem;
  line-height: 1.55;
}
.template-title-preview {
  margin: 0;
  border-radius: var(--ex-radius-sm);
  background: #f2f5f7;
  padding: var(--ex-space-3);
  color: var(--ex-color-text);
  font-size: 0.8125rem;
}
.template-form-divider {
  height: 1px;
  background: var(--ex-color-border);
  margin: var(--ex-space-1) 0;
}
.template-content-editor {
  min-width: 0;
}
.template-content-editor :deep(.ck-editor__editable_inline) {
  min-height: 36rem;
}
@media (max-width: 960px) {
  .template-form-layout {
    grid-template-columns: 1fr;
  }
  .template-form-content {
    border-top: 1px solid var(--ex-color-border);
    border-left: 0;
    padding-top: var(--ex-space-5);
    padding-left: 0;
  }
  .template-content-editor :deep(.ck-editor__editable_inline) {
    min-height: 28rem;
  }
}
@media (max-width: 680px) {
  .template-form-grid {
    grid-template-columns: 1fr;
  }
  .template-content-editor :deep(.ck-editor__editable_inline) {
    min-height: 22rem;
  }
}
</style>
