<script setup lang="ts">
withDefaults(defineProps<{ width?: string; height?: string }>(), { width: '100%', height: '1rem' })
</script>

<template><span class="skeleton" :style="{ width, height }" aria-hidden="true" /></template>

<style scoped>
.skeleton { display: block; border-radius: var(--ex-radius-sm); background: linear-gradient(90deg, var(--ex-color-neutral-subtle) 25%, #f4f7f9 37%, var(--ex-color-neutral-subtle) 63%); background-size: 400% 100%; animation: loading 1.4s ease infinite; }@keyframes loading { 0% { background-position: 100% 50%; } 100% { background-position: 0 50%; } }
</style>
