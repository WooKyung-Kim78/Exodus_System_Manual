<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, initializeCsrf } from '../api/client'
import { useSessionStore } from '../stores/session'
const userId = ref(''); const password = ref(''); const error = ref(''); const submitting = ref(false)
const route = useRoute(); const router = useRouter(); const session = useSessionStore()
async function signIn() { submitting.value = true; error.value = ''; try { await initializeCsrf(); await api('/api/auth/login', { method: 'POST', body: JSON.stringify({ USER_ID: userId.value, PASSWORD: password.value }) }); await session.load(); await router.push(typeof route.query.returnUrl === 'string' ? route.query.returnUrl : '/') } catch (e) { error.value = e instanceof Error ? e.message : '로그인하지 못했습니다.' } finally { submitting.value = false } }
</script>
<template><main class="signin"><form @submit.prevent="signIn"><h1>EXODUS System Manual</h1><p>계정으로 로그인하세요.</p><label>아이디<input v-model="userId" autocomplete="username" required /></label><label>비밀번호<input v-model="password" type="password" autocomplete="current-password" required /></label><p v-if="error" class="error">{{ error }}</p><button :disabled="submitting">{{ submitting ? '로그인 중…' : '로그인' }}</button></form></main></template>
