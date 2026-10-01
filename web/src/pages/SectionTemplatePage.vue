<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { api, query } from '../api/client'
import AppDialog from '../design-system/AppDialog.vue'
import AppTable from '../design-system/AppTable.vue'
import ConfirmDialog from '../design-system/ConfirmDialog.vue'
import { useConfirmDialog } from '../design-system/useConfirmDialog'
import BlockEditor from '../features/editor/BlockEditor.vue'
import { useOrderMove } from '../features/admin/useOrderMove'

interface Template { TPL_ID: number; LABEL?: string; COOLING?: string; SEC_LEVEL: number; SEC_NO?: string; TITLE: string; IS_MANDATORY: string; ORDER_NUM: number; ASSIGNED_TEAM?: string; CONTENT_HTML?: string; TITLE_ALIGN: string; SEC_TYPE: string; SHOW_IN_TOC: string; TITLE_UNDERLINE: string }
type TemplateInput = Omit<Template, 'TPL_ID'> & { TPL_ID?: number }
const list = ref<Template[]>([]); const label = ref(''); const cooling = ref(''); const form = ref<TemplateInput | null>(null); const error = ref(''); const saving = ref(false)
const confirmation = useConfirmDialog()
const normalTemplates = computed(() => list.value.filter(item => item.SEC_TYPE !== 'PAGEBREAK'))
async function load() { try { list.value = (await api<{ list: Template[] }>(query('/api/admin/section-template/list', { label: label.value, cooling: cooling.value }))).list } catch (e) { error.value = e instanceof Error ? e.message : '목차 템플릿을 불러오지 못했습니다.' } }
const { ordering, move: moveOrder } = useOrderMove<Template>({ getId: item => item.TPL_ID, getOrder: item => item.ORDER_NUM, setOrder: (item, order) => { item.ORDER_NUM = order }, save: orders => api(query('/api/admin/section-template/order', { orders }), { method: 'POST' }), reload: load, setError: message => { error.value = message }, errorMessage: '순서를 저장하지 못했습니다.' })
function open(item?: Template) { error.value = ''; form.value = item ? { ...item } : { LABEL: label.value, COOLING: cooling.value, SEC_LEVEL: 1, SEC_NO: '', TITLE: '', IS_MANDATORY: 'Y', ORDER_NUM: list.value.length + 1, ASSIGNED_TEAM: '', CONTENT_HTML: '', TITLE_ALIGN: 'LEFT', SEC_TYPE: 'NORMAL', SHOW_IN_TOC: 'Y', TITLE_UNDERLINE: 'N' } }
async function save() { if (!form.value) return; if (form.value.SEC_TYPE === 'PAGEBREAK') form.value.TITLE = '페이지 나눔'; saving.value = true; try { await api('/api/admin/section-template', { method: 'POST', body: JSON.stringify(form.value) }); form.value = null; await load() } catch (e) { error.value = e instanceof Error ? e.message : '템플릿을 저장하지 못했습니다.' } finally { saving.value = false } }
function remove(item: Template) { confirmation.request({ title: '템플릿 삭제', message: `“${item.TITLE}” 항목을 삭제합니다.`, confirmLabel: '삭제', danger: true, action: async () => { try { await api(query('/api/admin/section-template', { tplId: item.TPL_ID }), { method: 'DELETE' }); await load() } catch (e) { error.value = e instanceof Error ? e.message : '템플릿을 삭제하지 못했습니다.' } } }) }
async function move(index: number, direction: -1 | 1) { await moveOrder(list.value, index, direction, reordered => { list.value = reordered }) }
onMounted(load)
</script>
<template>
  <section>
    <div class="page-title"><div><h1>목차 템플릿</h1><p>Label·Cooling 조합별 기본 목차를 관리합니다.</p></div><button @click="open()">템플릿 추가</button></div>
    <p v-if="error" class="error">{{ error }}</p>
    <div class="toolbar"><label>Label<select v-model="label" @change="load"><option value="">전체</option><option value="EXODUS">Exodus</option><option value="OEM">OEM</option></select></label><label>Cooling<select v-model="cooling" @change="load"><option value="">전체</option><option value="AIR">Air</option><option value="LIQUID">Liquid</option></select></label></div>
    <div class="admin-grid">
      <AppTable>
        <thead><tr><th>순서</th><th>범위</th><th>제목</th><th>담당 팀</th><th></th></tr></thead>
        <tbody>
          <tr v-for="(item, index) in list" :key="item.TPL_ID">
            <td>{{ index + 1 }}</td><td>{{ item.LABEL || '전체' }} · {{ item.COOLING || '전체' }}</td><td>{{ item.SEC_TYPE === 'PAGEBREAK' ? '페이지 나눔' : `${item.SEC_NO || ''} ${item.TITLE}` }}</td><td>{{ item.ASSIGNED_TEAM }}</td>
            <td class="row-actions"><button class="inline action-move" :disabled="ordering || index === 0" @click="move(index, -1)">↑</button><button class="inline action-move" :disabled="ordering || index === list.length - 1" @click="move(index, 1)">↓</button><button class="inline action-edit" @click="open(item)">수정</button><button class="inline danger" @click="remove(item)">삭제</button></td>
          </tr>
        </tbody>
      </AppTable>
    </div>
    <AppDialog :open="form !== null" :title="form?.TPL_ID ? '템플릿 수정' : '템플릿 추가'" wide @update:open="open => { if (!open) form = null }">
      <form v-if="form" id="section-template-form" @submit.prevent="save">
        <label>종류<select v-model="form.SEC_TYPE"><option value="NORMAL">일반 목차</option><option value="PAGEBREAK">페이지 나눔</option></select></label>
        <template v-if="form.SEC_TYPE !== 'PAGEBREAK'">
          <label>Label<select v-model="form.LABEL"><option value="">전체</option><option value="EXODUS">Exodus</option><option value="OEM">OEM</option></select></label><label>Cooling<select v-model="form.COOLING"><option value="">전체</option><option value="AIR">Air</option><option value="LIQUID">Liquid</option></select></label><label>단계<select v-model.number="form.SEC_LEVEL"><option :value="1">대제목</option><option :value="2">중제목</option><option :value="3">소제목</option></select></label><label>번호<input v-model="form.SEC_NO" /></label><label>제목<input v-model="form.TITLE" required /></label><label>담당 팀<input v-model="form.ASSIGNED_TEAM" /></label><label>제목 가로 정렬<select v-model="form.TITLE_ALIGN"><option value="LEFT">왼쪽</option><option value="CENTER">가운데</option><option value="RIGHT">오른쪽</option></select></label>
          <div class="editor-field"><span>본문</span><BlockEditor :model-value="form.CONTENT_HTML ?? ''" upload-url="/api/admin/section-template/image" @update:model-value="form.CONTENT_HTML = $event" /></div>
        </template>
      </form>
      <template #footer><button class="secondary" type="button" @click="form = null">취소</button><button form="section-template-form" type="submit" :disabled="saving">{{ saving ? '저장 중…' : '저장' }}</button></template>
    </AppDialog>
    <ConfirmDialog v-model:open="confirmation.open" :title="confirmation.title" :message="confirmation.message" :confirm-label="confirmation.confirmLabel" :danger="confirmation.danger" @confirm="confirmation.confirm" @cancel="confirmation.cancel" />
  </section>
</template>
