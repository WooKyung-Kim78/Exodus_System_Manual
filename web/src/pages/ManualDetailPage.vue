<script setup lang="ts">
import { computed, onMounted, ref, type CSSProperties } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, formData, query } from '../api/client'
import type { DatasheetOption, HeadingStyle, ManualHeader, ManualSection, NotifyRecipient } from '../api/types'
import AppDialog from '../design-system/AppDialog.vue'
import ConfirmDialog from '../design-system/ConfirmDialog.vue'
import { useConfirmDialog } from '../design-system/useConfirmDialog'
import { useSessionStore } from '../stores/session'

const route = useRoute()
const router = useRouter()
const session = useSessionStore()
const mid = computed(() => typeof route.query.mid === 'string' ? route.query.mid : '')
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
const notifyOpen = ref(false)
const notifyLoading = ref(false)
const notifySending = ref(false)
const notifyOnlyAssigned = ref(false)
const notifyMemo = ref('')
const notifyError = ref('')
const recipients = ref<NotifyRecipient[]>([])
const docStyleOpen = ref(false)
const docStyleSaving = ref(false)
const headingStyles = ref<Record<string, HeadingStyle>>({})
const bodyFont = ref('CARLITO')
const bodyLineHeight = ref(1.2)
const bodyLetterSpacing = ref(0)
const confirmation = useConfirmDialog()

const notifyTargets = computed(() => recipients.value.filter(item => Boolean(item.EMAIL_ADDRESS) && (!notifyOnlyAssigned.value || item.SECTION_CNT > 0)))
const headingPreview = computed<CSSProperties>(() => ({
  fontSize: (headingStyles.value['1']?.size ?? 13) + 'pt',
  color: headingStyles.value['1']?.color ?? '#3f4254',
  fontWeight: headingStyles.value['1']?.bold ? '700' : '400',
  textDecoration: headingStyles.value['1']?.underline ? 'underline' : 'none',
}))

function defaultHeadingStyles(): Record<string, HeadingStyle> {
  return Object.fromEntries(Object.entries(session.bootstrap?.headingStyles ?? {}).map(([level, style]) => [level, { ...style }]))
}
function parseHeadingStyles(value?: string): Record<string, HeadingStyle> {
  const styles = defaultHeadingStyles()
  try {
    const saved = value ? JSON.parse(value) as Record<string, Partial<HeadingStyle>> : null
    if (saved) Object.keys(styles).forEach(level => { styles[level] = { ...styles[level], ...saved[level] } })
  } catch { /* Keep server-provided defaults for malformed legacy data. */ }
  return styles
}
async function load() {
  if (!mid.value) return
  loading.value = true; error.value = ''
  try {
    const data = await api<{ header: ManualHeader; sections: ManualSection[]; access: { CAN_EDIT: string } }>(query('/api/manual/find', { mid: mid.value }))
    header.value = data.header; sections.value = data.sections; form.value = { ...data.header }; canEdit.value = data.access.CAN_EDIT === 'Y'
  } catch (cause) { error.value = cause instanceof Error ? cause.message : '문서를 불러오지 못했습니다.' } finally { loading.value = false }
}
async function loadDatasheets() { try { datasheets.value = (await api<{ list: DatasheetOption[] }>('/api/manual/datasheets')).list } catch { datasheets.value = [] } }
async function create() {
  try {
    const data = await api<{ M_ID: string }>('/api/manual/create', { method: 'POST', body: JSON.stringify({ MODEL_NAME: '새 문서', PAGE_SIZE: 'LETTER' }) })
    await router.replace({ path: '/manual/detail', query: { mid: data.M_ID } }); await load()
  } catch (cause) { error.value = cause instanceof Error ? cause.message : '문서를 만들지 못했습니다.' }
}
function pickDatasheet() { if (form.value) form.value.JOB_NUMBER = datasheets.value.find(item => item.D_ID === form.value?.PROCESS_ID)?.NAME }
async function save() {
  if (!form.value) return
  saving.value = true
  try { await api('/api/manual/header', { method: 'POST', body: JSON.stringify({ ...form.value, M_ID: mid.value }) }); await load() }
  catch (cause) { error.value = cause instanceof Error ? cause.message : '문서를 저장하지 못했습니다.' } finally { saving.value = false }
}
function remove() { confirmation.request({ title: '삭제 확인', message: '이 문서를 삭제합니다.', confirmLabel: '삭제', danger: true, action: async () => { try { await api(query('/api/manual/delete', { mid: mid.value }), { method: 'DELETE' }); await router.push('/manual') } catch (cause) { error.value = cause instanceof Error ? cause.message : '문서를 삭제하지 못했습니다.' } } }) }
async function uploadCover(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  coverUploading.value = true
  try {
    const data = new FormData(); data.append('mid', mid.value); data.append('file', file)
    const result = await api<{ path: string }>('/api/manual/cover', { method: 'POST', body: data })
    if (header.value) header.value.COVER_IMAGE_PATH = result.path
  } catch (cause) { error.value = cause instanceof Error ? cause.message : '표지 이미지를 등록하지 못했습니다.' }
  finally { coverUploading.value = false; (event.target as HTMLInputElement).value = '' }
}
function deleteCover() { confirmation.request({ title: '표지 이미지 제거', message: '표지 이미지를 제거합니다.', confirmLabel: '제거', danger: true, action: async () => { try { await api(query('/api/manual/cover', { mid: mid.value }), { method: 'DELETE' }); if (header.value) header.value.COVER_IMAGE_PATH = undefined } catch (cause) { error.value = cause instanceof Error ? cause.message : '표지 이미지를 제거하지 못했습니다.' } } }) }
async function openSpec() {
  specOpen.value = true; specLoading.value = true; specHtml.value = ''; specMessage.value = ''
  try { const data = await api<{ html?: string; message: string }>(query('/api/manual/spec', { mid: mid.value })); specHtml.value = data.html ?? ''; specMessage.value = data.message }
  catch (cause) { specMessage.value = cause instanceof Error ? cause.message : '사양을 불러오지 못했습니다.' } finally { specLoading.value = false }
}
async function openNotify() {
  notifyOpen.value = true; notifyLoading.value = true; notifyError.value = ''; notifyMemo.value = ''; notifyOnlyAssigned.value = false
  try { recipients.value = (await api<{ list: NotifyRecipient[] }>(query('/api/manual/notify/recipients', { mid: mid.value }))).list }
  catch (cause) { notifyError.value = cause instanceof Error ? cause.message : '수신자를 불러오지 못했습니다.' } finally { notifyLoading.value = false }
}
async function sendNotify() {
  notifySending.value = true; notifyError.value = ''
  try { await api('/api/manual/notify', { method: 'POST', body: formData({ mid: mid.value, memo: notifyMemo.value, onlyAssigned: notifyOnlyAssigned.value ? 'Y' : 'N' }) }); notifyOpen.value = false }
  catch (cause) { notifyError.value = cause instanceof Error ? cause.message : '작성 요청을 보내지 못했습니다.' } finally { notifySending.value = false }
}
function openDocStyle() {
  if (!header.value) return
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
    await api('/api/editor/heading-style', { method: 'POST', body: formData({ mid: mid.value, style: JSON.stringify(headingStyles.value), bodyFont: bodyFont.value, lineHeight: bodyLineHeight.value, letterSpacing: bodyLetterSpacing.value }) })
    docStyleOpen.value = false; await load()
  } catch (cause) { error.value = cause instanceof Error ? cause.message : '문서 스타일을 저장하지 못했습니다.' } finally { docStyleSaving.value = false }
}
onMounted(async () => { await Promise.all([load(), loadDatasheets()]) })
</script>

