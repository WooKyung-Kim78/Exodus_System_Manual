<script setup lang="ts">
import { computed, onMounted, ref, type CSSProperties } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, formData, query } from '../api/client'
import type {
  DatasheetOption,
  HeadingStyle,
  ManualHeader,
  ManualSection,
  NotifyRecipient,
  TeamOption,
} from '../api/types'
import AppDialog from '../design-system/AppDialog.vue'
import AppBadge from '../design-system/AppBadge.vue'
import AppTable from '../design-system/AppTable.vue'
import ConfirmDialog from '../design-system/ConfirmDialog.vue'
import { useConfirmDialog } from '../design-system/useConfirmDialog'
import { useSessionStore } from '../stores/session'
import { useOrderMove } from '../features/admin/useOrderMove'
import DatasheetSelect from '../features/manual/DatasheetSelect.vue'
import TemplateSectionDialog from '../features/manual/TemplateSectionDialog.vue'

const route = useRoute()
const router = useRouter()
const session = useSessionStore()
const mid = computed(() => (typeof route.query.mid === 'string' ? route.query.mid : ''))
const header = ref<ManualHeader | null>(null)
const sections = ref<ManualSection[]>([])
const form = ref<ManualHeader | null>(null)
const canEdit = ref(false)
const error = ref('')
const loading = ref(false)
const saving = ref(false)
const datasheets = ref<DatasheetOption[]>([])
const coverUploading = ref(false)
const specOpen = ref(false)
const specLoading = ref(false)
const specHtml = ref('')
const specMessage = ref('')
interface SectionForm {
  SEC_ID?: number
  TITLE: string
  SEC_LEVEL: number
  SEC_NO?: string
  ASSIGNED_TEAM?: string
  TITLE_ALIGN: 'LEFT' | 'CENTER' | 'RIGHT'
  SHOW_IN_TOC: 'Y' | 'N'
  TITLE_UNDERLINE: 'Y' | 'N'
  SEC_TYPE: 'NORMAL' | 'PAGEBREAK'
}
const sectionOpen = ref(false)
const sectionLoading = ref(false)
const sectionSaving = ref(false)
const sectionError = ref('')
const teams = ref<TeamOption[]>([])
const sectionForm = ref<SectionForm>({
  TITLE: '',
  SEC_LEVEL: 1,
  TITLE_ALIGN: 'LEFT',
  SHOW_IN_TOC: 'Y',
  TITLE_UNDERLINE: 'N',
  SEC_TYPE: 'NORMAL',
})
const notifyOpen = ref(false)
const notifyLoading = ref(false)
const notifySending = ref(false)
const notifyOnlyAssigned = ref(false)
const notifyMemo = ref('')
const notifyError = ref('')
const notifyTestMode = ref(false)
const recipients = ref<NotifyRecipient[]>([])
const docStyleOpen = ref(false)
const templateOpen = ref(false)
const docStyleSaving = ref(false)
const headingStyles = ref<Record<string, HeadingStyle>>({})
const bodyFont = ref('CARLITO')
const bodyLineHeight = ref(1.2)
const bodyLetterSpacing = ref(0)
const confirmation = useConfirmDialog()

const notifyTargets = computed(() =>
  recipients.value.filter((item) => Boolean(item.EMAIL_ADDRESS) && (!notifyOnlyAssigned.value || item.SECTION_CNT > 0)),
)
const bodyPreview = computed<CSSProperties>(() => ({
  fontFamily: bodyFont.value,
  fontSize: '12pt',
  lineHeight: String(bodyLineHeight.value),
  letterSpacing: `${bodyLetterSpacing.value}px`,
}))
const specTitle = 'SPECIFICATIONS'
// DocumentHtmlBuilder와 같은 순서로 CSS를 불러온다. 개발 서버에서는 vite.config.ts가 /css를 API 서버로 전달한다.
const specDocument = computed(
  () =>
    `<!doctype html><html lang="ko"><head><meta charset="utf-8"><link rel="stylesheet" href="/css/doc-base.css"><link rel="stylesheet" href="/css/fonts.css"><link rel="stylesheet" href="/css/doc-type.css"><link rel="stylesheet" href="/css/ds-spec.css"><link rel="stylesheet" href="/css/preview.css"><style>body { background: #fff; } .spec-preview { padding: 0; }</style></head><body><div class="spec-preview"><div class="doc-block">${specHtml.value}</div></div></body></html>`,
)

