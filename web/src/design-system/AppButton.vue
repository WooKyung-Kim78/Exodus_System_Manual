<script setup lang="ts">
withDefaults(defineProps<{ variant?: 'primary' | 'secondary' | 'danger' | 'ghost' }>(), { variant: 'primary' })
</script>

<template><button class="app-button" :class="`app-button--${variant}`"><slot /></button></template>

<style scoped>
.app-button { border: 0; border-radius: var(--ex-radius-sm); padding: var(--ex-space-2) var(--ex-space-3); cursor: pointer; font: inherit; font-weight: 600; }
.app-button:focus-visible { outline: 3px solid var(--ex-color-focus); outline-offset: 2px; }
.app-button:disabled { cursor: not-allowed; opacity: .55; }
.app-button--primary { background: var(--ex-color-primary); color: white; }.app-button--secondary { background: var(--ex-color-secondary); color: var(--ex-color-text); }.app-button--danger { background: var(--ex-color-danger); color: white; }.app-button--ghost { background: transparent; color: var(--ex-color-text-muted); }
</style>
