<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { api, query } from '../../api/client'
import AppBadge from '../../design-system/AppBadge.vue'
import AppDialog from '../../design-system/AppDialog.vue'
import AppTable from '../../design-system/AppTable.vue'
import ListCard from '../../design-system/ListCard.vue'
import ListSearch from '../../design-system/ListSearch.vue'
import ConfirmDialog from '../../design-system/ConfirmDialog.vue'
import { useConfirmDialog } from '../../design-system/useConfirmDialog'

interface User {
  USER_ID: string
  FULL_NAME: string
  EMAIL?: string
  DIVISION?: string
  TEAM?: string
  SUPERVISOR_USER_ID?: string | null
  SUPERVISOR_NAME?: string
  ROLE_NAME: string
  AUTHORIZED: string
  IS_DELETED: string
}

type UserInput = Pick<
  User,
  'USER_ID' | 'FULL_NAME' | 'EMAIL' | 'DIVISION' | 'TEAM' | 'SUPERVISOR_USER_ID' | 'ROLE_NAME' | 'AUTHORIZED'
> & { N_PASSWORD?: string }
type PasswordInput = { USER_ID: string; FULL_NAME: string; N_PASSWORD: string; C_PASSWORD: string }

const roleLabels: Record<string, string> = { ADMIN: '관리자', USER: '유저', READER: '읽기전용', SUPPORTER: '서포터' }
const users = ref<User[]>([])
const lookupUsers = ref<User[]>([])
const keyword = ref('')
const view = ref('USE')
const form = ref<UserInput | null>(null)
const isNew = ref(false)
const passwordForm = ref<PasswordInput | null>(null)
const error = ref('')
const formError = ref('')
const passwordError = ref('')
const saving = ref(false)
const passwordSaving = ref(false)
const confirmation = useConfirmDialog()

const divisions = computed(() => distinct(lookupUsers.value.map((user) => user.DIVISION)))
const teams = computed(() => distinct(lookupUsers.value.map((user) => user.TEAM)))
const supervisors = computed(() => lookupUsers.value.filter((user) => user.USER_ID !== form.value?.USER_ID))

function distinct(values: Array<string | undefined>) {
  return [...new Set(values.filter((value): value is string => Boolean(value)))].sort()
}
function roleLabel(role: string) {
  return roleLabels[role] ?? role
}
function accountStatus(user: User) {
  if (user.IS_DELETED === 'Y') return { label: '삭제됨', tone: 'danger' as const }
  return user.AUTHORIZED === 'Y'
    ? { label: '승인', tone: 'success' as const }
    : { label: '미승인', tone: 'warning' as const }
}

async function load() {
  try {
    const data = await api<{ list: User[] }>(
      query('/api/admin/user/list', { keyword: keyword.value, view: view.value }),
    )
    users.value = data.list
    if (!keyword.value && view.value === 'USE') lookupUsers.value = data.list
    error.value = ''
  } catch (e) {
    error.value = e instanceof Error ? e.message : '사용자 목록을 불러오지 못했습니다.'
  }
}

function open(user?: User) {
  formError.value = ''
  isNew.value = !user
  form.value = user
    ? {
        USER_ID: user.USER_ID,
        FULL_NAME: user.FULL_NAME,
        EMAIL: user.EMAIL ?? '',
        DIVISION: user.DIVISION ?? '',
        TEAM: user.TEAM ?? '',
        SUPERVISOR_USER_ID: user.SUPERVISOR_USER_ID ?? null,
        ROLE_NAME: user.ROLE_NAME,
        AUTHORIZED: user.AUTHORIZED === 'Y' ? 'Y' : 'S',
      }
    : {
        USER_ID: '',
        FULL_NAME: '',
        EMAIL: '',
        DIVISION: '',
        TEAM: '',
        SUPERVISOR_USER_ID: null,
        ROLE_NAME: 'USER',
        AUTHORIZED: 'Y',
        N_PASSWORD: '',
      }
}

function closeForm() {
  form.value = null
}

async function save() {
  if (!form.value) return
  if (isNew.value && !form.value.N_PASSWORD) {
    formError.value = '신규 사용자의 초기 비밀번호를 입력하세요.'
    return
  }

  saving.value = true
  formError.value = ''
  try {
    await api('/api/admin/user', { method: 'POST', body: JSON.stringify(form.value) })
    closeForm()
    await load()
  } catch (e) {
    formError.value = e instanceof Error ? e.message : '사용자를 저장하지 못했습니다.'
  } finally {
    saving.value = false
  }
}

function openPassword(user: User) {
  passwordError.value = ''
  passwordForm.value = { USER_ID: user.USER_ID, FULL_NAME: user.FULL_NAME, N_PASSWORD: '', C_PASSWORD: '' }
}

