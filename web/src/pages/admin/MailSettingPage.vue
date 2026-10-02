<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { api, query } from '../../api/client'
import AppBadge from '../../design-system/AppBadge.vue'
interface Setting {
  SYSTEM_NAME: string
  SYSTEM_EMAIL: string
  SYSTEM_SMTP: string
  SYSTEM_SMTP_PORT: string
  SYSTEM_SMTP_SECURE: string
  SYSTEM_EMAIL_ID: string
  SYSTEM_SMTP_SCOPE: string
}
interface Log {
  IDX: number
  MAIL_TYPE: string
  TO_LIST: string
  SUBJECT: string
  IS_SUCCESS: string
  ERROR_MSG?: string
  REG_DT: string
}
const setting = ref<Setting>({
  SYSTEM_NAME: '',
  SYSTEM_EMAIL: '',
  SYSTEM_SMTP: '',
  SYSTEM_SMTP_PORT: '587',
  SYSTEM_SMTP_SECURE: 'STARTTLS',
  SYSTEM_EMAIL_ID: '',
  SYSTEM_SMTP_SCOPE: 'T',
})
const password = ref('')
const hasPassword = ref(false)
const testTo = ref('')
const logs = ref<Log[]>([])
const error = ref('')
const saving = ref(false)
const sending = ref(false)
const logLoading = ref(false)
const testMode = computed(() => setting.value.SYSTEM_SMTP_SCOPE === 'T')
async function load() {
  try {
    const data = await api<{ setting: Setting; hasPassword: boolean }>('/api/admin/setting/mail')
    setting.value = data.setting
    hasPassword.value = data.hasPassword
  } catch (e) {
    error.value = e instanceof Error ? e.message : '설정을 불러오지 못했습니다.'
  }
}
async function loadLogs() {
  logLoading.value = true
  try {
    logs.value = (await api<{ list: Log[] }>('/api/admin/setting/mail/log')).list
  } catch (e) {
    error.value = e instanceof Error ? e.message : '발송 이력을 불러오지 못했습니다.'
  } finally {
    logLoading.value = false
  }
}
async function save() {
  saving.value = true
  try {
    await api('/api/admin/setting/mail', {
      method: 'POST',
      body: JSON.stringify({ ...setting.value, SYSTEM_EMAIL_PASSWORD: password.value }),
    })
    password.value = ''
    await load()
  } catch (e) {
    error.value = e instanceof Error ? e.message : '설정을 저장하지 못했습니다.'
  } finally {
    saving.value = false
  }
}
async function sendTest() {
  if (!testTo.value) {
    error.value = '받는 사람 주소를 입력하세요.'
    return
  }
  sending.value = true
  try {
    await api(query('/api/admin/setting/mail/test', { to: testTo.value }), { method: 'POST' })
    await loadLogs()
  } catch (e) {
    error.value = e instanceof Error ? e.message : '테스트 메일을 보내지 못했습니다.'
  } finally {
    sending.value = false
  }
}
function formatDate(value: string) {
  return new Intl.DateTimeFormat('ko-KR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
}
onMounted(async () => {
  await Promise.all([load(), loadLogs()])
})
</script>
<template>
  <section>
    <div class="page-title mail-settings-title">
      <div><h1>메일 설정</h1></div>
    </div>
    <p v-if="error" class="error">{{ error }}</p>
    <div class="mail-settings-grid">
      <form class="panel admin-card" @submit.prevent="save">
        <header class="admin-card-header"><h2>SMTP</h2></header>
        <div class="admin-card-content smtp-fields">
          <p v-if="testMode" class="mail-scope-notice full-width">
            적용 범위가 <strong>TEST</strong> 입니다. 메일을 실제로 보내지 않고 <code>App_Data/mail-drop</code> 폴더에
            <code>.eml</code> 파일로 저장합니다.
          </p>
          <label>시스템 이름<input v-model="setting.SYSTEM_NAME" required /></label
          ><label>발신 주소<input v-model="setting.SYSTEM_EMAIL" type="email" required /></label
          ><label>SMTP 서버<input v-model="setting.SYSTEM_SMTP" required /></label
          ><label>포트<input v-model="setting.SYSTEM_SMTP_PORT" type="number" required /></label
          ><label
            >보안<select v-model="setting.SYSTEM_SMTP_SECURE">
              <option>STARTTLS</option>
              <option>SSL</option>
              <option>NONE</option>
            </select></label
          ><label
            >발송 범위<select v-model="setting.SYSTEM_SMTP_SCOPE">
              <option value="T">TEST (메일 파일 저장)</option>
              <option value="P">PRODUCTION</option>
            </select></label
          ><label class="full-width">계정 ID<input v-model="setting.SYSTEM_EMAIL_ID" /></label
          ><label class="full-width"
            >계정 비밀번호 <small>{{ hasPassword ? '설정됨 — 비워 두면 유지' : '미설정' }}</small
            ><input v-model="password" type="password" /></label
          ><small class="full-width">암호화된 저장값은 화면으로 다시 내려주지 않습니다.</small>
          <div class="actions full-width">
            <button class="form-submit" :disabled="saving">{{ saving ? '저장 중…' : '설정 저장' }}</button>
          </div>
        </div>
      </form>
      <div class="mail-settings-side">
        <section class="panel admin-card">
          <header class="admin-card-header"><h2>테스트 발송</h2></header>
          <div class="admin-card-content">
            <label>받는 사람<input v-model="testTo" type="email" placeholder="you@example.com" /></label
            ><button class="form-submit" type="button" :disabled="sending" @click="sendTest">
              {{ sending ? '발송 중…' : '테스트 메일 발송' }}
            </button>
          </div>
        </section>
        <section class="panel admin-card">
          <header class="admin-card-header">
            <h2>발송 이력</h2>
            <button class="secondary inline" type="button" :disabled="logLoading" @click="loadLogs">
              {{ logLoading ? '새로고침 중…' : '새로고침' }}
            </button>
          </header>
          <div class="admin-card-content">
            <p v-if="logLoading && logs.length === 0">불러오는 중…</p>
            <p v-else-if="logs.length === 0">발송 이력이 없습니다.</p>
            <div v-else class="mail-log-list">
              <article v-for="log in logs" :key="log.IDX" class="mail-log-item">
                <div>
                  <strong>{{ log.SUBJECT }}</strong
                  ><small>수신: {{ log.TO_LIST }}</small
                  ><small>{{ formatDate(log.REG_DT) }} · {{ log.MAIL_TYPE }}</small
                  ><small v-if="log.ERROR_MSG" class="mail-log-error">{{ log.ERROR_MSG }}</small>
                </div>
                <AppBadge
                  :label="log.IS_SUCCESS === 'Y' ? '성공' : '실패'"
                  :tone="log.IS_SUCCESS === 'Y' ? 'success' : 'danger'"
                />
              </article>
            </div>
          </div>
        </section>
      </div>
    </div>
  </section>
</template>