<template>
  <section>
    <div class="page-title"><div><h1>{{ header?.MODEL_NAME ?? '새 문서' }}</h1><p v-if="header">{{ header.DOC_NUM }} · Rev {{ header.REVISION }} · {{ header.STATUS }}</p></div><div v-if="mid" class="actions"><RouterLink class="button secondary" :to="{ path: '/manual/preview', query: { mid } }">미리보기</RouterLink><RouterLink class="button" :to="{ path: '/editor', query: { mid } }">편집기</RouterLink></div></div>
    <p v-if="error" class="error">{{ error }}</p>
    <div v-else-if="!mid" class="empty"><p>새 문서를 생성합니다.</p><button @click="create">문서 생성</button></div>
    <div v-else-if="loading">불러오는 중…</div>
    <template v-else-if="header && form">
      <p v-if="!canEdit" class="readonly-notice">읽기 전용입니다. 수정 기능은 사용할 수 없습니다.</p>
      <form class="panel detail-form" @submit.prevent="save">
        <label>Model Name<input v-model="form.MODEL_NAME" :readonly="!canEdit" required /></label>
        <label>Datasheet<select v-model="form.PROCESS_ID" :disabled="!canEdit || datasheets.length === 0" @change="pickDatasheet"><option value="">선택 안 함</option><option v-for="item in datasheets" :key="item.D_ID" :value="item.D_ID">{{ item.NAME }}{{ item.DS_VERSION ? ' · ' + item.DS_VERSION : '' }}</option></select></label>
        <label>Job Number<input v-model="form.JOB_NUMBER" :readonly="!canEdit" /></label><label>Version<input v-model="form.DOC_VERSION" :readonly="!canEdit" /></label>
        <label>Label<select v-model="form.LABEL" :disabled="!canEdit"><option value="">없음</option><option value="EXODUS">Exodus</option><option value="OEM">OEM</option></select></label><label>Cooling<select v-model="form.COOLING" :disabled="!canEdit"><option value="">없음</option><option value="AIR">Air</option><option value="LIQUID">Liquid</option></select></label>
        <label>Page Size<select v-model="form.PAGE_SIZE" :disabled="!canEdit"><option value="LETTER">Letter</option><option value="A4">A4</option></select></label><label>Option<input v-model="form.OPTION_TEXT" :readonly="!canEdit" /></label>
        <div v-if="canEdit" class="actions"><button :disabled="saving">{{ saving ? '저장 중…' : '저장' }}</button><button class="danger" type="button" @click="remove">삭제</button></div>
      </form>
      <section class="panel document-tools"><h2>문서 도구</h2><div class="actions"><button class="secondary" type="button" @click="openSpec">사양 확인</button><button class="secondary" type="button" :disabled="!canEdit" @click="openDocStyle">문서 스타일</button><button class="secondary" type="button" :disabled="!canEdit" @click="openNotify">작성 요청 보내기</button></div><div class="cover-tools"><img v-if="header.COVER_IMAGE_PATH" :src="header.COVER_IMAGE_PATH" alt="표지 이미지" /><p v-else>등록된 표지 이미지가 없습니다.</p><label v-if="canEdit" class="button"><input type="file" accept="image/png,image/jpeg,image/gif,image/webp" :disabled="coverUploading" @change="uploadCover" />{{ coverUploading ? '업로드 중…' : '표지 이미지 등록' }}</label><button v-if="canEdit && header.COVER_IMAGE_PATH" class="danger" type="button" @click="deleteCover">표지 이미지 제거</button></div></section>
      <h2>목차</h2><ol class="sections"><li v-for="section in sections" :key="section.SEC_ID" :style="{ marginLeft: ((section.SEC_LEVEL - 1) * 1.5) + 'rem' }">{{ section.SEC_NO }} {{ section.TITLE }} <small>{{ section.ASSIGNED_TEAM }}</small></li></ol>
    </template>
    <AppDialog v-model:open="specOpen" title="SPECIFICATIONS"><p v-if="specLoading">불러오는 중…</p><template v-else><p>{{ specMessage }}</p><div v-if="specHtml" class="datasheet-spec" v-html="specHtml" /></template></AppDialog>
    <AppDialog v-model:open="notifyOpen" title="작성 요청 보내기"><p v-if="notifyLoading">수신자를 불러오는 중…</p><template v-else><p v-if="notifyError" class="error">{{ notifyError }}</p><label class="check-label"><input v-model="notifyOnlyAssigned" type="checkbox" /> 담당 목차가 있는 사용자에게만 보내기</label><label>메모<textarea v-model="notifyMemo" rows="4" /></label><ul class="recipient-list"><li v-for="recipient in notifyTargets" :key="recipient.USER_ID">{{ recipient.FULL_NAME }} · {{ recipient.EMAIL_ADDRESS }} <small>{{ recipient.ASSIGNED_SECTIONS || '-' }}</small></li></ul><p v-if="notifyTargets.length === 0">보낼 수신자가 없습니다.</p></template><template #footer><button class="secondary" type="button" @click="notifyOpen = false">취소</button><button type="button" :disabled="notifyLoading || notifySending || notifyTargets.length === 0" @click="sendNotify">{{ notifySending ? '보내는 중…' : notifyTargets.length + '명에게 보내기' }}</button></template></AppDialog>
    <AppDialog v-model:open="docStyleOpen" title="문서 공통 스타일">
      <p>모든 제목 단계의 기본 모양과 본문 서식을 설정합니다. 목차에서 개별 지정한 스타일은 이 설정보다 우선합니다.</p>
      <div class="doc-style-grid"><label>본문 글꼴<select v-model="bodyFont"><option v-for="font in session.bootstrap?.bodyFonts ?? []" :key="font.code" :value="font.code">{{ font.name }}</option></select></label><label>줄 간격<input v-model.number="bodyLineHeight" type="number" min="1" max="3" step="0.1" /></label><label>자간(px)<input v-model.number="bodyLetterSpacing" type="number" min="-1" max="3" step="0.1" /></label></div>
      <fieldset v-for="level in ['1', '2', '3']" :key="level" class="heading-style-fieldset"><legend>{{ level === '1' ? '대제목' : level === '2' ? '중제목' : '소제목' }}</legend><div class="doc-style-grid"><label>크기(pt)<input v-model.number="headingStyles[level].size" type="number" min="8" max="48" /></label><label>글자색<input v-model="headingStyles[level].color" type="color" /></label><label>굵기<select v-model="headingStyles[level].bold"><option :value="true">굵게</option><option :value="false">보통</option></select></label><label>밑줄<select v-model="headingStyles[level].underline"><option :value="true">사용</option><option :value="false">없음</option></select></label></div></fieldset>
      <div class="style-preview" :style="headingPreview">1. 문서 제목 미리보기</div>
      <template #footer><button class="secondary" type="button" @click="docStyleOpen = false">취소</button><button type="button" :disabled="docStyleSaving" @click="saveDocStyle">{{ docStyleSaving ? '저장 중…' : '저장' }}</button></template>
    </AppDialog>
    <ConfirmDialog v-model:open="confirmation.open" :title="confirmation.title" :message="confirmation.message" :confirm-label="confirmation.confirmLabel" :danger="confirmation.danger" @confirm="confirmation.confirm" @cancel="confirmation.cancel" />
  </section>
</template>