async function savePassword() {
  if (!passwordForm.value) return
  if (!passwordForm.value.N_PASSWORD) {
    passwordError.value = '새 비밀번호를 입력하세요.'
    return
  }
  if (passwordForm.value.N_PASSWORD !== passwordForm.value.C_PASSWORD) {
    passwordError.value = '두 비밀번호가 서로 다릅니다.'
    return
  }

  passwordSaving.value = true
  passwordError.value = ''
  try {
    await api('/api/admin/user/password', {
      method: 'POST',
      body: JSON.stringify({ USER_ID: passwordForm.value.USER_ID, N_PASSWORD: passwordForm.value.N_PASSWORD }),
    })
    passwordForm.value = null
  } catch (e) {
    passwordError.value = e instanceof Error ? e.message : '비밀번호를 변경하지 못했습니다.'
  } finally {
    passwordSaving.value = false
  }
}

function remove(user: User) {
  confirmation.request({
    title: '계정 삭제',
    message: `${user.FULL_NAME} (${user.USER_ID}) 계정을 삭제합니다.`,
    confirmLabel: '삭제',
    danger: true,
    action: async () => {
      try {
        await api(query('/api/admin/user', { userId: user.USER_ID }), { method: 'DELETE' })
        await load()
      } catch (e) {
        error.value = e instanceof Error ? e.message : '삭제하지 못했습니다.'
      }
    },
  })
}

function restore(user: User) {
  confirmation.request({
    title: '계정 복구',
    message: `${user.FULL_NAME} (${user.USER_ID}) 계정을 복구합니다. 복구 후 미승인 상태가 됩니다.`,
    confirmLabel: '복구',
    action: async () => {
      try {
        await api(query('/api/admin/user/restore', { userId: user.USER_ID }), { method: 'POST' })
        await load()
      } catch (e) {
        error.value = e instanceof Error ? e.message : '복구하지 못했습니다.'
      }
    },
  })
}

onMounted(load)
</script>