function defaultHeadingStyles(): Record<string, HeadingStyle> {
  return Object.fromEntries(
    Object.entries(session.bootstrap?.headingStyles ?? {}).map(([level, style]) => [level, { ...style }]),
  )
}
function parseHeadingStyles(value?: string): Record<string, HeadingStyle> {
  const styles = defaultHeadingStyles()
  try {
    const saved = value ? (JSON.parse(value) as Record<string, Partial<HeadingStyle>>) : null
    if (saved)
      Object.keys(styles).forEach((level) => {
        styles[level] = { ...styles[level], ...saved[level] }
      })
  } catch {
    /* Keep server-provided defaults for malformed legacy data. */
  }
  return styles
}
async function load() {
  if (!mid.value) return
  loading.value = true
  error.value = ''
  try {
    const data = await api<{ header: ManualHeader; sections: ManualSection[]; access: { CAN_EDIT: string } }>(
      query('/api/manual/find', { mid: mid.value }),
    )
    header.value = data.header
    sections.value = data.sections
    form.value = { ...data.header }
    canEdit.value = data.access.CAN_EDIT === 'Y'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '문서를 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
}
async function loadDatasheets() {
  try {
    datasheets.value = (await api<{ list: DatasheetOption[] }>('/api/manual/datasheets')).list
  } catch {
    datasheets.value = []
  }
}
async function loadTeams() {
  try {
    teams.value = (await api<{ teams: TeamOption[] }>('/api/manual/teams')).teams
  } catch {
    teams.value = []
  }
}
async function loadSections() {
  sections.value = (await api<{ list: ManualSection[] }>(query('/api/editor/sections', { mid: mid.value }))).list
}
async function reloadSections() {
  await loadSections()
}
async function create() {
  try {
    const data = await api<{ M_ID: string }>('/api/manual/create', {
      method: 'POST',
      body: JSON.stringify({ MODEL_NAME: '새 문서', PAGE_SIZE: 'LETTER' }),
    })
    await router.replace({ path: '/manual/detail', query: { mid: data.M_ID } })
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '문서를 만들지 못했습니다.'
  }
}
function pickDatasheet(item: DatasheetOption | null) {
  if (form.value) form.value.PROCESS_ID = item?.D_ID ?? ''
}
function isPageBreak(section: ManualSection) {
  return section.SEC_TYPE === 'PAGEBREAK'
}
function sectionNumber(section: ManualSection) {
  return section.SEC_NO?.trim() || String(section.ORDER_NUM)
}
function canEditSection(section: ManualSection) {
  return canEdit.value && section.CAN_EDIT_SEC === 'Y'
}
function levelName(level: number) {
  return level === 1 ? '대제목' : level === 2 ? '중제목' : '소제목'
}
function roleLabel(role: string) {
  return (
    ({ OWNER: '소유자', EDITOR: '작성자', REVIEWER: '검토자', APPROVER: '승인자' } as Record<string, string>)[role] ??
    role
  )
}
function bodyFontLabel(code: string, name: string) {
  return code === 'CARLITO' ? 'Carlito (Calibri 호환)' : name
}
function headingPreview(level: string): CSSProperties {
  const style = headingStyles.value[level]
  return {
    fontSize: `${style?.size ?? 13}pt`,
    color: style?.color ?? '#3f4254',
    fontWeight: style?.bold ? '700' : '400',
    textDecoration: style?.underline ? 'underline' : 'none',
  }
}
function formatDate(value?: string) {
  return value
    ? new Intl.DateTimeFormat('ko-KR', { year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(value))
    : '-'
}
function formatDateTime(value?: string) {
  return value
    ? new Intl.DateTimeFormat('ko-KR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
    : '-'
}
function openEditor(sectionId?: number) {
  router.push({ path: '/editor', query: { mid: mid.value, ...(sectionId ? { secId: sectionId } : {}) } })
}
function newSectionForm(section: ManualSection): SectionForm {
  return {
    SEC_ID: section.SEC_ID,
    TITLE: section.TITLE,
    SEC_LEVEL: section.SEC_LEVEL,
    SEC_NO: section.SEC_NO,
    ASSIGNED_TEAM: section.ASSIGNED_TEAM,
    TITLE_ALIGN: section.TITLE_ALIGN ?? 'LEFT',
    SHOW_IN_TOC: section.SHOW_IN_TOC ?? 'Y',
    TITLE_UNDERLINE: section.TITLE_UNDERLINE ?? 'N',
    SEC_TYPE: section.SEC_TYPE ?? 'NORMAL',
  }
}
async function openSection(section: ManualSection) {
  if (!canEditSection(section) || isPageBreak(section)) return
  sectionError.value = ''
  sectionLoading.value = true
  try {
    // 목록은 오래됐을 수 있으므로 기존 화면처럼 저장 직전의 목차 값을 다시 읽는다.
    const data = await api<{ section: ManualSection }>(
      query('/api/editor/sections', { mid: mid.value, secId: section.SEC_ID }),
    )
    sectionForm.value = newSectionForm(data.section)
    sectionOpen.value = true
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '목차 정보를 불러오지 못했습니다.'
  } finally {
    sectionLoading.value = false
  }
}
async function saveSection() {
  if (!canEdit.value || !sectionForm.value.TITLE.trim()) {
    sectionError.value = '제목은 필수입니다.'
    return
  }
  sectionSaving.value = true
  sectionError.value = ''
  try {
    await api('/api/editor/section', {
      method: 'POST',
      body: JSON.stringify({ ...sectionForm.value, M_ID: mid.value }),
    })
    sectionOpen.value = false
    await loadSections()
  } catch (cause) {
    sectionError.value = cause instanceof Error ? cause.message : '목차를 저장하지 못했습니다.'
  } finally {
    sectionSaving.value = false
  }
}
function removeSection(section: ManualSection) {
  confirmation.request({
    title: '목차 삭제',
    message: isPageBreak(section) ? '페이지 나눔을 삭제합니다.' : `“${section.TITLE}” 목차와 작성된 내용을 삭제합니다.`,
    confirmLabel: '삭제',
    danger: true,
    action: async () => {
      try {
        await api(query('/api/editor/section', { secId: section.SEC_ID, mid: mid.value }), { method: 'DELETE' })
        await loadSections()
      } catch (cause) {
        error.value = cause instanceof Error ? cause.message : '목차를 삭제하지 못했습니다.'
      }
    },
  })
}
const { ordering, move: moveSection } = useOrderMove<ManualSection>({
  getId: (section) => section.SEC_ID,
  getOrder: (section) => section.ORDER_NUM ?? 0,
  setOrder: (section, order) => {
    section.ORDER_NUM = order
  },
  save: (orders) => api('/api/editor/section/order', { method: 'POST', body: formData({ mid: mid.value, orders }) }),
  reload: loadSections,
  setError: (message) => {
    error.value = message
  },
  errorMessage: '목차 순서를 저장하지 못했습니다.',
})
async function save() {
  if (!form.value) return
  saving.value = true
  try {
    await api('/api/manual/header', { method: 'POST', body: JSON.stringify({ ...form.value, M_ID: mid.value }) })
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '문서를 저장하지 못했습니다.'
  } finally {
    saving.value = false
  }
}
async function uploadCover(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  coverUploading.value = true
  try {
    const data = new FormData()
    data.append('mid', mid.value)
    data.append('file', file)
    const result = await api<{ path: string }>('/api/manual/cover', { method: 'POST', body: data })
    if (header.value) header.value.COVER_IMAGE_PATH = result.path
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '표지 이미지를 등록하지 못했습니다.'
  } finally {
    coverUploading.value = false
    ;(event.target as HTMLInputElement).value = ''
  }
}
function deleteCover() {
  confirmation.request({
    title: '표지 이미지 제거',
    message: '표지 이미지를 제거합니다.',
    confirmLabel: '제거',
    danger: true,
    action: async () => {
      try {
        await api(query('/api/manual/cover', { mid: mid.value }), { method: 'DELETE' })
        if (header.value) header.value.COVER_IMAGE_PATH = undefined
      } catch (cause) {
        error.value = cause instanceof Error ? cause.message : '표지 이미지를 제거하지 못했습니다.'
      }
    },
  })
}
async function openSpec() {
  specOpen.value = true
  specLoading.value = true
  specHtml.value = ''
  specMessage.value = ''
  try {
    const data = await api<{ html?: string; message: string }>(query('/api/manual/spec', { mid: mid.value }))
    specHtml.value = data.html ?? ''
    specMessage.value = data.message
  } catch (cause) {
    specMessage.value = cause instanceof Error ? cause.message : '사양을 불러오지 못했습니다.'
  } finally {
    specLoading.value = false
  }
}
async function openNotify() {
  notifyOpen.value = true
  notifyLoading.value = true
  notifyError.value = ''
  notifyMemo.value = ''
  notifyOnlyAssigned.value = false
  notifyTestMode.value = false
  try {
    const data = await api<{ list: NotifyRecipient[]; testMode: boolean }>(
      query('/api/manual/notify/recipients', { mid: mid.value }),
    )
    recipients.value = data.list
    notifyTestMode.value = data.testMode
  } catch (cause) {
    notifyError.value = cause instanceof Error ? cause.message : '수신자를 불러오지 못했습니다.'
  } finally {
    notifyLoading.value = false
  }
}
async function sendNotify() {
  notifySending.value = true
  notifyError.value = ''
  try {
    await api('/api/manual/notify', {
      method: 'POST',
      body: formData({ mid: mid.value, memo: notifyMemo.value, onlyAssigned: notifyOnlyAssigned.value ? 'Y' : 'N' }),
    })
    notifyOpen.value = false
  } catch (cause) {
    notifyError.value = cause instanceof Error ? cause.message : '작성 요청을 보내지 못했습니다.'
  } finally {
    notifySending.value = false
  }
}
async function openDocStyle() {
  if (!header.value) return
  try {
    if (!session.bootstrap) await session.load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '문서 스타일 기본값을 불러오지 못했습니다.'
    return
  }
  headingStyles.value = parseHeadingStyles(header.value.HEADING_STYLE_JSON)
  bodyFont.value = header.value.BODY_FONT ?? 'CARLITO'
  bodyLineHeight.value = header.value.BODY_LINE_HEIGHT ?? 1.2
  bodyLetterSpacing.value = header.value.BODY_LETTER_SPACING ?? 0
  docStyleOpen.value = true
}
async function saveDocStyle() {
  if (!canEdit.value) return
  docStyleSaving.value = true
  try {
    await api('/api/editor/heading-style', {
      method: 'POST',
      body: formData({
        mid: mid.value,
        style: JSON.stringify(headingStyles.value),
        bodyFont: bodyFont.value,
        lineHeight: bodyLineHeight.value,
        letterSpacing: bodyLetterSpacing.value,
      }),
    })
    docStyleOpen.value = false
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '문서 스타일을 저장하지 못했습니다.'
  } finally {
    docStyleSaving.value = false
  }
}
onMounted(async () => {
  await Promise.all([load(), loadDatasheets(), loadTeams()])
})
</script>

<template>
  <section class="manual-detail">
    <p v-if="error" class="error">{{ error }}</p>
    <div v-else-if="!mid" class="empty">
      <p>새 문서를 생성합니다.</p>
      <button @click="create">문서 생성</button>
    </div>
    <div v-else-if="loading">불러오는 중…</div>
    <template v-else-if="header && form">
      <header class="manual-detail-heading">
        <div>
          <div class="manual-detail-title">
            <h1>{{ header.MODEL_NAME }}</h1>
            <AppBadge :status="header.STATUS" /><span class="manual-revision">Rev {{ header.REVISION }}</span>
          </div>
          <p>{{ header.DOC_NUM }} · 등록 {{ formatDate(header.REG_DT) }}</p>
        </div>
        <div class="manual-detail-actions">
          <RouterLink class="button secondary" to="/manual">목록</RouterLink
          ><button class="secondary" type="button" :disabled="!canEdit" @click="openNotify">작성 요청 보내기</button
          ><RouterLink class="button secondary" :to="{ path: '/manual/preview', query: { mid } }"
            >미리보기 · PDF</RouterLink
          ><button type="button" :disabled="!canEdit" @click="openEditor()">본문 편집</button>
        </div>
      </header>
      <p v-if="!canEdit" class="readonly-notice">읽기 전용입니다. 수정 기능은 사용할 수 없습니다.</p>
      <div class="manual-detail-grid">
        <form class="panel admin-card manual-info-card" @submit.prevent="save">
          <header class="admin-card-header">
            <h2>기본 정보</h2>
            <button class="secondary inline" type="button" :disabled="!canEdit" @click="openDocStyle">
              문서 스타일
            </button>
          </header>
          <div class="admin-card-content manual-info-fields">
            <label
              ><span class="field-label">Model Name <strong aria-hidden="true">*</strong></span
              ><input v-model="form.MODEL_NAME" :readonly="!canEdit" required
            /></label>
            <label
              >Job Number<DatasheetSelect
                v-model="form.JOB_NUMBER"
                :options="datasheets"
                :disabled="!canEdit"
                @select="pickDatasheet"
            /></label>
            <button
              class="secondary form-submit"
              type="button"
              :disabled="specLoading || !form.JOB_NUMBER"
              @click="openSpec"
            >
              {{ specLoading ? '불러오는 중…' : 'SPECIFICATIONS 보기' }}
            </button>
            <p class="field-help">
              Datasheet 의 category·parameter 를 볼 때마다 읽어 SPECIFICATIONS 목차와 PDF 에 그립니다.
            </p>
            <label
              >Label<select v-model="form.LABEL" :disabled="!canEdit">
                <option value="">선택 안 함</option>
                <option value="EXODUS">Exodus</option>
                <option value="OEM">OEM</option>
              </select></label
            >
            <label
              >Cooling<select v-model="form.COOLING" :disabled="!canEdit">
                <option value="">선택 안 함</option>
                <option value="AIR">Air</option>
                <option value="LIQUID">Liquid</option>
              </select></label
            >
            <label>Option<textarea v-model="form.OPTION_TEXT" :readonly="!canEdit" rows="3" /></label>
            <label>Version<input v-model="form.DOC_VERSION" :readonly="!canEdit" /></label>
            <p class="field-help">PDF 아래쪽에 “1 | Page - Ver. 1.0” 형식으로 찍힙니다.</p>
            <label
              >Page Size<select v-model="form.PAGE_SIZE" :disabled="!canEdit">
                <option value="LETTER">Letter (216 x 279mm)</option>
                <option value="A4">A4 (210 x 297mm)</option>
              </select></label
            >
            <button v-if="canEdit" class="form-submit" :disabled="saving">
              {{ saving ? '저장 중…' : '기본 정보 저장' }}
            </button>
            <div class="manual-cover">
              <span>표지 이미지</span>
              <div class="manual-cover-preview">
                <img v-if="header.COVER_IMAGE_PATH" :src="header.COVER_IMAGE_PATH" alt="표지 이미지" />
                <p v-else>미리보기 표지에 넣을 제품 사진을 올리세요.</p>
              </div>
              <div v-if="canEdit" class="manual-cover-actions">
                <label class="button secondary"
                  ><input
                    type="file"
                    accept="image/png,image/jpeg,image/gif,image/webp"
                    :disabled="coverUploading"
                    @change="uploadCover"
                  />{{ coverUploading ? '업로드 중…' : '이미지 업로드' }}</label
                ><button class="danger" type="button" :disabled="!header.COVER_IMAGE_PATH" @click="deleteCover">
                  삭제
                </button>
              </div>
            </div>
          </div>
        </form>
        <section class="panel admin-card manual-sections-card">
          <header class="admin-card-header">
            <h2>
              목차 <small>{{ sections.length }}개</small>
            </h2>
            <button class="secondary inline" type="button" :disabled="!canEdit" @click="templateOpen = true">
              목차관리
            </button>
          </header>
          <div class="admin-card-content">
            <AppTable min-width="66rem"
              ><thead>
                <tr>
                  <th>번호</th>
                  <th>제목</th>
                  <th>담당</th>
                  <th>내용</th>
                  <th>최종 수정</th>
                  <th>관리</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(section, index) in sections" :key="section.SEC_ID">
                  <td class="cell-nowrap">{{ sectionNumber(section) }}</td>
                  <td>
                    <span v-if="isPageBreak(section)" class="template-pagebreak">— 페이지 나눔 —</span>
                    <div v-else class="manual-section-title" :style="{ paddingLeft: `${section.SEC_LEVEL - 1}rem` }">
                      <strong>{{ section.TITLE }}</strong
                      ><small>{{ levelName(section.SEC_LEVEL) }}</small>
                    </div>
                  </td>
                  <td>{{ isPageBreak(section) ? '-' : section.ASSIGNED_TEAM || '전체' }}</td>
                  <td class="cell-nowrap">{{ isPageBreak(section) ? '-' : (section.BLOCK_CNT ?? 0) }}</td>
                  <td>
                    <template v-if="section.EDITOR_NAME || section.UPT_DT"
                      ><strong>{{ section.EDITOR_NAME || '-' }}</strong
                      ><small>{{ formatDateTime(section.UPT_DT) }}</small></template
                    ><span v-else>-</span>
                  </td>
                  <td class="row-actions">
                    <button
                      class="inline action-move"
                      :disabled="!canEditSection(section) || ordering || index === 0"
                      @click="moveSection(sections, index, -1, (items) => (sections = items))"
                    >
                      ↑</button
                    ><button
                      class="inline action-move"
                      :disabled="!canEditSection(section) || ordering || index === sections.length - 1"
                      @click="moveSection(sections, index, 1, (items) => (sections = items))"
                    >
                      ↓</button
                    ><button
                      class="inline action-edit"
                      :disabled="!canEditSection(section) || sectionLoading || isPageBreak(section)"
                      @click="openSection(section)"
                    >
                      수정</button
                    ><button class="inline danger" :disabled="!canEditSection(section)" @click="removeSection(section)">
                      삭제</button
                    ><button
                      v-if="!isPageBreak(section)"
                      class="inline action-info"
                      type="button"
                      @click="openEditor(section.SEC_ID)"
                    >
                      본문
                    </button>
                  </td>
                </tr>
              </tbody></AppTable
            >
            <p class="manual-sections-help">
              목차에 지정된 팀이 그대로 참여 범위가 됩니다. 팀을 바꾸려면 목차관리를 사용하세요.
            </p>
          </div>
        </section>
      </div>
    </template>
    <AppDialog v-model:open="specOpen" :title="specTitle" :title-detail="form?.JOB_NUMBER" wide
      ><p v-if="specLoading">불러오는 중…</p>
      <template v-else
        ><p v-if="specMessage" class="spec-message">{{ specMessage }}</p>
        <iframe v-if="specHtml" class="spec-source-frame" :srcdoc="specDocument" title="Datasheet 사양" />
        <p v-else>보여줄 사양이 없습니다.</p></template
      ><template #footer
        ><button class="secondary" type="button" @click="specOpen = false">닫기</button></template
      ></AppDialog
    >
    <TemplateSectionDialog v-model:open="templateOpen" :mid="mid" :can-edit="canEdit" @changed="reloadSections" />
    <AppDialog v-model:open="sectionOpen" title="목차 수정">
      <p v-if="sectionError" class="error">{{ sectionError }}</p>
      <div class="section-edit-grid">
        <label
          ><span class="field-label">제목 단계<strong>*</strong></span
          ><select v-model.number="sectionForm.SEC_LEVEL">
            <option :value="1">대제목</option>
            <option :value="2">중제목</option>
            <option :value="3">소제목</option>
          </select></label
        >
        <label>번호<input v-model.trim="sectionForm.SEC_NO" maxlength="20" placeholder="예: 1 / 1.1 / 1.1.1" /></label>
      </div>
      <label
        ><span class="field-label">제목<strong>*</strong></span
        ><input v-model.trim="sectionForm.TITLE" maxlength="200" required
      /></label>
      <label
        ><span class="field-label">제목 가로 정렬<strong>*</strong></span
        ><select v-model="sectionForm.TITLE_ALIGN">
          <option value="LEFT">왼쪽</option>
          <option value="CENTER">가운데</option>
          <option value="RIGHT">오른쪽</option></select
        ><small>문서 제목 스타일과 별개로 동작합니다.</small></label
      >
      <div class="section-edit-grid">
        <label
          ><span class="field-label">제목 밑줄<strong>*</strong></span
          ><select v-model="sectionForm.TITLE_UNDERLINE">
            <option value="N">없음</option>
            <option value="Y">사용</option>
          </select></label
        >
        <label
          ><span class="field-label">목차 페이지 표시<strong>*</strong></span
          ><select v-model="sectionForm.SHOW_IN_TOC">
            <option value="Y">보임</option>
            <option value="N">숨김</option>
          </select></label
        >
      </div>
      <label
        >담당 팀<select v-model="sectionForm.ASSIGNED_TEAM">
          <option value="">미지정 (참여자 모두 작성 가능)</option>
          <option v-for="team in teams" :key="`${team.DIVISION}/${team.TEAM}`" :value="team.TEAM">
            {{ team.DIVISION }} / {{ team.TEAM }}
          </option></select
        ><small>팀을 지정하면 그 팀 소속만 내용을 작성·수정할 수 있습니다.</small></label
      >
      <template #footer
        ><button class="secondary" type="button" @click="sectionOpen = false">취소</button
        ><button type="button" :disabled="sectionSaving" @click="saveSection">
          {{ sectionSaving ? '저장 중…' : '저장' }}
        </button></template
      >
    </AppDialog>
    <AppDialog v-model:open="notifyOpen" title="작성 요청 보내기" large>
      <p v-if="notifyLoading">수신자를 불러오는 중…</p>
      <template v-else>
        <div v-if="notifyTestMode" class="notify-test-notice">
          메일 설정이 <strong>TEST</strong> 모드입니다. 실제 발송 대신 <code>App_Data/mail-drop</code>에
          <code>.eml</code> 파일로 저장됩니다.
        </div>
        <p v-if="notifyError" class="error">{{ notifyError }}</p>
        <label
          >메모 (선택)<textarea
            v-model.trim="notifyMemo"
            rows="2"
            maxlength="500"
            placeholder="예: 9월 10일까지 담당 섹션 작성 부탁드립니다."
          />
        </label>
        <label class="notify-assignment-filter"
          ><input v-model="notifyOnlyAssigned" type="checkbox" /> 담당 목차가 있는 사람에게만 보내기</label
        >
        <p class="notify-recipient-title">수신 예정</p>
        <table class="notify-recipients-table">
          <thead>
            <tr>
              <th>이름</th>
              <th>역할</th>
              <th>이메일</th>
              <th>담당 섹션</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="recipient in notifyTargets" :key="recipient.USER_ID">
              <td>
                <strong>{{ recipient.FULL_NAME }}</strong>
              </td>
              <td>{{ roleLabel(recipient.MEMBER_ROLE) }}</td>
              <td>{{ recipient.EMAIL_ADDRESS || '이메일 없음' }}</td>
              <td>{{ recipient.ASSIGNED_SECTIONS || '-' }}</td>
            </tr>
            <tr v-if="notifyTargets.length === 0">
              <td colspan="4" class="notify-empty">보낼 수신자가 없습니다.</td>
            </tr>
          </tbody>
        </table>
      </template>
      <template #footer
        ><button class="secondary" type="button" @click="notifyOpen = false">취소</button
        ><button
          type="button"
          :disabled="notifyLoading || notifySending || notifyTargets.length === 0"
          @click="sendNotify"
        >
          {{ notifySending ? '보내는 중…' : notifyTargets.length + '명에게 보내기' }}
        </button></template
      >
    </AppDialog>
    <AppDialog v-model:open="docStyleOpen" title="문서 스타일 (문서 전체 공통)">
      <div class="document-style-form">
        <section class="document-style-section">
          <h3>본문</h3>
          <div class="document-style-body-grid">
            <label class="document-style-full"
              >글꼴<select v-model="bodyFont">
                <option v-for="font in session.bootstrap?.bodyFonts ?? []" :key="font.code" :value="font.code">
                  {{ bodyFontLabel(font.code, font.name) }}
                </option>
              </select></label
            >
            <label
              >행간 (줄 간격)<input v-model.number="bodyLineHeight" type="number" min="1" max="3" step="0.1"
            /></label>
            <label
              >자간 (px)<input v-model.number="bodyLetterSpacing" type="number" min="-1" max="3" step="0.1"
            /></label>
          </div>
          <div class="document-style-preview" :style="bodyPreview">
            본문 미리보기 — The quick brown fox jumps over.<br />여러 줄일 때의 줄 간격을 이렇게 확인할 수 있습니다.
          </div>
          <p class="field-help">글자 크기는 12pt로 고정입니다. 글꼴·행간·자간은 문서 전체에 동일하게 적용됩니다.</p>
        </section>
        <div class="document-style-divider"></div>
        <p class="document-style-note">개별 스타일을 지정한 목차는 여기서 바꿔도 그대로 유지됩니다.</p>
        <section v-for="level in ['1', '2', '3']" :key="level" class="document-style-section document-heading-section">
          <h3>{{ levelName(Number(level)) }}</h3>
          <div class="document-style-heading-grid">
            <label>크기(pt)<input v-model.number="headingStyles[level].size" type="number" min="8" max="48" /></label>
            <label>글자색<input v-model="headingStyles[level].color" type="color" /></label>
            <label
              >굵기<select v-model="headingStyles[level].bold">
                <option :value="true">굵게</option>
                <option :value="false">보통</option>
              </select></label
            >
            <label
              >밑줄<select v-model="headingStyles[level].underline">
                <option :value="true">사용</option>
                <option :value="false">없음</option>
              </select></label
            >
          </div>
          <div class="document-style-preview" :style="headingPreview(level)">
            {{ levelName(Number(level)) }} 미리보기
          </div>
        </section>
      </div>
      <template #footer
        ><button class="secondary" type="button" @click="docStyleOpen = false">취소</button
        ><button type="button" :disabled="docStyleSaving" @click="saveDocStyle">
          {{ docStyleSaving ? '저장 중…' : '저장' }}
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
.document-style-form,
.document-style-section {
  display: grid;
  gap: var(--ex-space-4);
}
.document-style-form label {
  margin: 0;
}
.document-style-section h3 {
  margin: 0;
  color: var(--ex-color-text);
  font-size: 0.875rem;
  font-weight: 700;
}
.document-style-body-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--ex-space-3);
}
.document-style-full {
  grid-column: 1 / -1;
}
.document-style-preview {
  border-radius: var(--ex-radius-sm);
  background: #f2f5f7;
  padding: var(--ex-space-3);
  color: var(--ex-color-text);
  font-size: 0.875rem;
}
.document-style-section .field-help {
  margin: -0.3rem 0 0;
  color: var(--ex-color-text-subtle);
  font-size: 0.75rem;
  line-height: 1.55;
}
.document-style-divider {
  height: 1px;
  background: var(--ex-color-border);
  margin: var(--ex-space-1) 0;
}
.document-style-note {
  margin: 0;
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
  line-height: 1.55;
}
.document-heading-section {
  border-bottom: 1px solid var(--ex-color-border);
  padding-bottom: var(--ex-space-4);
}
.document-heading-section:last-child {
  border-bottom: 0;
  padding-bottom: 0;
}
.document-style-heading-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: var(--ex-space-3);
}
.section-edit-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--ex-space-3);
}
.notify-test-notice {
  margin-bottom: var(--ex-space-4);
  border: 1px solid #d9c5f6;
  border-radius: var(--ex-radius-sm);
  background: #eee7fc;
  color: #5f3ea5;
  padding: 0.75rem var(--ex-space-3);
  font-size: 0.75rem;
  line-height: 1.5;
}
.notify-test-notice code {
  border-radius: var(--ex-radius-xs);
  background: #fff;
  color: #c0449c;
  padding: 0.1rem 0.3rem;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
}
.notify-assignment-filter {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: var(--ex-space-4);
  font-size: 0.8125rem;
}
.notify-recipient-title {
  margin: 0 0 var(--ex-space-2);
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
}
.notify-recipients-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.75rem;
}
.notify-recipients-table th {
  border-top: 1px solid var(--ex-color-border);
  border-bottom: 1px solid var(--ex-color-border);
  color: var(--ex-color-text-muted);
  font-weight: 700;
  text-align: left;
}
.notify-recipients-table th,
.notify-recipients-table td {
  padding: 0.5rem 0.25rem;
}
.notify-recipients-table th:nth-child(2) {
  width: 6.875rem;
}
.notify-recipients-table th:nth-child(3) {
  width: 12.5rem;
}
.notify-recipients-table td {
  border-bottom: 1px solid var(--ex-color-border);
  color: var(--ex-color-text-muted);
}
.notify-recipients-table td:first-child {
  color: var(--ex-color-text);
}
.notify-empty {
  padding: 1.5rem !important;
  text-align: center;
}
@media (max-width: 680px) {
  .document-style-heading-grid,
  .section-edit-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
