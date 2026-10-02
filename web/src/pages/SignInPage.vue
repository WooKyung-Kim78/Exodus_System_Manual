<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../api/client'
import { useSessionStore } from '../stores/session'
const userId = ref('')
const password = ref('')
const error = ref('')
const submitting = ref(false)
const route = useRoute()
const router = useRouter()
const session = useSessionStore()
async function signIn() {
  submitting.value = true
  error.value = ''
  try {
    await api('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ USER_ID: userId.value, PASSWORD: password.value }),
    })
    await session.load()
    await router.push(typeof route.query.returnUrl === 'string' ? route.query.returnUrl : '/')
  } catch (e) {
    error.value = e instanceof Error ? e.message : '로그인하지 못했습니다.'
  } finally {
    submitting.value = false
  }
}
</script>
<template>
  <main class="signin">
    <div class="signin-card">
      <div class="signin-form">
        <RouterLink class="signin-brand" to="/"><strong>EXODUS</strong><span>System Manual</span></RouterLink>
        <form @submit.prevent="signIn">
          <header>
            <h1>로그인</h1>
            <p>사내 계정으로 시스템 매뉴얼 플랫폼에 접속합니다.</p>
          </header>
          <label>ID<input v-model="userId" autocomplete="username" required /></label
          ><label>Password<input v-model="password" type="password" autocomplete="current-password" required /></label>
          <p v-if="error" class="error">{{ error }}</p>
          <button :disabled="submitting">{{ submitting ? '로그인 중…' : 'Sign In' }}</button>
        </form>
        <small>© 2026 Exodus Advanced Communications. All rights reserved.</small>
      </div>
      <aside class="signin-intro">
        <span>Knowledge Base Platform</span>
        <h2>시스템 매뉴얼을 한곳에서 작성하고 배포합니다.</h2>
        <p>목차별 담당 팀이 함께 문서를 채우고, 검토를 거쳐 표준 서식의 PDF로 배포합니다.</p>
        <ul>
          <li>팀 단위 공동 작성과 편집 권한 관리</li>
          <li>목차 템플릿으로 문서 구조 표준화</li>
          <li>변경 이력 추적과 버전 관리</li>
        </ul>
      </aside>
    </div>
  </main>
</template>
