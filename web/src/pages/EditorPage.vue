<script setup lang="ts">
import { computed, onMounted, ref, watch, type CSSProperties } from 'vue'
import { useRoute } from 'vue-router'
import { api, formData, query } from '../api/client'
import type { HeadingStyle, ManualHeader, ManualSection, SectionHistoryItem, TeamOption } from '../api/types'
import AppDialog from '../design-system/AppDialog.vue'
import AppBadge from '../design-system/AppBadge.vue'
import ConfirmDialog from '../design-system/ConfirmDialog.vue'
import { useConfirmDialog } from '../design-system/useConfirmDialog'
import BlockEditor from '../features/editor/BlockEditor.vue'
import { newTable, normalizeTable, toTableHtml, type TableState } from '../features/editor/table'
import { useSessionStore } from '../stores/session'
import TemplateSectionDialog from '../features/manual/TemplateSectionDialog.vue'

interface Block {
  ELE_ID?: number
  M_ID: string
  SEC_ID: number
  ELE_TYPE: 'TEXT' | 'IMAGE' | 'TABLE'
  ORDER_NUM: number
  WIDTH: number
  HEIGHT: number
  CONTENT_HTML?: string
  IMAGE_PATH?: string
  CAPTION?: string
  STYLE_JSON?: string
  ROW_VER?: string
  TABLE?: TableState
}
interface Access {
  CAN_EDIT: string
}
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

const route = useRoute()
const mid = computed(() => (typeof route.query.mid === 'string' ? route.query.mid : ''))
const requestedSecId = computed(() => Number(route.query.secId))
const session = useSessionStore()
const header = ref<ManualHeader | null>(null)
const sections = ref<ManualSection[]>([])
const blocks = ref<Block[]>([])
const access = ref<Access | null>(null)
const activeSecId = ref<number | null>(null)
const error = ref('')
const saving = ref<number | 'new' | null>(null)
const sectionOpen = ref(false)
const templateOpen = ref(false)
const sectionSaving = ref(false)
const sectionError = ref('')
const teams = ref<TeamOption[]>([])
const historyOpen = ref(false)
const historyLoading = ref(false)
const history = ref<SectionHistoryItem[]>([])
const specHtml = ref('')
const specMessage = ref('')
const specLoading = ref(false)
const saveState = ref('')
const styleOpen = ref(false)
const styleSaving = ref(false)
const styleEnabled = ref(false)
const sectionStyle = ref<HeadingStyle>({ size: 13, color: '#181c32', bold: true, underline: false })
const confirmation = useConfirmDialog()
const sectionForm = ref<SectionForm>({
  TITLE: '',
  SEC_LEVEL: 1,
  TITLE_ALIGN: 'LEFT',
  SHOW_IN_TOC: 'Y',
  TITLE_UNDERLINE: 'N',
  SEC_TYPE: 'NORMAL',
})
const activeSection = computed(() => sections.value.find((section) => section.SEC_ID === activeSecId.value) ?? null)
const activeBlocks = computed(() =>
  blocks.value
    .filter((block) => block.SEC_ID === activeSecId.value)
    .sort((left, right) => left.ORDER_NUM - right.ORDER_NUM),
)
const canEditDocument = computed(() => access.value?.CAN_EDIT === 'Y')
const canEditActive = computed(() => canEditDocument.value && activeSection.value?.CAN_EDIT_SEC === 'Y')
const isSpecSection = computed(() => /SPECIFICATION/i.test(activeSection.value?.TITLE ?? ''))

