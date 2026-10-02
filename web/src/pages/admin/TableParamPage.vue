<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { api, query } from '../../api/client'
import AppDialog from '../../design-system/AppDialog.vue'
import AppTable from '../../design-system/AppTable.vue'
import ConfirmDialog from '../../design-system/ConfirmDialog.vue'
import ListCard from '../../design-system/ListCard.vue'
import { useConfirmDialog } from '../../design-system/useConfirmDialog'
import BlockEditor from '../../features/editor/BlockEditor.vue'

interface TableParam {
  IDX: number
  TITLE: string
  FUNC_HTML: string
  ORDER_NUM: number
}

const list = ref<TableParam[]>([])
const form = ref<Partial<TableParam> | null>(null)
const error = ref('')
const formError = ref('')
const saving = ref(false)
const confirmation = useConfirmDialog()

async function load() {
  error.value = ''
  try {
    list.value = (await api<{ list: TableParam[] }>('/api/admin/table-param/list')).list
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '표 기본값을 불러오지 못했습니다.'
  }
}
function open(item?: TableParam) {
  formError.value = ''
  form.value = item ? { ...item } : { TITLE: '', FUNC_HTML: '', ORDER_NUM: 0 }
}
function close() {
  form.value = null
}
async function save() {
  if (!form.value) return
  if (!form.value.TITLE?.trim() || !form.value.FUNC_HTML?.trim()) {
    formError.value = 'Title과 Function은 필수입니다.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    await api('/api/admin/table-param', { method: 'POST', body: JSON.stringify(form.value) })
    close()
    await load()
  } catch (cause) {
    formError.value = cause instanceof Error ? cause.message : '저장하지 못했습니다.'
  } finally {
    saving.value = false
  }
}
function text(html: string) {
  const element = document.createElement('div')
  element.innerHTML = html
  return element.textContent?.trim() || '내용 없음'
}
function remove(item: TableParam) {
  confirmation.request({
    title: '표 기본값 삭제',
    message: `“${item.TITLE}” 기본값을 삭제합니다. 이미 문서에 저장된 표는 바뀌지 않습니다.`,
    confirmLabel: '삭제',
    danger: true,
    action: async () => {
      try {
        await api(query('/api/admin/table-param', { idx: item.IDX }), { method: 'DELETE' })
        await load()
      } catch (cause) {
        error.value = cause instanceof Error ? cause.message : '삭제하지 못했습니다.'
      }
    },
  })
}
onMounted(load)
</script>

<template>
  <section>
    <p v-if="error" class="error">{{ error }}</p>
    <ListCard title="표 Title / Function 기본값">
      <template #header-actions><button @click="open()">기본값 추가</button></template>
      <p class="table-param-help">
        편집기 표의 Title을 선택하면 같은 Title에서 순서가 가장 빠른 Function이 자동 입력됩니다.
      </p>
      <AppTable>
        <thead>
          <tr>
            <th>Title</th>
            <th>Function</th>
            <th>순서</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in list" :key="item.IDX">
            <td>{{ item.TITLE }}</td>
            <td>{{ text(item.FUNC_HTML) }}</td>
            <td>{{ item.ORDER_NUM }}</td>
            <td class="row-actions">
              <button class="inline action-edit" @click="open(item)">수정</button
              ><button class="inline danger" @click="remove(item)">삭제</button>
            </td>
          </tr>
          <tr v-if="list.length === 0">
            <td colspan="4" class="empty-cell">등록된 기본값이 없습니다.</td>
          </tr>
        </tbody>
      </AppTable>
    </ListCard>
    <AppDialog
      :open="form !== null"
      :title="form?.IDX ? '표 기본값 수정' : '표 기본값 추가'"
      @update:open="
        (open) => {
          if (!open) close()
        }
      "
    >
      <form v-if="form" id="table-param-form" class="table-param-form" @submit.prevent="save">
        <p v-if="formError" class="error">{{ formError }}</p>
        <label>Title<input v-model.trim="form.TITLE" maxlength="200" required /></label>
        <label>정렬 순서<input v-model.number="form.ORDER_NUM" type="number" min="0" max="999" /></label>
        <label>Function<small>서식 있는 문구를 입력할 수 있습니다.</small></label>
        <BlockEditor :model-value="form.FUNC_HTML ?? ''" compact @update:model-value="form.FUNC_HTML = $event" />
      </form>
      <template #footer
        ><button class="secondary" type="button" @click="close">취소</button
        ><button form="table-param-form" type="submit" :disabled="saving">
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
.table-param-help {
  margin: 0 0 var(--ex-space-4);
  color: var(--ex-color-text-muted);
}
.table-param-form {
  display: grid;
  gap: var(--ex-space-3);
}
.table-param-form > label {
  display: grid;
  gap: 0.35rem;
}
.table-param-form small {
  color: var(--ex-color-text-muted);
  font-weight: normal;
}
.empty-cell {
  padding: var(--ex-space-5);
  color: var(--ex-color-text-muted);
  text-align: center;
}
</style>
