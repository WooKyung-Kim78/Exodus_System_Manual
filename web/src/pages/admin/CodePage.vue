<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { api, query } from '../../api/client'
import AppDialog from '../../design-system/AppDialog.vue'
import AppTable from '../../design-system/AppTable.vue'
import ListCard from '../../design-system/ListCard.vue'
import ConfirmDialog from '../../design-system/ConfirmDialog.vue'
import { useConfirmDialog } from '../../design-system/useConfirmDialog'
import { useOrderMove } from '../../features/admin/useOrderMove'
interface Code {
  IDX: number
  CATEGORY: string
  CODE: string
  NAME: string
  ORDER_NUM: number
}
const all = ref<Code[]>([])
const category = ref('')
const form = ref<Partial<Code> | null>(null)
const error = ref('')
const formError = ref('')
const saving = ref(false)
const uploading = ref(false)
const confirmation = useConfirmDialog()
const categories = computed(() => [...new Set(all.value.map((item) => item.CATEGORY))].sort())
const list = computed(() =>
  (category.value ? all.value.filter((item) => item.CATEGORY === category.value) : all.value)
    .slice()
    .sort(
      (left, right) =>
        left.CATEGORY.localeCompare(right.CATEGORY) || left.ORDER_NUM - right.ORDER_NUM || left.IDX - right.IDX,
    ),
)
const logoPath = computed(() => all.value.find((item) => item.CATEGORY === 'COVER' && item.CODE === 'LOGO_PATH')?.NAME)
async function load() {
  error.value = ''
  try {
    all.value = (await api<{ list: Code[] }>('/api/admin/code/list')).list
  } catch (e) {
    error.value = e instanceof Error ? e.message : '코드를 불러오지 못했습니다.'
  }
}
const { ordering, move: moveOrder } = useOrderMove<Code>({
  getId: (item) => item.IDX,
  getOrder: (item) => item.ORDER_NUM,
  setOrder: (item, order) => {
    item.ORDER_NUM = order
  },
  save: (orders) => api(query('/api/admin/code/order', { orders }), { method: 'POST' }),
  reload: load,
  setError: (message) => {
    error.value = message
  },
  errorMessage: '순서를 저장하지 못했습니다.',
})
function open(item?: Code) {
  formError.value = ''
  form.value = item ? { ...item } : { CATEGORY: category.value, CODE: '', NAME: '', ORDER_NUM: 0 }
}
function closeForm() {
  form.value = null
}
async function save() {
  if (!form.value) return
  if (!form.value.CATEGORY || !form.value.CODE) {
    formError.value = '분류와 코드는 필수입니다.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    await api('/api/admin/code', { method: 'POST', body: JSON.stringify(form.value) })
    closeForm()
    await load()
  } catch (e) {
    formError.value = e instanceof Error ? e.message : '저장하지 못했습니다.'
  } finally {
    saving.value = false
  }
}
async function move(item: Code, direction: -1 | 1) {
  const codes = all.value
    .filter((code) => code.CATEGORY === item.CATEGORY)
    .sort((left, right) => left.ORDER_NUM - right.ORDER_NUM || left.IDX - right.IDX)
  const index = codes.findIndex((code) => code.IDX === item.IDX)
  await moveOrder(codes, index, direction, () => {
    all.value = [...all.value]
  })
}
function remove(item: Code) {
  confirmation.request({
    title: '코드 삭제',
    message: `${item.CATEGORY} / ${item.CODE} 코드를 삭제합니다.`,
    confirmLabel: '삭제',
    danger: true,
    action: async () => {
      try {
        await api(query('/api/admin/code', { idx: item.IDX }), { method: 'DELETE' })
        await load()
      } catch (e) {
        error.value = e instanceof Error ? e.message : '삭제하지 못했습니다.'
      }
    },
  })
}
async function upload(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  uploading.value = true
  try {
    const data = new FormData()
    data.append('file', file)
    await api('/api/admin/code/logo', { method: 'POST', body: data })
    await load()
  } catch (e) {
    error.value = e instanceof Error ? e.message : '로고를 등록하지 못했습니다.'
  } finally {
    uploading.value = false
  }
}
onMounted(load)
</script>
<template>
  <section>
    <p v-if="error" class="error">{{ error }}</p>
    <div class="code-settings-grid">
      <section class="panel admin-card cover-logo-card">
        <header class="admin-card-header"><h2>표지 로고</h2></header>
        <div class="admin-card-content">
          <div class="cover-logo-preview">
            <img v-if="logoPath" :src="logoPath" alt="현재 표지 로고" /><span v-else>등록된 로고가 없습니다.</span>
          </div>
          <label class="code-logo-upload"
            >{{ uploading ? '업로드 중…' : '로고 이미지 업로드'
            }}<input
              type="file"
              accept="image/png,image/jpeg,image/gif,image/webp"
              :disabled="uploading"
              @change="upload"
          /></label>
          <p class="code-logo-help">png · jpg · gif · webp. 가로가 긴 이미지가 표지에 잘 맞습니다.</p>
        </div>
      </section>
      <ListCard class="code-list-card" title="코드 목록">
        <template #header-actions><button @click="open()">코드 추가</button></template>
        <template #filters
          ><select v-model="category" aria-label="분류 필터">
            <option value="">전체 분류</option>
            <option v-for="item in categories" :key="item">{{ item }}</option>
          </select></template
        >
        <AppTable>
          <thead>
            <tr>
              <th>분류</th>
              <th>코드</th>
              <th>값</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, index) in list" :key="item.IDX">
              <td>{{ item.CATEGORY }}</td>
              <td>{{ item.CODE }}</td>
              <td>{{ item.NAME }}</td>
              <td class="row-actions">
                <button
                  class="inline action-move"
                  :disabled="ordering || index === 0 || list[index - 1]?.CATEGORY !== item.CATEGORY"
                  @click="move(item, -1)"
                >
                  ↑</button
                ><button
                  class="inline action-move"
                  :disabled="ordering || index === list.length - 1 || list[index + 1]?.CATEGORY !== item.CATEGORY"
                  @click="move(item, 1)"
                >
                  ↓</button
                ><button class="inline action-edit" @click="open(item)">수정</button
                ><button class="inline danger" @click="remove(item)">삭제</button>
              </td>
            </tr>
          </tbody>
        </AppTable>
      </ListCard>
    </div>
    <AppDialog
      :open="form !== null"
      :title="form?.IDX ? '코드 수정' : '코드 추가'"
      @update:open="
        (open) => {
          if (!open) closeForm()
        }
      "
    >
      <form v-if="form" id="code-form" class="code-form" @submit.prevent="save">
        <p v-if="formError" class="error">{{ formError }}</p>
        <div class="code-form-grid">
          <label
            ><span class="field-label">분류<strong>*</strong></span
            ><input
              v-model.trim="form.CATEGORY"
              :disabled="Boolean(form.IDX)"
              maxlength="50"
              placeholder="COVER"
              required
          /></label>
          <label
            ><span class="field-label">코드<strong>*</strong></span
            ><input
              v-model.trim="form.CODE"
              :disabled="Boolean(form.IDX)"
              maxlength="50"
              placeholder="TITLE_LINE1"
              required
          /></label>
          <label class="code-form-full">값<input v-model="form.NAME" maxlength="200" /></label>
          <label class="code-form-full"
            >정렬 순서<input v-model.number="form.ORDER_NUM" type="number" min="0" max="999"
          /></label>
        </div>
      </form>
      <template #footer
        ><button class="secondary" type="button" @click="closeForm">취소</button
        ><button form="code-form" type="submit" :disabled="saving">{{ saving ? '저장 중…' : '저장' }}</button></template
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
.code-form {
  display: grid;
  gap: var(--ex-space-4);
}
.code-form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--ex-space-4);
}
.code-form-grid > label {
  margin: 0;
}
.code-form-grid > .code-form-full {
  grid-column: 1 / -1;
}
@media (max-width: 680px) {
  .code-form-grid {
    grid-template-columns: 1fr;
  }
  .code-form-grid > .code-form-full {
    grid-column: 1;
  }
}
</style>