<template>
  <section>
    <ListCard title="사용자 목록">
      <template #header-actions><button v-if="view === 'USE'" @click="open()">사용자 등록</button></template>
      <template #filters
        ><select v-model="view" aria-label="조회 대상" @change="load">
          <option value="USE">사용</option>
          <option value="DEL">삭제</option>
        </select></template
      >
      <template #search
        ><ListSearch
          v-model="keyword"
          label="사용자 검색"
          placeholder="이름 · 아이디 · 이메일 · 팀 검색"
          @search="load"
      /></template>
      <p v-if="error" class="error">{{ error }}</p>
      <AppTable min-width="56rem">
        <thead>
          <tr>
            <th>이름</th>
            <th>아이디</th>
            <th>이메일</th>
            <th>소속</th>
            <th>역할</th>
            <th>상태</th>
            <th>관리</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in users" :key="user.USER_ID">
            <td class="user-name">
              <strong>{{ user.FULL_NAME }}</strong
              ><small v-if="user.SUPERVISOR_NAME">상급자 {{ user.SUPERVISOR_NAME }}</small>
            </td>
            <td class="cell-nowrap">{{ user.USER_ID }}</td>
            <td>{{ user.EMAIL || '-' }}</td>
            <td>
              {{ user.DIVISION }}<span v-if="user.TEAM"> / {{ user.TEAM }}</span>
            </td>
            <td>{{ roleLabel(user.ROLE_NAME) }}</td>
            <td><AppBadge v-bind="accountStatus(user)" /></td>
            <td class="row-actions">
              <template v-if="user.IS_DELETED === 'Y'"
                ><button class="inline" @click="restore(user)">복구</button></template
              ><template v-else
                ><button class="inline" @click="open(user)">수정</button
                ><button class="inline action-info" @click="openPassword(user)">비밀번호</button
                ><button class="inline danger" @click="remove(user)">삭제</button></template
              >
            </td>
          </tr>
          <tr v-if="users.length === 0">
            <td colspan="7" class="user-empty">
              {{ view === 'DEL' ? '삭제된 사용자가 없습니다.' : '사용자가 없습니다.' }}
            </td>
          </tr>
        </tbody>
      </AppTable>
    </ListCard>

    <datalist id="user-division-options">
      <option v-for="division in divisions" :key="division" :value="division" />
    </datalist>
    <datalist id="user-team-options"><option v-for="team in teams" :key="team" :value="team" /></datalist>

    <AppDialog
      :open="form !== null"
      :title="isNew ? '사용자 등록' : '사용자 수정'"
      wide
      @update:open="
        (open) => {
          if (!open) closeForm()
        }
      "
    >
      <form v-if="form" id="user-form" class="user-form" @submit.prevent="save">
        <p v-if="formError" class="error">{{ formError }}</p>
        <div class="user-form-grid">
          <label
            ><span class="field-label">아이디<strong>*</strong></span
            ><input
              v-model.trim="form.USER_ID"
              :disabled="!isNew"
              maxlength="20"
              placeholder="영문·숫자 4~20자"
              required
          /></label>
          <label
            ><span class="field-label">이름<strong>*</strong></span
            ><input v-model.trim="form.FULL_NAME" maxlength="100" required
          /></label>
          <label class="user-form-full"
            >이메일<input v-model.trim="form.EMAIL" type="email" maxlength="100" placeholder="알림 메일을 받을 주소"
          /></label>
          <label
            >본부<input
              v-model.trim="form.DIVISION"
              list="user-division-options"
              maxlength="100"
              placeholder="직접 입력하거나 목록에서 선택"
          /></label>
          <label
            >팀<input
              v-model.trim="form.TEAM"
              list="user-team-options"
              maxlength="100"
              placeholder="직접 입력하거나 목록에서 선택"
          /></label>
          <label class="user-form-third"
            ><span class="field-label">역할<strong>*</strong></span
            ><select v-model="form.ROLE_NAME">
              <option value="ADMIN">관리자</option>
              <option value="USER">유저</option>
              <option value="READER">읽기전용</option>
            </select></label
          >
          <label class="user-form-third"
            ><span class="field-label">계정 상태<strong>*</strong></span
            ><select v-model="form.AUTHORIZED">
              <option value="Y">승인</option>
              <option value="S">미승인</option>
            </select></label
          >
          <label class="user-form-third"
            >상급자<select v-model="form.SUPERVISOR_USER_ID">
              <option :value="null">지정 안 함</option>
              <option v-for="supervisor in supervisors" :key="supervisor.USER_ID" :value="supervisor.USER_ID">
                {{ supervisor.FULL_NAME }} ({{ supervisor.USER_ID }})
              </option>
            </select></label
          >
          <label v-if="isNew" class="user-form-full"
            ><span class="field-label">초기 비밀번호<strong>*</strong></span
            ><input
              v-model="form.N_PASSWORD"
              type="password"
              maxlength="50"
              autocomplete="new-password"
              required
            /><small>8자 이상, 영문·숫자·특수문자를 각각 1자 이상 포함해야 합니다.</small></label
          >
        </div>
      </form>
      <template #footer
        ><button class="secondary" type="button" @click="closeForm">취소</button
        ><button form="user-form" type="submit" :disabled="saving">{{ saving ? '저장 중…' : '저장' }}</button></template
      >
    </AppDialog>

    <AppDialog
      :open="passwordForm !== null"
      title="비밀번호 재설정"
      @update:open="
        (open) => {
          if (!open) passwordForm = null
        }
      "
    >
      <form v-if="passwordForm" id="password-form" class="user-password-form" @submit.prevent="savePassword">
        <p v-if="passwordError" class="error">{{ passwordError }}</p>
        <p>{{ passwordForm.FULL_NAME }} ({{ passwordForm.USER_ID }})</p>
        <label
          ><span class="field-label">새 비밀번호<strong>*</strong></span
          ><input v-model="passwordForm.N_PASSWORD" type="password" maxlength="50" autocomplete="new-password" required
        /></label>
        <label
          ><span class="field-label">새 비밀번호 확인<strong>*</strong></span
          ><input v-model="passwordForm.C_PASSWORD" type="password" maxlength="50" autocomplete="new-password" required
        /></label>
        <small>8자 이상, 영문·숫자·특수문자를 각각 1자 이상 포함해야 합니다.</small>
      </form>
      <template #footer
        ><button class="secondary" type="button" @click="passwordForm = null">취소</button
        ><button form="password-form" type="submit" :disabled="passwordSaving">
          {{ passwordSaving ? '변경 중…' : '변경' }}
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
.user-form {
  display: grid;
  gap: var(--ex-space-4);
}
.user-form-grid {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
  gap: var(--ex-space-4);
}
.user-form-grid > label {
  grid-column: span 3;
  margin: 0;
}
.user-form-grid > .user-form-full {
  grid-column: 1 / -1;
}
.user-form-grid > .user-form-third {
  grid-column: span 2;
}
.user-form small,
.user-password-form > small {
  color: var(--ex-color-text-muted);
  font-size: 0.75rem;
  font-weight: 400;
  line-height: 1.45;
}
.user-password-form {
  display: grid;
  gap: var(--ex-space-4);
}
.user-password-form > p {
  margin: 0;
  font-size: 0.8125rem;
}
.user-password-form > label {
  margin: 0;
}
.user-name small {
  display: block;
  margin-top: 0.25rem;
}
.user-empty {
  color: var(--ex-color-text-muted);
  padding: var(--ex-space-6);
  text-align: center;
}
@media (max-width: 680px) {
  .user-form-grid {
    grid-template-columns: 1fr;
  }
  .user-form-grid > label,
  .user-form-grid > .user-form-third {
    grid-column: 1;
  }
}
</style>
