<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { api, query } from '../api/client'
import type { DatasheetOption, ManualListItem } from '../api/types'
import DatasheetSelect from '../features/manual/DatasheetSelect.vue'
import AppBadge from '../design-system/AppBadge.vue'
import AppDialog from '../design-system/AppDialog.vue'
import AppTable from '../design-system/AppTable.vue'
import EmptyState from '../design-system/EmptyState.vue'
import ListCard from '../design-system/ListCard.vue'
import ListSearch from '../design-system/ListSearch.vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'
const list = ref<ManualListItem[]>([])
const loading = ref(true)
const error = ref('')
const status = ref('')
const onlyMine = ref(false)
const keyword = ref('')
const appliedKeyword = ref('')
const session = useSessionStore()
const router = useRouter()
const newOpen = ref(false)
const newSaving = ref(false)
const newError = ref('')
const datasheets = ref<DatasheetOption[]>([])
const newManual = ref({
  MODEL_NAME: '',
  JOB_NUMBER: '',
  PROCESS_ID: '',
  LABEL: '',
  COOLING: '',
  OPTION_TEXT: '',
  DOC_VERSION: '1.0',
  PAGE_SIZE: 'LETTER',
})
async function load() {
  loading.value = true
  error.value = ''
  try {
    list.value = (
      await api<{ list: ManualListItem[] }>(
        query('/api/manual/list', { status: status.value, onlyMine: onlyMine.value ? 'Y' : undefined }),
      )
    ).list
  } catch (e) {
    error.value = e instanceof Error ? e.message : '목록을 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
}
const filteredList = computed(() => {
  const search = appliedKeyword.value.trim().toLowerCase()
  if (!search) return list.value
  return list.value.filter((item) =>
    [item.DOC_NUM, item.MODEL_NAME, item.JOB_NUMBER, item.OPTION_TEXT, item.REQUESTER_NAME].some((value) =>
      value?.toLowerCase().includes(search),
    ),
  )
})
function search() {
  appliedKeyword.value = keyword.value
}
async function openNew() {
  newError.value = ''
  newManual.value = {
    MODEL_NAME: '',
    JOB_NUMBER: '',
    PROCESS_ID: '',
    LABEL: '',
    COOLING: '',
    OPTION_TEXT: '',
    DOC_VERSION: '1.0',
    PAGE_SIZE: 'LETTER',
  }
  newOpen.value = true
  try {
    datasheets.value = (await api<{ list: DatasheetOption[] }>('/api/manual/datasheets')).list
  } catch {
    datasheets.value = []
  }
}
function pickDatasheet(item: DatasheetOption | null) {
  newManual.value.PROCESS_ID = item?.D_ID ?? ''
}
async function create() {
  if (!newManual.value.MODEL_NAME.trim()) {
    newError.value = 'Model Name 은 필수입니다.'
    return
  }
  newSaving.value = true
  newError.value = ''
  try {
    const data = await api<{ M_ID: string }>('/api/manual/create', {
      method: 'POST',
      body: JSON.stringify(newManual.value),
    })
    newOpen.value = false
    await router.push({ path: '/manual/detail', query: { mid: data.M_ID } })
  } catch (e) {
    newError.value = e instanceof Error ? e.message : '문서를 만들지 못했습니다.'
  } finally {
    newSaving.value = false
  }
}
function openDetail(mid: string) {
  router.push({ path: '/manual/detail', query: { mid } })
}
function formatDate(value: string) {
  return value
    ? new Intl.DateTimeFormat('ko-KR', { year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(value))
    : '-'
}
onMounted(load)
</script>
<template>
  <section>
    <ListCard title="System Manual List"
      ><template #header-actions
        ><button v-if="session.user?.CAPABILITIES.CAN_CREATE_MANUAL" class="button" @click="openNew">
          New Manual
        </button></template
      ><template #filters
        ><div class="manual-list-filters">
          <select v-model="status" aria-label="상태 필터" @change="load">
            <option value="">전체 상태</option>
            <option value="DRAFT">DRAFT</option>
            <option value="REVIEW">REVIEW</option>
            <option value="APPROVED">APPROVED</option>
            <option value="PUBLISHED">PUBLISHED</option>
            <option value="OBSOLETE">OBSOLETE</option></select
          ><label class="check-label"><input v-model="onlyMine" type="checkbox" @change="load" /> 내 문서만</label>
        </div></template
      ><template #search
        ><ListSearch
          style="min-width: 250px"
          v-model="keyword"
          label="매뉴얼 검색"
          placeholder="문서 번호, 모델명, Job Number 검색"
          @search="search"
      /></template>
      <p v-if="error" class="error">{{ error }}</p>
      <p v-else-if="loading">불러오는 중…</p>
      <EmptyState
        v-else-if="filteredList.length === 0"
        title="표시할 문서가 없습니다"
        description="필터 또는 검색어를 바꿔 보세요."
      /><AppTable v-else
        ><thead>
          <tr>
            <th>Doc No.</th>
            <th>Model Name</th>
            <th>Job Number</th>
            <th>상태</th>
            <th>Option</th>
            <th>Requester</th>
            <th>등록일</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="item in filteredList"
            :key="item.M_ID"
            class="clickable-row"
            tabindex="0"
            @click="openDetail(item.M_ID)"
            @keydown.enter="openDetail(item.M_ID)"
            @keydown.space.prevent="openDetail(item.M_ID)"
          >
            <td>{{ item.DOC_NUM }}</td>
            <td>
              {{ item.MODEL_NAME }}<span v-if="item.MY_ROLE" class="manual-role-badge">{{ item.MY_ROLE }}</span>
            </td>
            <td>{{ item.JOB_NUMBER }}</td>
            <td><AppBadge :status="item.STATUS" /></td>
            <td>{{ item.OPTION_TEXT }}</td>
            <td>{{ item.REQUESTER_NAME }}</td>
            <td>{{ formatDate(item.REG_DT) }}</td>
          </tr>
        </tbody></AppTable
      ></ListCard
    ><AppDialog v-model:open="newOpen" title="New System Manual">
      <p v-if="newError" class="error">{{ newError }}</p>
      <label
        ><span class="field-label">Model Name<strong>*</strong></span
        ><input v-model.trim="newManual.MODEL_NAME" maxlength="100" required
      /></label>
      <label
        >Job Number<DatasheetSelect
          v-model="newManual.JOB_NUMBER"
          :options="datasheets"
          @select="pickDatasheet"
        /><small>Datasheet 를 고르면 SPECIFICATIONS 목차에 사양이 자동으로 보입니다.</small></label
      >
      <label
        >Label<select v-model="newManual.LABEL">
          <option value="">선택 안 함</option>
          <option value="EXODUS">Exodus</option>
          <option value="OEM">OEM</option>
        </select></label
      >
      <label
        >Cooling<select v-model="newManual.COOLING">
          <option value="">선택 안 함</option>
          <option value="AIR">Air</option>
          <option value="LIQUID">Liquid</option></select
        ><small>Label·Cooling 에 맞는 필수 목차가 자동으로 들어갑니다.</small></label
      >
      <label>Option<textarea v-model.trim="newManual.OPTION_TEXT" maxlength="500" /></label>
      <label
        >Version<input v-model.trim="newManual.DOC_VERSION" maxlength="20" placeholder="1.0" /><small
          >PDF 아래쪽에 "1 | Page - Ver. 1.0" 형식으로 찍힙니다.</small
        ></label
      >
      <label
        >Page Size<select v-model="newManual.PAGE_SIZE">
          <option value="LETTER">Letter (216 x 279mm)</option>
          <option value="A4">A4 (210 x 297mm)</option>
        </select></label
      >
      <template #footer
        ><button class="secondary" type="button" @click="newOpen = false">취소</button
        ><button type="button" :disabled="newSaving" @click="create">
          {{ newSaving ? '생성 중…' : '생성' }}
        </button></template
      >
    </AppDialog>
  </section>
</template>