function prepareBlock(block: Block): Block {
  return block.ELE_TYPE === 'TABLE' ? { ...block, TABLE: normalizeTable(block.STYLE_JSON) } : block
}
function commonStyle(level: number): HeadingStyle {
  return {
    ...(session.bootstrap?.headingStyles[String(level)] ?? {
      size: 13,
      color: '#181c32',
      bold: true,
      underline: false,
    }),
  }
}
function parseStyle(value?: string): Partial<HeadingStyle> | null {
  try {
    const parsed = value ? JSON.parse(value) : null
    return parsed && typeof parsed === 'object' ? (parsed as Partial<HeadingStyle>) : null
  } catch {
    return null
  }
}
function levelName(level: number) {
  return level === 1 ? '대제목' : level === 2 ? '중제목' : '소제목'
}
function isPageBreak(section?: ManualSection | null) {
  return section?.SEC_TYPE === 'PAGEBREAK'
}
function newSectionForm(section?: ManualSection): SectionForm {
  return section
    ? {
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
    : { TITLE: '', SEC_LEVEL: 1, TITLE_ALIGN: 'LEFT', SHOW_IN_TOC: 'Y', TITLE_UNDERLINE: 'N', SEC_TYPE: 'NORMAL' }
}
async function load() {
  if (!mid.value) return
  error.value = ''
  try {
    const data = await api<{ header: ManualHeader; sections: ManualSection[]; blocks: Block[]; access: Access }>(
      query('/api/editor/data', { mid: mid.value }),
    )
    header.value = data.header
    sections.value = data.sections
    blocks.value = data.blocks.map(prepareBlock)
    access.value = data.access
    const requested = requestedSecId.value
    activeSecId.value ??= data.sections.some((section) => section.SEC_ID === requested)
      ? requested
      : (data.sections.find((section) => section.SEC_TYPE !== 'PAGEBREAK')?.SEC_ID ?? data.sections[0]?.SEC_ID ?? null)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '편집기를 불러오지 못했습니다.'
  }
}
async function loadSections() {
  sections.value = (await api<{ list: ManualSection[] }>(query('/api/editor/sections', { mid: mid.value }))).list
}
async function loadTeams() {
  try {
    teams.value = (await api<{ teams: TeamOption[] }>('/api/manual/teams')).teams
  } catch {
    teams.value = []
  }
}
async function save(block: Block) {
  if (!canEditActive.value) return
  saving.value = block.ELE_ID ?? 'new'
  saveState.value = '저장 중…'
  if (block.ELE_TYPE === 'TABLE' && block.TABLE) {
    block.STYLE_JSON = JSON.stringify(block.TABLE)
    block.CONTENT_HTML = toTableHtml(block.TABLE)
  }
  try {
    const result = await api<{ block: Block }>('/api/editor/block', { method: 'POST', body: JSON.stringify(block) })
    const saved = prepareBlock(result.block)
    const index = blocks.value.findIndex((item) => item.ELE_ID === block.ELE_ID)
    if (index >= 0) blocks.value[index] = saved
    else blocks.value.push(saved)
    saveState.value = '저장됨'
    window.setTimeout(() => {
      if (saveState.value === '저장됨') saveState.value = ''
    }, 1500)
  } catch (cause) {
    saveState.value = '저장 실패'
    error.value = cause instanceof Error ? cause.message : '블록을 저장하지 못했습니다.'
  } finally {
    saving.value = null
  }
}
function addText() {
  if (activeSecId.value && canEditActive.value)
    blocks.value.push({
      M_ID: mid.value,
      SEC_ID: activeSecId.value,
      ELE_TYPE: 'TEXT',
      ORDER_NUM: activeBlocks.value.length + 1,
      WIDTH: 0,
      HEIGHT: 0,
      CONTENT_HTML: '',
    })
}
function addTable() {
  if (!activeSecId.value || !canEditActive.value) return
  const table = newTable()
  blocks.value.push({
    M_ID: mid.value,
    SEC_ID: activeSecId.value,
    ELE_TYPE: 'TABLE',
    ORDER_NUM: activeBlocks.value.length + 1,
    WIDTH: 100,
    HEIGHT: 0,
    STYLE_JSON: JSON.stringify(table),
    CONTENT_HTML: toTableHtml(table),
    TABLE: table,
  })
}
function addTableRow(block: Block) {
  block.TABLE?.rows.push(block.TABLE.head.map(() => ''))
}
function removeTableRow(block: Block, index: number) {
  if (block.TABLE && block.TABLE.rows.length > 1) block.TABLE.rows.splice(index, 1)
}
function addTableColumn(block: Block) {
  if (!block.TABLE) return
  block.TABLE.head.push('')
  block.TABLE.align.push('left')
  block.TABLE.widths.push(0)
  block.TABLE.rows.forEach((row) => row.push(''))
}
function removeTableColumn(block: Block, index: number) {
  if (!block.TABLE || block.TABLE.head.length <= 1) return
  block.TABLE.head.splice(index, 1)
  block.TABLE.align.splice(index, 1)
  block.TABLE.widths.splice(index, 1)
  block.TABLE.rows.forEach((row) => row.splice(index, 1))
}
async function uploadImage(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file || !activeSecId.value || !canEditActive.value) return
  saving.value = 'new'
  try {
    const data = new FormData()
    data.append('mid', mid.value)
    data.append('file', file)
    const upload = await api<{ path: string }>('/api/editor/image', { method: 'POST', body: data })
    const result = await api<{ block: Block }>('/api/editor/block', {
      method: 'POST',
      body: JSON.stringify({
        M_ID: mid.value,
        SEC_ID: activeSecId.value,
        ELE_TYPE: 'IMAGE',
        ORDER_NUM: activeBlocks.value.length + 1,
        WIDTH: 100,
        HEIGHT: 0,
        IMAGE_PATH: upload.path,
        CAPTION: '',
      }),
    })
    blocks.value.push(result.block)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '이미지를 추가하지 못했습니다.'
  } finally {
    saving.value = null
    ;(event.target as HTMLInputElement).value = ''
  }
}
async function saveActiveBlocks() {
  for (const block of activeBlocks.value) await save(block)
}
async function moveBlock(index: number, delta: number) {
  if (!canEditActive.value) return
  const reordered = [...activeBlocks.value]
  const target = index + delta
  if (target < 0 || target >= reordered.length) return
  if (reordered.some((block) => !block.ELE_ID)) {
    error.value = '새 블록을 먼저 저장한 뒤 순서를 바꾸세요.'
    return
  }
  ;[reordered[index], reordered[target]] = [reordered[target], reordered[index]]
  reordered.forEach((block, order) => {
    block.ORDER_NUM = order + 1
  })
  try {
    await api('/api/editor/block/order', {
      method: 'POST',
      body: JSON.stringify({
        M_ID: mid.value,
        ORDERS: reordered.map((block) => `${block.ELE_ID}:${block.ORDER_NUM}`).join(','),
      }),
    })
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '블록 순서를 저장하지 못했습니다.'
    await load()
  }
}
function removeBlock(block: Block) {
  if (!block.ELE_ID) return
  confirmation.request({
    title: '블록 삭제',
    message: '이 블록을 삭제합니다.',
    confirmLabel: '삭제',
    danger: true,
    action: async () => {
      try {
        await api(query('/api/editor/block', { eleId: block.ELE_ID, mid: mid.value }), { method: 'DELETE' })
        blocks.value = blocks.value.filter((item) => item.ELE_ID !== block.ELE_ID)
      } catch (cause) {
        error.value = cause instanceof Error ? cause.message : '블록을 삭제하지 못했습니다.'
      }
    },
  })
}
function openSection(section?: ManualSection) {
  sectionError.value = ''
  sectionForm.value = newSectionForm(section)
  sectionOpen.value = true
}
async function saveSection() {
  if (!canEditDocument.value || !sectionForm.value.TITLE.trim()) {
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
function deleteSection() {
  if (!activeSection.value || !canEditActive.value) return
  const section = activeSection.value
  confirmation.request({
    title: '목차 삭제',
    message: '선택한 목차와 작성된 내용을 삭제합니다.',
    confirmLabel: '삭제',
    danger: true,
    action: async () => {
      try {
        await api(query('/api/editor/section', { secId: section.SEC_ID, mid: mid.value }), { method: 'DELETE' })
        activeSecId.value = null
        await load()
      } catch (cause) {
        error.value = cause instanceof Error ? cause.message : '목차를 삭제하지 못했습니다.'
      }
    },
  })
}
async function moveSection(delta: number) {
  if (!activeSection.value || !canEditActive.value) return
  const index = sections.value.findIndex((item) => item.SEC_ID === activeSection.value?.SEC_ID)
  const target = index + delta
  if (index < 0 || target < 0 || target >= sections.value.length) return
  const reordered = [...sections.value]
  ;[reordered[index], reordered[target]] = [reordered[target], reordered[index]]
  sections.value = reordered
  try {
    await api('/api/editor/section/order', {
      method: 'POST',
      body: formData({
        mid: mid.value,
        orders: reordered.map((item, order) => `${item.SEC_ID}:${order + 1}`).join(','),
      }),
    })
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '목차 순서를 저장하지 못했습니다.'
    await loadSections()
  }
}
async function templateChanged(sectionId: number) {
  await loadSections()
  activeSecId.value = sectionId
}
function openStyle() {
  if (!activeSection.value) return
  const own = parseStyle(activeSection.value.STYLE_JSON)
  styleEnabled.value = Boolean(own)
  sectionStyle.value = { ...commonStyle(activeSection.value.SEC_LEVEL), ...own }
  styleOpen.value = true
}
const sectionStylePreview = computed<CSSProperties>(() => ({
  fontSize: `${sectionStyle.value.size}pt`,
  color: sectionStyle.value.color,
  fontWeight: sectionStyle.value.bold ? '700' : '400',
  textDecoration: sectionStyle.value.underline || activeSection.value?.TITLE_UNDERLINE === 'Y' ? 'underline' : 'none',
  textAlign:
    activeSection.value?.TITLE_ALIGN === 'CENTER'
      ? 'center'
      : activeSection.value?.TITLE_ALIGN === 'RIGHT'
        ? 'right'
        : 'left',
}))
function sectionCss(section: ManualSection): CSSProperties {
  const style = { ...commonStyle(section.SEC_LEVEL), ...parseStyle(section.STYLE_JSON) }
  return {
    fontSize: `${style.size}pt`,
    color: style.color,
    fontWeight: style.bold ? '700' : '400',
    textDecoration: style.underline || section.TITLE_UNDERLINE === 'Y' ? 'underline' : 'none',
    textAlign: section.TITLE_ALIGN === 'CENTER' ? 'center' : section.TITLE_ALIGN === 'RIGHT' ? 'right' : 'left',
  }
}
async function loadSpec() {
  specHtml.value = ''
  specMessage.value = ''
  if (!isSpecSection.value) return
  specLoading.value = true
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
async function saveStyle() {
  if (!activeSection.value || !canEditActive.value) return
  styleSaving.value = true
  try {
    const section = activeSection.value
    await api('/api/editor/section', {
      method: 'POST',
      body: JSON.stringify({
        SEC_ID: section.SEC_ID,
        M_ID: mid.value,
        TITLE: section.TITLE,
        SEC_LEVEL: section.SEC_LEVEL,
        SEC_NO: section.SEC_NO,
        ASSIGNED_TEAM: section.ASSIGNED_TEAM,
        TITLE_ALIGN: section.TITLE_ALIGN ?? 'LEFT',
        SEC_TYPE: section.SEC_TYPE ?? 'NORMAL',
        SHOW_IN_TOC: section.SHOW_IN_TOC ?? 'Y',
        TITLE_UNDERLINE: section.TITLE_UNDERLINE ?? 'N',
        STYLE_JSON: styleEnabled.value ? JSON.stringify(sectionStyle.value) : '',
      }),
    })
    styleOpen.value = false
    await loadSections()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '제목 스타일을 저장하지 못했습니다.'
  } finally {
    styleSaving.value = false
  }
}
async function openHistory() {
  if (!activeSection.value) return
  historyOpen.value = true
  historyLoading.value = true
  history.value = []
  try {
    history.value = (
      await api<{ list: SectionHistoryItem[] }>(
        query('/api/editor/section/history', { mid: mid.value, secId: activeSection.value.SEC_ID }),
      )
    ).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '수정 이력을 불러오지 못했습니다.'
  } finally {
    historyLoading.value = false
  }
}
function historyAction(action: string) {
  return (
    (
      {
        CREATE: '추가',
        UPDATE: '수정',
        DELETE: '삭제',
        REORDER: '순서 변경',
        MOVE: '이동',
        RESIZE: '크기 변경',
        RESTORE: '복원',
        ASSIGN: '담당 변경',
      } as Record<string, string>
    )[action] ?? action
  )
}
function historyTarget(item: SectionHistoryItem) {
  if (item.FIELD_NAME === 'SECTION') return '목차'
  if (item.FIELD_NAME === 'TITLE') return '목차 제목'
  if (item.FIELD_NAME === 'TITLE_ALIGN') return '목차 제목 정렬'
  if (item.FIELD_NAME === 'SECTION_ORDER') return '목차 순서'
  if (item.AFTER_VALUE === 'IMAGE') return '이미지 블록'
  if (item.AFTER_VALUE === 'TEXT') return '텍스트 블록'
  if (item.AFTER_VALUE === 'TABLE') return '표 블록'
  return item.ELE_ID ? '블록' : (item.FIELD_NAME ?? '')
}
function formatDateTime(value: string) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '' : `${date.toLocaleDateString('sv-SE')} ${date.toTimeString().slice(0, 5)}`
}
watch(activeSecId, () => {
  void loadSpec()
})
onMounted(async () => {
  await Promise.all([load(), loadTeams()])
})
</script>
<template>
  <section class="manual-editor">
    <p v-if="error" class="error">{{ error }}</p>
    <p v-else-if="!header">불러오는 중…</p>
    <template v-else>
      <header class="manual-editor-header">
        <div>
          <div class="manual-editor-title">
            <h1>{{ header.MODEL_NAME }}</h1>
            <AppBadge :status="header.STATUS" /><span class="manual-editor-revision">Rev {{ header.REVISION }}</span>
          </div>
          <p>{{ header.DOC_NUM }}</p>
        </div>
        <div class="manual-editor-header-actions">
          <span class="editor-save-state" aria-live="polite">{{ saveState }}</span
          ><RouterLink class="button secondary" :to="{ path: '/manual/detail', query: { mid } }">문서 정보</RouterLink
          ><RouterLink class="button" :to="{ path: '/manual/preview', query: { mid } }">미리보기 · PDF</RouterLink>
        </div>
      </header>
      <p v-if="!canEditDocument" class="readonly-notice">
        읽기 전용입니다. 작성(DRAFT) 상태의 참여자만 편집할 수 있습니다.
      </p>
      <div class="manual-editor-layout">
        <aside class="manual-outline">
          <header>
            <span>목차</span
            ><button class="inline" :disabled="!canEditDocument" @click="templateOpen = true">목차관리</button>
          </header>
          <p v-if="sections.length === 0" class="manual-outline-empty">목차가 없습니다.<br />템플릿에서 가져오세요.</p>
          <button
            v-for="section in sections"
            :key="section.SEC_ID"
            class="manual-outline-item"
            :class="[
              `level-${section.SEC_LEVEL}`,
              { active: section.SEC_ID === activeSecId, pagebreak: isPageBreak(section) },
            ]"
            type="button"
            @click="activeSecId = section.SEC_ID"
          >
            <template v-if="isPageBreak(section)"><span>— 페이지 나눔 —</span></template
            ><template v-else
              ><span v-if="section.SEC_NO" class="manual-outline-no">{{ section.SEC_NO }}</span
              ><span class="manual-outline-title">{{ section.TITLE }}</span
              ><span v-if="section.BLOCK_CNT" class="manual-outline-count">{{ section.BLOCK_CNT }}</span></template
            >
          </button>
          <footer v-if="sections.length">
            <button class="inline action-move" :disabled="!canEditActive" @click="moveSection(-1)">↑</button
            ><button class="inline action-move" :disabled="!canEditActive" @click="moveSection(1)">↓</button
            ><button
              class="inline"
              :disabled="!canEditActive || activeSection?.SEC_TYPE === 'PAGEBREAK'"
              @click="openSection(activeSection ?? undefined)"
            >
              ✎</button
            ><button class="inline danger" :disabled="!canEditActive" @click="deleteSection">×</button>
          </footer>
        </aside>
        <div class="manual-editor-content">
          <div v-if="!activeSection" class="manual-editor-empty">왼쪽에서 목차를 선택하세요.</div>
          <div v-else-if="isPageBreak(activeSection)" class="manual-editor-empty">
            <strong>페이지 나눔</strong
            ><span
              >PDF에서 이 자리부터 새 페이지로 시작합니다.<br />내용은 넣을 수 없고 순서를 옮기거나 삭제만 할 수
              있습니다.</span
            >
          </div>
          <template v-else>
            <header class="manual-section-header">
              <div>
                <h2 :style="sectionCss(activeSection)">
                  <span v-if="activeSection.SEC_NO">{{ activeSection.SEC_NO }} </span>{{ activeSection.TITLE }}
                </h2>
                <p>
                  {{ levelName(activeSection.SEC_LEVEL) }}<span v-if="activeSection.STYLE_JSON"> · 개별 스타일</span
                  ><span v-if="activeSection.ASSIGNED_TEAM"> · {{ activeSection.ASSIGNED_TEAM }} 담당</span
                  ><span v-if="activeSection.EDITOR_NAME"> · 최종 수정 {{ activeSection.EDITOR_NAME }}</span
                  ><button class="inline" type="button" @click="openHistory">이력</button>
                </p>
              </div>
              <div class="manual-section-actions">
                <button class="inline action-info" :disabled="!canEditActive" @click="addText">+ 텍스트</button
                ><label class="action-info" :class="{ disabled: !canEditActive }"
                  >+ 이미지<input
                    type="file"
                    accept="image/png,image/jpeg,image/gif,image/webp"
                    :disabled="!canEditActive"
                    @change="uploadImage" /></label
                ><button class="inline action-info" :disabled="!canEditActive" @click="addTable">+ 표</button
                ><button :disabled="!canEditActive || saving !== null" @click="saveActiveBlocks">
                  {{ saving !== null ? '저장 중…' : '저장' }}
                </button>
              </div>
            </header>
            <p v-if="!canEditActive && canEditDocument" class="readonly-notice">
              이 목차는 <strong>{{ activeSection.ASSIGNED_TEAM }}</strong> 담당입니다. 내용 수정은 해당 팀만 가능합니다.
            </p>
            <section v-if="isSpecSection" class="manual-spec-panel">
              <header>
                <strong>Datasheet 사양</strong><span>{{ specMessage }}</span
                ><button class="inline" :disabled="specLoading" @click="loadSpec">다시 읽기</button>
              </header>
              <p v-if="specLoading">불러오는 중…</p>
              <div v-else-if="specHtml" class="datasheet-spec" v-html="specHtml" />
              <p v-else>보여줄 사양이 없습니다. 문서 정보에서 Job Number를 확인하세요.</p>
            </section>
            <div v-if="activeBlocks.length === 0" class="manual-editor-empty">
              내용이 없습니다. 텍스트·이미지·표를 추가하세요.
            </div>
            <article
              v-for="(block, index) in activeBlocks"
              :key="block.ELE_ID ?? `new-${index}`"
              class="editor-block-card"
            >
              <header>
                <span>{{ block.ELE_TYPE === 'TEXT' ? '텍스트' : block.ELE_TYPE === 'IMAGE' ? '이미지' : '표' }}</span>
                <div>
                  <button
                    class="inline action-move"
                    :disabled="!canEditActive || index === 0"
                    @click="moveBlock(index, -1)"
                  >
                    ↑</button
                  ><button
                    class="inline action-move"
                    :disabled="!canEditActive || index === activeBlocks.length - 1"
                    @click="moveBlock(index, 1)"
                  >
                    ↓</button
                  ><button
                    class="inline danger"
                    :disabled="!canEditActive || !block.ELE_ID"
                    @click="removeBlock(block)"
                  >
                    ×
                  </button>
                </div>
              </header>
              <div class="editor-block-body">
                <BlockEditor
                  v-if="block.ELE_TYPE === 'TEXT'"
                  :model-value="block.CONTENT_HTML ?? ''"
                  :read-only="!canEditActive"
                  :upload-url="`/api/editor/image?mid=${encodeURIComponent(mid)}`"
                  @update:model-value="block.CONTENT_HTML = $event"
                  @blur="save(block)"
                />
                <div v-else-if="block.ELE_TYPE === 'IMAGE'" class="image-block">
                  <img
                    :src="block.IMAGE_PATH"
                    :style="{ maxWidth: `${block.WIDTH || 100}%` }"
                    alt="문서 이미지"
                  /><label
                    >캡션<input
                      v-model="block.CAPTION"
                      :readonly="!canEditActive"
                      maxlength="500"
                      @change="save(block)" /></label
                  ><label
                    >너비 {{ block.WIDTH || 100 }}%<input
                      v-model.number="block.WIDTH"
                      type="range"
                      min="20"
                      max="100"
                      step="5"
                      :disabled="!canEditActive"
                      @change="save(block)"
                  /></label>
                </div>
                <div v-else-if="block.TABLE" class="table-block">
                  <div class="table-actions">
                    <button class="inline action-info" :disabled="!canEditActive" @click="addTableRow(block)">
                      + 행</button
                    ><button class="inline action-info" :disabled="!canEditActive" @click="addTableColumn(block)">
                      + 열</button
                    ><small>너비(%)를 비우면 내용에 맞춰 자동 조절됩니다.</small>
                  </div>
                  <div class="table-scroll">
                    <table>
                      <thead>
                        <tr>
                          <th></th>
                          <th v-for="(_, column) in block.TABLE.head" :key="column">
                            <input v-model="block.TABLE.head[column]" :readonly="!canEditActive" placeholder="머리글" />
                            <div class="table-column-options">
                              <select v-model="block.TABLE.align[column]" :disabled="!canEditActive">
                                <option value="left">좌</option>
                                <option value="center">중</option>
                                <option value="right">우</option></select
                              ><input
                                v-model.number="block.TABLE.widths[column]"
                                type="number"
                                min="0"
                                max="100"
                                :readonly="!canEditActive"
                                placeholder="%"
                              /><button
                                class="inline danger"
                                :disabled="!canEditActive || block.TABLE.head.length <= 1"
                                @click="removeTableColumn(block, column)"
                              >
                                ×
                              </button>
                            </div>
                          </th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="(row, rowIndex) in block.TABLE.rows" :key="rowIndex">
                          <td>
                            <small>{{ rowIndex + 1 }}</small
                            ><button
                              class="inline danger"
                              :disabled="!canEditActive || block.TABLE.rows.length <= 1"
                              @click="removeTableRow(block, rowIndex)"
                            >
                              ×
                            </button>
                          </td>
                          <td v-for="(_, column) in row" :key="column">
                            <textarea
                              v-model="block.TABLE.rows[rowIndex][column]"
                              :readonly="!canEditActive"
                              :style="{ textAlign: block.TABLE.align[column] }"
                              rows="2"
                            />
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </article>
          </template>
        </div>
      </div>
    </template>
    <AppDialog v-model:open="sectionOpen" :title="sectionForm.SEC_ID ? '목차 수정' : '목차 추가'"
      ><p v-if="sectionError" class="error">{{ sectionError }}</p>
      <label
        >제목 단계<select v-model.number="sectionForm.SEC_LEVEL">
          <option :value="1">대제목</option>
          <option :value="2">중제목</option>
          <option :value="3">소제목</option>
        </select></label
      ><label>번호<input v-model.trim="sectionForm.SEC_NO" maxlength="20" /></label
      ><label>제목<input v-model.trim="sectionForm.TITLE" maxlength="200" /></label
      ><label
        >제목 가로 정렬<select v-model="sectionForm.TITLE_ALIGN">
          <option value="LEFT">왼쪽</option>
          <option value="CENTER">가운데</option>
          <option value="RIGHT">오른쪽</option>
        </select></label
      ><label
        >목차 페이지 표시<select v-model="sectionForm.SHOW_IN_TOC">
          <option value="Y">보임</option>
          <option value="N">숨김</option>
        </select></label
      ><label
        >제목 밑줄<select v-model="sectionForm.TITLE_UNDERLINE">
          <option value="N">없음</option>
          <option value="Y">사용</option>
        </select></label
      ><label
        >담당 팀<select v-model="sectionForm.ASSIGNED_TEAM">
          <option value="">미지정</option>
          <option v-for="team in teams" :key="`${team.DIVISION}/${team.TEAM}`" :value="team.TEAM">
            {{ team.DIVISION }} / {{ team.TEAM }}
          </option>
        </select></label
      ><template #footer
        ><button class="secondary" type="button" @click="sectionOpen = false">취소</button
        ><button type="button" :disabled="sectionSaving" @click="saveSection">
          {{ sectionSaving ? '저장 중…' : '저장' }}
        </button></template
      ></AppDialog
    >
    <TemplateSectionDialog
      v-model:open="templateOpen"
      :mid="mid"
      :can-edit="canEditDocument"
      @changed="templateChanged"
    />
    <div v-if="activeSection" class="history-trigger">
      <button class="secondary" type="button" @click="openHistory">선택 목차 수정 이력</button>
    </div>
    <AppDialog v-model:open="historyOpen" :title="`${activeSection?.TITLE ?? ''} 수정 이력`"
      ><p v-if="historyLoading">불러오는 중…</p>
      <p v-else-if="history.length === 0">수정 이력이 없습니다.</p>
      <table v-else class="history-table">
        <thead>
          <tr>
            <th>일시</th>
            <th>수정자</th>
            <th>작업</th>
            <th>대상</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in history" :key="item.HIS_ID">
            <td>{{ formatDateTime(item.REG_DT) }}</td>
            <td>
              {{ item.REG_NAME }}<small v-if="item.REG_TEAM">{{ item.REG_TEAM }}</small>
            </td>
            <td>{{ historyAction(item.ACTION) }}</td>
            <td>
              {{ historyTarget(item)
              }}<small v-if="item.FIELD_NAME === 'TITLE' && item.BEFORE_VALUE"
                >{{ item.BEFORE_VALUE }} → {{ item.AFTER_VALUE }}</small
              >
            </td>
          </tr>
        </tbody>
      </table>
      <template #footer><span>최근 100건만 표시합니다.</span></template></AppDialog
    >
    <div v-if="activeSection && activeSection.SEC_TYPE !== 'PAGEBREAK'" class="history-trigger">
      <button class="secondary" type="button" :disabled="!canEditActive" @click="openStyle">
        선택 목차 제목 스타일
      </button>
    </div>
    <AppDialog v-model:open="styleOpen" title="목차 제목 스타일"
      ><p>개별 지정을 끄면 이 제목 단계의 문서 공통 스타일을 따릅니다.</p>
      <label class="check-label"><input v-model="styleEnabled" type="checkbox" /> 개별 스타일 지정</label>
      <fieldset :disabled="!styleEnabled">
        <label>크기(pt)<input v-model.number="sectionStyle.size" type="number" min="8" max="48" /></label
        ><label>글자색<input v-model="sectionStyle.color" type="color" /></label
        ><label
          >굵기<select v-model="sectionStyle.bold">
            <option :value="true">굵게</option>
            <option :value="false">보통</option>
          </select></label
        ><label
          >밑줄<select v-model="sectionStyle.underline">
            <option :value="true">사용</option>
            <option :value="false">없음</option>
          </select></label
        >
      </fieldset>
      <div class="style-preview" :style="sectionStylePreview">
        {{ activeSection?.SEC_NO }} {{ activeSection?.TITLE || '미리보기' }}
      </div>
      <template #footer
        ><button class="secondary" type="button" @click="styleOpen = false">취소</button
        ><button type="button" :disabled="styleSaving" @click="saveStyle">
          {{ styleSaving ? '저장 중…' : '저장' }}
        </button></template
      ></AppDialog
    >
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
.manual-editor {
  min-width: 0;
}
.manual-editor-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--ex-space-4);
  margin-bottom: var(--ex-space-5);
}
.manual-editor-title {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--ex-space-3);
}
.manual-editor-title h1 {
  margin: 0;
  font-size: 1.125rem;
}
.manual-editor-header p {
  margin: 0.3rem 0 0;
  font-size: 0.8125rem;
}
.manual-editor-revision {
  border-radius: 999px;
  background: #f2f4f7;
  color: var(--ex-color-text-muted);
  padding: 0.15rem 0.45rem;
  font-size: 0.6875rem;
  font-weight: 700;
}
.manual-editor-header-actions,
.manual-section-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: flex-end;
  gap: var(--ex-space-2);
}
.manual-editor-header-actions > *,
.manual-section-actions > * {
  min-height: var(--ex-control-height);
  font-size: var(--ex-control-font-size);
}
.editor-save-state {
  min-width: 4.375rem;
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
  text-align: right;
}
.manual-editor-layout {
  display: grid;
  grid-template-columns: 16.25rem minmax(0, 1fr);
  align-items: start;
  gap: var(--ex-space-5);
}
.manual-outline {
  position: sticky;
  top: calc(4.5rem + var(--ex-space-4));
  display: grid;
  max-height: calc(100vh - 7.5rem);
  overflow: auto;
  border: 1px solid var(--ex-color-border);
  border-radius: var(--ex-radius-sm);
  background: var(--ex-color-surface);
  padding: var(--ex-space-3);
}
.manual-outline > header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--ex-space-2);
  margin-bottom: var(--ex-space-2);
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
  font-weight: 700;
}
.manual-outline-empty {
  margin: 0;
  padding: var(--ex-space-3);
  font-size: 0.75rem;
}
.manual-outline-item {
  display: flex;
  width: 100%;
  min-height: 2rem;
  align-items: center;
  gap: 0.375rem;
  overflow: hidden;
  border: 0;
  border-radius: var(--ex-radius-xs);
  background: transparent;
  color: var(--ex-color-text-muted);
  padding: 0.35rem 0.4rem;
  font-size: 0.75rem;
  text-align: left;
}
.manual-outline-item:hover {
  background: #f2f4f7;
  color: var(--ex-color-text);
  transform: none;
}
.manual-outline-item.active {
  background: var(--ex-color-primary-subtle);
  color: var(--ex-color-text);
  font-weight: 700;
}
.manual-outline-item.level-1 {
  font-weight: 700;
  color: var(--ex-color-text);
}
.manual-outline-item.level-2 {
  padding-left: 1.25rem;
}
.manual-outline-item.level-3 {
  padding-left: 2rem;
}
.manual-outline-item.pagebreak {
  color: var(--ex-color-text-muted);
  font-weight: 500;
}
.manual-outline-no {
  flex: 0 0 auto;
  color: var(--ex-color-text-subtle);
}
.manual-outline-title {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.manual-outline-count {
  display: inline-grid;
  min-width: 1.125rem;
  height: 1.125rem;
  flex: 0 0 auto;
  place-items: center;
  border-radius: 999px;
  background: #f2f4f7;
  color: var(--ex-color-text-muted);
  font-size: 0.625rem;
  font-weight: 650;
}
.manual-outline footer {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 0.25rem;
  margin-top: var(--ex-space-3);
  border-top: 1px solid var(--ex-color-border);
  padding-top: var(--ex-space-3);
}
.manual-outline footer button {
  padding: 0.25rem;
}
.manual-editor-content {
  min-width: 0;
}
.manual-editor-empty {
  display: grid;
  min-height: 7.5rem;
  place-content: center;
  gap: 0.5rem;
  border: 1px solid var(--ex-color-border);
  border-radius: var(--ex-radius-sm);
  background: var(--ex-color-surface);
  color: var(--ex-color-text-muted);
  padding: var(--ex-space-5);
  font-size: 0.8125rem;
  text-align: center;
  box-shadow: var(--ex-shadow);
}
.manual-editor-empty strong {
  color: var(--ex-color-text);
}
.manual-section-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--ex-space-4);
  margin-bottom: var(--ex-space-4);
}
.manual-section-header h2 {
  margin: 0;
}
.manual-section-header p {
  margin: 0.35rem 0 0;
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
}
.manual-section-header p .inline {
  margin-left: var(--ex-space-2);
  vertical-align: middle;
}
.manual-section-actions label {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #d4ebf7;
  border-radius: var(--ex-radius-sm);
  background: #e8f5fb;
  color: #287aab;
  padding: 0.375rem 0.75rem;
  font-weight: 650;
  cursor: pointer;
}
.manual-section-actions label.disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
.manual-section-actions label input {
  display: none;
}
.manual-spec-panel {
  margin-bottom: var(--ex-space-4);
  border: 1px solid var(--ex-color-border);
  border-radius: var(--ex-radius-sm);
  background: var(--ex-color-surface);
  padding: var(--ex-space-4);
}
.manual-spec-panel > header {
  display: flex;
  align-items: center;
  gap: var(--ex-space-3);
  margin-bottom: var(--ex-space-3);
}
.manual-spec-panel > header span {
  flex: 1;
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
}
.editor-block-card {
  margin-bottom: var(--ex-space-4);
  overflow: hidden;
  border: 1px solid var(--ex-color-border);
  border-radius: var(--ex-radius-sm);
  background: var(--ex-color-surface);
  box-shadow: var(--ex-shadow);
}
.editor-block-card > header {
  display: flex;
  min-height: 2.5rem;
  align-items: center;
  justify-content: space-between;
  gap: var(--ex-space-3);
  border-bottom: 1px solid var(--ex-color-border);
  background: #fcfcfd;
  padding: 0.375rem var(--ex-space-3);
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
}
.editor-block-card > header div {
  display: flex;
  gap: 0.25rem;
}
.editor-block-body {
  padding: var(--ex-space-4);
}
.editor-block-body .image-block {
  display: grid;
  gap: var(--ex-space-3);
}
.editor-block-body .image-block img {
  display: block;
  margin: 0 auto;
}
.table-actions {
  align-items: center;
}
.table-actions small {
  margin-left: auto;
  color: var(--ex-color-text-muted);
}
.table-scroll td:first-child {
  width: 3rem;
  text-align: center;
}
.table-scroll td:first-child small {
  display: block;
}
.table-scroll td:first-child button {
  margin-top: 0.25rem;
}
@media (max-width: 960px) {
  .manual-editor-layout {
    grid-template-columns: 1fr;
  }
  .manual-outline {
    position: static;
    max-height: 20rem;
  }
  .manual-editor-header,
  .manual-section-header {
    flex-direction: column;
  }
  .manual-editor-header-actions,
  .manual-section-actions {
    justify-content: flex-start;
  }
}
@media (max-width: 680px) {
  .manual-editor-header-actions,
  .manual-section-actions {
    width: 100%;
  }
  .manual-editor-header-actions > *,
  .manual-section-actions > * {
    flex: 1;
  }
  .editor-save-state {
    display: none;
  }
}
</style>
