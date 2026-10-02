<script setup lang="ts">
defineProps<{ code: number }>()
</script>
<template>
  <main class="error-page">
    <h1>{{ code }}</h1>
    <p>{{ code === 403 ? '이 페이지에 접근할 권한이 없습니다.' : '요청한 페이지를 찾을 수 없습니다.' }}</p>
    <RouterLink to="/manual">문서 목록으로</RouterLink>
  </main>
</template>
